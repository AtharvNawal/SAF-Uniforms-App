"""Tests for `geometry.project_rules` — confirms it correctly surfaces
`angle_deg`/`tolerance_deg` (the one thing `rule_engine.resolve_rules()`
doesn't expose as its own field) without reimplementing rule resolution.

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

from calibration.pnp_solve import _build_camera_matrix, _load_anchors  # noqa: E402
from geometry.project_rules import cm_per_px_from_anchor_pose, project_rules  # noqa: E402
from geometry.solve_camera_pose import solve_camera_pose  # noqa: E402
from pose.anchor_mapping import _ALL_ANCHOR_NAMES  # noqa: E402

IMAGE_WIDTH, IMAGE_HEIGHT = 1200, 1600
TRUE_RVEC = np.array([[0.02], [0.05], [0.01]])
TRUE_TVEC = np.array([[0.0], [0.0], [2.6]])


@pytest.fixture(scope="module")
def camera_and_anchor_pose():
    anchors = _load_anchors()
    camera_matrix = _build_camera_matrix(IMAGE_WIDTH, IMAGE_HEIGHT)
    dist_coeffs = np.zeros((4, 1))

    anchor_pose = {}
    for name in _ALL_ANCHOR_NAMES:
        pt = anchors[name]
        obj = np.array([[pt["x"], pt["y"], pt["z"]]], dtype=np.float64)
        projected, _ = cv2.projectPoints(obj, TRUE_RVEC, TRUE_TVEC, camera_matrix, dist_coeffs)
        px, py = float(projected[0, 0, 0]), float(projected[0, 0, 1])
        anchor_pose[name] = {"x_px": px, "y_px": py, "confidence": 0.9}

    camera = solve_camera_pose(anchor_pose, IMAGE_WIDTH, IMAGE_HEIGHT)
    assert camera.solved
    return camera, anchor_pose


def test_cm_per_px_from_anchor_pose_positive_and_finite(camera_and_anchor_pose):
    _camera, anchor_pose = camera_and_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    assert cm_per_px is not None
    assert cm_per_px > 0


def test_project_rules_returns_nonempty_for_specialist_profile(camera_and_anchor_pose):
    camera, anchor_pose = camera_and_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    projected = project_rules(camera, cm_per_px, profile={"rank_tier": "specialist", "gender": "male", "isSikh": False, "medalRowCount": 0})
    assert len(projected) > 0
    assert all(p.crops for p in projected)


def test_cap_badge_orientation_tolerance_surfaced(camera_and_anchor_pose):
    """army_cap_badge_sltc_me6_below carries angle_deg=0, tolerance_deg=10
    in the doctrine JSON — must come through unchanged, not invented."""
    camera, anchor_pose = camera_and_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    projected = project_rules(camera, cm_per_px, profile={"rank_tier": "sltc_me6_and_below"})
    cap_badge = next(p for p in projected if p.object_id == "army_cap_badge_sltc_me6_below")
    assert cap_badge.angle_deg == 0
    assert cap_badge.tolerance_deg == 10


def test_presence_only_rule_has_no_orientation_tolerance(camera_and_anchor_pose):
    """army_beret has no angle/tolerance_deg in doctrine (presence +
    region only) — must be None, not a fabricated default."""
    camera, anchor_pose = camera_and_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    projected = project_rules(camera, cm_per_px, profile={})
    beret = next(p for p in projected if p.object_id == "army_beret")
    assert beret.angle_deg is None
    assert beret.tolerance_deg is None


def test_name_tag_orientation_tolerance_surfaced(camera_and_anchor_pose):
    camera, anchor_pose = camera_and_anchor_pose
    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose)
    projected = project_rules(camera, cm_per_px, profile={})
    name_tag = next(p for p in projected if p.object_id == "name_tag_standard")
    assert name_tag.angle_deg == 0
    assert name_tag.tolerance_deg == 8
