"""B10 — doctrine colour check on a detected item's mask.

Only rules whose doctrine text states a colour carry `expected_color`
(`rules/army_no3_male.json`: shoes and socks, "plain black"). "Black" is
judged *relative to the shirt*, not in absolute pixel values: an
under-exposed photo makes everything dark and an over-exposed one lifts
black toward grey, but the white No.3 shirt is exposed the same way, so
the ratio item-brightness / shirt-brightness is stable. A polished shoe's
specular highlights are handled by using the median, not the mean.

Never guesses: no shirt in view, or too few mask pixels, leaves the
verdict unchanged with a note. See
ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import dataclasses

import cv2
import numpy as np

import config
from rules.rule_engine import VerdictResult
from segmentation.segment_uniform import SegmentationResult

_MIN_PIXELS = 40


def _median_value(hsv: np.ndarray, mask: np.ndarray) -> float | None:
    if mask is None or int(mask.sum()) < _MIN_PIXELS:
        return None
    return float(np.median(hsv[..., 2][mask]))


def _median_saturation(hsv: np.ndarray, mask: np.ndarray) -> float:
    return float(np.median(hsv[..., 1][mask]))


def _shirt_brightness(hsv: np.ndarray, segmentation: SegmentationResult) -> float | None:
    shirts = [r for r in segmentation.regions if r.class_name == "shirt"]
    if not shirts:
        return None
    return _median_value(hsv, max(shirts, key=lambda r: int(r.mask.sum())).mask)


def check_colors(
    verdicts: list[VerdictResult], rules_by_id: dict[str, dict], image_bgr: np.ndarray, segmentation: SegmentationResult
) -> list[VerdictResult]:
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    shirt_value = _shirt_brightness(hsv, segmentation)
    checked: list[VerdictResult] = []
    for verdict in verdicts:
        expected = (rules_by_id.get(verdict.accessory) or {}).get("expected_color")
        if expected != "black" or verdict.region_mask is None or verdict.status not in ("pass", "slightly_misaligned"):
            checked.append(verdict)
            continue
        item_value = _median_value(hsv, verdict.region_mask)
        if item_value is None or not shirt_value:
            checked.append(dataclasses.replace(verdict, reason=verdict.reason + "; colour not checked (no shirt reference or too few pixels)"))
            continue
        relative = item_value / shirt_value
        saturation = _median_saturation(hsv, verdict.region_mask)
        is_black = relative <= config.BLACK_MAX_RELATIVE_BRIGHTNESS and saturation <= config.BLACK_MAX_SATURATION
        note = f"colour: brightness {relative:.2f}× the shirt's, saturation {saturation:.0f} (black ≤ {config.BLACK_MAX_RELATIVE_BRIGHTNESS}×, ≤ {config.BLACK_MAX_SATURATION:.0f})"
        if is_black:
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; {note} — black as required"))
        else:
            checked.append(dataclasses.replace(
                verdict, status="fail", failure_kind="color", reason=f"{verdict.reason}; {note} — doctrine requires black"
            ))
    return checked
