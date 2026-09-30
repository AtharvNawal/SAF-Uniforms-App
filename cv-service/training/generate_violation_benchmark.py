"""C14 — synthetic uniform-violation benchmark with known ground truth.

Every accuracy number cv-service had before this measured a *stage*
(anchor error, camera error, segmentation mAP) — never the thing the user
sees: "is each item's verdict right?". Real photos with labelled
violations don't exist, but the rendering pipeline can produce them with
exact ground truth:

  - every item is placed so its doctrine reference point sits exactly on
    the rule's 3D point (anchor + rule offset, with the anchors scaled to
    the scene's body height) — a "correct" item is correct by construction;
  - then 0-2 violations per scene are injected, each with the verdict it
    should produce:
      * displaced by 0.5× tolerance  → pass
      * displaced by 1.25× tolerance → slightly_misaligned
      * displaced by 2.0× tolerance  → fail
      * removed                      → missing
      * name tag on the wrong pocket → missing (nothing in the right one)
      * wrong cap-badge variant      → fail (variant)
      * grey socks                   → fail (colour)
  - camera within the capture protocol (near-frontal, hand-held roll),
    true focal length written to EXIF (FocalLengthIn35mmFilm), true
    gravity direction and body height stored for the D16 inputs.

Output (gitignored): `cv-service/synthetic_data/violation_benchmark_v1/`
with `scene_XXXX.jpg` + `scene_XXXX.json`. Scored by
`evaluation/run_violation_benchmark.py`. Synthetic-only, restated: this
measures the pipeline on renders of one reference body; it is the best
available proxy, not real-world accuracy.

    .venv-tools/bin/python cv-service/training/generate_violation_benchmark.py --n 60
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import sys
from pathlib import Path

import cv2
import numpy as np
import trimesh
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_segmentation_dataset_v2 as gen  # noqa: E402

CV_ROOT = Path(__file__).resolve().parents[1]
REFERENCE_STATURE_M = 1.78
WIDTH, HEIGHT = 960, 1440
RANK_TIER = "enlistee"  # -> SLTC/ME6-and-below cap badge + enlistee sleeve insignia

# rule object -> (glb stem, rotate_y_deg, anchors are paired)
ITEMS = {
    "army_beret": ("army_beret", 0.0),
    "army_cap_badge_sltc_me6_below": ("army_cap_badge_sltc_me6_below", 0.0),
    "epaulettes_standard": ("epaulettes_standard", 90.0),
    "army_enlistee_insignia": ("army_enlistee_insignia", 0.0),
    "army_arms_badge": ("army_arms_badge", 0.0),
    "name_tag_standard": ("name_tag_standard", 0.0),
    "nylon_belt": ("nylon_belt", 0.0),
    "black_socks": ("procedural_socks", 0.0),
}
# Presence-only items keep the generator's visually-tuned placement; items
# with a cm tolerance are placed exactly on the doctrine point.
PRESENCE_PLACEMENT = {
    "army_beret": (0, -16.0, 0),
    "epaulettes_standard": (-2.6, 2.2, -10.0),
    "black_socks": (4.6, 1.2, -5.9),
}
DISPLACEABLE = ["army_cap_badge_sltc_me6_below", "army_enlistee_insignia", "army_arms_badge", "name_tag_standard", "nylon_belt"]
REMOVABLE = ["army_beret", "army_cap_badge_sltc_me6_below", "epaulettes_standard", "army_enlistee_insignia",
             "army_arms_badge", "name_tag_standard", "nylon_belt", "black_socks"]
DISPLACEMENTS = [(0.5, "pass"), (1.25, "slightly_misaligned"), (2.0, "fail")]


def _rules() -> dict[str, dict]:
    return {r["object"]: r for r in json.loads((CV_ROOT / "rules" / "army_no3_male.json").read_text())["rules"]}


def _mesh(stem: str, rotate_y: float) -> trimesh.Trimesh:
    mesh = gen._load_mesh(stem).copy()
    if rotate_y and stem not in gen._ROTATE_Y_DEG:
        mesh.apply_transform(trimesh.transformations.rotation_matrix(math.radians(rotate_y), [0, 1, 0]))
    return mesh


def _place(mesh: trimesh.Trimesh, point: np.ndarray, mirror: bool, by_origin: bool) -> trimesh.Trimesh:
    """`by_origin`: put the mesh's own origin at `point` (how the dataset
    generator and the 3D merger place presence-only items); otherwise put
    its bounding-box centre there (doctrine-exact placement)."""
    placed = mesh.copy()
    if mirror:
        placed.apply_transform(np.diag([-1, 1, 1, 1]))
    placed.apply_translation(point if by_origin else point - placed.bounds.mean(axis=0))
    return placed


def _target_point(rule: dict, anchor: dict, anchor_name: str, mesh: trimesh.Trimesh, object_id: str) -> np.ndarray:
    """3D point the mesh's bounding-box centre goes to."""
    if object_id in PRESENCE_PLACEMENT:
        dx, dy, dz = (v / 100 for v in PRESENCE_PLACEMENT[object_id])
        if anchor_name.startswith("right_") and "," in rule["expected_anchor"]:
            dx = -dx
        # presence placements are offsets of the mesh origin (see _place)
        return np.array([anchor["x"] + dx, anchor["y"] + dy, anchor["z"] + dz])
    point = np.array([
        anchor["x"] + rule.get("offset_x_cm", 0) / 100,
        anchor["y"] + rule.get("offset_y_cm", 0) / 100,
        anchor["z"] + rule.get("offset_z_cm", 0) / 100,
    ])
    half_height = (mesh.bounds[1][1] - mesh.bounds[0][1]) / 2
    kind = rule.get("reference_point", "center")
    if kind == "bottom_edge":
        point[1] += half_height
    elif kind == "top_edge":
        point[1] -= half_height
    return point


def _gravity_up_cv(cam_pose: np.ndarray) -> list[float]:
    """World +y expressed in the OpenCV camera frame (x right, y down,
    z forward) — what the app sends as gravity_x/y/z."""
    r_gl_world_to_cam = cam_pose[:3, :3].T
    up_gl = r_gl_world_to_cam @ np.array([0.0, 1.0, 0.0])
    return [float(up_gl[0]), float(-up_gl[1]), float(-up_gl[2])]


def _save_with_exif(path: Path, rgb: np.ndarray, focal_px: float) -> None:
    image = Image.fromarray(rgb)
    exif = image.getexif()
    exif.get_ifd(0x8769)[0xA405] = int(round(focal_px * math.hypot(36, 24) / math.hypot(WIDTH, HEIGHT)))
    image.save(path, quality=92, exif=exif)


def build_scene(index: int, seed: int, rules: dict, body: dict, base_anchors: dict, out_dir: Path) -> None:
    rng = random.Random(seed * 7919 + index)
    stature = rng.uniform(0.93, 1.05) * REFERENCE_STATURE_M
    scale = stature / REFERENCE_STATURE_M
    anchors = {k: {**a, "x": a["x"] * scale, "y": a["y"] * scale, "z": a["z"] * scale} for k, a in base_anchors.items()}

    violations: list[dict] = []
    present = set(ITEMS)
    displaced: dict[str, np.ndarray] = {}
    stems = {k: v[0] for k, v in ITEMS.items()}
    socks_color = None
    name_tag_anchor = "right_chest_pocket"
    expected = {obj: {"status": "pass"} for obj in ITEMS}
    expected["leather_shoes_low_cut"] = {"status": "pass"}

    for _ in range(rng.choice([0, 1, 1, 2])):
        kind = rng.choice(["displace", "displace", "remove", "wrong_variant", "wrong_side", "grey_socks"])
        if kind == "displace":
            obj = rng.choice([o for o in DISPLACEABLE if o in present and o not in displaced])
            factor, status = rng.choice(DISPLACEMENTS)
            angle = rng.uniform(0, 2 * math.pi)
            distance_cm = factor * rules[obj]["tolerance_cm"]
            displaced[obj] = np.array([math.cos(angle), math.sin(angle), 0.0]) * distance_cm / 100
            expected[obj] = {"status": status, "violation": f"displaced {distance_cm:.2f} cm ({factor}× tolerance)"}
        elif kind == "remove":
            obj = rng.choice([o for o in REMOVABLE if o in present])
            present.discard(obj)
            if obj == "army_beret":
                present.discard("army_cap_badge_sltc_me6_below")
                expected["army_cap_badge_sltc_me6_below"] = {"status": "missing", "violation": "beret removed"}
            expected[obj] = {"status": "missing", "violation": "removed"}
        elif kind == "wrong_variant" and "army_cap_badge_sltc_me6_below" in present:
            stems["army_cap_badge_sltc_me6_below"] = rng.choice(["army_cap_badge_col_me7", "army_cap_badge_bg_me8_above"])
            expected["army_cap_badge_sltc_me6_below"] = {"status": "fail", "violation": f"wrong variant ({stems['army_cap_badge_sltc_me6_below']})"}
        elif kind == "wrong_side" and "name_tag_standard" in present:
            name_tag_anchor = "left_chest_pocket"
            expected["name_tag_standard"] = {"status": "missing", "violation": "on the left pocket"}
        elif kind == "grey_socks" and "black_socks" in present:
            socks_color = rng.choice([[130, 130, 135, 255], [90, 70, 50, 255]])
            expected["black_socks"] = {"status": "fail", "violation": "not black"}
        violations.append({"kind": kind})

    rgb_meshes = []
    for mesh in body["rgb"]:
        scaled = mesh.copy()
        scaled.apply_scale(scale)
        rgb_meshes.append(scaled)
    for obj in present:
        rule = rules[obj]
        mesh = _mesh(stems[obj], ITEMS[obj][1])
        if obj == "black_socks" and socks_color is not None:
            mesh.visual.vertex_colors = np.tile(socks_color, (len(mesh.vertices), 1))
        anchor_names = [n.strip() for n in rule["expected_anchor"].split(",")]
        if obj == "name_tag_standard":
            anchor_names = [name_tag_anchor]
        for anchor_name in anchor_names:
            point = _target_point(rule, anchors[anchor_name], anchor_name, mesh, obj)
            if obj in displaced:
                point = point + displaced[obj]
            rgb_meshes.append(_place(
                mesh, point, mirror=anchor_name.startswith("right_") and len(anchor_names) > 1,
                by_origin=obj in PRESENCE_PLACEMENT,
            ))

    cam_pose, yfov = gen._camera_pose(rng, wide=False)
    gen.IMAGE_WIDTH, gen.IMAGE_HEIGHT = WIDTH, HEIGHT
    rgb, depth, _ = gen.render_scene(rng, rgb_meshes, [], (1.0, 1.0), cam_pose, yfov, wide=False)
    image = gen.composite(rng, rgb, depth)
    image = gen.photometric(rng, image) if rng.random() < 0.7 else image
    focal_px = (HEIGHT / 2) / math.tan(yfov / 2)

    name = f"scene_{index:04d}"
    _save_with_exif(out_dir / f"{name}.jpg", image, focal_px)
    (out_dir / f"{name}.json").write_text(json.dumps({
        "profile": {"rank_tier": RANK_TIER, "gender": "male", "is_sikh": False, "medal_row_count": 0},
        "height_cm": round(stature * 100, 1),
        "focal_length_px": round(focal_px, 1),
        "gravity_up_cam": [round(v, 5) for v in _gravity_up_cv(cam_pose)],
        # The exact render camera (OpenGL convention, camera-to-world) and
        # vertical field of view — lets evaluation/calibrate_uncertainty.py
        # measure the TRUE projection error of every doctrine point.
        "camera_pose_gl": [[round(v, 6) for v in row] for row in cam_pose.tolist()],
        "yfov_deg": round(math.degrees(yfov), 4),
        "image_size": [WIDTH, HEIGHT],
        "anchor_scale": round(scale, 5),
        "violations": violations,
        "expected": expected,
        "is_synthetic": True,
    }, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=60)
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/violation_benchmark_v1")
    args = parser.parse_args()
    out_dir = Path(__file__).resolve().parents[2] / args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    rules = _rules()
    base_anchors = gen.load_anchors()
    body = gen.load_body_parts_v2(base_anchors)
    for i in range(args.n):
        if (out_dir / f"scene_{i:04d}.json").exists():
            continue
        build_scene(i, args.seed, rules, body, base_anchors, out_dir)
        if (i + 1) % 10 == 0:
            print(f"  {i + 1}/{args.n}", flush=True)
    print(f"wrote {args.n} scenes to {out_dir}")


if __name__ == "__main__":
    main()
