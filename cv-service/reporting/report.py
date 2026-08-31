"""Stage 7 — compliance report synthesis.

Folds Stage 6's resolved rules + the vision-crop verdicts (Stage 4/5
substitute) into the JSON report shape from the architecture memo §14,
plus an annotated image (green/yellow/red crop boxes). The scoring
weights here are an explicit starting proposal, not doctrine — see the
memo's §13 note. Two subscore buckets (`lower_body`, `appearance`) have
no rules targeting them yet and are reported as `null`, not faked.
"""

from __future__ import annotations

import base64
from dataclasses import dataclass

import cv2
import numpy as np

import config
from detectors.vision_crop_inspector import CropVerdict
from rules.rule_engine import ResolvedRule, VerdictResult

CATEGORY_TO_SUBSCORE = {
    "headdress_beret": "headwear",
    "headdress_sikh_turban": "headwear",
    "cap_badge": "headwear",
    "epaulette": "sleeves",
    "sleeve_rank_specialist": "sleeves",
    "sleeve_rank_enlistee": "sleeves",
    "skill_tab": "sleeves",
    "skill_badge": "sleeves",
    "arms_badge": "collar",
    "name_tag": "chest",
    "medal_ribbons": "chest",
    "saf_badge": "chest",
    "belt": "waist",
    "footwear": "footwear",
    "socks": "footwear",
}
SUBSCORE_GROUPS = ["headwear", "chest", "collar", "sleeves", "waist", "lower_body", "footwear", "appearance"]

# Worst-first — combining multiple crops of a paired item (e.g. left +
# right sleeve insignia) takes the more severe verdict, matching how an
# inspector would treat "correct on one side, missing on the other."
_SEVERITY = ["missing", "wrong_type", "misaligned", "low_confidence", "present"]

_VERDICT_TO_ITEM_SCORE = {"present": 100.0, "low_confidence": 50.0, "misaligned": 0.0, "wrong_type": 0.0, "missing": 0.0}

_STATUS_THRESHOLDS = config.STATUS_SCORE_THRESHOLDS
_DEFAULT_STATUS = config.DEFAULT_STATUS_LABEL

_COLOR_PRESENT = (60, 190, 60)      # green, BGR
_COLOR_UNCERTAIN = (40, 200, 230)   # yellow
_COLOR_ISSUE = (50, 60, 200)        # red


@dataclass(frozen=True)
class ItemVerdict:
    object_id: str
    category: str
    doctrine_ref: str
    required: bool
    verdict: str
    confidence: float
    note: str
    crops: list


def _combine(verdicts: list[CropVerdict]) -> tuple[str, float, str]:
    worst = min(verdicts, key=lambda v: _SEVERITY.index(v.verdict))
    avg_confidence = sum(v.confidence for v in verdicts) / len(verdicts)
    notes = "; ".join(f"{v.anchor_name}: {v.note}" for v in verdicts if v.note)
    return worst.verdict, avg_confidence, notes


def combine_item_verdicts(
    resolved_rules: list[ResolvedRule], crop_verdicts: list[CropVerdict]
) -> list[ItemVerdict]:
    by_object: dict[str, list[CropVerdict]] = {}
    for v in crop_verdicts:
        by_object.setdefault(v.object_id, []).append(v)

    items: list[ItemVerdict] = []
    for rule in resolved_rules:
        verdicts = by_object.get(rule.object_id, [])
        if not verdicts:
            continue
        verdict, confidence, note = _combine(verdicts)
        items.append(
            ItemVerdict(
                object_id=rule.object_id,
                category=rule.category,
                doctrine_ref=rule.doctrine_ref,
                required=rule.required,
                verdict=verdict,
                confidence=confidence,
                note=note,
                crops=[v.crop for v in verdicts],
            )
        )
    return items


def compute_subscores(items: list[ItemVerdict]) -> dict[str, float | None]:
    buckets: dict[str, list[float]] = {g: [] for g in SUBSCORE_GROUPS}
    for item in items:
        group = CATEGORY_TO_SUBSCORE.get(item.category)
        if group is None:
            continue
        buckets[group].append(_VERDICT_TO_ITEM_SCORE.get(item.verdict, 0.0))

    return {
        group: (round(sum(scores) / len(scores), 1) if scores else None)
        for group, scores in buckets.items()
    }


def compute_overall_score(subscores: dict[str, float | None]) -> float:
    modeled = [s for s in subscores.values() if s is not None]
    return round(sum(modeled) / len(modeled), 1) if modeled else 0.0


def _status_for_score(score: float) -> str:
    for threshold, label in _STATUS_THRESHOLDS:
        if score >= threshold:
            return label
    return _DEFAULT_STATUS


def build_report(resolved_rules: list[ResolvedRule], crop_verdicts: list[CropVerdict]) -> dict:
    items = combine_item_verdicts(resolved_rules, crop_verdicts)
    subscores = compute_subscores(items)
    overall = compute_overall_score(subscores)

    issues = [
        {
            "item": item.object_id,
            "category": item.category,
            "problem": item.verdict,
            "severity": "High" if (item.required and item.verdict == "missing") else "Medium",
            "confidence": round(item.confidence, 2),
            "doctrine_ref": item.doctrine_ref,
            "note": item.note,
            "bbox": [
                [round(c.x1, 1), round(c.y1, 1), round(c.x2, 1), round(c.y2, 1)] for c in item.crops
            ],
        }
        for item in items
        if item.verdict in ("missing", "misaligned", "wrong_type")
    ]
    uncertain = [
        {"item": item.object_id, "reason": item.note or "low confidence", "confidence": round(item.confidence, 2)}
        for item in items
        if item.verdict == "low_confidence"
    ]

    return {
        "overall_score": overall,
        "status": _status_for_score(overall),
        "subscores": subscores,
        "issues": issues,
        "uncertain": uncertain,
        "items_evaluated": len(items),
        "_scoring_note": (
            "MVP scoring: unweighted mean of modeled subscore buckets, item "
            "score in {100, 50, 0} by verdict. Not calibrated against real "
            "inspection outcomes yet — see architecture memo §13."
        ),
    }


def render_annotated_image(image_bgr: np.ndarray, items: list[ItemVerdict]) -> bytes:
    annotated = image_bgr.copy()
    for item in items:
        color = (
            _COLOR_PRESENT
            if item.verdict == "present"
            else _COLOR_UNCERTAIN
            if item.verdict == "low_confidence"
            else _COLOR_ISSUE
        )
        for crop in item.crops:
            p1, p2 = (int(crop.x1), int(crop.y1)), (int(crop.x2), int(crop.y2))
            cv2.rectangle(annotated, p1, p2, color, 2)
            cv2.putText(
                annotated, item.object_id, (p1[0], max(p1[1] - 5, 10)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1, cv2.LINE_AA,
            )
    ok, buf = cv2.imencode(".jpg", annotated, [cv2.IMWRITE_JPEG_QUALITY, 90])
    if not ok:
        raise ValueError("failed to encode annotated image")
    return buf.tobytes()


def render_annotated_image_b64(image_bgr: np.ndarray, items: list[ItemVerdict]) -> str:
    return base64.b64encode(render_annotated_image(image_bgr, items)).decode("ascii")


# --- Debug visualization for /check_uniform's geometric VerdictResult ------
# Distinct from `render_annotated_image` above (which draws vision-crop
# `ItemVerdict` boxes) — this draws the enriched geometric VerdictResult's
# expected-vs-detected marker pair + an error-vector arrow between them,
# matching the debug-overlay style requested in the check_uniform-api-
# contract plan §14.

_DEBUG_COLOR_BY_STATUS = {
    "pass": _COLOR_PRESENT,
    "slightly_misaligned": (30, 165, 230),  # amber, BGR
    "fail": _COLOR_ISSUE,
    "missing": _COLOR_ISSUE,
    "unverifiable": (150, 150, 150),  # grey
}
_DEBUG_COLOR_EXPECTED = (230, 120, 30)  # blue, BGR


def render_debug_image(image_bgr: np.ndarray, verdicts: list[VerdictResult]) -> bytes:
    annotated = image_bgr.copy()
    for verdict in verdicts:
        color = _DEBUG_COLOR_BY_STATUS.get(verdict.status, (150, 150, 150))

        expected = verdict.expected_position_px
        detected = verdict.detected_position_px
        if expected is not None:
            p_expected = (int(expected[0]), int(expected[1]))
            cv2.circle(annotated, p_expected, 5, _DEBUG_COLOR_EXPECTED, -1, cv2.LINE_AA)
        if detected is not None:
            p_detected = (int(detected[0]), int(detected[1]))
            cv2.circle(annotated, p_detected, 5, color, -1, cv2.LINE_AA)
        if expected is not None and detected is not None:
            cv2.arrowedLine(annotated, p_expected, p_detected, color, 1, cv2.LINE_AA, tipLength=0.2)

        label_point = detected or expected
        if label_point is not None:
            label = f"{verdict.accessory}: {verdict.status.upper()}"
            origin = (int(label_point[0]) + 8, max(int(label_point[1]) - 8, 10))
            cv2.putText(annotated, label, origin, cv2.FONT_HERSHEY_SIMPLEX, 0.4, color, 1, cv2.LINE_AA)

    ok, buf = cv2.imencode(".jpg", annotated, [cv2.IMWRITE_JPEG_QUALITY, 90])
    if not ok:
        raise ValueError("failed to encode debug image")
    return buf.tobytes()


def render_debug_image_b64(image_bgr: np.ndarray, verdicts: list[VerdictResult]) -> str:
    return base64.b64encode(render_debug_image(image_bgr, verdicts)).decode("ascii")
