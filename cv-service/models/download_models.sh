#!/usr/bin/env bash
# Fetches the pretrained model weights this service needs. Nothing here
# is fine-tuned or SAF-specific — see cv-service/README.md for why.
#
# yolov8n.pt (Stage 1, human detection) downloads itself automatically
# on first use via the `ultralytics` package, so it's not fetched here —
# this script only needs to handle the MediaPipe pose landmarker, which
# `mediapipe`'s Tasks API does NOT auto-download.
set -euo pipefail
cd "$(dirname "$0")"

curl -sSL -o pose_landmarker_lite.task \
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task"

# Heavy variant — the default pose model since
# ChangeRequest/2026-09-28_accuracy-program-no-real-data.md (A1); the lite
# model stays as a fallback when this file is absent.
curl -sSL -o pose_landmarker_heavy.task \
  "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/1/pose_landmarker_heavy.task"

echo "Wrote $(pwd)/pose_landmarker_lite.task and pose_landmarker_heavy.task"

# Zero-shot second opinion (detectors/zero_shot.py): YOLO-World + SAM 2.
# Ultralytics downloads these on first use too; fetching them here keeps the
# first request from stalling on a download.
curl -sSL -o yolov8s-worldv2.pt \
  "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolov8s-worldv2.pt"
curl -sSL -o sam2_t.pt \
  "https://github.com/ultralytics/assets/releases/download/v8.3.0/sam2_t.pt"
echo "Wrote yolov8s-worldv2.pt and sam2_t.pt"

# DINOv2-small (detectors/variant_matcher.py) and the EasyOCR English model
# (detectors/name_tag_ocr.py) cache themselves under ~/.cache/torch/hub and
# ~/.EasyOCR on first use.
echo "yolov8n.pt will download automatically on first pipeline run."
