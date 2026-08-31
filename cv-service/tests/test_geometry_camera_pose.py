"""Tests for `geometry.solve_camera_pose` — mirrors
`test_pnp_projection.py`'s synthetic-correspondence pattern (known
camera, project anchors to synthesize "detected" 2D points, confirm
recovery + generalization to a held-out anchor), plus degenerate-case
handling and an integration check against Milestone A's 3 known-camera
synthetic stand-ins.

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np
import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from calibration.pnp_solve import _build_camera_matrix, _load_anchors, project_point  # noqa: E402
from geometry.evaluate_camera_pose_accuracy import build_report  # noqa: E402
from geometry.solve_camera_pose import MIN_CORRESPONDENCES_DEFAULT, solve_camera_pose  # noqa: E402
from pose.anchor_mapping import _ALL_ANCHOR_NAMES  # noqa: E402

IMAGE_WIDTH, IMAGE_HEIGHT = 1200, 1600
TRUE_RVEC = np.array([[0.05], [0.15], [0.02]])
TRUE_TVEC = np.array([[0.08], [-0.05], [2.4]])
DIRECT_CONFIDENCE = 0.9


def _synthesize_anchor_pose(held_out: set[str] = frozenset()) -> tuple[dict, dict]:
    anchors = _load_anchors()
    camera_matrix = _build_camera_matrix(IMAGE_WIDTH, IMAGE_HEIGHT)
    dist_coeffs = np.zeros((4, 1))

    anchor_pose: dict = {}
    for name in _ALL_ANCHOR_NAMES:
        if name in held_out or name not in anchors:
            anchor_pose[name] = {"x_px": None, "y_px": None, "confidence": 0.0}
            continue
        pt = anchors[name]
        obj = np.array([[pt["x"], pt["y"], pt["z"]]], dtype=np.float64)
        projected, _ = cv2.projectPoints(obj, TRUE_RVEC, TRUE_TVEC, camera_matrix, dist_coeffs)
        px, py = float(projected[0, 0, 0]), float(projected[0, 0, 1])
        anchor_pose[name] = {"x_px": px, "y_px": py, "confidence": DIRECT_CONFIDENCE}
    return anchor_pose, anchors


def test_solve_camera_pose_recovers_known_camera():
    anchor_pose, _ = _synthesize_anchor_pose()
    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    assert camera.solved, camera.reason
    assert camera.reliable
    # 15 socket anchors qualify (chest_center excluded by design, leaving
    # 16 - 1 = 15).
    assert camera.correspondence_count == 15
    assert camera.reprojection_error_px < 1.0  # near-zero: synthetic, noiseless


def test_projection_generalizes_to_a_held_out_anchor():
    """head_top is held out of the correspondence set entirely — the
    solved camera must still project it correctly, same spirit as
    `test_pnp_projection.py`'s chest_center check."""
    anchor_pose, anchors = _synthesize_anchor_pose(held_out={"head_top"})
    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    assert camera.solved

    head_top = anchors["head_top"]
    predicted_px = project_point((head_top["x"], head_top["y"], head_top["z"]), camera)

    camera_matrix = _build_camera_matrix(IMAGE_WIDTH, IMAGE_HEIGHT)
    true_px, _ = cv2.projectPoints(
        np.array([[head_top["x"], head_top["y"], head_top["z"]]]),
        TRUE_RVEC, TRUE_TVEC, camera_matrix, np.zeros((4, 1)),
    )
    true_x, true_y = float(true_px[0, 0, 0]), float(true_px[0, 0, 1])
    assert abs(predicted_px[0] - true_x) < 2.0
    assert abs(predicted_px[1] - true_y) < 2.0


def test_chest_center_excluded_from_correspondences_even_if_present():
    anchor_pose, _ = _synthesize_anchor_pose()
    assert anchor_pose["chest_center"]["confidence"] > 0.0  # present in input
    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    # 15, not 16 — chest_center must not have been counted.
    assert camera.correspondence_count == 15


def test_insufficient_correspondences_flagged_not_silently_returned():
    sparse_pose = {name: {"x_px": None, "y_px": None, "confidence": 0.0} for name in _ALL_ANCHOR_NAMES}
    camera = solve_camera_pose(sparse_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    assert not camera.solved
    assert camera.reason == "insufficient_correspondences"


def test_low_confidence_correspondences_excluded():
    anchor_pose, _ = _synthesize_anchor_pose()
    for name in anchor_pose:
        anchor_pose[name]["confidence"] = 0.1  # below default min_confidence=0.3
    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    assert not camera.solved
    assert camera.reason == "insufficient_correspondences"


def test_min_correspondences_default_matches_plan_justification():
    assert MIN_CORRESPONDENCES_DEFAULT == 6


def test_corrupted_correspondences_flagged_unreliable_not_silently_trusted():
    """Deliberately scramble half the 2D points far from where they
    should be — solvePnP will still often converge to SOME camera, but
    it must not be reported as reliable."""
    anchor_pose, _ = _synthesize_anchor_pose()
    corrupted = 0
    for name, estimate in anchor_pose.items():
        if estimate["confidence"] > 0.0 and corrupted < 8:
            estimate["x_px"] += 400
            estimate["y_px"] -= 300
            corrupted += 1
    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    if camera.solved:
        assert not camera.reliable


def test_against_milestone_a_known_camera_stand_ins():
    """Integration check against Milestone A's 3 synthetic stand-ins,
    whose exact render camera is known — see
    geometry/evaluate_camera_pose_accuracy.py. Bounds documented in the
    plan file's verification table; this only guards against a future
    regression breaking the solve entirely, not a tight accuracy gate."""
    labels_dir = REPO_ROOT / "cv-service" / "data" / "labels"
    if not labels_dir.exists() or not list(labels_dir.glob("*.json")):
        pytest.skip("no local Milestone A stand-in photos/labels (gitignored)")

    report = build_report()
    assert report["solved_count"] == report["photo_count"] == 3
    # Reprojection error is the metric everything else depends on being
    # sane; lateral error is the metric that matters most for 2D crop
    # projection. Depth error is deliberately NOT bounded tightly here —
    # see the plan file: it's the one metric this milestone found to be
    # unreliable from a single near-frontal view, by design of the test,
    # not a bug to hide with a loose assertion.
    assert report["reprojection_error_px"]["mean"] < 100
    assert report["lateral_error_cm"]["mean"] < 30
