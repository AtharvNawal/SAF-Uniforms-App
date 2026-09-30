"""Tests for ChangeRequest/2026-09-28_accuracy-program-no-real-data.md —
the model-free parts of every new stage. Heavy pretrained models (OCR,
DINOv2, YOLO-World, SAM 2) are stubbed; their accuracy is measured by
the violation benchmark, not unit tests.

Run with: .venv-tools/bin/pytest cv-service/tests/
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import cv2
import numpy as np
import pytest
from PIL import Image

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

import config  # noqa: E402
from api.burst import aggregate_burst  # noqa: E402
from api.instructions import instruction_for  # noqa: E402
from api.intrinsics import focal_px_from_exif, resolve_intrinsics  # noqa: E402
from api.pipeline import REFERENCE_STATURE_M, scaled_anchors  # noqa: E402
from calibration.pnp_solve import points_in_front  # noqa: E402
from detectors import variant_matcher  # noqa: E402
from detectors.color_check import check_colors  # noqa: E402
from detectors.name_tag_ocr import surname_match  # noqa: E402
from geometry.mask_anchor_refinement import refine_anchors_with_masks  # noqa: E402
from geometry.solve_camera_pose import gravity_disagreement_deg, refine_with_gravity  # noqa: E402
from rules.rule_engine import CropBox, ResolvedRule, VerdictResult, _position_status, evaluate_verdicts  # noqa: E402
from segmentation.mask_geometry import mask_reference_point  # noqa: E402
from segmentation.segment_uniform import SegmentationResult, SegmentedRegion  # noqa: E402
from segmentation.two_stage import mask_iou, merge_regions  # noqa: E402

W, H = 400, 600


def _rect(x1, y1, x2, y2, w=W, h=H):
    mask = np.zeros((h, w), dtype=bool)
    mask[y1:y2, x1:x2] = True
    return mask


def _verdict(accessory="x", status="pass", **kw):
    return VerdictResult(accessory=accessory, status=status, reason="r", doctrine_ref="ref", **kw)


# --- A3 reference point ------------------------------------------------------

def test_mask_reference_point_edges():
    mask = _rect(100, 50, 140, 70)
    assert mask_reference_point(mask, "center") == pytest.approx((119.5, 59.5))
    assert mask_reference_point(mask, "top_edge") == pytest.approx((119.5, 50))
    assert mask_reference_point(mask, "bottom_edge") == pytest.approx((119.5, 69))


def test_verdict_measures_the_doctrine_edge_not_the_centroid(monkeypatch):
    # isolate the reference-point logic from the calibrated uncertainty
    monkeypatch.setattr(config, "UNCERTAINTY_MASK_FRACTION", 0.0)
    # Name-tag-like rule: bottom edge must sit on the expected point.
    crop = CropBox("pocket", (120.0, 70.0), 60, 10, 180, 130, px_per_cm=10.0)
    rule = ResolvedRule("name_tag_standard", "name_tag", "ref", True, [crop], 1.0, None, "",
                        {"tolerance_cm": 1.0, "reference_point": "bottom_edge"})
    seg = SegmentationResult([SegmentedRegion("name_tag", 0.9, _rect(100, 50, 140, 71), (100, 50, 140, 71))], W, H)
    [verdict] = evaluate_verdicts([rule], seg, cm_per_px=0.1, image_width=W, image_height=H)
    # centroid is 10px (1 cm) off, the bottom edge is on target
    assert verdict.status == "pass"
    assert verdict.detected_position_px[1] == pytest.approx(70)


# --- A4 local scale / A5 uncertainty -----------------------------------------

@pytest.mark.parametrize("distance,uncertainty,expected", [
    (5, 2, "pass"),            # 7 <= 10
    (9, 2, "unverifiable"),    # straddles the tolerance
    (13, 2, "slightly_misaligned"),  # 11 > 10, 13 <= 15
    (20, 2, "fail"),
])
def test_position_status_respects_uncertainty(distance, uncertainty, expected):
    assert _position_status(distance, uncertainty, tolerance_px=10) == expected


def test_crop_px_per_cm_overrides_global_scale():
    # Global cm_per_px says 1 cm = 10 px; the crop's local scale says 1 cm = 30 px.
    crop = CropBox("belt_center", (200.0, 300.0), 100, 200, 300, 400, px_per_cm=30.0)
    rule = ResolvedRule("nylon_belt", "belt", "ref", True, [crop], 1.0, None, "", {"tolerance_cm": 1.0})
    seg = SegmentationResult([SegmentedRegion("belt", 0.9, _rect(215, 295, 225, 305), (215, 295, 225, 305))], W, H)
    [verdict] = evaluate_verdicts([rule], seg, cm_per_px=0.1, image_width=W, image_height=H)
    assert verdict.status == "pass"  # ~20px off < 30px tolerance
    assert verdict.px_per_cm == pytest.approx(30.0)


def test_geometric_uncertainty_turns_a_boundary_pass_into_unverifiable():
    crop = CropBox("belt_center", (200.0, 300.0), 100, 200, 300, 400, px_per_cm=20.0, uncertainty_px=8.0)
    rule = ResolvedRule("nylon_belt", "belt", "ref", True, [crop], 1.0, None, "", {"tolerance_cm": 1.0})
    seg = SegmentationResult([SegmentedRegion("belt", 0.9, _rect(212, 295, 222, 305), (212, 295, 222, 305))], W, H)
    [verdict] = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=W, image_height=H)
    assert verdict.status == "unverifiable"
    assert verdict.failure_kind == "boundary"


def test_mapped_class_missing_from_loaded_model_is_unverifiable_not_missing():
    crop = CropBox("pocket", (200.0, 300.0), 150, 250, 250, 350)
    rule = ResolvedRule("name_tag_standard", "name_tag", "ref", True, [crop], 1.5, None, "", {"tolerance_cm": 1.5})
    seg = SegmentationResult([], W, H, class_names=frozenset({"shirt", "belt"}))
    [verdict] = evaluate_verdicts([rule], seg, cm_per_px=0.05, image_width=W, image_height=H)
    assert verdict.status == "unverifiable"
    assert verdict.failure_kind == "no_detector"


# --- B10 colour --------------------------------------------------------------

def _image_with(shirt_value: int, item_value: int, item_saturation: int = 0):
    hsv = np.zeros((H, W, 3), np.uint8)
    hsv[..., 2] = shirt_value
    hsv[400:450, 100:200, 1] = item_saturation
    hsv[400:450, 100:200, 2] = item_value
    return cv2.cvtColor(hsv, cv2.COLOR_HSV2BGR)


@pytest.mark.parametrize("item_value,saturation,expected", [(40, 0, "pass"), (150, 0, "fail"), (60, 200, "fail")])
def test_black_is_judged_relative_to_the_shirt(item_value, saturation, expected):
    image = _image_with(220, item_value, saturation)
    seg = SegmentationResult([SegmentedRegion("shirt", 0.9, _rect(0, 0, W, 300), (0, 0, W, 300))], W, H)
    verdict = _verdict("black_socks", region_mask=_rect(100, 400, 200, 450))
    [checked] = check_colors([verdict], {"black_socks": {"expected_color": "black"}}, image, seg)
    assert checked.status == expected
    if expected == "fail":
        assert checked.failure_kind == "color"


def test_dark_photo_still_reads_black_socks_as_black():
    image = _image_with(90, 20)  # under-exposed: shirt only 90/255
    seg = SegmentationResult([SegmentedRegion("shirt", 0.9, _rect(0, 0, W, 300), (0, 0, W, 300))], W, H)
    [checked] = check_colors([_verdict("black_socks", region_mask=_rect(100, 400, 200, 450))],
                             {"black_socks": {"expected_color": "black"}}, image, seg)
    assert checked.status == "pass"


def test_colour_not_checked_without_shirt_reference():
    image = _image_with(220, 150)
    [checked] = check_colors([_verdict("black_socks", region_mask=_rect(100, 400, 200, 450))],
                             {"black_socks": {"expected_color": "black"}}, image, SegmentationResult([], W, H))
    assert checked.status == "pass"
    assert "colour not checked" in checked.reason


# --- B8 name tag -------------------------------------------------------------

def test_surname_match_is_fuzzy_and_joins_split_tokens():
    assert surname_match(["TAN"], "Tan")[0] == pytest.approx(1.0)
    ratio, best = surname_match(["LIMK", "OH"], "Lim Koh")
    assert best == "LIMKOH" and ratio == pytest.approx(1.0)
    assert surname_match(["WONG"], "Tan")[0] < config.NAME_MATCH_FAIL
    assert surname_match([], "Tan") == (0.0, None)


def test_name_match_accepts_any_word_of_the_full_name():
    # surname-first order: a tag reading "TAN" matches "Tan Ah Kow"
    assert surname_match(["TAN"], "Tan Ah Kow")[0] == pytest.approx(1.0)
    # given-name-last order
    assert surname_match(["RAHMAN"], "Muhammad Rahman")[0] == pytest.approx(1.0)
    assert surname_match(["LIM"], "Tan Ah Kow")[0] < config.NAME_MATCH_FAIL


# --- B9 variant --------------------------------------------------------------

def test_variant_check_fails_only_on_a_clear_margin(monkeypatch):
    embeddings = {"expected": np.array([1.0, 0.0]), "other": np.array([0.0, 1.0])}
    monkeypatch.setattr(variant_matcher, "_reference_embedding", lambda oid: embeddings[oid])
    rules = [{"object": "expected", "category": "cap_badge"}, {"object": "other", "category": "cap_badge"}]
    image = np.zeros((H, W, 3), np.uint8)
    verdict = _verdict("expected", bounding_box_px=(100, 100, 140, 130))

    def run(item_vector):
        monkeypatch.setattr(variant_matcher, "_embed", lambda crop: item_vector / np.linalg.norm(item_vector))
        return variant_matcher.check_variants([verdict], rules, image, {"expected": "cap_badge"})[0]

    assert run(np.array([0.2, 1.0])).status == "fail"            # clearly the other badge
    assert run(np.array([1.0, 0.2])).status == "pass"            # clearly the expected one
    assert run(np.array([1.0, 1.02])).status == "pass"           # too close to call -> unchanged
    assert "not distinguishable" in run(np.array([1.0, 1.02])).reason


def test_content_crop_drops_whitespace_and_border_rules():
    image = np.full((200, 600, 3), 255, np.uint8)
    image[0:2, :] = 0          # thin PDF rule
    image[80:120, 250:330] = 30  # the badge
    crop = variant_matcher._content_crop(image)
    assert crop.shape[:2] == (40, 80)


# --- D16 intrinsics / gravity / height -----------------------------------------

def test_focal_from_exif_35mm_equivalent(tmp_path):
    path = tmp_path / "exif.jpg"
    image = Image.new("RGB", (400, 300))
    exif = image.getexif()
    exif.get_ifd(0x8769)[0xA405] = 26  # FocalLengthIn35mmFilm
    image.save(path, exif=exif)
    intrinsics = focal_px_from_exif(str(path), 400, 300)
    assert intrinsics.source == "exif_35mm"
    assert intrinsics.focal_px == pytest.approx(26 * 500 / math.hypot(36, 24))


def test_no_exif_is_assumed_and_client_value_wins(tmp_path):
    path = tmp_path / "plain.jpg"
    Image.new("RGB", (40, 30)).save(path)
    assert focal_px_from_exif(str(path), 40, 30).source == "assumed"
    assert resolve_intrinsics(str(path), 40, 30, client_focal_px=1234.0).focal_px == 1234.0


def _frontal_camera():
    camera_matrix = np.array([[1000, 0, 400], [0, 1000, 600], [0, 0, 1]], dtype=np.float64)
    rvec = np.array([[math.pi], [0.0], [0.0]])  # looking at the body from +z
    tvec = np.array([[0.0], [1.0], [2.5]])
    obj = np.array([[x, y, z] for x in (-0.2, 0.0, 0.2) for y in (0.1, 1.0, 1.5) for z in (0.0, 0.1)], dtype=np.float64)
    img, _ = cv2.projectPoints(obj, rvec, tvec, camera_matrix, np.zeros((4, 1)))
    return camera_matrix, rvec, tvec, obj, img.reshape(-1, 2)


def test_cheirality_check():
    _, rvec, tvec, obj, _ = _frontal_camera()
    assert points_in_front(obj, rvec, tvec)
    assert not points_in_front(obj, rvec, -tvec)


def test_gravity_prior_pulls_a_tilted_solution_level():
    camera_matrix, rvec, tvec, obj, img = _frontal_camera()
    tilted, _ = cv2.Rodrigues(cv2.Rodrigues(rvec)[0] @ cv2.Rodrigues(np.array([0.1, 0.0, 0.0]))[0])
    level_up = (0.0, -1.0, 0.0)  # world up in OpenCV camera coords for a level camera
    assert gravity_disagreement_deg(tilted, level_up) > 4
    refined_r, _ = refine_with_gravity(obj, img, camera_matrix, tilted, tvec, level_up)
    assert gravity_disagreement_deg(refined_r, level_up) < 1.0


def test_scaled_anchors_scale_about_the_feet():
    base, scale_one = scaled_anchors(None)
    scaled, scale = scaled_anchors(REFERENCE_STATURE_M * 100 * 0.9)
    assert scale_one == 1.0 and scale == pytest.approx(0.9)
    assert scaled["head_top"]["y"] == pytest.approx(base["head_top"]["y"] * 0.9)
    assert scaled_anchors(90.0)[1] == 1.0  # implausible height ignored


# --- A2 mask anchors -----------------------------------------------------------

def _pose(**points):
    return {name: {"x_px": x, "y_px": y, "confidence": 0.5} for name, (x, y) in points.items()}


def test_mask_refinement_moves_head_top_and_cap_band_together():
    pose = _pose(left_shoulder_seam=(250, 200), right_shoulder_seam=(150, 200), head_top=(200, 40), cap_band_front=(200, 60))
    seg = SegmentationResult([SegmentedRegion("headwear", 0.9, _rect(170, 30, 230, 60), (170, 30, 230, 60))], W, H)
    refined = refine_anchors_with_masks(pose, seg)
    assert refined["head_top"]["y_px"] == pytest.approx(30)
    assert refined["head_top"]["source"] == "mask"
    assert refined["cap_band_front"]["y_px"] == pytest.approx(50)  # moved by the same 10px


def test_mask_refinement_rejects_far_away_masks():
    pose = _pose(left_shoulder_seam=(250, 200), right_shoulder_seam=(150, 200), head_top=(200, 40))
    seg = SegmentationResult([SegmentedRegion("headwear", 0.9, _rect(0, 500, 40, 540), (0, 500, 40, 540))], W, H)
    assert refine_anchors_with_masks(pose, seg)["head_top"] == pose["head_top"]


def test_belt_anchor_comes_from_the_waistline_not_the_belt():
    pose = _pose(left_shoulder_seam=(250, 200), right_shoulder_seam=(150, 200), belt_center=(200, 330))
    seg = SegmentationResult([
        SegmentedRegion("shirt", 0.9, _rect(140, 200, 260, 340), (140, 200, 260, 340)),
        SegmentedRegion("trousers", 0.9, _rect(140, 350, 260, 590), (140, 350, 260, 590)),
        SegmentedRegion("belt", 0.9, _rect(140, 400, 260, 420), (140, 400, 260, 420)),  # misplaced belt: ignored
    ], W, H)
    refined = refine_anchors_with_masks(pose, seg)
    assert refined["belt_center"]["y_px"] == pytest.approx((339 + 350) / 2)


# --- B13 merge -----------------------------------------------------------------

def test_merge_keeps_the_more_confident_overlapping_detection():
    a = SegmentedRegion("cap_badge", 0.5, _rect(10, 10, 30, 30), (10, 10, 30, 30))
    b = SegmentedRegion("cap_badge", 0.8, _rect(12, 12, 30, 30), (12, 12, 30, 30), source="two_stage")
    c = SegmentedRegion("cap_badge", 0.6, _rect(100, 100, 120, 120), (100, 100, 120, 120), source="two_stage")
    assert mask_iou(a.mask, b.mask) > 0.5
    merged = merge_regions([a], [b, c])
    assert [r.source for r in merged] == ["two_stage", "two_stage"]
    assert merged[0].confidence == 0.8


# --- E18 instructions ------------------------------------------------------------

def test_instruction_speaks_in_cm_and_the_wearers_left_right():
    # detected 20px right (image) and 10px low of target at 10 px/cm
    verdict = _verdict("army_cap_badge_sltc_me6_below", "fail", error_px=(20.0, 10.0), px_per_cm=10.0, failure_kind="position")
    text = instruction_for(verdict)
    # fix = move 1 cm up and 2 cm image-left = the wearer's right
    assert "1.0 cm up" in text and "2.0 cm to your right" in text
    assert text.startswith("Army Cap Badge")


@pytest.mark.parametrize("status,kind,needle", [
    ("missing", "missing", "not found"),
    ("unverifiable", "no_detector", "check it yourself"),
    ("unverifiable", "out_of_frame", "whole body"),
    ("fail", "color", "black"),
    ("fail", "name_text", "name on the tag"),
])
def test_instruction_per_failure_kind(status, kind, needle):
    assert needle in instruction_for(_verdict("black_socks", status, failure_kind=kind))


# --- D17 burst -------------------------------------------------------------------

def _frame(statuses: dict[str, str]):
    return {
        "success": True, "overall_status": "FAIL", "overall_score": 0, "image_quality": {}, "person": {},
        "accessories": [
            {"name": n, "status": s, "required": True, "checkable": True, "present": s != "MISSING",
             "position_correct": s == "CORRECT", "instruction": f"{n}: x"}
            for n, s in statuses.items()
        ],
    }


def test_burst_takes_strict_majority_and_flags_disagreement():
    frames = [
        _frame({"a": "CORRECT", "b": "MISSING"}),
        _frame({"a": "CORRECT", "b": "CORRECT"}),
        _frame({"a": "INCORRECT", "b": "UNCERTAIN"}),
    ]
    combined = aggregate_burst(frames + [None], [None, None, None, {"frame": 3, "status": "IMAGE_TOO_BLURRY"}])
    items = {a["name"]: a for a in combined["accessories"]}
    assert items["a"]["status"] == "CORRECT" and items["a"]["frame_agreement"] == "2/3"
    assert items["b"]["status"] == "UNCERTAIN" and "disagreed" in items["b"]["instruction"]
    assert combined["burst"] == {"frames": 4, "usable_frames": 3, "frame_errors": [{"frame": 3, "status": "IMAGE_TOO_BLURRY"}]}
    assert combined["summary"]["correct"] == 1


def test_boundary_instruction_reports_the_measured_offset():
    verdict = _verdict("nylon_belt", "unverifiable", failure_kind="boundary", error_px=(3.0, 4.0), px_per_cm=10.0, tolerance_cm=1.0)
    text = instruction_for(verdict)
    assert "looks correctly placed" in text and "0.5 cm" in text
    far = _verdict("nylon_belt", "unverifiable", failure_kind="boundary", error_px=(9.0, 0.0), px_per_cm=10.0, tolerance_cm=1.0)
    assert "may be slightly off" in instruction_for(far)
