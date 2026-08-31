"""Stage 1 — human detection.

A small, pretrained gate: confirm exactly one person is in the frame
before spending budget on pose estimation, PnP, or vision calls. No
fine-tuning — COCO's "person" class is enough for this job (see the
architecture memo, Stage 1).
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from ultralytics import YOLO

import config

_MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "yolov8n.pt"
_PERSON_CLASS_ID = 0  # COCO class 0 == "person"
_DEFAULT_MIN_CONFIDENCE = config.MIN_PERSON_CONFIDENCE

_model: YOLO | None = None


def _get_model() -> YOLO:
    global _model
    if _model is None:
        _model = YOLO(str(_MODEL_PATH))
    return _model


@dataclass(frozen=True)
class PersonBox:
    x1: float
    y1: float
    x2: float
    y2: float
    confidence: float

    @property
    def width(self) -> float:
        return self.x2 - self.x1

    @property
    def height(self) -> float:
        return self.y2 - self.y1


@dataclass(frozen=True)
class DetectionResult:
    accepted: bool
    reason: str
    person: PersonBox | None
    candidate_count: int


def detect_person(
    image_path: str, *, min_confidence: float = _DEFAULT_MIN_CONFIDENCE
) -> DetectionResult:
    """Run the person-detection gate against a single image file.

    Returns `accepted=False` with a specific `reason` for empty,
    multi-person, or low-confidence frames — callers should surface
    that reason to the user rather than a generic failure (see the
    architecture memo's capture-protocol guidance).
    """
    model = _get_model()
    results = model.predict(
        source=image_path, classes=[_PERSON_CLASS_ID], verbose=False
    )
    boxes = results[0].boxes

    candidates = [
        PersonBox(
            x1=float(b.xyxy[0][0]),
            y1=float(b.xyxy[0][1]),
            x2=float(b.xyxy[0][2]),
            y2=float(b.xyxy[0][3]),
            confidence=float(b.conf[0]),
        )
        for b in boxes
        if float(b.conf[0]) >= min_confidence
    ]

    if len(candidates) == 0:
        return DetectionResult(
            accepted=False,
            reason="no_person_detected",
            person=None,
            candidate_count=0,
        )
    if len(candidates) > 1:
        return DetectionResult(
            accepted=False,
            reason="multiple_people_detected",
            person=None,
            candidate_count=len(candidates),
        )

    return DetectionResult(
        accepted=True, reason="ok", person=candidates[0], candidate_count=1
    )
