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
from calibration.pnp_solve import CameraSolution  # noqa: E402

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


def _build_camera_matrix(image_width: int, image_height: int) -> np.ndarray:
    """Same approximate-intrinsics assumption as `pnp_solve.py`'s own
    helper: focal length ~= image width, principal point at image
    center."""
    focal_length = float(image_width)
    cx, cy = image_width / 2.0, image_height / 2.0
    return np.array(
        [[focal_length, 0, cx], [0, focal_length, cy], [0, 0, 1]], dtype=np.float64
    )


def _shoulder_width_px(anchor_pose: dict) -> float | None:
    left, right = anchor_pose.get("left_shoulder_seam"), anchor_pose.get("right_shoulder_seam")
    if not left or not right or left["confidence"] <= 0.0 or right["confidence"] <= 0.0:
        return None
    return abs(right["x_px"] - left["x_px"])


def solve_camera_pose(
    anchor_pose: dict,
    image_width: int,
    image_height: int,
    anchors: dict | None = None,
    *,
    min_correspondences: int = MIN_CORRESPONDENCES_DEFAULT,
    min_confidence: float = MIN_CONFIDENCE_DEFAULT,
) -> CameraSolution:
    if anchors is None:
        anchors = _load_anchors()

    object_points: list[list[float]] = []
    image_points: list[list[float]] = []

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
    camera_matrix = _build_camera_matrix(image_width, image_height)
    dist_coeffs = np.zeros((4, 1))

    ok, rvec, tvec = cv2.solvePnP(
        object_points_np,
        image_points_np,
        camera_matrix,
        dist_coeffs,
        flags=cv2.SOLVEPNP_ITERATIVE,
    )
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
    reliable = reprojection_error <= error_threshold_px

    return CameraSolution(
        solved=True,
        reason="ok" if reliable else "high_reprojection_error",
        rotation_vec=rvec,
        translation_vec=tvec,
        camera_matrix=camera_matrix,
        reprojection_error_px=reprojection_error,
        correspondence_count=len(object_points),
        reliable=reliable,
    )
