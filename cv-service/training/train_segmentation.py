"""Trains a YOLOv8n-seg model on the synthetic dataset from
`generate_segmentation_dataset.py`.

This is a REAL training run producing a REAL trained model — not a
placeholder. Read this before trusting its output for anything beyond
a proof of concept: every training image is a synthetic pyrender
render of the same one reference body GLB, from a randomized camera —
**zero real photographs were used.** There is no evaluation against a
real photo anywhere in this training run, so its validation metrics
(printed at the end, also saved under `runs/`) measure only "does it
generalize across synthetic camera angles of the same body," not
"does it work on an actual soldier." The synthetic-to-real domain gap
is real and completely unaddressed by this script — see the
architecture memo §15's training strategy, which always assumed real
photos would eventually close that gap, and the ChangeRequest plan
this belongs to for the full caveat.

Usage:
    .venv-tools/bin/python cv-service/training/train_segmentation.py \
        --data cv-service/synthetic_data/seg_v1/data.yaml \
        --epochs 40 --out cv-service/models/segmentation_v1
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from ultralytics import YOLO


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", type=str, required=True)
    parser.add_argument("--epochs", type=int, default=40)
    parser.add_argument("--imgsz", type=int, default=512)
    parser.add_argument("--device", type=str, default="mps")
    parser.add_argument("--out", type=str, default="cv-service/models/segmentation_v1")
    parser.add_argument("--model", type=str, default="yolov8n-seg.pt", help="base weights, e.g. yolov8s-seg.pt")
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--patience", type=int, default=15)
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    out_dir = repo_root / args.out
    out_dir.parent.mkdir(parents=True, exist_ok=True)

    model = YOLO(args.model)
    results = model.train(
        data=args.data,
        epochs=args.epochs,
        imgsz=args.imgsz,
        device=args.device,
        project=str(out_dir.parent),
        name=out_dir.name,
        patience=args.patience,
        batch=args.batch,
        exist_ok=True,
        verbose=True,
    )

    metrics = model.val()
    print("\n=== Validation metrics (synthetic val split only — no real photos) ===")
    print(f"mAP50(mask):    {metrics.seg.map50:.4f}")
    print(f"mAP50-95(mask): {metrics.seg.map:.4f}")
    print("Per-class mAP50(mask):")
    for i, name in model.names.items():
        try:
            print(f"  {name:15s} {metrics.seg.ap50[i]:.4f}")
        except (IndexError, AttributeError):
            pass

    best_weights = out_dir / "weights" / "best.pt"
    print(f"\nBest weights: {best_weights}")

    # Only now is the model complete — segmentation/segment_uniform.py
    # won't load a model directory without this marker.
    (out_dir / "training_complete.json").write_text(json.dumps({
        "base_model": args.model,
        "data": args.data,
        "epochs_requested": args.epochs,
        "imgsz": args.imgsz,
        "val_mask_map50": round(float(metrics.seg.map50), 4),
        "val_mask_map50_95": round(float(metrics.seg.map), 4),
        "per_class_mask_map50": {name: round(float(metrics.seg.ap50[i]), 4) for i, name in model.names.items()
                                 if i < len(metrics.seg.ap50)},
        "validated_on": "synthetic val split only — no real photos",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
