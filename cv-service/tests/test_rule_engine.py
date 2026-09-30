"""Rule engine tests — crop-region resolution against a fixed synthetic
camera (reusing the same known-camera setup as `test_pnp_projection.py`
so no real photo or model inference is needed).
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from calibration.pnp_solve import scale_factor_cm_per_unit, solve_camera_pose  # noqa: E402
from rules.rule_engine import load_anchors, load_rules, resolve_rules  # noqa: E402
from tests.test_pnp_projection import _synthesize_pose  # noqa: E402


@pytest.fixture(scope="module")
def solved_camera():
    pose, _ = _synthesize_pose()
    camera = solve_camera_pose(pose)
    assert camera.solved
    cm_per_px = scale_factor_cm_per_unit(pose)
    return camera, cm_per_px


def test_rules_file_loads_and_has_entries():
    rules = load_rules()
    assert len(rules) == 18
    ids = {r["object"] for r in rules}
    assert "name_tag_standard" in ids
    assert "army_arms_badge" in ids


def test_unconditional_rule_resolves_for_any_profile(solved_camera):
    camera, cm_per_px = solved_camera
    resolved = resolve_rules(camera, cm_per_px, profile={})
    ids = {r.object_id for r in resolved}
    # name_tag_standard and nylon_belt carry no `condition` field — always applicable
    assert "name_tag_standard" in ids
    assert "nylon_belt" in ids


def test_rank_conditioned_rule_only_resolves_for_matching_profile(solved_camera):
    camera, cm_per_px = solved_camera

    specialist_result = resolve_rules(camera, cm_per_px, profile={"rank_tier": "specialist"})
    specialist_ids = {r.object_id for r in specialist_result}
    assert "army_specialist_insignia" in specialist_ids
    assert "army_enlistee_insignia" not in specialist_ids

    enlistee_result = resolve_rules(camera, cm_per_px, profile={"rank_tier": "enlistee"})
    enlistee_ids = {r.object_id for r in enlistee_result}
    assert "army_enlistee_insignia" in enlistee_ids
    assert "army_specialist_insignia" not in enlistee_ids


def test_paired_anchor_rule_produces_two_crops(solved_camera):
    camera, cm_per_px = solved_camera
    resolved = resolve_rules(camera, cm_per_px, profile={"rank_tier": "specialist"})
    by_id = {r.object_id: r for r in resolved}
    assert len(by_id["army_specialist_insignia"].crops) == 2
    left_x = by_id["army_specialist_insignia"].crops[0].center_px[0]
    right_x = by_id["army_specialist_insignia"].crops[1].center_px[0]
    assert left_x != right_x  # left/right sleeve crops must land at different x


def test_crop_boxes_are_well_formed(solved_camera):
    camera, cm_per_px = solved_camera
    resolved = resolve_rules(camera, cm_per_px, profile={"rank_tier": "specialist"})
    for rule in resolved:
        for crop in rule.crops:
            assert crop.x2 > crop.x1
            assert crop.y2 > crop.y1
            # sanity: crop center should sit inside the crop box itself
            assert crop.x1 <= crop.center_px[0] <= crop.x2
            assert crop.y1 <= crop.center_px[1] <= crop.y2


def test_sikh_turban_compound_condition_respects_is_sikh_flag(solved_camera):
    """Regression test: `army_sikh_turban_standard`'s condition is a
    compound `profile.isSikh == true AND rank_tier != col_me7_and_above`
    string. The single-operator evaluator used to mis-parse this (matching
    the `!=` embedded in the second clause against the whole string, and
    never stripping the `profile.` prefix), so the rule resolved for
    EVERY profile regardless of `isSikh` — see the ChangeRequest plan
    this test belongs to."""
    camera, cm_per_px = solved_camera

    non_sikh = resolve_rules(camera, cm_per_px, profile={"isSikh": False, "rank_tier": "specialist"})
    assert "army_sikh_turban_standard" not in {r.object_id for r in non_sikh}

    sikh_specialist = resolve_rules(camera, cm_per_px, profile={"isSikh": True, "rank_tier": "specialist"})
    assert "army_sikh_turban_standard" in {r.object_id for r in sikh_specialist}

    # `col_me7` is what the app actually sends for a COL (the condition's
    # old `col_me7_and_above` value was never sent by anything).
    sikh_senior_officer = resolve_rules(
        camera, cm_per_px, profile={"isSikh": True, "rank_tier": "col_me7"}
    )
    assert "army_sikh_turban_standard" not in {r.object_id for r in sikh_senior_officer}


@pytest.mark.parametrize("rank_tier,expected_badge", [
    ("enlistee", "army_cap_badge_sltc_me6_below"),
    ("specialist", "army_cap_badge_sltc_me6_below"),
    ("officer_cadet_and_mxt_trainee", "army_cap_badge_sltc_me6_below"),
    ("col_me7", "army_cap_badge_col_me7"),
    ("bg_me8_and_above", "army_cap_badge_bg_me8_above"),
])
def test_every_rank_tier_gets_exactly_one_cap_badge_rule(solved_camera, rank_tier, expected_badge):
    """Regression: cap-badge conditions used to test rank_tier against
    'sltc_me6_and_below', which the app never sends — so enlistees and
    specialists (most soldiers) had no cap-badge check at all."""
    camera, cm_per_px = solved_camera
    resolved = resolve_rules(camera, cm_per_px, profile={"rank_tier": rank_tier})
    badges = [r.object_id for r in resolved if r.category == "cap_badge"]
    assert badges == [expected_badge]


def test_saf_badge_conditional_offset_present_in_raw_rule(solved_camera):
    camera, cm_per_px = solved_camera
    resolved = resolve_rules(camera, cm_per_px, profile={})
    by_id = {r.object_id: r for r in resolved}
    saf_badge = by_id["saf_badges_chest"]
    assert saf_badge.max_count == 3
    assert "conditional_offset" in saf_badge.raw_rule
