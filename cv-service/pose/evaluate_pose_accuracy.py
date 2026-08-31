"""Evaluates `anchor_mapping.estimate_anchor_pose` against ground-truth
label files produced by `cv-service/labeling/` (see Milestone A,
`ChangeRequest/2026-08-11_cv-service-real-photo-ground-truth-tooling.md`).

Reports **synthetic and real-photo accuracy separately, never averaged**
— per this milestone's explicit instruction, since synthetic accuracy
looks better and averaging would mask real-world performance. As of this
writing there are 0 real photos in this repo, so the real-photo row is
reported as an explicit gap, not a fabricated number and not silently
dropped.

    .venv-tools/bin/python cv-service/pose/evaluate_pose_accuracy.py
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pose.anchor_mapping import _ALL_ANCHOR_NAMES, estimate_anchor_pose  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"

# Ground-truth label files only carry the 15 clickable sockets (Milestone
# A's schema deliberately excludes chest_center — it's derived, not
# clickable). For evaluation we derive the same expected chest_center
# from the ground truth's own chest-pocket points, so the estimator's
# chest_center prediction still gets scored against something.
_GROUND_TRUTH_ANCHOR_NAMES = [n for n in _ALL_ANCHOR_NAMES if n != "chest_center"]


def _pixel_error(pred: dict, truth_x: float, truth_y: float) -> float | None:
    if pred["confidence"] <= 0.0 or pred["x_px"] is None:
        return None
    return math.hypot(pred["x_px"] - truth_x, pred["y_px"] - truth_y)


def _ground_truth_chest_center(truth_anchors: dict) -> dict | None:
    left, right = truth_anchors.get("left_chest_pocket"), truth_anchors.get("right_chest_pocket")
    if not left or not right or not left.get("visible") or not right.get("visible"):
        return None
    return {"x_px": (left["x_px"] + right["x_px"]) / 2, "y_px": (left["y_px"] + right["y_px"]) / 2, "visible": True}


def evaluate_one_photo(label: dict) -> dict[str, float | None]:
    """Returns {anchor_name: pixel_error or None} for one labeled photo.
    `None` means either ground truth marked the anchor not-visible, or
    the estimator returned zero confidence — neither counts toward
    accuracy, both are reported separately as coverage gaps."""
    photo_path = REPO_ROOT / label["source_path"]
    predicted = estimate_anchor_pose(str(photo_path))
    truth_anchors = dict(label["anchors"])
    truth_anchors["chest_center"] = _ground_truth_chest_center(truth_anchors)

    errors: dict[str, float | None] = {}
    for name in _ALL_ANCHOR_NAMES:
        truth = truth_anchors.get(name)
        if truth is None or not truth.get("visible"):
            errors[name] = None
            continue
        errors[name] = _pixel_error(predicted[name], truth["x_px"], truth["y_px"])
    return errors


def summarize(per_photo_errors: list[dict[str, float | None]]) -> dict:
    all_errors = [e for photo in per_photo_errors for e in photo.values() if e is not None]
    total_slots = sum(len(photo) for photo in per_photo_errors)
    covered_slots = len(all_errors)
    if not all_errors:
        return {"photo_count": len(per_photo_errors), "mean_px_error": None, "median_px_error": None, "coverage": 0.0}
    sorted_errors = sorted(all_errors)
    mid = len(sorted_errors) // 2
    median = sorted_errors[mid] if len(sorted_errors) % 2 else (sorted_errors[mid - 1] + sorted_errors[mid]) / 2
    return {
        "photo_count": len(per_photo_errors),
        "mean_px_error": round(sum(all_errors) / len(all_errors), 2),
        "median_px_error": round(median, 2),
        "coverage": round(covered_slots / total_slots, 3) if total_slots else 0.0,
    }


def build_accuracy_report() -> dict:
    synthetic_photos: list[dict] = []
    real_photos: list[dict] = []
    for label_path in sorted(LABELS_DIR.glob("*.json")) if LABELS_DIR.exists() else []:
        label = json.loads(label_path.read_text())
        (synthetic_photos if label["is_synthetic_stand_in"] else real_photos).append(label)

    synthetic_errors = [evaluate_one_photo(label) for label in synthetic_photos]
    real_errors = [evaluate_one_photo(label) for label in real_photos]

    return {
        "synthetic": summarize(synthetic_errors),
        "real": summarize(real_errors) if real_photos else {
            "photo_count": 0,
            "mean_px_error": None,
            "median_px_error": None,
            "coverage": None,
            "note": "0 real photos exist in this repo — see ChangeRequest/2026-08-11_cv-service-real-photo-ground-truth-tooling.md",
        },
    }


def main() -> None:
    report = build_accuracy_report()
    print("| Anchor set | Photos | Mean px error | Median px error | Coverage |")
    print("| --- | --- | --- | --- | --- |")
    for label, key in (("Synthetic", "synthetic"), ("Real", "real")):
        row = report[key]
        if row["photo_count"] == 0:
            print(f"| {label} | 0 | N/A | N/A | N/A — {row.get('note', 'no photos')} |")
        else:
            print(f"| {label} | {row['photo_count']} | {row['mean_px_error']} | {row['median_px_error']} | {row['coverage']:.0%} |")


if __name__ == "__main__":
    main()
