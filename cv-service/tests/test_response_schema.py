"""Pure-function tests for `api.response_schema` — constructed
ResolvedRule/VerdictResult fixtures, no model inference or fixtures
needed (mirrors `test_verdict_engine.py`'s fixture-construction style)."""

from __future__ import annotations

import sys
from pathlib import Path

CV_SERVICE_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_SERVICE_ROOT))

from api.response_schema import build_check_uniform_response, compute_overall_score  # noqa: E402
from pose.detect_person import DetectionResult, PersonBox  # noqa: E402
from rules.rule_engine import CropBox, ResolvedRule, VerdictResult  # noqa: E402


def _rule(object_id: str, *, required: bool = True) -> ResolvedRule:
    crop = CropBox(anchor_name="test_anchor", center_px=(100.0, 200.0), x1=80, y1=180, x2=120, y2=220)
    return ResolvedRule(
        object_id=object_id, category="belt", doctrine_ref="test-ref", required=required,
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
        "missing": 1,
        "uncertain": 1,
    }


def test_person_and_image_quality_passthrough():
    rule = _rule("a")
    verdict = _verdict("a", "pass")

    response = build_check_uniform_response([rule], [verdict], _detection(confidence=0.87), False, 0.5)

    assert response["person"] == {"detected": True, "confidence": 0.87}
    assert response["image_quality"] == {"usable": False, "confidence": 0.5}
