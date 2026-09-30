"""Recovers camera pose via PnP from Milestone B's 2D anchor-pose
estimate (`pose/anchor_mapping.py`) + the known 3D anchors
(`rules/anchors.male.json`).

This is a second correspondence-gathering path alongside
`calibration/pnp_solve.py`'s own `solve_camera_pose(pose: PoseResult,
...)` — that one takes a raw `PoseResult` and looks up a fixed 7-anchor
`CORRESPONDENCES` list by BlazePose landmark name; this one takes
Milestone B's already-anchor-keyed dict and can use up to 15
correspondences (every socket Milestone B estimates with confidence
above `min_confidence`), including 8 anchors PnP never had access to
before. Neither replaces the other — see
`ChangeRequest/2026-08-11_cv-service-geometry-camera-pose-rule-projection.md`
§2 for why. What IS reused, not reinvented: `pnp_solve.py`'s
`CameraSolution` type and `project_point()` — the projection math itself
is already proven; only the correspondence-gathering differs here.

    from geometry.solve_camera_pose import solve_camera_pose
    from pose.anchor_mapping import estimate_anchor_pose
    anchor_pose = estimate_anchor_pose("photo.jpg")
    camera = solve_camera_pose(anchor_pose, image_width=800, image_height=1200)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import config  # noqa: E402
from calibration.pnp_solve import CameraSolution, best_pnp_solution, points_in_front  # noqa: E402

_ANCHORS_PATH = Path(__file__).resolve().parents[1] / "rules" / "anchors.male.json"

# See config.py + the plan file's §3 for the reasoning behind both
# constants: 0.3 keeps well-detected heuristic (interpolated/extrapolated)
# anchors, which report confidence well below a raw-visibility threshold
# by design; 6 gives a stability margin above solvePnP's mathematical
# minimum of 4.
MIN_CONFIDENCE_DEFAULT = config.PNP_V2_MIN_CONFIDENCE
MIN_CORRESPONDENCES_DEFAULT = config.PNP_V2_MIN_CORRESPONDENCES

# chest_center is derived (midpoint of the two chest-pocket estimates,
# both already in the candidate correspondence set) — including it adds
# no new geometric information and risks quietly weighting the solve
# toward its own derivation.
_EXCLUDED_FROM_CORRESPONDENCES = {"chest_center"}


def _load_anchors(path: Path = _ANCHORS_PATH) -> dict:
    return json.loads(path.read_text())["anchors"]


def _build_camera_matrix(image_width: int, image_height: int, focal_px: float | None = None) -> np.ndarray:
    """Pinhole intrinsics. `focal_px` comes from the photo's EXIF
    (`api/intrinsics.py`) when available; otherwise the same
    focal ≈ image-width assumption as `pnp_solve.py` (a mis-guessed focal
    length is traded off against camera distance by PnP, which is where
    most of the recovered-depth error came from)."""
    focal_length = float(focal_px) if focal_px else float(image_width)
    cx, cy = image_width / 2.0, image_height / 2.0
    return np.array(
        [[focal_length, 0, cx], [0, focal_length, cy], [0, 0, 1]], dtype=np.float64
    )


def _shoulder_width_px(anchor_pose: dict) -> float | None:
    left, right = anchor_pose.get("left_shoulder_seam"), anchor_pose.get("right_shoulder_seam")
    if not left or not right or left["confidence"] <= 0.0 or right["confidence"] <= 0.0:
        return None
    return abs(right["x_px"] - left["x_px"])


def gravity_disagreement_deg(rvec: np.ndarray, gravity_up_cam) -> float:
    """Angle between the solved camera's world-up direction (R[:, 1] —
    world +y expressed in camera coordinates) and the phone's measured
    one."""
    rotation, _ = cv2.Rodrigues(rvec)
    measured = np.asarray(gravity_up_cam, dtype=np.float64)
    measured = measured / np.linalg.norm(measured)
    return float(np.degrees(np.arccos(np.clip(rotation[:, 1] @ measured, -1.0, 1.0))))


def refine_weighted(obj, img, camera_matrix, rvec, tvec, sigmas_px=None, gravity_up_cam=None):
    """Final least-squares refinement of a PnP solution.

    - Each correspondence's reprojection residual is divided by its own
      uncertainty `sigmas_px` (the anchor's calibrated residual spread —
      see pose/anchor_mapping.apply_anchor_offsets), rescaled so residuals
      stay in pixel units: precise anchors (shoulder seams, sleeves ±3 px)
      now outvote noisy ones (collar tips, pockets, ankles ±12-22 px)
      instead of all counting equally. On the violation benchmark, the
      horizontal scatter of projected doctrine points came mostly from
      exactly those noisy anchors.
    - D16: with the phone's accelerometer, adds a soft prior on camera
      pitch/roll — `config.GRAVITY_PRIOR_PX_PER_DEG` px per degree of
      disagreement. From a near-frontal view pitch is weakly constrained by
      body landmarks alone; the phone measures it directly to ~1°.

    Returns the input solution unchanged on optimiser failure."""
    from scipy.optimize import least_squares

    weights = np.ones(len(obj))
    if sigmas_px is not None:
        sigmas = np.maximum(np.asarray(sigmas_px, dtype=np.float64), config.PNP_MIN_SIGMA_PX)
        weights = sigmas.mean() / sigmas
    measured = None
    if gravity_up_cam is not None:
        measured = np.asarray(gravity_up_cam, dtype=np.float64)
        norm = np.linalg.norm(measured)
        measured = measured / norm if np.isfinite(norm) and norm > 1e-6 else None
    gravity_weight = config.GRAVITY_PRIOR_PX_PER_DEG * 180.0 / np.pi
    dist = np.zeros((4, 1))

    def residuals(params):
        r, t = params[:3].reshape(3, 1), params[3:].reshape(3, 1)
        projected, _ = cv2.projectPoints(obj, r, t, camera_matrix, dist)
        parts = [((projected.reshape(-1, 2) - img) * weights[:, None]).ravel()]
        if measured is not None:
            rotation, _ = cv2.Rodrigues(r)
            parts.append(gravity_weight * (rotation[:, 1] - measured))
        return np.concatenate(parts)

    try:
        result = least_squares(residuals, np.concatenate([rvec.ravel(), tvec.ravel()]), method="lm")
    except Exception:  # noqa: BLE001 - keep the unrefined solution
        return rvec, tvec
    if not result.success:
        return rvec, tvec
    return result.x[:3].reshape(3, 1), result.x[3:].reshape(3, 1)


def refine_with_gravity(obj, img, camera_matrix, rvec, tvec, gravity_up_cam):
    """Gravity-prior-only refinement (unweighted correspondences)."""
    return refine_weighted(obj, img, camera_matrix, rvec, tvec, None, gravity_up_cam)


def solve_camera_pose(
    anchor_pose: dict,
    image_width: int,
    image_height: int,
    anchors: dict | None = None,
    *,
    min_correspondences: int = MIN_CORRESPONDENCES_DEFAULT,
    min_confidence: float = MIN_CONFIDENCE_DEFAULT,
    focal_px: float | None = None,
    gravity_up_cam: tuple[float, float, float] | None = None,
) -> CameraSolution:
    if anchors is None:
        anchors = _load_anchors()

    object_points: list[list[float]] = []
    image_points: list[list[float]] = []
    sigmas: list[float | None] = []

    for anchor_name, estimate in anchor_pose.items():
        if anchor_name in _EXCLUDED_FROM_CORRESPONDENCES:
            continue
        if estimate["confidence"] < min_confidence or estimate["x_px"] is None:
            continue
        anchor_3d = anchors.get(anchor_name)
        if anchor_3d is None:
            continue
        object_points.append([anchor_3d["x"], anchor_3d["y"], anchor_3d["z"]])
        image_points.append([estimate["x_px"], estimate["y_px"]])
        sigmas.append(estimate.get("residual_px"))

    if len(object_points) < min_correspondences:
        return CameraSolution(
            solved=False,
            reason="insufficient_correspondences",
            rotation_vec=None,
            translation_vec=None,
            camera_matrix=None,
            reprojection_error_px=None,
            correspondence_count=len(object_points),
        )

    object_points_np = np.array(object_points, dtype=np.float64)
    image_points_np = np.array(image_points, dtype=np.float64)
    camera_matrix = _build_camera_matrix(image_width, image_height, focal_px)
    dist_coeffs = np.zeros((4, 1))

    ok, rvec, tvec = best_pnp_solution(object_points_np, image_points_np, camera_matrix, dist_coeffs)
    if ok and config.PNP_WEIGHTED_REFINEMENT:
        # Uncalibrated estimates (no residual_px) get the median known sigma,
        # or a neutral 1.0 when none is known (plain unweighted refinement).
        known = [x for x in sigmas if x]
        default_sigma = float(np.median(known)) if known else 1.0
        sigmas_px = [x if x else default_sigma for x in sigmas]
        rvec, tvec = refine_weighted(object_points_np, image_points_np, camera_matrix, rvec, tvec, sigmas_px, gravity_up_cam)
    elif ok and gravity_up_cam is not None:
        rvec, tvec = refine_with_gravity(object_points_np, image_points_np, camera_matrix, rvec, tvec, gravity_up_cam)
    if not ok:
        return CameraSolution(
            solved=False,
            reason="solvepnp_failed",
            rotation_vec=None,
            translation_vec=None,
            camera_matrix=None,
            reprojection_error_px=None,
            correspondence_count=len(object_points),
        )

    projected, _ = cv2.projectPoints(object_points_np, rvec, tvec, camera_matrix, dist_coeffs)
    reprojection_error = float(
        np.mean(np.linalg.norm(projected.reshape(-1, 2) - image_points_np, axis=1))
    )

    shoulder_width = _shoulder_width_px(anchor_pose)
    if shoulder_width:
        error_threshold_px = shoulder_width * 0.4
    else:
        error_threshold_px = max(image_width, image_height) * 0.03
    in_front = points_in_front(object_points_np, rvec, tvec)
    reliable = reprojection_error <= error_threshold_px and in_front
    if reliable:
        reason = "ok"
    elif not in_front:
        reason = "points_behind_camera"
    else:
        reason = "high_reprojection_error"

    return CameraSolution(
        solved=True,
        reason=reason,
        rotation_vec=rvec,
        translation_vec=tvec,
        camera_matrix=camera_matrix,
        reprojection_error_px=reprojection_error,
        correspondence_count=len(object_points),
        reliable=reliable,
    )
