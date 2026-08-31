"""Runs the trained YOLOv8n-seg model
(`cv-service/models/segmentation_v1`) against labeled real photos and
compares per-class mAP50 against its original synthetic-only validation
— side by side, never blended into one number, and never fabricated when
no real data exists.

**As of this writing, 0 real photos exist in this project** (see
`ChangeRequest/2026-08-11_cv-service-segmentation-real-vs-synthetic-comparison-tooling.md`).
Running this script today reports that plainly rather than substituting
synthetic data — running it against Milestone A's synthetic stand-ins
and calling the result "real-world accuracy" would be actively
misleading (synthetic-vs-synthetic, and those stand-ins have no
accessory geometry for 6 of the 9 classes anyway — see the plan's risk
section).

Methodology: both sides of the comparison run through the exact same
`model.val()` Ultralytics code path — the synthetic side is (re-)run
against `cv-service/synthetic_data/seg_v1/` if present locally
(gitignored — falls back to the documented baseline from the original
training run if absent), and the real side is built by converting
Milestone A's label JSON into the same YOLO-seg format via
`segmentation_label_conversion.py`. This is what makes "synthetic
mAP50" and "real mAP50" genuinely comparable numbers, not two
differently-computed metrics that happen to share a name.

Usage:
    .venv-tools/bin/python cv-service/evaluation/compare_segmentation_real_vs_synthetic.py
"""

from __future__ import annotations

import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from evaluation.segmentation_label_conversion import convert_labels_to_yolo_seg  # noqa: E402
from training.generate_segmentation_dataset import CLASSES  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[2]
LABELS_DIR = REPO_ROOT / "cv-service" / "data" / "labels"
MODEL_WEIGHTS = REPO_ROOT / "cv-service" / "models" / "segmentation_v1" / "weights" / "best.pt"
SYNTHETIC_DATA_YAML = REPO_ROOT / "cv-service" / "synthetic_data" / "seg_v1" / "data.yaml"

# See the plan file's §3 for the reasoning: the weakest synthetic classes
# already sit at 0.5-0.6 mAP50, so a smaller threshold would flag normal
# noise on an already-weak class; a larger one would miss a real problem
# on a strong class (e.g. shirt 0.995 -> 0.85 is real at only 0.145 drop).
REGRESSION_THRESHOLD_MAP50 = 0.15

DIAGNOSIS_CAUSES = [
    "lighting",
    "occlusion",
    "fabric_texture_mismatch",
    "camera_angle_ood",
    "insufficient_real_examples",
    "other",
]
PROPOSED_FIXES = ["augment_synthetic_data", "fine_tune_on_real", "flag_needs_more_real_data", "no_action_needed"]

# Fallback only — from the original training run's printed per-class
# mAP50 (ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md,
# CLAUDE.md §5.10). Used only if cv-service/synthetic_data/seg_v1/ isn't
# present locally to re-run against directly (it's gitignored).
DOCUMENTED_SYNTHETIC_MAP50 = {
    "shirt": 0.995, "trousers": 0.995, "headwear": 0.995, "footwear": 0.995,
    "cap_badge": 0.904, "belt": 0.556, "arms_badge": 0.524, "epaulette": 0.496,
    "sleeve_rank": 0.222,
}


@dataclass(frozen=True)
class ClassComparison:
    class_name: str
    synthetic_map50: float | None
    synthetic_source: str  # "re_run" | "documented_baseline"
    real_map50: float | None  # None: no real data for this class
    delta: float | None  # real - synthetic; None if either side missing


@dataclass
class Diagnosis:
    class_name: str
    synthetic_map50: float
    real_map50: float
    delta: float
    # Deliberately unpopulated by this script — filled in by a human
    # reviewer (or a future automated heuristic) once real regressions
    # exist to look at. Never guessed at with no real data to look at.
    likely_causes: list[str] = field(default_factory=list)
    proposed_fix: str | None = None
    notes: str = ""


def _per_class_map50(metrics, names: dict[int, str]) -> dict[str, float]:
    result = {}
    for i, name in names.items():
        try:
            result[name] = float(metrics.seg.ap50[i])
        except (IndexError, AttributeError):
            continue
    return result


def get_synthetic_map50() -> tuple[dict[str, float], str]:
    if SYNTHETIC_DATA_YAML.exists():
        from ultralytics import YOLO

        model = YOLO(str(MODEL_WEIGHTS))
        metrics = model.val(data=str(SYNTHETIC_DATA_YAML), verbose=False)
        return _per_class_map50(metrics, model.names), "re_run"
    return dict(DOCUMENTED_SYNTHETIC_MAP50), "documented_baseline"


def get_real_map50(out_dir: Path, *, require_real: bool = True) -> tuple[dict[str, float], int, int]:
    """Returns (per-class mAP50, real photo count used, synthetic photos skipped)."""
    label_paths = sorted(LABELS_DIR.glob("*.json")) if LABELS_DIR.exists() else []
    conversion = convert_labels_to_yolo_seg(label_paths, out_dir, require_real=require_real)
    if not conversion.converted_photo_ids:
        return {}, 0, len(conversion.skipped_synthetic_photo_ids)

    from ultralytics import YOLO

    model = YOLO(str(MODEL_WEIGHTS))
    metrics = model.val(data=str(conversion.data_yaml_path), verbose=False)
    return (
        _per_class_map50(metrics, model.names),
        len(conversion.converted_photo_ids),
        len(conversion.skipped_synthetic_photo_ids),
    )


def build_comparison(out_dir: Path, *, require_real: bool = True) -> tuple[list[ClassComparison], int, int]:
    synthetic_map, synthetic_source = get_synthetic_map50()
    real_map, real_count, skipped_count = get_real_map50(out_dir, require_real=require_real)

    comparisons = []
    for class_name in CLASSES:
        syn = synthetic_map.get(class_name)
        real = real_map.get(class_name) if real_count else None
        delta = (real - syn) if (syn is not None and real is not None) else None
        comparisons.append(ClassComparison(class_name, syn, synthetic_source, real, delta))
    return comparisons, real_count, skipped_count


def flag_regressions(comparisons: list[ClassComparison], threshold: float = REGRESSION_THRESHOLD_MAP50) -> list[Diagnosis]:
    return [
        Diagnosis(c.class_name, c.synthetic_map50, c.real_map50, c.delta)
        for c in comparisons
        if c.delta is not None and c.delta < -threshold
    ]


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        comparisons, real_count, skipped_count = build_comparison(Path(tmp))

    print(f"Real photos found: {real_count} (skipped {skipped_count} synthetic stand-ins)\n")
    print("| Class | Synthetic mAP50 | Real mAP50 | Delta |")
    print("| --- | --- | --- | --- |")
    for c in comparisons:
        syn_str = f"{c.synthetic_map50:.3f} ({c.synthetic_source})" if c.synthetic_map50 is not None else "N/A"
        real_str = f"{c.real_map50:.3f}" if c.real_map50 is not None else "N/A — 0 real photos"
        delta_str = f"{c.delta:+.3f}" if c.delta is not None else "N/A"
        print(f"| {c.class_name} | {syn_str} | {real_str} | {delta_str} |")

    if real_count == 0:
        print(
            "\n0 real photos exist — nothing to compare yet. See "
            "ChangeRequest/2026-08-11_cv-service-segmentation-real-vs-synthetic-comparison-tooling.md."
        )
        return

    flagged = flag_regressions(comparisons)
    if not flagged:
        print(f"\nNo class regressed more than {REGRESSION_THRESHOLD_MAP50} mAP50.")
    else:
        print(f"\n{len(flagged)} class(es) flagged (drop > {REGRESSION_THRESHOLD_MAP50} mAP50) — needs diagnosis:")
        for d in flagged:
            print(f"  {d.class_name}: {d.synthetic_map50:.3f} -> {d.real_map50:.3f} ({d.delta:+.3f})")
            print(f"    likely_causes: {DIAGNOSIS_CAUSES} (unpopulated — needs manual review)")
            print(f"    proposed_fix options: {PROPOSED_FIXES}")


if __name__ == "__main__":
    main()
