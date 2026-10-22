"""Synthetic violation benchmark — RSAF No.4, men + ladies.

Same idea and output format as `generate_violation_benchmark.py` (Army
No.3): renders with exact ground truth, scored by
`evaluation/run_violation_benchmark.py --bench violation_benchmark_rsaf`.

"Correct" is the operator's dressed figure as modelled
(`rules/anchors.rsaf_no4_*.json` → `items`, which the doctrine rules'
offsets were measured from — see `utils/build_rsaf_no4_rules.py`). Each
scene then injects 0-2 violations, each with the verdict it must produce:
  * item displaced by 0.5× its tolerance  → pass
  * displaced by 1.25×                    → slightly_misaligned
  * displaced by 2.0×                     → fail
  * item removed                          → missing
Displacements move front items (cap badge, rank tab, name / SINGAPORE
tags) in the body's front plane and sleeve patches along the arm's outer
face (up/down, forward/back).

Not injectable here, stated rather than faked: swapped name/SINGAPORE
tags (same shape — only the text differs) and a wrong rank-tab variant
(the engine has no rank-tab variant check).

Camera within the capture protocol, true focal length in EXIF, true
gravity and body height stored — the same inputs the app sends.
Synthetic-only: renders of two stylised figures, the best available
proxy, not real-world accuracy.

    .venv-tools/bin/python cv-service/training/generate_violation_benchmark_rsaf.py --n 60

See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import generate_segmentation_dataset_v2 as gen  # noqa: E402
from generate_violation_benchmark import HEIGHT, WIDTH, _gravity_up_cv, _save_with_exif  # noqa: E402
from rsaf_figure import build_scene, load_figure  # noqa: E402

import uniforms  # noqa: E402

CV_ROOT = Path(__file__).resolve().parents[1]
RANK_TIER = "enlistee"  # -> standard rank tab + all-other-ranks cap badge

# rule object -> (figure group(s), how it may be displaced)
ITEMS = {
    "rsaf_beret": (["beret"], None),
    "rsaf_cap_badge_sltc_me6_below": (["beret_badge"], "front"),
    "rsaf_no4_rank_epaulette": (["rank_tab_assembly"], "front"),
    "name_tag_standard": (["name_tape"], "front"),
    "singapore_tag": (["country_tape"], "front"),
    "rsaf_unit_patch": (["shoulder_patch_left", "shoulder_patch_right"], "sleeve"),
    "safety_boots": (["boots"], None),
}
REMOVABLE = ["rsaf_beret", "rsaf_cap_badge_sltc_me6_below", "rsaf_no4_rank_epaulette",
             "name_tag_standard", "singapore_tag", "rsaf_unit_patch"]
DISPLACEMENTS = [(0.5, "pass"), (1.25, "slightly_misaligned"), (2.0, "fail")]


def _rules(gender: str) -> dict[str, dict]:
    doc = json.loads((CV_ROOT / "rules" / f"rsaf_no4_{gender}.json").read_text())
    return {r["object"]: r for r in doc["rules"]}


def build(index: int, seed: int, figures: dict, out_dir: Path) -> None:
    rng = random.Random(seed * 7919 + index)
    gender = "male" if index % 2 == 0 else "female"
    figure, rules = figures[gender]
    spec = uniforms.UNIFORMS[f"rsaf_no4_{gender}"]
    scale = rng.uniform(0.94, 1.05)
    stature = spec.reference_stature_m * scale

    expected = {obj: {"status": "pass"} for obj in ITEMS}
    remove: set[str] = {"wing_badge_assembly"}  # optional item — not part of the standard
    displacements: dict[str, np.ndarray] = {}
    violations = []
    for _ in range(rng.choice([0, 1, 1, 2])):
        kind = rng.choice(["displace", "displace", "remove"])
        if kind == "displace":
            options = [o for o, (_, how) in ITEMS.items()
                       if how and expected[o]["status"] == "pass" and not set(ITEMS[o][0]) & set(displacements)]
            if not options:
                continue
            obj = rng.choice(options)
            groups, how = ITEMS[obj]
            factor, status = rng.choice(DISPLACEMENTS)
            distance_cm = factor * rules[obj]["tolerance_cm"]
            angle = rng.uniform(0, 2 * math.pi)
            if how == "front":
                direction = np.array([math.cos(angle), math.sin(angle), 0.0])
            else:  # sleeve patch: along the outer face of the arm (up/down, fore/aft)
                direction = np.array([0.0, math.cos(angle), math.sin(angle)])
            # Paired item: displace one side — the verdict is the worse side's.
            group = rng.choice(groups)
            displacements[group] = direction * distance_cm / 100
            expected[obj] = {"status": status, "violation": f"{group} displaced {distance_cm:.2f} cm ({factor}× tolerance)"}
        else:
            obj = rng.choice([o for o in REMOVABLE if expected[o]["status"] == "pass"])
            groups = ITEMS[obj][0]
            if obj == "rsaf_unit_patch":
                groups = [rng.choice(groups)]  # one sleeve missing is enough to be non-compliant
            remove |= set(groups)
            expected[obj] = {"status": "missing", "violation": f"removed {', '.join(groups)}"}
            if obj == "rsaf_beret":
                remove.add("beret_badge")
                expected["rsaf_cap_badge_sltc_me6_below"] = {"status": "missing", "violation": "beret removed"}
        violations.append({"kind": kind})

    placements = build_scene(figure, rng, removals={}, remove=remove, sikh=False, cadet=False,
                             displacements=displacements)
    meshes = []
    for mesh, _ in placements:
        m = mesh.copy()
        m.apply_scale(scale)
        meshes.append(m)

    cam_pose, yfov = gen._camera_pose(rng, wide=False)
    gen.IMAGE_WIDTH, gen.IMAGE_HEIGHT = WIDTH, HEIGHT
    rgb, depth, _ = gen.render_scene(rng, meshes, [], (1.0, 1.0), cam_pose, yfov, wide=False)
    ys, xs = np.nonzero(depth > 0)
    # Exact figure box from the depth mask. The COCO person detector often
    # misses these *stylised* mannequins (egg head, no features — read as
    # "teddy bear" or nothing); the runner falls back to this box only then,
    # and reports how often, so the benchmark measures the uniform check.
    person_box = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
    image = gen.composite(rng, rgb, depth)
    image = gen.photometric(rng, image) if rng.random() < 0.7 else image
    focal_px = (HEIGHT / 2) / math.tan(yfov / 2)

    name = f"scene_{index:04d}"
    _save_with_exif(out_dir / f"{name}.jpg", image, focal_px)
    (out_dir / f"{name}.json").write_text(json.dumps({
        "uniform_type": spec.uniform_type,
        "profile": {"rank_tier": RANK_TIER, "gender": gender, "is_sikh": False, "medal_row_count": 0},
        "height_cm": round(stature * 100, 1),
        "focal_length_px": round(focal_px, 1),
        "gravity_up_cam": [round(v, 5) for v in _gravity_up_cv(cam_pose)],
        "camera_pose_gl": [[round(v, 6) for v in row] for row in cam_pose.tolist()],
        "yfov_deg": round(math.degrees(yfov), 4),
        "image_size": [WIDTH, HEIGHT],
        "anchor_scale": round(scale, 5),
        "person_box_px": person_box,
        "violations": violations,
        "expected": expected,
        "is_synthetic": True,
    }, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=60)
    parser.add_argument("--seed", type=int, default=2027)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/violation_benchmark_rsaf")
    args = parser.parse_args()
    out_dir = Path(__file__).resolve().parents[2] / args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    figures = {g: (load_figure(g), _rules(g)) for g in ("male", "female")}
    for i in range(args.n):
        if (out_dir / f"scene_{i:04d}.json").exists():
            continue
        build(i, args.seed, figures, out_dir)
        if (i + 1) % 10 == 0:
            print(f"  {i + 1}/{args.n}", flush=True)
    print(f"wrote {args.n} scenes to {out_dir}")


if __name__ == "__main__":
    main()
