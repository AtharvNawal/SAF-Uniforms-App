#!/usr/bin/env bash
# Renders the seg_v2 dataset then trains segmentation_v2 (B11/B12).
set -euo pipefail
cd "$(dirname "$0")/../.."
.venv-tools/bin/python cv-service/training/generate_segmentation_dataset_v2.py \
  --n-train 1000 --n-val 150 --workers 3 --out cv-service/synthetic_data/seg_v2
.venv-tools/bin/python cv-service/training/train_segmentation.py \
  --data cv-service/synthetic_data/seg_v2/data.yaml --model yolov8s-seg.pt \
  --imgsz 768 --epochs 40 --batch 8 --patience 10 --out cv-service/models/segmentation_v2
