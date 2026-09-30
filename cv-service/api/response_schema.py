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
from api.instructions import instruction_for
from rules.rule_engine import ResolvedRule, VerdictResult, has_detector

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


def _accessory_entry(verdict: VerdictResult, required: bool = False, checkable: bool = True) -> dict:
    return {
        "name": verdict.accessory,
        # Whether doctrine requires this item for the wearer's profile, and
        # whether the system can detect it at all — lets a client (and the
        # burst aggregator, api/burst.py) recompute the overall result.
        "required": required,
        "checkable": checkable,
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
        # E18 — what the wearer should do, in cm and their own left/right.
        "instruction": instruction_for(verdict),
        # "trained" | "two_stage" | "zero_shot" — which detector found it.
        "detection_source": verdict.detection_source,
    }


def compute_overall_score(verdicts: list[VerdictResult], resolved_rules: list[ResolvedRule]) -> float:
    required_ids = {rule.object_id for rule in resolved_rules if rule.required}
    scorable = [
        _STATUS_TO_ITEM_SCORE[v.status]
        for v in verdicts
        if v.accessory in required_ids and v.status in _STATUS_TO_ITEM_SCORE
    ]
    return round(sum(scorable) / len(scorable), 1) if scorable else 0.0


def compute_coverage(
    verdicts: list[VerdictResult], resolved_rules: list[ResolvedRule], class_names: frozenset[str] | None = None
) -> dict:
    """How much of the required doctrine this photo actually verified.

    Denominator = required rules whose category has a detector at all;
    structurally-undetectable required items (name tag, socks, ...) are
    counted separately as `not_checkable_required` rather than dragging
    every profile below the gate forever — they're a known system gap,
    not something a better photo could fix. A "verified" item is one with
    a definite verdict (anything but `unverifiable`). See
    ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md.
    """
    checkable_ids = {rule.object_id for rule in resolved_rules if rule.required and has_detector(rule.category, class_names)}
    not_checkable = sum(1 for rule in resolved_rules if rule.required and not has_detector(rule.category, class_names))
    verified = sum(1 for v in verdicts if v.accessory in checkable_ids and v.status in _STATUS_TO_ITEM_SCORE)
    fraction = verified / len(checkable_ids) if checkable_ids else 0.0
    return {
        "verified_required": verified,
        "checkable_required": len(checkable_ids),
        "fraction": round(fraction, 2),
        "not_checkable_required": not_checkable,
    }


def compute_overall_status(
    overall_score: float, coverage: dict, verdicts: list[VerdictResult], resolved_rules: list[ResolvedRule]
) -> str:
    """PASS only when enough of the checkable required doctrine was
    actually verified AND it scored above the cutoff. Too little verified
    -> INCOMPLETE, unless a definite violation (fail / missing on a
    required item) was already found, which no amount of further checking
    could turn into a pass -> FAIL."""
    checkable = coverage["checkable_required"]
    if checkable > 0 and coverage["verified_required"] / checkable >= config.MIN_VERIFIED_COVERAGE:
        return "PASS" if overall_score >= _PASS_SCORE_CUTOFF else "FAIL"
    required_ids = {rule.object_id for rule in resolved_rules if rule.required}
    definite_violation = any(v.accessory in required_ids and v.status in ("fail", "missing") for v in verdicts)
    return "FAIL" if definite_violation else "INCOMPLETE"


def build_summary(verdicts: list[VerdictResult]) -> dict:
    return {
        "detected_accessories": sum(1 for v in verdicts if _PRESENT_BY_STATUS[v.status]),
        "correct": sum(1 for v in verdicts if v.status == "pass"),
        "incorrect": sum(1 for v in verdicts if v.status == "fail"),
        "slightly_misaligned": sum(1 for v in verdicts if v.status == "slightly_misaligned"),
        "missing": sum(1 for v in verdicts if v.status == "missing"),
        "uncertain": sum(1 for v in verdicts if v.status == "unverifiable"),
    }


def build_check_uniform_response(
    resolved_rules: list[ResolvedRule],
    verdicts: list[VerdictResult],
    detection: DetectionResult,
    image_quality_usable: bool,
    image_quality_confidence: float,
    class_names: frozenset[str] | None = None,
) -> dict:
    """Pure mapping — no model inference happens here. `resolved_rules`
    supplies `required_accessories` (verdicts alone don't carry that
    flag); everything else comes from `verdicts`."""
    overall_score = compute_overall_score(verdicts, resolved_rules)
    coverage = compute_coverage(verdicts, resolved_rules, class_names)
    required_ids = {rule.object_id for rule in resolved_rules if rule.required}
    categories = {rule.object_id: rule.category for rule in resolved_rules}
    summary = build_summary(verdicts)
    summary["required_accessories"] = sum(1 for rule in resolved_rules if rule.required)

    return {
        "success": True,
        "overall_status": compute_overall_status(overall_score, coverage, verdicts, resolved_rules),
        "overall_score": overall_score,
        "coverage": coverage,
        "image_quality": {"usable": image_quality_usable, "confidence": round(image_quality_confidence, 2)},
        "person": {
            "detected": detection.accepted,
            "confidence": round(detection.person.confidence, 2) if detection.person else 0.0,
        },
        "accessories": [
            _accessory_entry(
                v,
                required=v.accessory in required_ids,
                checkable=has_detector(categories.get(v.accessory, ""), class_names),
            )
            for v in verdicts
        ],
        "summary": summary,
    }


# Response-level status name -> internal verdict status (inverse of _STATUS_MAP).
_INTERNAL_STATUS = {v: k for k, v in _STATUS_MAP.items()}


def recompute_from_entries(accessories: list[dict]) -> dict:
    """Recomputes `overall_score`, `overall_status`, `coverage` and
    `summary` from response-level accessory entries (each carrying
    `status`, `required`, `checkable`) — the same rules as
    `build_check_uniform_response`, for callers that only have the JSON
    (the burst aggregator)."""
    internal = [(a, _INTERNAL_STATUS[a["status"]]) for a in accessories]
    scorable = [_STATUS_TO_ITEM_SCORE[st] for a, st in internal if a["required"] and st in _STATUS_TO_ITEM_SCORE]
    score = round(sum(scorable) / len(scorable), 1) if scorable else 0.0
    checkable = [st for a, st in internal if a["required"] and a["checkable"]]
    verified = sum(1 for st in checkable if st in _STATUS_TO_ITEM_SCORE)
    coverage = {
        "verified_required": verified,
        "checkable_required": len(checkable),
        "fraction": round(verified / len(checkable), 2) if checkable else 0.0,
        "not_checkable_required": sum(1 for a, _ in internal if a["required"] and not a["checkable"]),
    }
    if checkable and verified / len(checkable) >= config.MIN_VERIFIED_COVERAGE:
        status = "PASS" if score >= _PASS_SCORE_CUTOFF else "FAIL"
    else:
        status = "FAIL" if any(a["required"] and st in ("fail", "missing") for a, st in internal) else "INCOMPLETE"
    summary = {
        "detected_accessories": sum(1 for _, st in internal if _PRESENT_BY_STATUS[st]),
        "correct": sum(1 for _, st in internal if st == "pass"),
        "incorrect": sum(1 for _, st in internal if st == "fail"),
        "slightly_misaligned": sum(1 for _, st in internal if st == "slightly_misaligned"),
        "missing": sum(1 for _, st in internal if st == "missing"),
        "uncertain": sum(1 for _, st in internal if st == "unverifiable"),
        "required_accessories": sum(1 for a in accessories if a["required"]),
    }
    return {"overall_score": score, "overall_status": status, "coverage": coverage, "summary": summary}
