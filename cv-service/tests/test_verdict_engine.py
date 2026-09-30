"""Tests for `rules.rule_engine.evaluate_verdicts` and
`segmentation.mask_geometry` (Milestone:
`ChangeRequest/2026-08-11_cv-service-verdict-engine-army-no3-male.md`).

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from rules.rule_engine import CropBox, ResolvedRule, evaluate_verdicts  # noqa: E402
from segmentation.mask_geometry import (  # noqa: E402
    angle_difference_deg,
    mask_centroid_px,
    mask_orientation_deg,
)
from segmentation.segment_uniform import SegmentationResult, SegmentedRegion  # noqa: E402

IMAGE_WIDTH, IMAGE_HEIGHT = 400, 600


def _rect_mask(x1: float, y1: float, x2: float, y2: float, width: int = IMAGE_WIDTH, height: int = IMAGE_HEIGHT) -> np.ndarray:
    mask = np.zeros((height, width), dtype=bool)
    mask[int(y1):int(y2), int(x1):int(x2)] = True
    return mask


def _crop(anchor_name: str, cx: float, cy: float, radius: float = 30.0) -> CropBox:
    return CropBox(anchor_name=anchor_name, center_px=(cx, cy), x1=cx - radius, y1=cy - radius, x2=cx + radius, y2=cy + radius)


def _rule(
    object_id: str,
    category: str,
    crops: list[CropBox],
    *,
    required: bool = True,
    tolerance_cm: float | None = None,
    angle_deg: float | None = None,
    tolerance_deg: float | None = None,
) -> ResolvedRule:
    raw = {"object": object_id, "category": category, "required": required}
    if tolerance_cm is not None:
        raw["tolerance_cm"] = tolerance_cm
    if angle_deg is not None:
        raw["angle_deg"] = angle_deg
    if tolerance_deg is not None:
        raw["tolerance_deg"] = tolerance_deg
    return ResolvedRule(
        object_id=object_id, category=category, doctrine_ref="test-ref", required=required,
        crops=crops, tolerance_cm=tolerance_cm, max_count=None, rule_text="", raw_rule=raw,
    )


def _segmentation(regions: list[SegmentedRegion]) -> SegmentationResult:
    return SegmentationResult(regions=regions, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)


# --- mask_geometry.py ---------------------------------------------------

def test_mask_centroid_px_known_rectangle():
    mask = _rect_mask(30, 10, 40, 20)  # x in [30,40), y in [10,20)
    centroid = mask_centroid_px(mask)
    assert centroid == pytest.approx((34.5, 14.5))


def test_mask_centroid_px_empty_returns_none():
    assert mask_centroid_px(np.zeros((100, 100), dtype=bool)) is None


def test_mask_orientation_deg_elongated_horizontal_bar_near_zero():
    mask = _rect_mask(50, 95, 150, 105)  # wide (100px) x short (10px) -> horizontal
    angle = mask_orientation_deg(mask)
    assert angle is not None
    assert angle_difference_deg(angle, 0.0) < 5.0


def test_mask_orientation_deg_square_blob_returns_none():
    mask = _rect_mask(50, 50, 80, 80)  # 30x30 square, aspect ratio 1.0
    assert mask_orientation_deg(mask) is None


def test_mask_orientation_deg_empty_returns_none():
    assert mask_orientation_deg(np.zeros((100, 100), dtype=bool)) is None


def test_angle_difference_deg_wraps_at_180():
    assert angle_difference_deg(170, 10) == pytest.approx(20.0)
    assert angle_difference_deg(5, 175) == pytest.approx(10.0)
    assert angle_difference_deg(0, 0) == pytest.approx(0.0)


# --- evaluate_verdicts: pass/fail/missing --------------------------------

def test_pass_when_centroid_within_tolerance():
    crop = _crop("belt_center", 200, 300, radius=50)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(195, 295, 205, 305)  # centroid ~(199.5, 299.5)
    seg = _segmentation([SegmentedRegion("belt", 0.9, mask, (195, 295, 205, 305))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert len(results) == 1
    assert results[0].accessory == "nylon_belt"
    assert results[0].status == "pass"


def test_fail_when_centroid_outside_tolerance():
    crop = _crop("belt_center", 200, 300, radius=100)  # generous crop bounds so the detection is inside the search area
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(250, 300, 260, 310)  # centroid ~(255, 305), far from (200,300)
    seg = _segmentation([SegmentedRegion("belt", 0.9, mask, (250, 300, 260, 310))])

    # tolerance_px = 1.0cm / 0.05 = 20px; actual distance ~55px -> fail
    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "fail"


def test_missing_when_required_and_nothing_detected_in_bounds():
    crop = _crop("belt_center", 200, 300, radius=40)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0, required=True)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "missing"


def test_optional_rule_skipped_when_detector_exists_but_finds_nothing():
    crop = _crop("epaulette_pos", 200, 300, radius=40)
    rule = _rule("fake_optional_epaulette", "epaulette", [crop], required=False)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results == []


# --- evaluate_verdicts: unverifiable cases --------------------------------

def test_unverifiable_when_no_detector_class_and_required():
    crop = _crop("chest_pocket", 200, 300, radius=40)
    rule = _rule("saf_badges_chest", "saf_badge", [crop], required=True)  # category has no detector
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "unverifiable"
    assert "no segmentation class" in results[0].reason


def test_unverifiable_when_no_detector_class_even_if_optional():
    """The real doctrine's medal_ribbons/saf_badge/skill_tab/skill_badge
    rules are exactly this shape: optional AND undetectable. Must still
    surface as unverifiable, not be silently dropped — see the plan
    file's rationale."""
    crop = _crop("chest", 200, 300, radius=40)
    rule = _rule("medal_ribbons", "medal_ribbons", [crop], required=False)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert len(results) == 1
    assert results[0].status == "unverifiable"


def test_unverifiable_when_expected_region_out_of_frame():
    crop = _crop("head_top", -50, -50, radius=20)  # projected entirely off-frame
    rule = _rule("army_beret", "headdress_beret", [crop], required=True)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "unverifiable"
    assert "outside the photo" in results[0].reason


def test_unverifiable_when_camera_not_reliable():
    crop = _crop("belt_center", 200, 300, radius=40)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(195, 295, 205, 305)
    seg = _segmentation([SegmentedRegion("belt", 0.9, mask, (195, 295, 205, 305))])

    results = evaluate_verdicts(
        [rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT, camera_reliable=False
    )
    assert results[0].status == "unverifiable"
    assert "camera pose unreliable" in results[0].reason


def test_low_confidence_segment_treated_as_not_detected():
    crop = _crop("belt_center", 200, 300, radius=40)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0, required=True)
    mask = _rect_mask(195, 295, 205, 305)
    seg = _segmentation([SegmentedRegion("belt", 0.1, mask, (195, 295, 205, 305))])  # below default 0.4

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "missing"


# --- evaluate_verdicts: orientation ---------------------------------------

def test_orientation_pass_when_within_tolerance():
    crop = _crop("cap_band_front", 200, 300, radius=40)
    rule = _rule("army_cap_badge_sltc_me6_below", "cap_badge", [crop], tolerance_cm=1.3, angle_deg=0, tolerance_deg=10)
    # An elongated horizontal mask (angle ~0deg) centred on the crop.
    mask = _rect_mask(170, 297, 230, 303)
    seg = _segmentation([SegmentedRegion("cap_badge", 0.9, mask, (170, 297, 230, 303))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "pass"


def test_orientation_fail_when_rotated_past_tolerance():
    crop = _crop("cap_band_front", 200, 300, radius=60)
    rule = _rule("army_cap_badge_sltc_me6_below", "cap_badge", [crop], tolerance_cm=5.0, angle_deg=0, tolerance_deg=10)
    # A ~45-degree diagonal elongated mask, well past the 10deg tolerance.
    mask = np.zeros((IMAGE_HEIGHT, IMAGE_WIDTH), dtype=bool)
    for i in range(-25, 25):
        mask[300 + i, 200 + i] = True
        mask[300 + i, 200 + i + 1] = True  # thicken slightly so it's a real blob
    seg = _segmentation([SegmentedRegion("cap_badge", 0.9, mask, (175, 275, 225, 325))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "fail"


def test_orientation_unverifiable_when_mask_too_ambiguous():
    crop = _crop("cap_band_front", 200, 300, radius=40)
    rule = _rule("army_cap_badge_sltc_me6_below", "cap_badge", [crop], tolerance_cm=5.0, angle_deg=0, tolerance_deg=10)
    mask = _rect_mask(185, 285, 215, 315)  # square-ish (30x30) -> orientation ambiguous
    seg = _segmentation([SegmentedRegion("cap_badge", 0.9, mask, (185, 285, 215, 315))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    # position passes (centroid at crop center) but orientation can't be
    # measured -> overall unverifiable, not a false "pass".
    assert results[0].status == "unverifiable"


# --- paired crops (worst-first) -------------------------------------------

def test_paired_crops_take_worst_status():
    left = _crop("left_shoulder_seam", 100, 300, radius=40)
    right = _crop("right_shoulder_seam", 300, 300, radius=40)
    rule = _rule("sleeve_insignia", "sleeve_rank_enlistee", [left, right], tolerance_cm=1.0, required=True)
    left_mask = _rect_mask(95, 295, 105, 305)  # ~0px off -> pass
    right_mask = _rect_mask(330, 300, 340, 310)  # ~35px off, tolerance 20px, band 30px -> fail
    seg = _segmentation([
        SegmentedRegion("sleeve_rank", 0.9, left_mask, (95, 295, 105, 305)),
        SegmentedRegion("sleeve_rank", 0.9, right_mask, (330, 300, 340, 310)),
    ])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert len(results) == 1
    assert results[0].status == "fail"  # worst of [pass, fail] = fail


def test_paired_crop_with_detection_outside_search_area_is_missing_not_fail():
    """A detection far from the expected region must not stand in for it:
    the right side is `missing`, not a misplaced `fail`."""
    left = _crop("left_shoulder_seam", 100, 300, radius=100)
    right = _crop("right_shoulder_seam", 300, 300, radius=100)
    rule = _rule("epaulettes_standard", "epaulette", [left, right], required=True)
    left_mask = _rect_mask(90, 290, 110, 310)  # inside left crop -> pass
    stray_mask = _rect_mask(380, 500, 390, 510)  # outside both crops
    seg = _segmentation([
        SegmentedRegion("epaulette", 0.9, left_mask, (90, 290, 110, 310)),
        SegmentedRegion("epaulette", 0.9, stray_mask, (380, 500, 390, 510)),
    ])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert len(results) == 1
    assert results[0].status == "missing"
    assert "outside the search area" in results[0].reason


def test_single_detection_cannot_satisfy_both_paired_crops():
    """Overlapping search boxes, one detection in the overlap: it may be
    assigned to only one side; the other side is `missing`."""
    left = _crop("left_foot_top", 180, 500, radius=40)
    right = _crop("right_foot_top", 220, 500, radius=40)
    rule = _rule("leather_shoes_low_cut", "footwear", [left, right], required=True)
    mask = _rect_mask(195, 495, 205, 505)  # centroid ~(199.5, 499.5), inside both crops
    seg = _segmentation([SegmentedRegion("footwear", 0.9, mask, (195, 495, 205, 505))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "missing"


def test_two_detections_assigned_to_their_own_sides():
    left = _crop("left_foot_top", 150, 500, radius=60)
    right = _crop("right_foot_top", 250, 500, radius=60)
    rule = _rule("leather_shoes_low_cut", "footwear", [left, right], required=True)
    left_mask = _rect_mask(145, 495, 155, 505)
    right_mask = _rect_mask(245, 495, 255, 505)
    seg = _segmentation([
        SegmentedRegion("footwear", 0.9, right_mask, (245, 495, 255, 505)),
        SegmentedRegion("footwear", 0.9, left_mask, (145, 495, 155, 505)),
    ])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "pass"


def test_optional_rule_skipped_when_detection_only_outside_search_area():
    crop = _crop("epaulette_pos", 200, 300, radius=40)
    rule = _rule("fake_optional_epaulette", "epaulette", [crop], required=False)
    stray = _rect_mask(20, 20, 30, 30)
    seg = _segmentation([SegmentedRegion("epaulette", 0.9, stray, (20, 20, 30, 30))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results == []


# --- enriched geometry fields (ChangeRequest/2026-08-28) -------------------

def test_pass_result_carries_geometry_fields():
    crop = _crop("belt_center", 200, 300, radius=50)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(195, 295, 205, 305)  # centroid ~(199.5, 299.5)
    seg = _segmentation([SegmentedRegion("belt", 0.9, mask, (195, 295, 205, 305))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    result = results[0]

    assert result.confidence == pytest.approx(0.9)
    assert result.bounding_box_px == (195, 295, 205, 305)
    assert result.expected_position_px == pytest.approx((200, 300))
    assert result.detected_position_px == pytest.approx((199.5, 299.5), abs=0.5)
    assert result.error_px is not None
    assert result.visibility == "visible"


def test_missing_result_carries_expected_position_only():
    crop = _crop("belt_center", 200, 300, radius=40)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0, required=True)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    result = results[0]

    assert result.status == "missing"
    assert result.expected_position_px == pytest.approx((200, 300))
    assert result.detected_position_px is None
    assert result.bounding_box_px is None
    assert result.visibility == "occluded"


def test_out_of_frame_result_has_out_of_frame_visibility():
    crop = _crop("head_top", -50, -50, radius=20)
    rule = _rule("army_beret", "headdress_beret", [crop], required=True)
    seg = _segmentation([])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].visibility == "out_of_frame"


def test_slightly_misaligned_between_tolerance_and_band():
    # tolerance_px = 1.0cm / 0.05 = 20px. Place the detected centroid
    # ~30px away — past tolerance, but within the 1.5x slight-misalignment
    # band (30px), so this should read "slightly_misaligned", not "fail".
    crop = _crop("belt_center", 200, 300, radius=100)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(225, 300, 235, 310)  # centroid ~(229.5, 304.5), ~30px from (200,300)
    seg = _segmentation([SegmentedRegion("belt", 0.9, mask, (225, 300, 235, 310))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].status == "slightly_misaligned"


def test_low_confidence_match_reported_partially_visible():
    crop = _crop("belt_center", 200, 300, radius=50)
    rule = _rule("nylon_belt", "belt", [crop], tolerance_cm=1.0)
    mask = _rect_mask(195, 295, 205, 305)
    # Above the 0.4 detection floor but below the 0.6 partial-visibility
    # cutoff (0.4 * 1.5) -> matched, but flagged partially_visible.
    seg = _segmentation([SegmentedRegion("belt", 0.45, mask, (195, 295, 205, 305))])

    results = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=IMAGE_WIDTH, image_height=IMAGE_HEIGHT)
    assert results[0].visibility == "partially_visible"
