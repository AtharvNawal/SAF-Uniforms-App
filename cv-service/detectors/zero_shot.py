"""B7 — zero-shot second opinion for items the trained segmenter missed.

The trained segmenter has only ever seen synthetic renders. For every
detector-backed rule whose search box ended up with no detection of its
class, this asks two pretrained, open-vocabulary models instead:
YOLO-World (boxes from a text prompt such as "metal cap badge") on an
upscaled crop of the search box, then SAM 2 (pixel mask from that box).
Both were trained on large real-image corpora, so they don't share the
synthetic-only blind spot.

It only ever *adds* a candidate where the trained model had none — it
never replaces or overrides a trained detection — and every region it
adds is tagged `source="zero_shot"` so the report can say so.

Measured on seg_v2 renders (true item present) vs. the bare-body test
fixture (item absent), YOLO-World scores separate cleanly for LARGE items
— true beret 0.70-0.91, true belt 0.61-0.69, but a bare head scores 0.18
as "beret" — and are near zero for small ones (cap badge, epaulette,
name tag < 0.2 even when present). Hence `ZERO_SHOT_ACCEPT_CONFIDENCE`
(0.45) and running it only for `ZERO_SHOT_CLASSES` (headwear, belt,
footwear) by default: below that it adds false positives, not recall. Weights
(`models/yolov8s-worldv2.pt`, `models/sam2_t.pt`) download on first use;
if they can't be loaded the pass is skipped. See
ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

import cv2
import numpy as np

import config
from rules.rule_engine import ResolvedRule, segmentation_class_for
from segmentation.mask_geometry import mask_centroid_px
from segmentation.segment_uniform import SegmentationResult, SegmentedRegion

_MODELS_DIR = Path(__file__).resolve().parents[1] / "models"

# Text prompts per segmentation class. Several phrasings per class — the
# best-scoring box across them wins.
PROMPTS: dict[str, list[str]] = {
    "headwear": ["beret", "military beret", "turban"],
    "cap_badge": ["metal cap badge", "badge on a beret"],
    "epaulette": ["epaulette", "shoulder rank slide"],
    "sleeve_rank": ["rank insignia patch on sleeve", "sleeve chevron"],
    "arms_badge": ["collar badge", "small metal collar pin"],
    "belt": ["belt buckle", "black waist belt"],
    "footwear": ["black leather shoe"],
    "name_tag": ["name tag", "name plate on shirt"],
    "socks": ["black sock"],
}


@lru_cache(maxsize=1)
def _world_model():
    from ultralytics import YOLOWorld

    model = YOLOWorld(str(_MODELS_DIR / "yolov8s-worldv2.pt"))
    classes = [prompt for prompts in PROMPTS.values() for prompt in prompts]
    model.set_classes(classes)
    return model, classes


@lru_cache(maxsize=1)
def _sam_model():
    from ultralytics import SAM

    return SAM(str(_MODELS_DIR / "sam2_t.pt"))


def _prompt_to_class() -> dict[str, str]:
    return {prompt: cls for cls, prompts in PROMPTS.items() for prompt in prompts}


def _search_box(rule: ResolvedRule, image_w: int, image_h: int, padding: float) -> list[tuple[float, float, float, float]]:
    boxes = []
    for crop in rule.crops:
        pad_x, pad_y = (crop.x2 - crop.x1) * padding / 2, (crop.y2 - crop.y1) * padding / 2
        boxes.append((max(0.0, crop.x1 - pad_x), max(0.0, crop.y1 - pad_y), min(float(image_w), crop.x2 + pad_x), min(float(image_h), crop.y2 + pad_y)))
    return boxes


def _crop_has_candidate(rule: ResolvedRule, crop, regions: list[SegmentedRegion], segmentation_class: str) -> bool:
    for region in regions:
        if region.class_name != segmentation_class or region.confidence < config.MIN_SEGMENT_CONFIDENCE:
            continue
        centroid = mask_centroid_px(region.mask)
        if centroid and crop.x1 <= centroid[0] <= crop.x2 and crop.y1 <= centroid[1] <= crop.y2:
            return True
    return False


def _best_boxes(image_bgr: np.ndarray, boxes: list[tuple[float, float, float, float]], classes: list[str]):
    """YOLO-World over every search box in ONE batched call; returns, per
    box, `(confidence, full-image box)` of the best detection of that box's
    class, or `None`."""
    model, prompts = _world_model()
    prompt_class = _prompt_to_class()
    crops, meta = [], []
    for index, box in enumerate(boxes):
        x1, y1, x2, y2 = (int(v) for v in box)
        crop = image_bgr[y1:y2, x1:x2]
        if crop.shape[0] < 8 or crop.shape[1] < 8:
            continue
        scale = max(1.0, config.TWO_STAGE_CROP_SIZE_PX / max(crop.shape[:2]))
        if scale > 1.0:
            crop = cv2.resize(crop, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
        crops.append(crop)
        meta.append((index, x1, y1, scale))
    best: list = [None] * len(boxes)
    if not crops:
        return best
    for (index, x1, y1, scale), result in zip(meta, model.predict(crops, conf=config.ZERO_SHOT_ACCEPT_CONFIDENCE, verbose=False)):
        for i in range(len(result.boxes)):
            if prompt_class.get(prompts[int(result.boxes.cls[i])]) != classes[index]:
                continue
            confidence = float(result.boxes.conf[i])
            if best[index] is None or confidence > best[index][0]:
                bx1, by1, bx2, by2 = (float(v) / scale for v in result.boxes.xyxy[i])
                best[index] = (confidence, (x1 + bx1, y1 + by1, x1 + bx2, y1 + by2))
    return best


def _to_region(image_bgr: np.ndarray, found, segmentation_class: str) -> SegmentedRegion:
    """SAM 2 turns a YOLO-World box into a pixel mask (falls back to the
    box itself)."""
    confidence, full_box = found
    h, w = image_bgr.shape[:2]
    mask = np.zeros((h, w), dtype=bool)
    try:
        sam_result = _sam_model()(image_bgr, bboxes=[list(full_box)], verbose=False)[0]
        if sam_result.masks is not None and len(sam_result.masks.data):
            sam_mask = sam_result.masks.data[0].cpu().numpy().astype(np.uint8)
            if sam_mask.shape != (h, w):
                sam_mask = cv2.resize(sam_mask, (w, h), interpolation=cv2.INTER_NEAREST)
            mask = sam_mask.astype(bool)
    except Exception:  # noqa: BLE001 - fall back to the box itself as the mask
        pass
    if not mask.any():
        bx1, by1, bx2, by2 = (int(v) for v in full_box)
        mask[by1:by2, bx1:bx2] = True
    return SegmentedRegion(
        class_name=segmentation_class,
        # The detector's own score, never inflated: it already cleared
        # ZERO_SHOT_ACCEPT_CONFIDENCE, which sits above the verdict
        # engine's MIN_SEGMENT_CONFIDENCE.
        confidence=confidence,
        mask=mask,
        bbox_px=full_box,
        source="zero_shot",
    )


def detect_in_box(image_bgr: np.ndarray, box: tuple[float, float, float, float], segmentation_class: str) -> SegmentedRegion | None:
    """Best YOLO-World detection of `segmentation_class` inside `box`,
    refined to a pixel mask by SAM 2. `None` when nothing clears
    `ZERO_SHOT_ACCEPT_CONFIDENCE`."""
    found = _best_boxes(image_bgr, [box], [segmentation_class])[0]
    return _to_region(image_bgr, found, segmentation_class) if found else None


def fill_missed_detections(
    image_bgr: np.ndarray, resolved_rules: list[ResolvedRule], segmentation: SegmentationResult
) -> SegmentationResult:
    """Returns `segmentation` plus zero-shot regions for every search box
    of a detector-backed rule that had no trained detection of its class."""
    if not config.ZERO_SHOT_ENABLED:
        return segmentation
    h, w = image_bgr.shape[:2]
    boxes, classes = [], []
    for rule in resolved_rules:
        segmentation_class = segmentation_class_for(rule.category, segmentation.class_names)
        if segmentation_class is None or segmentation_class not in config.ZERO_SHOT_CLASSES:
            continue
        for crop, box in zip(rule.crops, _search_box(rule, w, h, padding=0.0)):
            if not _crop_has_candidate(rule, crop, segmentation.regions, segmentation_class):
                boxes.append(box)
                classes.append(segmentation_class)
    if not boxes:
        return segmentation
    try:
        found = _best_boxes(image_bgr, boxes, classes)
        added = [_to_region(image_bgr, f, c) for f, c in zip(found, classes) if f is not None]
    except Exception:  # noqa: BLE001 - models unavailable -> skip the zero-shot pass entirely
        return segmentation
    return SegmentationResult(segmentation.regions + added, segmentation.image_width, segmentation.image_height, segmentation.class_names)
