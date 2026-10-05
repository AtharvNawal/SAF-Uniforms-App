"""Build-time warm-up: load every model the pipeline uses once, so anything
fetched lazily on first use (YOLOv8n via ultralytics, DINOv2 via torch.hub,
EasyOCR's English model, YOLO-World's CLIP text encoder, SAM 2) is
downloaded *into the image* rather than on every Cloud Run cold start.

Run from cv-service/ (the Dockerfile does this):
    python models/warm_cache.py

Exits non-zero if any loader fails, so a broken image fails the build
instead of the first user's scan.
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


def main() -> int:
    from detectors import name_tag_ocr, variant_matcher, zero_shot
    from pose import detect_person, estimate_pose
    from segmentation import segment_uniform

    steps = [
        ("person detector (YOLOv8n)", detect_person._get_model),
        ("pose landmarker (MediaPipe)", estimate_pose._get_landmarker),
        ("uniform segmenter", segment_uniform._get_model),
        ("badge-variant matcher (DINOv2)", variant_matcher._model),
        ("name-tag OCR (EasyOCR)", name_tag_ocr._reader),
        ("zero-shot detector (YOLO-World + CLIP)", zero_shot._world_model),
        ("zero-shot segmenter (SAM 2)", zero_shot._sam_model),
    ]
    failed = []
    for label, load in steps:
        t0 = time.time()
        try:
            load()
            print(f"[warm_cache] ok   {label} ({time.time() - t0:.1f}s)", flush=True)
        except Exception as e:  # noqa: BLE001 — report every failure, then fail the build
            print(f"[warm_cache] FAIL {label}: {e!r}", flush=True)
            failed.append(label)
    print(f"[warm_cache] segmentation model: {segment_uniform._MODEL_PATH}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
