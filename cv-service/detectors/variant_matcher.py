"""B9 — "is this the RIGHT badge?" via image-embedding similarity.

The segmenter has one class per category (`cap_badge` covers the SLTC/ME6,
COL/ME7 and BG/ME8 variants), so on its own it can confirm a cap badge is
present and correctly placed but never that it's the one the wearer's
rank calls for. This compares a crop of the detected item against the
doctrine reference photo of every variant in the same category
(`assets/accessories/<rule object>/image.png`) using DINOv2-small
embeddings (self-supervised, strong at instance-level visual similarity,
no training data needed).

Decision rule, deliberately conservative — it only ever *fails* an item,
never passes one it couldn't otherwise pass:
  - best match is a different variant, by at least `VARIANT_MARGIN`
    cosine similarity over the expected one → `fail` (`variant`);
  - expected variant is best → note only;
  - anything closer → note "variant not distinguishable", no change.

Reference images are photos cropped out of the doctrine PDF; detected
crops are small and differently lit, so real-world accuracy of this
check is unmeasured — the synthetic violation benchmark
(`evaluation/run_violation_benchmark.py`) is where its margin is tuned.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import dataclasses
from functools import lru_cache
from pathlib import Path

import cv2
import numpy as np

import config
from rules.rule_engine import VerdictResult

_REFERENCE_DIR = Path(__file__).resolve().parents[2] / "assets" / "accessories"
_INPUT_SIZE = 224
_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


@lru_cache(maxsize=1)
def _model():
    import torch

    model = torch.hub.load("facebookresearch/dinov2", "dinov2_vits14", verbose=False)
    model.eval()
    return model


def _content_crop(image_bgr: np.ndarray) -> np.ndarray:
    """Crops a doctrine reference image to its non-white content, ignoring
    the thin border rules the PDF extraction left in (removed by a
    morphological opening before taking the bounding box)."""
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    ink = (gray < 235).astype(np.uint8)
    ink = cv2.morphologyEx(ink, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    ys, xs = np.nonzero(ink)
    if len(xs) == 0:
        return image_bgr
    return image_bgr[ys.min(): ys.max() + 1, xs.min(): xs.max() + 1]


def _embed(image_bgr: np.ndarray) -> np.ndarray:
    import torch

    rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    h, w = rgb.shape[:2]
    scale = _INPUT_SIZE / max(h, w)
    rgb = cv2.resize(rgb, (max(1, int(w * scale)), max(1, int(h * scale))), interpolation=cv2.INTER_CUBIC)
    canvas = np.full((_INPUT_SIZE, _INPUT_SIZE, 3), 255, dtype=np.uint8)
    y0, x0 = (_INPUT_SIZE - rgb.shape[0]) // 2, (_INPUT_SIZE - rgb.shape[1]) // 2
    canvas[y0:y0 + rgb.shape[0], x0:x0 + rgb.shape[1]] = rgb
    tensor = torch.from_numpy(((canvas.astype(np.float32) / 255.0 - _MEAN) / _STD).transpose(2, 0, 1))[None]
    with torch.no_grad():
        feature = _model()(tensor)[0].numpy()
    return feature / (np.linalg.norm(feature) + 1e-9)


@lru_cache(maxsize=128)
def _reference_embedding(object_id: str) -> np.ndarray | None:
    path = _REFERENCE_DIR / object_id / "image.png"
    image = cv2.imread(str(path))
    if image is None:
        return None
    return _embed(_content_crop(image))


def _item_crop(image_bgr: np.ndarray, verdict: VerdictResult) -> np.ndarray | None:
    if verdict.bounding_box_px is None:
        return None
    x1, y1, x2, y2 = verdict.bounding_box_px
    pad_x, pad_y = (x2 - x1) * 0.15, (y2 - y1) * 0.15
    h, w = image_bgr.shape[:2]
    x1, y1 = max(0, int(x1 - pad_x)), max(0, int(y1 - pad_y))
    x2, y2 = min(w, int(x2 + pad_x)), min(h, int(y2 + pad_y))
    if x2 - x1 < 6 or y2 - y1 < 6:
        return None
    return image_bgr[y1:y2, x1:x2]


def variants_by_category(all_rules: list[dict]) -> dict[str, list[str]]:
    """Every doctrine variant per category, regardless of profile
    condition — the candidates a detected item could actually be."""
    by_category: dict[str, list[str]] = {}
    for rule in all_rules:
        by_category.setdefault(rule.get("category", ""), []).append(rule["object"])
    return by_category


def check_variants(
    verdicts: list[VerdictResult], all_rules: list[dict], image_bgr: np.ndarray, categories: dict[str, str]
) -> list[VerdictResult]:
    """`categories` maps a verdict's accessory id to its doctrine category."""
    variants = variants_by_category(all_rules)
    checked: list[VerdictResult] = []
    for verdict in verdicts:
        candidates = [v for v in variants.get(categories.get(verdict.accessory, ""), []) if v != verdict.accessory]
        crop = _item_crop(image_bgr, verdict)
        if not candidates or crop is None or verdict.status not in ("pass", "slightly_misaligned"):
            checked.append(verdict)
            continue
        try:
            item = _embed(crop)
            expected_ref = _reference_embedding(verdict.accessory)
            others = {c: _reference_embedding(c) for c in candidates}
        except Exception as exc:  # noqa: BLE001 - model unavailable -> leave the verdict as it was
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; variant not checked ({type(exc).__name__})"))
            continue
        if expected_ref is None:
            checked.append(verdict)
            continue
        expected_sim = float(item @ expected_ref)
        scored = {c: float(item @ ref) for c, ref in others.items() if ref is not None}
        best_other, best_sim = max(scored.items(), key=lambda kv: kv[1], default=(None, -1.0))
        if best_other is not None and best_sim - expected_sim >= config.VARIANT_MARGIN:
            checked.append(dataclasses.replace(
                verdict, status="fail", failure_kind="variant",
                reason=(f"{verdict.reason}; variant: looks like '{best_other}' (similarity {best_sim:.2f}) rather than the "
                        f"expected '{verdict.accessory}' ({expected_sim:.2f})"),
            ))
        elif best_other is None or expected_sim >= best_sim:
            checked.append(dataclasses.replace(verdict, reason=f"{verdict.reason}; variant: matches expected ({expected_sim:.2f})"))
        else:
            checked.append(dataclasses.replace(
                verdict, reason=f"{verdict.reason}; variant: not distinguishable from '{best_other}' ({best_sim:.2f} vs {expected_sim:.2f})"
            ))
    return checked
