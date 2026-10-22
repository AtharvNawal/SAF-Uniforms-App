"""Stage 4 — uniform segmentation. A REAL trained model, with a real,
unaddressed limitation: read this before wiring it into anything that
matters.

`cv-service/models/segmentation_v1/weights/best.pt` is a YOLOv8n-seg
model actually trained (not a placeholder) on
`cv-service/training/generate_segmentation_dataset.py`'s output —
**150 synthetic renders of one reference body GLB, zero real
photographs.** Its 9 classes are `shirt`, `trousers`, `headwear`,
`cap_badge`, `epaulette`, `sleeve_rank`, `arms_badge`, `belt`,
`footwear` — the ceiling of precision the reference mesh's actual
geometry supports (no separate `collar`/`pocket`/`sleeve` sub-regions
exist on the mesh; see the dataset generator's module docstring for
why). Validation metrics live in
`cv-service/models/segmentation_v1/results.csv` and were measured only
against held-out *synthetic* renders of the *same* body — they say
nothing about real-photo accuracy. Treat this as a proof that the
"train on geometry-labeled synthetic data" approach works mechanically,
not as a production-ready segmenter. The synthetic-to-real domain gap
is the same open risk flagged throughout every prior planning document
for this project — training on real photos (or at minimum real photos
mixed in) is the next step before this should gate anything.
"""

from __future__ import annotations

from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from ultralytics import YOLO

import config

_MODELS_DIR = Path(__file__).resolve().parents[1] / "models"


# Written by training/train_segmentation.py once a run has finished and
# been validated. Ultralytics rewrites weights/best.pt after EVERY epoch,
# so the weights file alone doesn't mean the model is done — without this
# marker the service would silently pick up a half-trained model mid-run.
TRAINING_COMPLETE_MARKER = "training_complete.json"
# A model a uniform *asks for* (`uniforms.UniformSpec.segmentation_model`,
# e.g. RSAF No.4 → segmentation_v3) is only used once it has also passed
# its promotion gate, recorded by this file (v3: Army val mAP50 no worse
# than v2's minus 0.02). Otherwise that uniform gets the default model.
# See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
PROMOTED_MARKER = "promoted.json"


def _usable(model_dir: Path, *markers: str) -> bool:
    return all((model_dir / f).exists() for f in (*markers, "weights/best.pt"))


def _model_path(preferred: str | None = None) -> Path:
    """`CV_SERVICE_SEGMENTATION_MODEL` (config) pins one model for every
    request. Otherwise `preferred` (the uniform's own model) if trained and
    promoted; otherwise the default — `segmentation_v2` (12 classes,
    domain-randomised — see training/generate_segmentation_dataset_v2.py)
    once its training has completed, else the original v1 (which predates
    the marker). Army No.3 asks for nothing, so it keeps v2: segmentation_v3
    raised Army belt false alarms 17.9% → 62.5% on the benchmark."""
    pinned = config.SEGMENTATION_MODEL
    if pinned:
        return _MODELS_DIR / pinned / "weights" / "best.pt"
    if preferred and _usable(_MODELS_DIR / preferred, TRAINING_COMPLETE_MARKER, PROMOTED_MARKER):
        return _MODELS_DIR / preferred / "weights" / "best.pt"
    v2 = _MODELS_DIR / "segmentation_v2"
    if (v2 / TRAINING_COMPLETE_MARKER).exists() and (v2 / "weights" / "best.pt").exists():
        return v2 / "weights" / "best.pt"
    return _MODELS_DIR / "segmentation_v1" / "weights" / "best.pt"


_MODEL_PATH = _model_path()
_DEFAULT_MIN_CONFIDENCE = config.MIN_SEGMENT_CONFIDENCE

_models: dict[Path, YOLO] = {}
# The model the current request asked for (see `using_model`); `None` = default.
_active_preference: ContextVar[str | None] = ContextVar("segmentation_model_preference", default=None)


@contextmanager
def using_model(preferred: str | None):
    """Selects the segmentation model for everything inside the block —
    `segment_uniform`, `segment_crops` (two-stage) and `available_classes`
    — so one request is judged by one model end to end."""
    token = _active_preference.set(preferred)
    try:
        yield
    finally:
        _active_preference.reset(token)


def active_model_path() -> Path:
    preferred = _active_preference.get()
    return _model_path(preferred) if preferred else _MODEL_PATH


def _get_model() -> YOLO:
    path = active_model_path()
    if path not in _models:
        if not path.exists():
            raise FileNotFoundError(
                f"{path} not found — run "
                "cv-service/training/generate_segmentation_dataset.py then "
                "cv-service/training/train_segmentation.py first."
            )
        _models[path] = YOLO(str(path))
    return _models[path]


@dataclass(frozen=True)
class SegmentedRegion:
    class_name: str
    confidence: float
    mask: np.ndarray  # boolean, same H×W as the input image
    bbox_px: tuple[float, float, float, float]  # x1, y1, x2, y2
    # "trained" (the segmentation model, full image), "two_stage" (the same
    # model on an upscaled crop, B13) or "zero_shot" (YOLO-World + SAM 2, B7).
    source: str = "trained"


@dataclass(frozen=True)
class SegmentationResult:
    regions: list[SegmentedRegion]
    image_width: int
    image_height: int
    # Classes the model that produced this result can detect at all.
    # `None` = unknown (hand-built results in tests) -> treated as "every
    # class the rule engine maps". Lets a rule whose class the loaded model
    # lacks (e.g. `name_tag` on the 9-class v1 model) be reported
    # `unverifiable`, never a false `missing`.
    class_names: frozenset[str] | None = None

    def regions_for(self, class_name: str) -> list[SegmentedRegion]:
        return [r for r in self.regions if r.class_name == class_name]

    def coverage_fraction(self, class_name: str) -> float:
        """Fraction of the image's pixels covered by the given class —
        a cheap real-vs-empty sanity signal callers can use without
        needing per-pixel mask access (e.g. "is there enough `shirt`
        pixel coverage to trust this photo has a torso in frame")."""
        matches = self.regions_for(class_name)
        if not matches:
            return 0.0
        total_pixels = self.image_width * self.image_height
        combined = np.zeros((self.image_height, self.image_width), dtype=bool)
        for region in matches:
            combined |= region.mask
        return float(combined.sum()) / total_pixels


def available_classes() -> frozenset[str]:
    return frozenset(_get_model().names.values())


def _regions_from_result(result, model, x_offset: float = 0.0, y_offset: float = 0.0, scale: float = 1.0,
                         full_shape: tuple[int, int] | None = None) -> list[SegmentedRegion]:
    """Converts one Ultralytics result into full-image `SegmentedRegion`s.
    For a crop that was upscaled by `scale` and cut at (x_offset, y_offset),
    masks are resized back and pasted into a `full_shape` canvas."""
    regions: list[SegmentedRegion] = []
    if result.masks is None:
        return regions
    crop_h, crop_w = result.orig_shape
    full_h, full_w = full_shape or (crop_h, crop_w)
    for i, mask_tensor in enumerate(result.masks.data):
        mask = mask_tensor.cpu().numpy().astype(np.uint8)
        if mask.shape != (crop_h, crop_w):
            mask = cv2.resize(mask, (crop_w, crop_h), interpolation=cv2.INTER_NEAREST)
        if scale != 1.0 or full_shape is not None:
            back_w, back_h = max(1, round(crop_w / scale)), max(1, round(crop_h / scale))
            small = cv2.resize(mask, (back_w, back_h), interpolation=cv2.INTER_NEAREST)
            canvas = np.zeros((full_h, full_w), dtype=np.uint8)
            x0, y0 = int(round(x_offset)), int(round(y_offset))
            x1, y1 = min(full_w, x0 + back_w), min(full_h, y0 + back_h)
            canvas[y0:y1, x0:x1] = small[: y1 - y0, : x1 - x0]
            mask = canvas
        bx1, by1, bx2, by2 = (float(v) for v in result.boxes.xyxy[i])
        regions.append(
            SegmentedRegion(
                class_name=model.names[int(result.boxes.cls[i])],
                confidence=float(result.boxes.conf[i]),
                mask=mask.astype(bool),
                bbox_px=(x_offset + bx1 / scale, y_offset + by1 / scale, x_offset + bx2 / scale, y_offset + by2 / scale),
            )
        )
    return regions


def _merge_tta(original: list[SegmentedRegion], flipped: list[SegmentedRegion]) -> list[SegmentedRegion]:
    """Merges detections from the mirrored pass: an overlapping same-class
    pair (IoU > MERGE_IOU_THRESHOLD) keeps the union of the masks at the
    higher confidence; a detection only one pass found is kept as is."""
    merged = list(original)
    for region in flipped:
        best, best_iou = None, config.MERGE_IOU_THRESHOLD
        for i, other in enumerate(merged):
            if other.class_name != region.class_name:
                continue
            union = np.logical_or(other.mask, region.mask).sum()
            iou = np.logical_and(other.mask, region.mask).sum() / union if union else 0.0
            if iou > best_iou:
                best, best_iou = i, iou
        if best is None:
            merged.append(region)
            continue
        other = merged[best]
        mask = np.logical_or(other.mask, region.mask)
        ys, xs = np.nonzero(mask)
        merged[best] = SegmentedRegion(
            other.class_name, max(other.confidence, region.confidence), mask,
            (float(xs.min()), float(ys.min()), float(xs.max()), float(ys.max())), other.source,
        )
    return merged


def segment_uniform(
    image_path: str, *, min_confidence: float = _DEFAULT_MIN_CONFIDENCE, augment: bool | None = None
) -> SegmentationResult:
    """Full-image segmentation. With `augment` (A6, default
    `config.SEGMENTATION_TTA`) the image is also segmented mirrored and
    the two passes merged (`_merge_tta`) — Ultralytics' own `augment=True`
    isn't supported for segmentation models, so this is done here. A
    horizontal flip is a safe augmentation for every class: none of them
    is side-specific in appearance (which side an item is on is judged
    later, by the geometry)."""
    model = _get_model()
    use_tta = config.SEGMENTATION_TTA if augment is None else augment
    image_bgr = cv2.imread(image_path)
    result = model.predict(source=image_bgr, conf=min_confidence, verbose=False)[0]
    h, w = result.orig_shape
    regions = _regions_from_result(result, model)
    if use_tta:
        flipped_result = model.predict(source=np.ascontiguousarray(image_bgr[:, ::-1]), conf=min_confidence, verbose=False)[0]
        flipped = []
        for region in _regions_from_result(flipped_result, model):
            x1, y1, x2, y2 = region.bbox_px
            flipped.append(SegmentedRegion(region.class_name, region.confidence, region.mask[:, ::-1].copy(),
                                           (w - x2, y1, w - x1, y2), region.source))
        regions = _merge_tta(regions, flipped)
    return SegmentationResult(regions=regions, image_width=w, image_height=h, class_names=available_classes())


def _prepare_crop(image_bgr: np.ndarray, box: tuple[float, float, float, float], size: int):
    full_h, full_w = image_bgr.shape[:2]
    x1, y1 = max(0, int(box[0])), max(0, int(box[1]))
    x2, y2 = min(full_w, int(box[2])), min(full_h, int(box[3]))
    if x2 - x1 < 8 or y2 - y1 < 8:
        return None
    crop = image_bgr[y1:y2, x1:x2]
    scale = size / max(crop.shape[:2])
    if scale > 1.0:
        crop = cv2.resize(crop, (int(crop.shape[1] * scale), int(crop.shape[0] * scale)), interpolation=cv2.INTER_CUBIC)
    else:
        scale = 1.0
    return crop, x1, y1, scale


def segment_crops(
    image_bgr: np.ndarray,
    boxes: list[tuple[float, float, float, float]],
    *,
    target_size: int | None = None,
    min_confidence: float = _DEFAULT_MIN_CONFIDENCE,
) -> list[list[SegmentedRegion]]:
    """B13 — re-segments upscaled crops around small items' expected
    regions, all in ONE batched model call, and returns each crop's
    detections in full-image coordinates. A cap badge is a few dozen
    pixels in a full-body photo; upscaling the crop to the model's working
    size gives it the resolution it was trained at."""
    model = _get_model()
    full_h, full_w = image_bgr.shape[:2]
    size = target_size or config.TWO_STAGE_CROP_SIZE_PX
    prepared = [_prepare_crop(image_bgr, box, size) for box in boxes]
    valid = [(i, p) for i, p in enumerate(prepared) if p is not None]
    out: list[list[SegmentedRegion]] = [[] for _ in boxes]
    if not valid:
        return out
    results = model.predict(source=[p[0] for _, p in valid], conf=min_confidence, verbose=False)
    for (i, (_, x1, y1, scale)), result in zip(valid, results):
        out[i] = _regions_from_result(result, model, x_offset=x1, y_offset=y1, scale=scale, full_shape=(full_h, full_w))
    return out


def segment_crop(
    image_bgr: np.ndarray,
    box: tuple[float, float, float, float],
    *,
    target_size: int | None = None,
    min_confidence: float = _DEFAULT_MIN_CONFIDENCE,
) -> list[SegmentedRegion]:
    """Single-crop convenience wrapper around `segment_crops`."""
    return segment_crops(image_bgr, [box], target_size=target_size, min_confidence=min_confidence)[0]
