"""PnP + projection math, validated against synthetic correspondences.

No real photo and no MediaPipe/YOLO inference needed here: pick a known
camera, project the canonical anchors through it to synthesize "detected"
2D landmarks, then confirm `solve_camera_pose` recovers a camera that
reprojects those same anchors accurately — and, crucially, that a held-out
anchor never used in the correspondence set (`chest_center`) also projects
correctly. That held-out check is the actual point of Stage 3: the camera
solved from a few known body points must generalize to project *every*
other doctrine anchor correctly, since that's what the rule engine relies
on for accessories with no direct pose-landmark equivalent.
"""

from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np
import pytest

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from calibration.pnp_solve import (  # noqa: E402
    CORRESPONDENCES,
    _build_camera_matrix,
    _load_anchors,
    project_point,
    scale_factor_cm_per_unit,
    solve_camera_pose,
)
from pose.estimate_pose import Landmark2D, PoseResult  # noqa: E402

IMAGE_WIDTH, IMAGE_HEIGHT = 1200, 1600

# A plausible "photo taken from slightly off-center, a couple of metres
# back" camera — arbitrary but fixed, not tuned to make the test pass.
TRUE_RVEC = np.array([[0.05], [0.15], [0.02]])
TRUE_TVEC = np.array([[0.08], [-0.05], [2.4]])


def _synthesize_pose() -> tuple[PoseResult, dict]:
    anchors = _load_anchors()
    camera_matrix = _build_camera_matrix(IMAGE_WIDTH, IMAGE_HEIGHT)
    dist_coeffs = np.zeros((4, 1))

    landmarks: dict[int, Landmark2D] = {}
    name_to_index = {
        "left_shoulder": 11,
        "right_shoulder": 12,
        "left_ankle": 27,
        "right_ankle": 28,
        "left_foot_index": 31,
        "right_foot_index": 32,
        "left_hip": 23,
        "right_hip": 24,
    }

    def project(anchor_name: str) -> tuple[float, float]:
        pt = anchors[anchor_name]
        obj = np.array([[pt["x"], pt["y"], pt["z"]]], dtype=np.float64)
        projected, _ = cv2.projectPoints(obj, TRUE_RVEC, TRUE_TVEC, camera_matrix, dist_coeffs)
        return float(projected[0, 0, 0]), float(projected[0, 0, 1])

    for anchor_name, landmark_name in CORRESPONDENCES:
        px, py = project(anchor_name)
        landmarks[name_to_index[landmark_name]] = Landmark2D(
            x_px=px, y_px=py, visibility=0.99, presence=0.99
        )

    # hip midpoint proxy for belt_center
    belt_px, belt_py = project("belt_center")
    # place both hips symmetrically around the true belt projection so
    # their midpoint reproduces it, matching solve_camera_pose's own logic
    landmarks[23] = Landmark2D(x_px=belt_px - 10, y_px=belt_py, visibility=0.99, presence=0.99)
    landmarks[24] = Landmark2D(x_px=belt_px + 10, y_px=belt_py, visibility=0.99, presence=0.99)

    pose = PoseResult(
        found=True, landmarks=landmarks, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT
    )
    return pose, anchors


def test_solve_camera_pose_succeeds_with_full_correspondence_set():
    pose, _ = _synthesize_pose()
    camera = solve_camera_pose(pose)
    assert camera.solved, camera.reason
    assert camera.correspondence_count >= 6
    assert camera.reprojection_error_px < 1.0  # near-zero: synthetic, noiseless data


def test_projection_generalizes_to_a_held_out_anchor():
    """chest_center is never in CORRESPONDENCES — this is the real test."""
    pose, anchors = _synthesize_pose()
    camera = solve_camera_pose(pose)
    assert camera.solved

    chest = anchors["chest_center"]
    predicted_px = project_point((chest["x"], chest["y"], chest["z"]), camera)

    camera_matrix = _build_camera_matrix(IMAGE_WIDTH, IMAGE_HEIGHT)
    true_px, _ = cv2.projectPoints(
        np.array([[chest["x"], chest["y"], chest["z"]]]),
        TRUE_RVEC,
        TRUE_TVEC,
        camera_matrix,
        np.zeros((4, 1)),
    )
    true_x, true_y = float(true_px[0, 0, 0]), float(true_px[0, 0, 1])

    assert abs(predicted_px[0] - true_x) < 2.0
    assert abs(predicted_px[1] - true_y) < 2.0


def test_insufficient_correspondences_reported_not_crashed():
    empty_pose = PoseResult(found=False, landmarks={}, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    camera = solve_camera_pose(empty_pose)
    assert not camera.solved
    assert camera.reason == "insufficient_correspondences"


def test_scale_factor_is_positive_and_finite():
    pose, _ = _synthesize_pose()
    factor = scale_factor_cm_per_unit(pose)
    assert factor is not None
    assert factor > 0
