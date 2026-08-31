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

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from ultralytics import YOLO

import config

_MODEL_PATH = (
    Path(__file__).resolve().parents[1] / "models" / "segmentation_v1" / "weights" / "best.pt"
)
_DEFAULT_MIN_CONFIDENCE = config.MIN_SEGMENT_CONFIDENCE

_model: YOLO | None = None


def _get_model() -> YOLO:
    global _model
    if _model is None:
        if not _MODEL_PATH.exists():
            raise FileNotFoundError(
                f"{_MODEL_PATH} not found — run "
                "cv-service/training/generate_segmentation_dataset.py then "
                "cv-service/training/train_segmentation.py first."
            )
        _model = YOLO(str(_MODEL_PATH))
    return _model


@dataclass(frozen=True)
class SegmentedRegion:
    class_name: str
    confidence: float
    mask: np.ndarray  # boolean, same H×W as the input image
    bbox_px: tuple[float, float, float, float]  # x1, y1, x2, y2


@dataclass(frozen=True)
class SegmentationResult:
    regions: list[SegmentedRegion]
    image_width: int
    image_height: int

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


def segment_uniform(
    image_path: str, *, min_confidence: float = _DEFAULT_MIN_CONFIDENCE
) -> SegmentationResult:
    model = _get_model()
    results = model.predict(source=image_path, conf=min_confidence, verbose=False)
    result = results[0]

    regions: list[SegmentedRegion] = []
    if result.masks is not None:
        h, w = result.orig_shape
        for i, mask_tensor in enumerate(result.masks.data):
            class_id = int(result.boxes.cls[i])
            confidence = float(result.boxes.conf[i])
            class_name = model.names[class_id]
            mask = mask_tensor.cpu().numpy().astype(bool)
            if mask.shape != (h, w):
                import cv2

                mask = cv2.resize(mask.astype(np.uint8), (w, h), interpolation=cv2.INTER_NEAREST).astype(bool)
            x1, y1, x2, y2 = (float(v) for v in result.boxes.xyxy[i])
            regions.append(
                SegmentedRegion(
                    class_name=class_name,
                    confidence=confidence,
                    mask=mask,
                    bbox_px=(x1, y1, x2, y2),
                )
            )

    h, w = result.orig_shape
    return SegmentationResult(regions=regions, image_width=w, image_height=h)
