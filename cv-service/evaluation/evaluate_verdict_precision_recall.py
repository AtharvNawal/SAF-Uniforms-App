"""Runs the full geometric pipeline (Milestone B pose → Milestone C
camera solve + rule projection → trained segmentation → verdict engine)
against Milestone A's labeled photos and computes precision/recall per
accessory class — treating `pass`/`fail` as "predicted present",
`missing` as "predicted absent", and excluding `unverifiable` from
scoring entirely (can't score what the pipeline never actually checked).

**0 real photos exist** (see the plan file) — this reports that
explicitly. The 3 synthetic stand-ins can only ever exercise `footwear`
(the only doctrine-rule category with any ground-truth-positive signal
in those renders — `shirt`/`trousers` aren't accessory rules in
`army_no3_male.json` at all, and no accessory GLBs are composited into
the stand-ins for the other categories), so even the synthetic table is
necessarily thin. Stated plainly, not padded out.

Usage:
    .venv-tools/bin/python cv-service/evaluation/evaluate_verdict_precision_recall.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from geometry.project_rules import cm_per_px_from_anchor_pose  # noqa: E402
from geometry.solve_camera_pose import solve_camera_pose  # noqa: E402
from pose.anchor_mapping import estimate_anchor_pose  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402
from rules.rule_engine import CATEGORY_TO_SEGMENTATION_CLASS, evaluate_verdicts, resolve_rules  # noqa: E402
from segmentation.segment_uniform import segment_uniform  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"

DEFAULT_PROFILE = {"rank_tier": "sltc_me6_and_below", "gender": "male", "isSikh": False, "medalRowCount": 0}

# Reverse of CATEGORY_TO_SEGMENTATION_CLASS, restricted to categories
# that actually have a detector — used to translate a VerdictResult back
# to the ground-truth segmentation class it should be checked against.
_SEGMENTATION_CLASS_FOR_CATEGORY = {k: v for k, v in CATEGORY_TO_SEGMENTATION_CLASS.items() if v is not None}


def run_pipeline_for_photo(photo_path: Path, profile: dict) -> list:
    detection = detect_person(str(photo_path))
    if not detection.accepted:
        return []

    anchor_pose = estimate_anchor_pose(str(photo_path))
    image = cv2.imread(str(photo_path))
    height, width = image.shape[:2]

    camera = solve_camera_pose(anchor_pose, image_width=width, image_height=height)
    if not camera.solved:
        return []

    cm_per_px = cm_per_px_from_anchor_pose(anchor_pose) or 0.1
    resolved = resolve_rules(camera, cm_per_px, profile=profile)
    segmentation = segment_uniform(str(photo_path))

    return evaluate_verdicts(
        resolved, segmentation, cm_per_px, width, height, camera_reliable=camera.reliable
    )


def ground_truth_presence(label: dict) -> dict[str, bool]:
    presence = {}
    for accessory in label["accessories"]:
        presence[accessory["class_name"]] = bool(accessory.get("present"))
    return presence


def main() -> None:
    label_paths = sorted(LABELS_DIR.glob("*.json")) if LABELS_DIR.exists() else []
    synthetic_labels = [json.loads(p.read_text()) for p in label_paths if json.loads(p.read_text())["is_synthetic_stand_in"]]
    real_labels = [json.loads(p.read_text()) for p in label_paths if not json.loads(p.read_text())["is_synthetic_stand_in"]]

    print(f"Real photos: {len(real_labels)}, synthetic stand-ins: {len(synthetic_labels)}\n")

    if not real_labels:
        print("Real-photo precision/recall: N/A — 0 real photos exist in this repo.\n")

    # object_id -> category, straight from the doctrine file, so verdicts
    # can be mapped back to the segmentation/ground-truth class they were
    # actually checked against.
    rules_json = json.loads((REPO_ROOT / "cv-service" / "rules" / "army_no3_male.json").read_text())["rules"]
    object_id_to_category = {r["object"]: r.get("category", "") for r in rules_json}

    # counts[class_name] = [tp, fp, fn]
    counts: dict[str, list[int]] = {}

    for label in synthetic_labels:
        photo_path = REPO_ROOT / label["source_path"]
        presence = ground_truth_presence(label)
        verdicts = run_pipeline_for_photo(photo_path, DEFAULT_PROFILE)

        print(f"{label['photo_id']}: {len(verdicts)} verdicts")
        for v in verdicts:
            category = object_id_to_category.get(v.accessory, "")
            seg_class = _SEGMENTATION_CLASS_FOR_CATEGORY.get(category)
            if seg_class is None or seg_class not in presence:
                continue  # not a class the ground-truth schema tracks, or unmapped
            predicted_present = v.status in ("pass", "fail")
            actual_present = presence[seg_class]
            bucket = counts.setdefault(seg_class, [0, 0, 0])
            if predicted_present and actual_present:
                bucket[0] += 1  # TP
            elif predicted_present and not actual_present:
                bucket[1] += 1  # FP
            elif not predicted_present and actual_present:
                bucket[2] += 1  # FN
            print(f"  {v.accessory} ({seg_class}): predicted={'present' if predicted_present else 'absent'} status={v.status} actual={'present' if actual_present else 'absent'}")

    print("\n| Class | TP | FP | FN | Precision | Recall | (synthetic, 3 stand-ins) |")
    print("| --- | --- | --- | --- | --- | --- | --- |")
    for class_name in sorted(set(_SEGMENTATION_CLASS_FOR_CATEGORY.values())):
        tp, fp, fn = counts.get(class_name, [0, 0, 0])
        if tp + fp + fn == 0:
            print(f"| {class_name} | 0 | 0 | 0 | N/A (no signal) | N/A (no signal) | |")
            continue
        precision = tp / (tp + fp) if (tp + fp) else None
        recall = tp / (tp + fn) if (tp + fn) else None
        print(f"| {class_name} | {tp} | {fp} | {fn} | {precision if precision is not None else 'N/A'} | {recall if recall is not None else 'N/A'} | |")

    print(
        "\nUncoverable classes (no segmentation detector — always "
        "unverifiable, excluded from scoring): name_tag, medal_ribbons, "
        "saf_badge, skill_tab, skill_badge, socks."
    )


if __name__ == "__main__":
    main()
