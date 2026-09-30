"""B8 — read the name tag and compare it with the wearer's surname.

A detected name tag in the right place still fails doctrine if it isn't
the wearer's. EasyOCR (pretrained, no training data needed) reads the
upscaled name-tag crop; the best-matching token is compared, fuzzily
(OCR on a small embroidered/engraved tag drops or confuses letters), with
the name the app sends — the profile's full name. Which word a tag shows
depends on the name's order (a Chinese name's surname comes first), so a
tag matching ANY word of the name, or the whole name, counts.

  - match ratio ≥ NAME_MATCH_OK        → note "reads '<text>' — matches"
  - readable text, ratio < NAME_MATCH_FAIL → `fail` (`name_text`)
  - anything else (unreadable, in between) → note only, no change

Only ever fails an item; never upgrades one. No surname → skipped.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import dataclasses
import re
from difflib import SequenceMatcher
from functools import lru_cache

import cv2
import numpy as np

import config
from rules.rule_engine import VerdictResult

_MIN_CROP_HEIGHT_PX = 96


@lru_cache(maxsize=1)
def _reader():
    import easyocr

    return easyocr.Reader(["en"], gpu=False, verbose=False)


def _normalise(text: str) -> str:
    return re.sub(r"[^A-Z]", "", text.upper())


def read_text(crop_bgr: np.ndarray) -> list[str]:
    scale = max(1.0, _MIN_CROP_HEIGHT_PX / max(1, crop_bgr.shape[0]))
    if scale > 1.0:
        crop_bgr = cv2.resize(crop_bgr, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    results = _reader().readtext(cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB), detail=0, paragraph=False)
    return [t for t in (_normalise(r) for r in results) if t]


def surname_match(tokens: list[str], name: str) -> tuple[float, str | None]:
    """Best fuzzy ratio between what was read (any token, or the tokens
    joined, for tags OCR splits in two) and the name (any of its words, or
    all of them joined)."""
    targets = [t for t in (_normalise(w) for w in name.split()) if t]
    if len(targets) > 1:
        targets.append("".join(targets))
    if not targets or not tokens:
        return 0.0, None
    candidates = tokens + (["".join(tokens)] if len(tokens) > 1 else [])
    ratio, best = max(
        ((SequenceMatcher(None, c, t).ratio(), c) for c in candidates for t in targets), key=lambda rb: rb[0]
    )
    return ratio, best


def check_name_tag(verdicts: list[VerdictResult], image_bgr: np.ndarray, surname: str | None) -> list[VerdictResult]:
    if not surname or not surname.strip():
        return verdicts
    checked: list[VerdictResult] = []
    for verdict in verdicts:
        if not verdict.accessory.startswith("name_tag") or verdict.bounding_box_px is None or verdict.status not in ("pass", "slightly_misaligned"):
            checked.append(verdict)
            continue
        x1, y1, x2, y2 = verdict.bounding_box_px
        h, w = image_bgr.shape[:2]
        pad_x, pad_y = (x2 - x1) * 0.1, (y2 - y1) * 0.3
        crop = image_bgr[max(0, int(y1 - pad_y)): min(h, int(y2 + pad_y)), max(0, int(x1 - pad_x)): min(w, int(x2 + pad_x))]
        try:
            tokens = read_text(crop) if crop.size else []
        except Exception as exc:  # noqa: BLE001 - OCR unavailable -> leave verdict as it was
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; name not read ({type(exc).__name__})"))
            continue
        ratio, best = surname_match(tokens, surname)
        if best is None:
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; name tag text not readable in this photo"))
        elif ratio >= config.NAME_MATCH_OK:
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; name tag reads '{best}' — matches the profile name"))
        elif ratio < config.NAME_MATCH_FAIL and len(best) >= 3:
            checked.append(dataclasses.replace(
                verdict, status="fail", failure_kind="name_text",
                reason=f"{verdict.reason}; name tag reads '{best}', expected a word of '{surname.upper()}' (match {ratio:.2f})",
            ))
        else:
            checked.append(dataclasses.replace(
                verdict, reason=f"{verdict.reason}; name tag reads '{best}' — can't confirm it matches '{surname.upper()}' (match {ratio:.2f})"
            ))
    return checked
