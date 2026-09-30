"""C14 — scores `/check_uniform`'s full pipeline against the synthetic
violation benchmark (`training/generate_violation_benchmark.py`).

Each configuration ("variant") runs in its own subprocess because
`config.py` is read at import time. Built-in variants:

  baseline      every stage added by the accuracy program switched OFF
                (lite pose, no anchor-offset calibration / mask anchors /
                EXIF focal / height / gravity / TTA / two-stage /
                zero-shot / colour / variant / OCR / uncertainty, v1
                segmenter). The correctness fixes made alongside it —
                anatomical anchor sides, behind-camera guard, coverage gate,
                search-area matching, cap-badge tier — can't be toggled
                and are present in every variant.
  program_v1    everything on, v1 (9-class) segmenter
  program_v2    everything on, v2 (12-class, domain-randomised) segmenter

Reported per variant: exact-verdict accuracy, violation recall (a real
problem flagged as fail/slightly-misaligned/missing), false-alarm rate
(a correct item flagged), abstention (UNCERTAIN), overall PASS/FAIL
agreement, and the same per item. **Synthetic-only** — renders of one
reference body; the best proxy available, not real-world accuracy.

    .venv-tools/bin/python cv-service/evaluation/run_violation_benchmark.py [--variants baseline program_v1]
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

CV_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CV_ROOT.parent
BENCH_DIR = CV_ROOT / "synthetic_data" / "violation_benchmark_v1"
RESULTS_DIR = CV_ROOT / "logs" / "violation_benchmark"

_OFF = {
    "CV_SERVICE_POSE_MODEL_VARIANT": "lite",
    "CV_SERVICE_APPLY_ANCHOR_OFFSETS": "0",
    "CV_SERVICE_MASK_ANCHOR_REFINEMENT": "0",
    "CV_SERVICE_USE_EXIF_INTRINSICS": "0",
    "CV_SERVICE_SEGMENTATION_TTA": "0",
    "CV_SERVICE_TWO_STAGE_ENABLED": "0",
    "CV_SERVICE_ZERO_SHOT_ENABLED": "0",
    "CV_SERVICE_COLOR_CHECK_ENABLED": "0",
    "CV_SERVICE_VARIANT_CHECK_ENABLED": "0",
    "CV_SERVICE_NAME_TAG_OCR_ENABLED": "0",
    "CV_SERVICE_UNCERTAINTY_REPROJECTION_WEIGHT": "0",
    "CV_SERVICE_UNCERTAINTY_MASK_FRACTION": "0",
    "CV_SERVICE_SEGMENTATION_MODEL": "segmentation_v1",
}
VARIANTS: dict[str, dict] = {
    "baseline": {"env": _OFF, "use_height_gravity": False},
    # v1 keeps its own fitted uncertainty weights (calibrate_uncertainty.py on v1)
    "program_v1": {"env": {"CV_SERVICE_SEGMENTATION_MODEL": "segmentation_v1",
                           "CV_SERVICE_UNCERTAINTY_REPROJECTION_WEIGHT": "1.35",
                           "CV_SERVICE_UNCERTAINTY_MASK_FRACTION": "0.09"}, "use_height_gravity": True},
    "program_v2": {"env": {"CV_SERVICE_SEGMENTATION_MODEL": "segmentation_v2"}, "use_height_gravity": True},
}
_TO_INTERNAL = {"CORRECT": "pass", "SLIGHTLY_MISALIGNED": "slightly_misaligned", "INCORRECT": "fail",
                "MISSING": "missing", "UNCERTAIN": "unverifiable"}
_FLAGGED = {"fail", "slightly_misaligned", "missing"}


def run_variant(variant: str, limit: int | None) -> Path:
    """Worker mode — runs in a subprocess with the variant's env set."""
    sys.path.insert(0, str(CV_ROOT))
    from api.pipeline import CheckError, CheckParams, run_check

    spec = VARIANTS[variant]
    scenes = sorted(BENCH_DIR.glob("scene_*.json"))[:limit]
    records = []
    for i, gt_path in enumerate(scenes):
        gt = json.loads(gt_path.read_text())
        params = CheckParams(
            uniform_type="army_no3_male", rank_tier=gt["profile"]["rank_tier"],
            height_cm=gt["height_cm"] if spec["use_height_gravity"] else None,
            gravity_up_cam=tuple(gt["gravity_up_cam"]) if spec["use_height_gravity"] else None,
        )
        try:
            response = run_check(str(gt_path.with_suffix(".jpg")), params)
            predicted = {a["name"]: _TO_INTERNAL[a["status"]] for a in response["accessories"]}
            records.append({"scene": gt_path.stem, "error": None, "overall": response["overall_status"],
                            "predicted": predicted, "expected": {k: v["status"] for k, v in gt["expected"].items()},
                            "camera": response.get("camera")})
        except CheckError as err:
            records.append({"scene": gt_path.stem, "error": err.status, "overall": None, "predicted": {},
                            "expected": {k: v["status"] for k, v in gt["expected"].items()}})
        print(f"  [{variant}] {i + 1}/{len(scenes)}", flush=True)
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    out = RESULTS_DIR / f"{variant}.json"
    out.write_text(json.dumps(records, indent=1) + "\n")
    return out


def score(records: list[dict]) -> dict:
    per_item: dict[str, Counter] = defaultdict(Counter)
    totals = Counter()
    overall = Counter()
    for rec in records:
        if rec["error"]:
            totals["scenes_rejected"] += 1
        gt_overall = "FAIL" if any(s != "pass" for s in rec["expected"].values()) else "PASS"
        overall[(gt_overall, rec["overall"] or f"ERROR:{rec['error']}")] += 1
        for item, expected in rec["expected"].items():
            predicted = rec["predicted"].get(item, "rejected" if rec["error"] else "not_reported")
            c = per_item[item]
            for counter in (c, totals):
                counter["n"] += 1
                counter["exact"] += predicted == expected
                counter["abstain"] += predicted in ("unverifiable", "rejected", "not_reported")
                if expected == "pass":
                    counter["gt_pass"] += 1
                    counter["false_alarm"] += predicted in _FLAGGED
                else:
                    counter["gt_violation"] += 1
                    counter["caught"] += predicted in _FLAGGED
    def rates(c: Counter) -> dict:
        return {
            "n": c["n"],
            "exact_accuracy": round(c["exact"] / c["n"], 3) if c["n"] else None,
            "violation_recall": round(c["caught"] / c["gt_violation"], 3) if c["gt_violation"] else None,
            "false_alarm_rate": round(c["false_alarm"] / c["gt_pass"], 3) if c["gt_pass"] else None,
            "abstention_rate": round(c["abstain"] / c["n"], 3) if c["n"] else None,
            "violations": c["gt_violation"],
        }
    return {
        "overall_items": rates(totals),
        "scenes": len(records),
        "scenes_rejected": totals["scenes_rejected"],
        "overall_status": {f"{gt}->{pred}": n for (gt, pred), n in sorted(overall.items())},
        "per_item": {item: rates(c) for item, c in sorted(per_item.items())},
    }


def _fmt(v) -> str:
    return "—" if v is None else (f"{v:.1%}" if isinstance(v, float) else str(v))


def print_report(scores: dict[str, dict]) -> None:
    print("\n## Violation benchmark (synthetic renders only — 0 real photos)\n")
    print("| Variant | Items | Exact | Violation recall | False alarms | Abstain | Scenes rejected |")
    print("| --- | --- | --- | --- | --- | --- | --- |")
    for name, s in scores.items():
        o = s["overall_items"]
        print(f"| {name} | {o['n']} | {_fmt(o['exact_accuracy'])} | {_fmt(o['violation_recall'])} ({o['violations']}) | "
              f"{_fmt(o['false_alarm_rate'])} | {_fmt(o['abstention_rate'])} | {s['scenes_rejected']}/{s['scenes']} |")
    for name, s in scores.items():
        print(f"\n### {name} — per item\n")
        print("| Item | Exact | Violation recall | False alarms | Abstain |")
        print("| --- | --- | --- | --- | --- |")
        for item, r in s["per_item"].items():
            print(f"| {item} | {_fmt(r['exact_accuracy'])} | {_fmt(r['violation_recall'])} ({r['violations']}) | "
                  f"{_fmt(r['false_alarm_rate'])} | {_fmt(r['abstention_rate'])} |")
        print(f"\nOverall status (truth->predicted): {s['overall_status']}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--variants", nargs="+", default=["baseline", "program_v1"], choices=sorted(VARIANTS))
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--worker", choices=sorted(VARIANTS), help=argparse.SUPPRESS)
    parser.add_argument("--rescore", action="store_true", help="only re-score existing results")
    args = parser.parse_args()

    if args.worker:
        run_variant(args.worker, args.limit)
        return
    scores = {}
    for variant in args.variants:
        out = RESULTS_DIR / f"{variant}.json"
        if not args.rescore:
            env = {**os.environ, **VARIANTS[variant]["env"]}
            cmd = [sys.executable, __file__, "--worker", variant] + (["--limit", str(args.limit)] if args.limit else [])
            subprocess.run(cmd, env=env, check=True, cwd=str(REPO_ROOT))
        scores[variant] = score(json.loads(out.read_text()))
    (RESULTS_DIR / "summary.json").write_text(json.dumps(scores, indent=2) + "\n")
    print_report(scores)


if __name__ == "__main__":
    main()
