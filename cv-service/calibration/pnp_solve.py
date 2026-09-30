"""Stage 3 — camera pose recovery via PnP.

The core idea of the whole pipeline (see the architecture memo, Stage
3): the reference body's canonical 3D anchors are already correct,
doctrine-aligned geometry — this module recovers *where the camera
was standing* relative to that geometry, so every other anchor+offset
in `rules/army_no3_male.json` can be projected onto this specific
photo, instead of re-deriving placement rules in 2D from scratch.

Method: classical Perspective-n-Point (`cv2.solvePnP`), not a learned
model — a fixed correspondence set between canonical 3D anchors
(`rules/anchors.male.json`) and 2D BlazePose landmarks
(`pose/estimate_pose.py`), solved once per photo.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np

import config
from pose.estimate_pose import PoseResult

_ANCHORS_PATH = Path(__file__).resolve().parents[1] / "rules" / "anchors.male.json"

# (canonical 3D anchor name, 2D pose landmark name) — the anatomically
# sound overlap between the 15-socket body rig and BlazePose's 33
# points. `belt_center` has no direct BlazePose equivalent; the hip
# midpoint is a reasonable proxy for waist height and is computed by
# the caller before solving, not read directly off one landmark.
CORRESPONDENCES = [
    ("left_shoulder_seam", "left_shoulder"),
    ("right_shoulder_seam", "right_shoulder"),
    ("left_ankle", "left_ankle"),
    ("right_ankle", "right_ankle"),
    ("left_foot_top", "left_foot_index"),
    ("right_foot_top", "right_foot_index"),
]


def _load_anchors(path: Path = _ANCHORS_PATH) -> dict:
    return json.loads(path.read_text())["anchors"]


@dataclass(frozen=True)
class CameraSolution:
    solved: bool
    reason: str
    rotation_vec: np.ndarray | None
    translation_vec: np.ndarray | None
    camera_matrix: np.ndarray | None
    reprojection_error_px: float | None
    correspondence_count: int
    reliable: bool = False
    """True only when `solvePnP` converged AND the reprojection error is
    low enough to trust for tight cm-tolerance geometric checks (§9).
    `solved=True, reliable=False` happens for real: e.g. a body pose
    that doesn't resemble the reference A-pose (arms spread wide, deep
    lunge) makes `solvePnP` converge to a mathematically-valid but
    physically-nonsensical camera — see the architecture memo §10's
    "extreme angle" fallback. Rule callers should not run precise
    distance/tolerance checks against an unreliable solution; treat it
    the same as `solved=False` for anything beyond rough region
    guidance."""


def _build_camera_matrix(image_width: int, image_height: int) -> np.ndarray:
    """Approximate intrinsics: focal length ~= image width, principal
    point at image center. Standard assumption for `solvePnP` when the
    true camera calibration is unknown — good enough for a phone
    photo at typical field of view; revisit if EXIF focal length
    becomes available."""
    focal_length = float(image_width)
    cx, cy = image_width / 2.0, image_height / 2.0
    return np.array(
        [[focal_length, 0, cx], [0, focal_length, cy], [0, 0, 1]], dtype=np.float64
    )


def points_in_front(object_points: np.ndarray, rvec: np.ndarray, tvec: np.ndarray) -> bool:
    """Cheirality check: every correspondence must have positive depth in
    the solved camera frame. `solvePnP` can return a solution with the
    body *behind* the camera that still reprojects with low error (a
    point behind the camera projects mirrored) — that's exactly how a
    left/right-swapped anchor set used to "fit" (see
    utils/extract_anchors.py `_to_anatomical_sides`). A low reprojection
    error alone is not enough to call a camera reliable."""
    rotation, _ = cv2.Rodrigues(rvec)
    depths = (object_points @ rotation.T + np.asarray(tvec).reshape(1, 3))[:, 2]
    return bool(np.all(depths > 0))


# A camera ~2.5 m in front of the body looking at it: OpenCV camera axes
# (x right, y down, z forward) = world (+x, -y, -z) -> R = diag(1,-1,-1),
# i.e. a 180° rotation about x. Used to seed the iterative solve so it
# starts in the physically plausible basin.
_FRONTAL_RVEC = np.array([[np.pi], [0.0], [0.0]])
_FRONTAL_TVEC = np.array([[0.0], [1.0], [2.5]])


def _reprojection_error(obj, img, rvec, tvec, camera_matrix, dist) -> float:
    projected, _ = cv2.projectPoints(obj, rvec, tvec, camera_matrix, dist)
    return float(np.mean(np.linalg.norm(projected.reshape(-1, 2) - img, axis=1)))


def best_pnp_solution(obj, img, camera_matrix, dist):
    """Runs a frontal-seeded iterative solve and SQPnP, and keeps the
    lowest-error candidate that is physically valid (all points in front
    of the camera). Falls back to the lowest-error candidate overall —
    the caller's cheirality check then marks it unreliable."""
    candidates = []
    try:
        ok, rvec, tvec = cv2.solvePnP(
            obj, img, camera_matrix, dist,
            rvec=_FRONTAL_RVEC.copy(), tvec=_FRONTAL_TVEC.copy(),
            useExtrinsicGuess=True, flags=cv2.SOLVEPNP_ITERATIVE,
        )
        if ok:
            candidates.append((rvec, tvec))
    except cv2.error:
        pass
    try:
        ok, rvec, tvec = cv2.solvePnP(obj, img, camera_matrix, dist, flags=cv2.SOLVEPNP_SQPNP)
        if ok:
            candidates.append((rvec, tvec))
    except cv2.error:
        pass
    if not candidates:
        return False, None, None
    scored = sorted(
        candidates,
        key=lambda c: (not points_in_front(obj, c[0], c[1]), _reprojection_error(obj, img, c[0], c[1], camera_matrix, dist)),
    )
    return True, scored[0][0], scored[0][1]


def solve_camera_pose(
    pose: PoseResult, anchors: dict | None = None, *, min_correspondences: int = 4
) -> CameraSolution:
    if anchors is None:
        anchors = _load_anchors()

    object_points: list[list[float]] = []
    image_points: list[list[float]] = []

    for anchor_name, landmark_name in CORRESPONDENCES:
        landmark = pose.named(landmark_name)
        anchor = anchors.get(anchor_name)
        if landmark is None or anchor is None:
            continue
        if landmark.visibility < config.MIN_POSE_VISIBILITY:
            continue
        object_points.append([anchor["x"], anchor["y"], anchor["z"]])
        image_points.append([landmark.x_px, landmark.y_px])

    # belt_center has no single matching BlazePose point — approximate
    # it with the hip midpoint, included separately since it needs both
    # hip landmarks to be visible together.
    left_hip, right_hip = pose.named("left_hip"), pose.named("right_hip")
    belt_anchor = anchors.get("belt_center")
    if (
        left_hip
        and right_hip
        and belt_anchor
        and left_hip.visibility > config.MIN_POSE_VISIBILITY
        and right_hip.visibility > config.MIN_POSE_VISIBILITY
    ):
        object_points.append([belt_anchor["x"], belt_anchor["y"], belt_anchor["z"]])
        image_points.append(
            [(left_hip.x_px + right_hip.x_px) / 2, (left_hip.y_px + right_hip.y_px) / 2]
        )

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
    camera_matrix = _build_camera_matrix(pose.image_width, pose.image_height)
    dist_coeffs = np.zeros((4, 1))  # assume negligible lens distortion

    ok, rvec, tvec = best_pnp_solution(object_points_np, image_points_np, camera_matrix, dist_coeffs)
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

    projected, _ = cv2.projectPoints(
        object_points_np, rvec, tvec, camera_matrix, dist_coeffs
    )
    reprojection_error = float(
        np.mean(np.linalg.norm(projected.reshape(-1, 2) - image_points_np, axis=1))
    )

    # Reliability threshold, scaled to the subject's own measured size
    # rather than a fixed pixel count — a tight crop and a full-body
    # shot need different absolute tolerances. Shoulder width is the
    # steadiest scale reference available (see scale_factor_cm_per_unit);
    # fall back to a fraction of image size when it's missing.
    if pose.shoulder_width_px:
        error_threshold_px = pose.shoulder_width_px * config.PNP_RELIABILITY_SHOULDER_WIDTH_FRACTION
    else:
        error_threshold_px = (
            max(pose.image_width, pose.image_height) * config.PNP_RELIABILITY_IMAGE_SIZE_FRACTION
        )
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


def project_point(
    point_xyz: tuple[float, float, float], camera: CameraSolution
) -> tuple[float, float]:
    """Project a canonical 3D point (an anchor + rule offset, already
    summed by the caller) into this photo's pixel space."""
    if not camera.solved:
        raise ValueError("cannot project through an unsolved camera")
    object_point = np.array([point_xyz], dtype=np.float64)
    if not points_in_front(object_point, camera.rotation_vec, camera.translation_vec):
        raise ValueError("point is behind the camera")
    dist_coeffs = np.zeros((4, 1))
    projected, _ = cv2.projectPoints(
        object_point, camera.rotation_vec, camera.translation_vec, camera.camera_matrix, dist_coeffs
    )
    px, py = projected.reshape(2)
    return float(px), float(py)


def scale_factor_cm_per_unit(pose: PoseResult) -> float | None:
    """cm-per-pixel at the subject's depth, derived from the ratio of
    the canonical anchors' real shoulder width to this photo's
    measured shoulder width — see the architecture memo §9."""
    if pose.shoulder_width_px is None or pose.shoulder_width_px == 0:
        return None
    anchors = _load_anchors()
    left = anchors["left_shoulder_seam"]
    right = anchors["right_shoulder_seam"]
    reference_shoulder_width_cm = abs(right["x"] - left["x"]) * 100.0
    return reference_shoulder_width_cm / pose.shoulder_width_px
