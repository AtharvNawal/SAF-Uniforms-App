"""Maps the pipeline's internal types (`ResolvedRule` + the enriched
`VerdictResult`, `DetectionResult`, `ValidationResult`) into the
`POST /check_uniform` JSON contract. Pure functions, no I/O — everything
needed is already computed by `rules.rule_engine.evaluate_verdicts` and
`api.validation.validate_image`; this module only reshapes it.

Kept deliberately separate from `reporting/report.py`'s `/inspect`
response shape (subscores/issues/uncertain) — same "two independent,
differently-shaped reports" posture already used elsewhere in this
service (see `cv_inspection_result.dart`'s module comment on the Flutter
side) rather than forcing one contract to serve both callers.
"""

from __future__ import annotations

import config
from pose.detect_person import DetectionResult
from rules.rule_engine import ResolvedRule, VerdictResult

# Doctrine-verified position/presence -> the spec's requested vocabulary.
_STATUS_MAP = {
    "pass": "CORRECT",
    "slightly_misaligned": "SLIGHTLY_MISALIGNED",
    "fail": "INCORRECT",
    "missing": "MISSING",
    "unverifiable": "UNCERTAIN",
}

# `present`/`position_correct` per the requested contract's four states
# (present+correct, present+incorrect, missing, unable to determine).
_PRESENT_BY_STATUS = {
    "pass": True,
    "slightly_misaligned": True,
    "fail": True,
    "missing": False,
    "unverifiable": None,
}
_POSITION_CORRECT_BY_STATUS = {
    "pass": True,
    "slightly_misaligned": False,
    "fail": False,
    "missing": None,
    "unverifiable": None,
}

# Item score for the overall compliance score — mirrors
# reporting/report.py's `_VERDICT_TO_ITEM_SCORE` convention. Unverifiable
# items are excluded from scoring entirely (see `compute_overall_score`
# below) rather than penalized — we genuinely don't know, so it shouldn't
# count against the wearer.
_STATUS_TO_ITEM_SCORE = {
    "pass": 100.0,
    "slightly_misaligned": 50.0,
    "fail": 0.0,
    "missing": 0.0,
}

# Reuses config's "Fully Compliant" cutoff (95) as the PASS/FAIL line,
# rather than inventing a second, uncoordinated threshold.
_PASS_SCORE_CUTOFF = config.STATUS_SCORE_THRESHOLDS[0][0]


def _bbox_to_dict(bbox: tuple[float, float, float, float] | None) -> dict | None:
    if bbox is None:
        return None
    x1, y1, x2, y2 = bbox
    return {"x": round(x1, 1), "y": round(y1, 1), "width": round(x2 - x1, 1), "height": round(y2 - y1, 1)}


def _point_to_dict(point: tuple[float, float] | None) -> dict | None:
    if point is None:
        return None
    return {"x": round(point[0], 1), "y": round(point[1], 1)}


def _accessory_entry(verdict: VerdictResult) -> dict:
    return {
        "name": verdict.accessory,
        "present": _PRESENT_BY_STATUS[verdict.status],
        "position_correct": _POSITION_CORRECT_BY_STATUS[verdict.status],
        "confidence": round(verdict.confidence, 2) if verdict.confidence is not None else None,
        "status": _STATUS_MAP[verdict.status],
        "visibility": verdict.visibility.upper(),
        "bounding_box": _bbox_to_dict(verdict.bounding_box_px),
        "expected_position": _point_to_dict(verdict.expected_position_px),
        "detected_position": _point_to_dict(verdict.detected_position_px),
        "error": _point_to_dict(verdict.error_px),
        "doctrine_ref": verdict.doctrine_ref,
        "message": verdict.reason,
    }


def compute_overall_score(verdicts: list[VerdictResult], resolved_rules: list[ResolvedRule]) -> float:
    required_ids = {rule.object_id for rule in resolved_rules if rule.required}
    scorable = [
        _STATUS_TO_ITEM_SCORE[v.status]
        for v in verdicts
        if v.accessory in required_ids and v.status in _STATUS_TO_ITEM_SCORE
    ]
    return round(sum(scorable) / len(scorable), 1) if scorable else 0.0


def build_summary(verdicts: list[VerdictResult]) -> dict:
    return {
        "detected_accessories": sum(1 for v in verdicts if _PRESENT_BY_STATUS[v.status]),
        "correct": sum(1 for v in verdicts if v.status == "pass"),
        "incorrect": sum(1 for v in verdicts if v.status in ("fail", "slightly_misaligned")),
        "missing": sum(1 for v in verdicts if v.status == "missing"),
        "uncertain": sum(1 for v in verdicts if v.status == "unverifiable"),
    }


def build_check_uniform_response(
    resolved_rules: list[ResolvedRule],
    verdicts: list[VerdictResult],
    detection: DetectionResult,
    image_quality_usable: bool,
    image_quality_confidence: float,
) -> dict:
    """Pure mapping — no model inference happens here. `resolved_rules`
    supplies `required_accessories` (verdicts alone don't carry that
    flag); everything else comes from `verdicts`."""
    overall_score = compute_overall_score(verdicts, resolved_rules)
    summary = build_summary(verdicts)
    summary["required_accessories"] = sum(1 for rule in resolved_rules if rule.required)

    return {
        "success": True,
        "overall_status": "PASS" if overall_score >= _PASS_SCORE_CUTOFF else "FAIL",
        "overall_score": overall_score,
        "image_quality": {"usable": image_quality_usable, "confidence": round(image_quality_confidence, 2)},
        "person": {
            "detected": detection.accepted,
            "confidence": round(detection.person.confidence, 2) if detection.person else 0.0,
        },
        "accessories": [_accessory_entry(v) for v in verdicts],
        "summary": summary,
    }
