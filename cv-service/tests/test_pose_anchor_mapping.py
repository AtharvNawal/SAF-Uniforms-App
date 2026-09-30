"""Tests for `pose.anchor_mapping` — the general BlazePose-to-anchor
mapping (Milestone: `ChangeRequest/2026-08-11_cv-service-pose-anchor-mapping.md`).

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from pose.anchor_mapping import (  # noqa: E402
    _ALL_ANCHOR_NAMES,
    apply_anchor_offsets,
    body_frame,
    estimate_anchor_pose,
    map_pose_to_anchors,
)
from pose.estimate_pose import Landmark2D, PoseResult  # noqa: E402
from pose.evaluate_pose_accuracy import build_accuracy_report  # noqa: E402

FIXTURE_PHOTO = REPO_ROOT / "cv-service" / "tests" / "fixtures" / "rendered_army_no3_male_front.jpg"
ANCHORS_MALE_JSON = REPO_ROOT / "cv-service" / "rules" / "anchors.male.json"
LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"

_BLAZEPOSE_INDEX = {
    "nose": 0,
    "left_eye": 2,
    "right_eye": 5,
    "left_ear": 7,
    "right_ear": 8,
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_elbow": 13,
    "right_elbow": 14,
    "left_hip": 23,
    "right_hip": 24,
    "left_ankle": 27,
    "right_ankle": 28,
    "left_foot_index": 31,
    "right_foot_index": 32,
}


def _fake_pose(points: dict[str, tuple[float, float]], visibility: float = 0.9, width: int = 800, height: int = 1200) -> PoseResult:
    landmarks = {
        _BLAZEPOSE_INDEX[name]: Landmark2D(x_px=x, y_px=y, visibility=visibility, presence=visibility)
        for name, (x, y) in points.items()
    }
    return PoseResult(found=True, landmarks=landmarks, image_width=width, image_height=height)


_FULL_BODY_POINTS = {
    "nose": (400, 150),
    "left_eye": (390, 140),
    "right_eye": (410, 140),
    "left_ear": (375, 145),
    "right_ear": (425, 145),
    "left_shoulder": (330, 330),
    "right_shoulder": (470, 330),
    "left_elbow": (300, 450),
    "right_elbow": (500, 450),
    "left_hip": (350, 600),
    "right_hip": (450, 600),
    "left_ankle": (340, 1050),
    "right_ankle": (460, 1050),
    "left_foot_index": (335, 1120),
    "right_foot_index": (465, 1120),
}


def test_output_key_set_matches_anchors_male_json():
    anchors_json_keys = set(json.loads(ANCHORS_MALE_JSON.read_text())["anchors"].keys())
    assert set(_ALL_ANCHOR_NAMES) == anchors_json_keys


def test_pose_not_found_returns_all_null():
    pose = PoseResult(found=False, landmarks={}, image_width=800, image_height=1200)
    result = map_pose_to_anchors(pose)
    assert set(result.keys()) == set(_ALL_ANCHOR_NAMES)
    assert all(v["confidence"] == 0.0 and v["x_px"] is None for v in result.values())


def test_direct_anchors_use_landmark_coordinates_exactly():
    pose = _fake_pose(_FULL_BODY_POINTS, visibility=0.9)
    result = map_pose_to_anchors(pose, apply_offsets=False)
    assert result["left_shoulder_seam"]["x_px"] == 330
    assert result["left_shoulder_seam"]["y_px"] == 330
    assert result["left_shoulder_seam"]["confidence"] == pytest.approx(0.9)
    assert result["right_ankle"]["x_px"] == 460
    assert result["left_foot_top"]["x_px"] == 335  # left_foot_index proxy


def test_belt_center_is_hip_midpoint():
    pose = _fake_pose(_FULL_BODY_POINTS)
    result = map_pose_to_anchors(pose, apply_offsets=False)
    assert result["belt_center"]["x_px"] == pytest.approx((350 + 450) / 2)
    assert result["belt_center"]["y_px"] == pytest.approx((600 + 600) / 2)


def test_chest_center_is_midpoint_of_estimated_chest_pockets():
    pose = _fake_pose(_FULL_BODY_POINTS)
    result = map_pose_to_anchors(pose)
    left, right, center = result["left_chest_pocket"], result["right_chest_pocket"], result["chest_center"]
    assert center["x_px"] == pytest.approx((left["x_px"] + right["x_px"]) / 2)
    assert center["y_px"] == pytest.approx((left["y_px"] + right["y_px"]) / 2)


def test_heuristic_anchors_are_confidence_penalized_below_direct_anchors():
    pose = _fake_pose(_FULL_BODY_POINTS, visibility=0.9)
    result = map_pose_to_anchors(pose)
    assert result["left_chest_pocket"]["confidence"] < result["left_shoulder_seam"]["confidence"]
    assert result["head_top"]["confidence"] < result["left_chest_pocket"]["confidence"]


def test_missing_elbow_nulls_out_sleeve_upper_but_not_shoulder():
    points = dict(_FULL_BODY_POINTS)
    del points["left_elbow"]
    pose = _fake_pose(points)
    result = map_pose_to_anchors(pose)
    assert result["left_sleeve_upper"]["confidence"] == 0.0
    assert result["left_sleeve_upper"]["x_px"] is None
    assert result["left_shoulder_seam"]["confidence"] > 0.0


def test_low_visibility_landmark_treated_as_not_visible():
    pose = _fake_pose({"left_shoulder": (330, 330), "right_shoulder": (470, 330)}, visibility=0.2)
    result = map_pose_to_anchors(pose)
    assert result["left_shoulder_seam"]["confidence"] == 0.0


def test_head_top_is_above_face_reference_in_pixel_space():
    """Pixel y grows downward — head_top must have a SMALLER y than the
    ear/eye line it's extrapolated from, or the heuristic has its sign
    backwards."""
    pose = _fake_pose(_FULL_BODY_POINTS)
    result = map_pose_to_anchors(pose)
    assert result["head_top"]["y_px"] < 145  # above the ear line (y=145)


def test_estimate_anchor_pose_runs_end_to_end_against_rendered_fixture():
    if not FIXTURE_PHOTO.exists():
        pytest.skip(f"fixture photo not found at {FIXTURE_PHOTO}")
    result = estimate_anchor_pose(str(FIXTURE_PHOTO))
    assert set(result.keys()) == set(_ALL_ANCHOR_NAMES)
    non_null = [name for name, v in result.items() if v["confidence"] > 0.0]
    assert len(non_null) >= 10, f"expected most anchors covered on a clean front-on render, got {non_null}"


def test_accuracy_report_synthetic_vs_real_are_reported_separately():
    """Milestone A's ground truth is used here as real accuracy
    verification, not just unit-test fixtures. Synthetic and real MUST
    stay two separate numbers per this milestone's own instruction —
    this test guards against a future refactor accidentally merging
    them into one blended score."""
    if not LABELS_DIR.exists() or not list(LABELS_DIR.glob("*.json")):
        pytest.skip("no label files under cv-service/data/labels/ (gitignored, local-only)")

    report = build_accuracy_report()
    assert "synthetic" in report and "real" in report
    assert report["synthetic"]["photo_count"] == 3

    synthetic = report["synthetic"]
    assert synthetic["mean_px_error"] is not None
    # Sanity bound, not a tight regression gate: heuristic anchors on a
    # placeholder-body render have real, expected error — this only
    # catches something badly broken (e.g. detector totally failing, or
    # a mapping bug producing thousand-pixel errors).
    assert synthetic["mean_px_error"] < 400
    assert synthetic["coverage"] > 0.5

    # The real-photo row must say "0", never a fabricated number.
    assert report["real"]["photo_count"] == 0
    assert report["real"]["mean_px_error"] is None


# --- fitted landmark->socket bias corrections (ChangeRequest/2026-09-28) ---

def _estimate(points):
    return {name: {"x_px": x, "y_px": y, "confidence": 0.9} for name, (x, y) in points.items()}


def test_body_frame_outward_points_from_right_to_left_shoulder():
    frame = body_frame(_estimate({"left_shoulder_seam": (500, 300), "right_shoulder_seam": (300, 300)}))
    _, outward, down, width = frame
    assert width == pytest.approx(200)
    assert outward == pytest.approx([1.0, 0.0])
    assert down == pytest.approx([0.0, 1.0])  # toward the hips


def test_offsets_mirror_outward_per_side_and_scale_with_shoulder_width():
    estimate = _estimate({
        "left_shoulder_seam": (500, 300), "right_shoulder_seam": (300, 300),
        "left_chest_pocket": (450, 400), "right_chest_pocket": (350, 400), "belt_center": (400, 600),
    })
    offsets = {
        "left_chest_pocket": {"outward": -0.1, "down": 0.2, "residual_std": 0.05},
        "right_chest_pocket": {"outward": -0.1, "down": 0.2, "residual_std": 0.05},
        "belt_center": {"outward": 0.0, "down": -0.4, "residual_std": 0.05},
    }
    corrected = apply_anchor_offsets(estimate, offsets)
    # inward by 0.1 × 200px on each side (mirrored), down by 0.2 × 200px
    assert (corrected["left_chest_pocket"]["x_px"], corrected["left_chest_pocket"]["y_px"]) == pytest.approx((430, 440))
    assert (corrected["right_chest_pocket"]["x_px"], corrected["right_chest_pocket"]["y_px"]) == pytest.approx((370, 440))
    assert corrected["belt_center"]["y_px"] == pytest.approx(520)
    assert corrected["belt_center"]["residual_px"] == pytest.approx(10)
    assert corrected["left_shoulder_seam"] == estimate["left_shoulder_seam"]  # no offset entry -> untouched


def test_default_mapping_applies_fitted_offsets_when_file_present():
    offsets_file = REPO_ROOT / "cv-service" / "pose" / "anchor_offsets.male.json"
    if not offsets_file.exists():
        pytest.skip("anchor_offsets.male.json not fitted")
    pose = _fake_pose(_FULL_BODY_POINTS)
    raw = map_pose_to_anchors(pose, apply_offsets=False)
    fitted = map_pose_to_anchors(pose)
    assert fitted["belt_center"]["y_px"] != pytest.approx(raw["belt_center"]["y_px"])
    assert fitted["belt_center"].get("calibrated") is True
