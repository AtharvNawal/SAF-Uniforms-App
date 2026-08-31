"""Converts Milestone A's ground-truth label JSON
(`cv-service/data/labels/*.json`, pixel-space polygons) into the exact
YOLO-seg dataset format `training/generate_segmentation_dataset.py`
already produces (normalized polygon coordinates, one instance per line,
a `data.yaml` with the same class ordering).

This is a **format converter, not a new metric implementation** — the
whole point is that `model.val()` then computes mAP50 through the
identical Ultralytics code path the original synthetic training run
used, so a real-vs-synthetic comparison is genuinely apples-to-apples
rather than two differently-computed numbers that happen to share a
name. See `evaluation/compare_segmentation_real_vs_synthetic.py`.
"""

from __future__ import annotations

import json
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from training.generate_segmentation_dataset import CLASS_ID  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class ConversionResult:
    converted_photo_ids: list[str] = field(default_factory=list)
    skipped_synthetic_photo_ids: list[str] = field(default_factory=list)
    data_yaml_path: Path | None = None


def _label_to_yolo_lines(label: dict) -> list[str]:
    width, height = label["image_width"], label["image_height"]
    lines: list[str] = []
    for accessory in label["accessories"]:
        if not accessory.get("present"):
            continue
        class_id = CLASS_ID.get(accessory["class_name"])
        if class_id is None:
            continue
        polygon = accessory.get("polygon_px")
        if not polygon or len(polygon) < 3:
            continue
        coords = " ".join(f"{x / width:.5f} {y / height:.5f}" for x, y in polygon)
        lines.append(f"{class_id} {coords}")
    return lines


def convert_labels_to_yolo_seg(
    label_paths: list[Path], out_dir: Path, *, require_real: bool = True
) -> ConversionResult:
    """`require_real=True` (the default) excludes any label with
    `is_synthetic_stand_in: true` — a caller has to explicitly opt out
    (`require_real=False`) to include synthetic stand-ins, which should
    only ever happen for a mechanical smoke test, never for a result
    presented as "real-world" accuracy."""
    images_dir = out_dir / "images" / "val"
    labels_dir = out_dir / "labels" / "val"

    converted: list[str] = []
    skipped_synthetic: list[str] = []

    for label_path in label_paths:
        label = json.loads(Path(label_path).read_text())
        if label["is_synthetic_stand_in"] and require_real:
            skipped_synthetic.append(label["photo_id"])
            continue

        photo_id = label["photo_id"]
        source_path = REPO_ROOT / label["source_path"]
        lines = _label_to_yolo_lines(label)

        images_dir.mkdir(parents=True, exist_ok=True)
        labels_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(source_path, images_dir / f"{photo_id}{source_path.suffix}")
        (labels_dir / f"{photo_id}.txt").write_text("\n".join(lines))
        converted.append(photo_id)

    if not converted:
        return ConversionResult(converted_photo_ids=[], skipped_synthetic_photo_ids=skipped_synthetic, data_yaml_path=None)

    data_yaml_path = out_dir / "data.yaml"
    data_yaml = {
        "path": str(out_dir),
        # Ultralytics' data.yaml schema expects a `train` key even for a
        # validation-only run; pointing it at the same val split is a
        # no-op since only `model.val(data=...)` ever reads this file here.
        "train": "images/val",
        "val": "images/val",
        "names": {i: name for name, i in CLASS_ID.items()},
    }
    data_yaml_path.write_text(yaml.safe_dump(data_yaml, sort_keys=False))

    return ConversionResult(
        converted_photo_ids=converted,
        skipped_synthetic_photo_ids=skipped_synthetic,
        data_yaml_path=data_yaml_path,
    )
