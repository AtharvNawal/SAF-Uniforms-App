"""Pure-function tests for `api.response_schema` — constructed
ResolvedRule/VerdictResult fixtures, no model inference or fixtures
needed (mirrors `test_verdict_engine.py`'s fixture-construction style)."""

from __future__ import annotations

import sys
from pathlib import Path

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from api.response_schema import (  # noqa: E402
    build_check_uniform_response,
    compute_coverage,
    compute_overall_score,
    recompute_from_entries,
)
from pose.detect_person import DetectionResult, PersonBox  # noqa: E402
from rules.rule_engine import CropBox, ResolvedRule, VerdictResult  # noqa: E402


def _rule(object_id: str, *, required: bool = True, category: str = "belt") -> ResolvedRule:
    crop = CropBox(anchor_name="test_anchor", center_px=(100.0, 200.0), x1=80, y1=180, x2=120, y2=220)
    return ResolvedRule(
        object_id=object_id, category=category, doctrine_ref="test-ref", required=required,
        crops=[crop], tolerance_cm=1.0, max_count=None, rule_text="", raw_rule={},
    )


def _verdict(accessory: str, status: str, **kwargs) -> VerdictResult:
    defaults = dict(
        confidence=0.9,
        bounding_box_px=(95.0, 195.0, 105.0, 205.0),
        expected_position_px=(100.0, 200.0),
        detected_position_px=(103.0, 202.0),
        error_px=(3.0, 2.0),
        visibility="visible",
    )
    defaults.update(kwargs)
    return VerdictResult(accessory=accessory, status=status, reason=f"{accessory} test reason", doctrine_ref="test-ref", **defaults)


def _detection(confidence: float = 0.95) -> DetectionResult:
    person = PersonBox(x1=10, y1=10, x2=200, y2=500, confidence=confidence)
    return DetectionResult(accepted=True, reason="ok", person=person, candidate_count=1)


def test_pass_verdict_maps_to_correct_status():
    rule = _rule("nylon_belt")
    verdict = _verdict("nylon_belt", "pass")

    response = build_check_uniform_response([rule], [verdict], _detection(), True, 0.95)

    item = response["accessories"][0]
    assert item["status"] == "CORRECT"
    assert item["present"] is True
    assert item["position_correct"] is True
    assert item["bounding_box"] == {"x": 95.0, "y": 195.0, "width": 10.0, "height": 10.0}
    assert item["expected_position"] == {"x": 100.0, "y": 200.0}
    assert item["error"] == {"x": 3.0, "y": 2.0}


def test_missing_verdict_has_null_position_correct():
    rule = _rule("nylon_belt")
    verdict = _verdict(
        "nylon_belt", "missing", confidence=None, bounding_box_px=None, detected_position_px=None,
        error_px=None, visibility="occluded",
    )

    response = build_check_uniform_response([rule], [verdict], _detection(), True, 0.95)

    item = response["accessories"][0]
    assert item["present"] is False
    assert item["position_correct"] is None
    assert item["confidence"] is None
    assert item["bounding_box"] is None


def test_unverifiable_verdict_has_null_present():
    rule = _rule("name_tag_standard")
    verdict = _verdict(
        "name_tag_standard", "unverifiable", confidence=None, bounding_box_px=None,
        detected_position_px=None, error_px=None, visibility="uncertain",
    )

    response = build_check_uniform_response([rule], [verdict], _detection(), True, 0.95)

    item = response["accessories"][0]
    assert item["present"] is None
    assert item["position_correct"] is None
    assert item["status"] == "UNCERTAIN"


def test_overall_score_only_counts_required_scorable_items():
    required_pass = _rule("a", required=True)
    required_fail = _rule("b", required=True)
    optional_pass = _rule("c", required=False)

    verdicts = [
        _verdict("a", "pass"),
        _verdict("b", "fail"),
        _verdict("c", "pass"),  # optional -> excluded from scoring
    ]

    score = compute_overall_score(verdicts, [required_pass, required_fail, optional_pass])

    assert score == 50.0  # mean(100, 0) over the two required items only


def test_overall_score_excludes_unverifiable_items():
    required_pass = _rule("a", required=True)
    required_unverifiable = _rule("b", required=True)

    verdicts = [
        _verdict("a", "pass"),
        _verdict("b", "unverifiable"),
    ]

    score = compute_overall_score(verdicts, [required_pass, required_unverifiable])

    assert score == 100.0  # unverifiable excluded, not counted as a failure


def test_overall_status_pass_requires_full_score():
    rule = _rule("a")
    verdict = _verdict("a", "pass")

    response = build_check_uniform_response([rule], [verdict], _detection(), True, 0.95)

    assert response["overall_score"] == 100.0
    assert response["overall_status"] == "PASS"


def test_overall_status_fail_when_score_below_cutoff():
    rule = _rule("a")
    verdict = _verdict("a", "fail")

    response = build_check_uniform_response([rule], [verdict], _detection(), True, 0.95)

    assert response["overall_status"] == "FAIL"


def test_summary_counts():
    rules = [_rule("a"), _rule("b"), _rule("c"), _rule("d")]
    verdicts = [
        _verdict("a", "pass"),
        _verdict("b", "fail"),
        _verdict("c", "missing", confidence=None, bounding_box_px=None, detected_position_px=None, error_px=None),
        _verdict("d", "unverifiable", confidence=None, bounding_box_px=None, detected_position_px=None, error_px=None),
    ]

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)

    assert response["summary"] == {
        "required_accessories": 4,
        "detected_accessories": 2,  # pass + fail (both "present")
        "correct": 1,
        "incorrect": 1,
        "slightly_misaligned": 0,
        "missing": 1,
        "uncertain": 1,
    }


def test_person_and_image_quality_passthrough():
    rule = _rule("a")
    verdict = _verdict("a", "pass")

    response = build_check_uniform_response([rule], [verdict], _detection(confidence=0.87), False, 0.5)

    assert response["person"] == {"detected": True, "confidence": 0.87}
    assert response["image_quality"] == {"usable": False, "confidence": 0.5}


# --- verification-coverage gate (ChangeRequest/2026-09-28) ----------------

def _unverifiable(accessory: str) -> VerdictResult:
    return _verdict(accessory, "unverifiable", confidence=None, bounding_box_px=None,
                    detected_position_px=None, error_px=None, visibility="uncertain")


def test_incomplete_when_too_few_checkable_items_verified():
    # 1 of 3 checkable required items verified (and it passed) -> score is
    # 100, but that must NOT read as PASS.
    rules = [_rule("a"), _rule("b"), _rule("c")]
    verdicts = [_verdict("a", "pass"), _unverifiable("b"), _unverifiable("c")]

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)

    assert response["overall_score"] == 100.0
    assert response["overall_status"] == "INCOMPLETE"
    assert response["coverage"] == {
        "verified_required": 1, "checkable_required": 3, "fraction": 0.33, "not_checkable_required": 0,
    }


def test_fail_not_incomplete_when_definite_violation_found_despite_low_coverage():
    rules = [_rule("a"), _rule("b"), _rule("c")]
    verdicts = [
        _verdict("a", "missing", confidence=None, bounding_box_px=None, detected_position_px=None, error_px=None),
        _unverifiable("b"),
        _unverifiable("c"),
    ]

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)

    assert response["overall_status"] == "FAIL"


def test_incomplete_when_nothing_scorable():
    rules = [_rule("a")]
    response = build_check_uniform_response(rules, [_unverifiable("a")], _detection(), True, 0.95)

    assert response["overall_score"] == 0.0
    assert response["overall_status"] == "INCOMPLETE"


def test_structurally_undetectable_items_excluded_from_gate():
    # medal ribbons / skill tabs have no detector: they're counted separately
    # and don't block PASS, otherwise PASS would be impossible for every profile.
    rules = [_rule("a"), _rule("b"), _rule("medal_ribbons", category="medal_ribbons"), _rule("skill_tabs_sleeve", category="skill_tab")]
    verdicts = [_verdict("a", "pass"), _verdict("b", "pass"), _unverifiable("medal_ribbons"), _unverifiable("skill_tabs_sleeve")]

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)

    assert response["overall_status"] == "PASS"
    assert response["coverage"]["checkable_required"] == 2
    assert response["coverage"]["not_checkable_required"] == 2


def test_pass_allowed_at_coverage_threshold():
    # 4 of 5 = 0.8, exactly the default MIN_VERIFIED_COVERAGE.
    rules = [_rule(x) for x in "abcde"]
    verdicts = [_verdict(x, "pass") for x in "abcd"] + [_unverifiable("e")]

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)

    assert response["overall_status"] == "PASS"


def test_coverage_ignores_optional_rules():
    rules = [_rule("a"), _rule("opt", required=False)]
    verdicts = [_verdict("a", "pass"), _unverifiable("opt")]

    coverage = compute_coverage(verdicts, rules)

    assert coverage["checkable_required"] == 1
    assert coverage["verified_required"] == 1


def test_name_tag_not_checkable_when_loaded_model_lacks_the_class():
    # The 9-class v1 segmenter has no name_tag class: the item must count as
    # not-checkable, not as a checkable item that failed to verify.
    rules = [_rule("a"), _rule("name_tag_standard", category="name_tag")]
    verdicts = [_verdict("a", "pass"), _unverifiable("name_tag_standard")]
    v1_classes = frozenset({"shirt", "trousers", "headwear", "cap_badge", "epaulette", "sleeve_rank", "arms_badge", "belt", "footwear"})

    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95, class_names=v1_classes)

    assert response["coverage"]["checkable_required"] == 1
    assert response["coverage"]["not_checkable_required"] == 1
    assert response["overall_status"] == "PASS"
    entries = {a["name"]: a for a in response["accessories"]}
    assert entries["name_tag_standard"]["checkable"] is False
    assert entries["a"]["required"] is True


def test_accessory_entry_carries_instruction_and_detection_source():
    rule = _rule("nylon_belt")
    response = build_check_uniform_response([rule], [_verdict("nylon_belt", "pass", detection_source="two_stage")], _detection(), True, 0.95)
    item = response["accessories"][0]
    assert item["instruction"].endswith("correct.")
    assert item["detection_source"] == "two_stage"


def test_recompute_from_entries_matches_the_verdict_path():
    rules = [_rule("a"), _rule("b"), _rule("c"), _rule("d"), _rule("opt", required=False)]
    verdicts = [
        _verdict("a", "pass"),
        _verdict("b", "slightly_misaligned"),
        _verdict("c", "missing", confidence=None, bounding_box_px=None, detected_position_px=None, error_px=None),
        _unverifiable("d"),
        _verdict("opt", "pass"),
    ]
    response = build_check_uniform_response(rules, verdicts, _detection(), True, 0.95)
    recomputed = recompute_from_entries(response["accessories"])
    for key in ("overall_score", "overall_status", "coverage", "summary"):
        assert recomputed[key] == response[key], key
