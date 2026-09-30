"""A5 calibration — fit the verdict engine's uncertainty weights from data.

`rules/rule_engine.py` treats a measurement as uncertain by
    u = UNCERTAINTY_REPROJECTION_WEIGHT × camera reprojection error
      ⊕ UNCERTAINTY_MASK_FRACTION × sqrt(mask area)          (⊕ = hypot)
and only calls `pass` when distance + u ≤ tolerance. Too small a `u`
turns measurement noise into false alarms; too large and nothing can ever
pass (every item comes back "unverifiable"). The right size is whatever
actually covers the pipeline's real measurement error — which the
violation benchmark can measure, because its camera and every item's
true position are known.

For every item that is *correctly placed* in the benchmark (true offset
0) and gets detected, the distance the verdict engine measures is pure
measurement error. This script collects those distances with each
item's reprojection error and mask area, grid-searches the two weights
for the tightest `u` that covers `--coverage` (default 90%) of them, and
also reports the geometric part on its own: how far the projected
doctrine point lands from the TRUE projection, in px and cm.

Synthetic-only (renders of one body) — re-fit when real labelled photos
exist. Uses the segmenter currently configured (CV_SERVICE_SEGMENTATION_MODEL).

    .venv-tools/bin/python cv-service/evaluation/calibrate_uncertainty.py
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np

CV_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_ROOT))

from api.pipeline import CheckError, CheckParams, solve_geometry  # noqa: E402
from detectors.zero_shot import fill_missed_detections  # noqa: E402
from rules.rule_engine import _assign_regions_to_crops, _resolve_offset_point, segmentation_class_for  # noqa: E402
from segmentation.mask_geometry import mask_reference_point  # noqa: E402
from segmentation.two_stage import refine_small_items  # noqa: E402

BENCH_DIR = CV_ROOT / "synthetic_data" / "violation_benchmark_v1"
OUT_PATH = CV_ROOT / "logs" / "violation_benchmark" / "uncertainty_calibration.json"


def _true_projection(point, gt: dict) -> tuple[float, float] | None:
    width, height = gt["image_size"]
    focal = (height / 2) / math.tan(math.radians(gt["yfov_deg"]) / 2)
    p_cam = np.linalg.inv(np.array(gt["camera_pose_gl"])) @ np.append(np.asarray(point, dtype=float), 1.0)
    if p_cam[2] >= 0:
        return None
    return width / 2 + focal * p_cam[0] / -p_cam[2], height / 2 - focal * p_cam[1] / -p_cam[2]


def collect(limit: int | None) -> list[dict]:
    samples = []
    for gt_path in sorted(BENCH_DIR.glob("scene_*.json"))[:limit]:
        gt = json.loads(gt_path.read_text())
        params = CheckParams("army_no3_male", gt["profile"]["rank_tier"], height_cm=gt["height_cm"],
                             gravity_up_cam=tuple(gt["gravity_up_cam"]))
        try:
            g = solve_geometry(str(gt_path.with_suffix(".jpg")), params)
        except CheckError:
            continue
        segmentation = fill_missed_detections(g.image_bgr, g.resolved, refine_small_items(g.image_bgr, g.resolved, g.segmentation))
        for rule in g.resolved:
            tolerance_cm = rule.raw_rule.get("tolerance_cm")
            if tolerance_cm is None or gt["expected"].get(rule.object_id, {}).get("status") != "pass":
                continue
            seg_class = segmentation_class_for(rule.category, segmentation.class_names)
            if seg_class is None:
                continue
            candidates = [r for r in segmentation.regions if r.class_name == seg_class and r.confidence >= 0.4]
            for crop, match in zip(rule.crops, _assign_regions_to_crops(rule.crops, candidates)):
                truth = _true_projection(_resolve_offset_point(g.anchors[crop.anchor_name], rule.raw_rule), gt)
                sample = {
                    "scene": gt_path.stem, "item": rule.object_id, "anchor": crop.anchor_name,
                    "reprojection_px": g.camera.reprojection_error_px, "px_per_cm": crop.px_per_cm,
                    "tolerance_px": tolerance_cm * crop.px_per_cm if crop.px_per_cm else None,
                    "geometric_error_px": math.dist(crop.center_px, truth) if truth else None,
                }
                if match is not None:
                    region, centroid = match
                    measured = mask_reference_point(region.mask, rule.raw_rule.get("reference_point", "center")) or centroid
                    sample["measured_error_px"] = math.dist(measured, crop.center_px)
                    sample["sqrt_area"] = math.sqrt(float(region.mask.sum()))
                samples.append(sample)
        print(f"  {gt_path.stem}: {len(samples)} samples", flush=True)
    return samples


def fit(samples: list[dict], coverage: float) -> dict:
    usable = [s for s in samples if "measured_error_px" in s and s["tolerance_px"]]
    if not usable:
        return {"error": "no detected correctly-placed items to fit on"}
    err = np.array([s["measured_error_px"] for s in usable])
    reproj = np.array([s["reprojection_px"] for s in usable])
    area = np.array([s["sqrt_area"] for s in usable])
    tol = np.array([s["tolerance_px"] for s in usable])
    best = None
    for a in np.arange(0.0, 3.01, 0.05):
        for b in np.arange(0.0, 0.401, 0.01):
            u = np.hypot(a * reproj, b * area)
            if np.mean(err <= u) >= coverage and (best is None or u.mean() < best[2]):
                best = (round(float(a), 2), round(float(b), 2), float(u.mean()))
    if best is None:
        return {"error": f"no weights in the grid reach {coverage:.0%} coverage", "samples": len(usable)}
    a, b, _ = best
    u = np.hypot(a * reproj, b * area)
    return {
        "samples": len(usable),
        "coverage_target": coverage,
        "UNCERTAINTY_REPROJECTION_WEIGHT": a,
        "UNCERTAINTY_MASK_FRACTION": b,
        "mean_u_px": round(float(u.mean()), 2),
        "measured_error_px": {"p50": round(float(np.percentile(err, 50)), 2), "p90": round(float(np.percentile(err, 90)), 2)},
        "measured_error_cm_p50": round(float(np.median(err / np.array([s["px_per_cm"] for s in usable]))), 2),
        # How many correctly-placed items could still be called `pass`
        # (distance + u ≤ tolerance) — the ceiling the tolerances allow.
        "correct_items_passable": round(float(np.mean(err + u <= tol)), 3),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--coverage", type=float, default=0.9)
    args = parser.parse_args()
    samples = collect(args.limit)
    geo = [s["geometric_error_px"] / s["px_per_cm"] for s in samples if s["geometric_error_px"] is not None and s["px_per_cm"]]
    result = {
        "geometric_error_cm": {"n": len(geo), "p50": round(float(np.percentile(geo, 50)), 2), "p90": round(float(np.percentile(geo, 90)), 2)} if geo else None,
        "fit": fit(samples, args.coverage),
        "per_item_measured_error_cm_p50": {
            item: round(float(np.median([s["measured_error_px"] / s["px_per_cm"] for s in samples if s["item"] == item and "measured_error_px" in s])), 2)
            for item in sorted({s["item"] for s in samples if "measured_error_px" in s})
        },
        "detection_rate_on_correct_items": round(float(np.mean(["measured_error_px" in s for s in samples])), 3) if samples else None,
        "synthetic_only": True,
    }
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps({"summary": result, "samples": samples}, indent=1) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
