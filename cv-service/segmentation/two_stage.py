"""B13 — second, upscaled segmentation pass for small items.

In a full-body photo a cap badge or collar badge is a few dozen pixels,
below what the segmenter resolves reliably at its working size. Once the
camera is solved we know where each small item *should* be, so the same
trained model is re-run on an upscaled crop around that search box
(`segment_uniform.segment_crop`) and its detections are merged back:
an overlapping same-class detection keeps whichever is more confident;
a new one is added with `source="two_stage"`.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import numpy as np

import config
from rules.rule_engine import ResolvedRule, segmentation_class_for
from segmentation.segment_uniform import SegmentationResult, SegmentedRegion, segment_crops


def mask_iou(a: np.ndarray, b: np.ndarray) -> float:
    union = np.logical_or(a, b).sum()
    return float(np.logical_and(a, b).sum() / union) if union else 0.0


def merge_regions(existing: list[SegmentedRegion], new: list[SegmentedRegion]) -> list[SegmentedRegion]:
    merged = list(existing)
    for region in new:
        overlap = [
            i for i, other in enumerate(merged)
            if other.class_name == region.class_name and mask_iou(other.mask, region.mask) > config.MERGE_IOU_THRESHOLD
        ]
        if not overlap:
            merged.append(region)
            continue
        best = max(overlap, key=lambda i: merged[i].confidence)
        if region.confidence > merged[best].confidence:
            merged[best] = region
    return merged


def refine_small_items(
    image_bgr: np.ndarray, resolved_rules: list[ResolvedRule], segmentation: SegmentationResult
) -> SegmentationResult:
    if not config.TWO_STAGE_ENABLED:
        return segmentation
    h, w = image_bgr.shape[:2]
    boxes: list[tuple[float, float, float, float]] = []
    classes: list[str] = []
    for rule in resolved_rules:
        if rule.category not in config.TWO_STAGE_CATEGORIES:
            continue
        segmentation_class = segmentation_class_for(rule.category, segmentation.class_names)
        if segmentation_class is None:
            continue
        for crop in rule.crops:
            pad_x = (crop.x2 - crop.x1) * config.TWO_STAGE_PADDING / 2
            pad_y = (crop.y2 - crop.y1) * config.TWO_STAGE_PADDING / 2
            boxes.append((max(0.0, crop.x1 - pad_x), max(0.0, crop.y1 - pad_y), min(float(w), crop.x2 + pad_x), min(float(h), crop.y2 + pad_y)))
            classes.append(segmentation_class)
    regions = list(segmentation.regions)
    # one batched model call for every small-item crop
    for segmentation_class, found in zip(classes, segment_crops(image_bgr, boxes)):
        regions = merge_regions(regions, [
            SegmentedRegion(r.class_name, r.confidence, r.mask, r.bbox_px, source="two_stage")
            for r in found if r.class_name == segmentation_class
        ])
    return SegmentationResult(regions, segmentation.image_width, segmentation.image_height, segmentation.class_names)
