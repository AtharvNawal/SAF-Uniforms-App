"""Segmentation dataset v2 — domain-randomised, 12 classes.

Builds on `generate_segmentation_dataset.py` (v1: 9 classes, one flat
background, one light, narrow camera range, 150 renders) to attack the
synthetic-to-real gap with everything that doesn't need a real photo.
See ChangeRequest/2026-09-28_accuracy-program-no-real-data.md (B11, B12).

New classes (B11):
  - `name_tag` — `assets/3d/accessories/name_tag_standard.glb`
  - `socks`    — `assets/3d/accessories/black_socks.glb`
  - `hand`     — forearm + hand split out of the body mesh. Below
    y≈1.15 m the A-pose arms separate from the torso (measured: a
    ≥3 cm x-gap at every slice from 1.1 m down to the fingertips at
    ~0.72 m), so faces past that gap are labelled `hand` instead of
    falling into `shirt`/`trousers` — fixes v1's documented "hands
    labelled trousers" error.

Domain randomisation (B12):
  - accessory *variants* per slot (3 cap badges, beret/turban, 2 belts,
    2 epaulette types, specialist/enlistee insignia) and random removal
    of each item (so the model sees absence, not just presence)
  - body proportion scaling (width 0.9-1.12, height 0.94-1.06)
  - camera: azimuth ±35°, elevation -8..12°, roll ±5° (hand-held phone),
    distance 1.8-3.2 m, yfov 38-60°, subject off-centre
  - lighting: key light from random direction + fill + ambient
  - procedural backgrounds composited via the depth buffer (gradients,
    wall/floor split, blurred noise, stripes, clutter rectangles)
  - photometric: HSV jitter, gamma, Gaussian/motion blur, sensor noise,
    down/up-sampling, JPEG quality 35-95

Usage:
    .venv-tools/bin/python cv-service/training/generate_segmentation_dataset_v2.py \\
        --n-train 1000 --n-val 150 --workers 4 --out cv-service/synthetic_data/seg_v2
"""

from __future__ import annotations

import argparse
import math
import multiprocessing as mp
import random
import sys
from pathlib import Path

import cv2
import numpy as np
import trimesh
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_synthetic_dataset import BODY_GLB, RenderCamera, _load_accessory_mesh, load_anchors  # noqa: E402
from generate_segmentation_dataset import _mask_to_yolo_polygons  # noqa: E402

IMAGE_WIDTH, IMAGE_HEIGHT = 640, 960

CLASSES = [
    "shirt", "trousers", "headwear", "cap_badge", "epaulette", "sleeve_rank",
    "arms_badge", "belt", "footwear", "name_tag", "socks", "hand",
]
CLASS_ID = {name: i for i, name in enumerate(CLASSES)}
_PALETTE = [
    (220, 20, 60), (30, 144, 255), (34, 139, 34), (255, 165, 0),
    (148, 0, 211), (0, 206, 209), (255, 20, 147), (139, 69, 19),
    (0, 128, 128), (255, 255, 0), (70, 70, 255), (255, 120, 120),
]
CLASS_COLOR = {name: _PALETTE[i] for i, name in enumerate(CLASSES)}

# Forearm/hand split: below this height the arms are separate from the
# torso; |x| threshold sits in the measured torso↔arm gap.
_ARM_SPLIT_TOP_Y = 1.15


def _arm_x_threshold(y: np.ndarray) -> np.ndarray:
    return np.where(y >= 0.95, 0.185, 0.21)


# slot -> list of (glb stem, anchor names, offset_cm, weight). One entry
# per slot is chosen per render; `None` stem = slot left empty.
SLOTS: dict[str, dict] = {
    "headwear": {
        "class": "headwear", "p_present": 0.93,
        "variants": [
            ("army_beret", ["head_top"], (0, -16.0, 0), 0.85),
            ("army_sikh_turban_standard", ["head_top"], (0, 1.0, 0), 0.15),
        ],
    },
    "cap_badge": {
        "class": "cap_badge", "p_present": 0.9, "requires": ("headwear", "army_beret"),
        "variants": [
            ("army_cap_badge_sltc_me6_below", ["cap_band_front"], (0, -1.0, 3.0), 0.6),
            ("army_cap_badge_col_me7", ["cap_band_front"], (0, -1.0, 3.0), 0.2),
            ("army_cap_badge_bg_me8_above", ["cap_band_front"], (0, -1.0, 3.0), 0.2),
        ],
    },
    "epaulette": {
        "class": "epaulette", "p_present": 0.9,
        "variants": [
            ("epaulettes_standard", ["left_shoulder_seam", "right_shoulder_seam"], (-2.6, 2.2, -10.0), 0.8),
            ("epaulettes_officer_cadet_me_trainee", ["left_shoulder_seam", "right_shoulder_seam"], (-2.6, 2.2, -10.0), 0.2),
        ],
    },
    "sleeve_rank": {
        "class": "sleeve_rank", "p_present": 0.8,
        "variants": [
            ("army_specialist_insignia", ["left_sleeve_upper", "right_sleeve_upper"], (0.4, 0, -7.0), 0.5),
            ("army_enlistee_insignia", ["left_sleeve_upper", "right_sleeve_upper"], (1.3, 0, -7.0), 0.5),
        ],
    },
    "arms_badge": {
        "class": "arms_badge", "p_present": 0.6,
        "variants": [("army_arms_badge", ["right_collar_tip"], (0, -3.0, -3.0), 1.0)],
    },
    "belt": {
        "class": "belt", "p_present": 0.9,
        "variants": [
            ("nylon_belt", ["belt_center"], (0, -3.0, -16.0), 0.7),
            ("leather_belt", ["belt_center"], (0, -3.0, -16.0), 0.3),
        ],
    },
    "name_tag": {
        "class": "name_tag", "p_present": 0.85,
        # bottom edge 1 cm above the pocket anchor (tag is 1.7 cm tall)
        "variants": [("name_tag_standard", ["right_chest_pocket"], (0, 1.85, -2.0), 1.0)],
    },
    "socks": {
        "class": "socks", "p_present": 0.9,
        "variants": [("procedural_socks", ["left_ankle", "right_ankle"], (4.6, 1.2, -5.9), 1.0)],
    },
}


def load_body_parts_v2(anchors: dict) -> dict:
    """RGB meshes (full body + feet) and per-class SEG meshes, with the
    forearm/hand split out of the single continuous body mesh by face
    centroid (no plane caps needed — the SEG pass only needs coverage)."""
    scene = trimesh.load(str(BODY_GLB), force="scene")
    rgb: list[trimesh.Trimesh] = []
    seg: dict[str, trimesh.Trimesh] = {}
    waist_y = anchors["belt_center"]["y"]
    neck_y = (anchors["left_collar_tip"]["y"] + anchors["right_collar_tip"]["y"]) / 2
    for node_name in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph[node_name]
        geom = scene.geometry[geom_name]
        if geom.vertices.shape[0] <= 16:
            continue  # socket marker cubes
        world = geom.copy()
        world.apply_transform(transform)
        rgb.append(world)
        if node_name == "feet":
            seg["footwear"] = world
        elif node_name == "body":
            centers = world.triangles_center
            y, ax = centers[:, 1], np.abs(centers[:, 0])
            hand = (y < _ARM_SPLIT_TOP_Y) & (y > 0.55) & (ax > _arm_x_threshold(y))
            head = (y >= neck_y) & ~hand
            shirt = (y >= waist_y) & (y < neck_y) & ~hand
            trousers = (y < waist_y) & ~hand
            for name, faces in (("hand", hand), ("_occluder_head", head), ("shirt", shirt), ("trousers", trousers)):
                if faces.any():
                    seg[name] = world.submesh([np.where(faces)[0]], append=True)
    return {"rgb": rgb, "seg": seg}


# Meshes authored facing +z that must face outward from the arm (±x).
_ROTATE_Y_DEG = {
    "army_specialist_insignia": 90.0,
    # epaulettes run along the shoulder strap (collar -> shoulder, i.e. x)
    "epaulettes_standard": 90.0,
    "epaulettes_officer_cadet_me_trainee": 90.0,
}


def _socks_mesh() -> trimesh.Trimesh:
    """Thin near-black elliptical band just outside the leg between the
    trouser hem and the shoe (measured leg cross-section at y≈0.11 m:
    x half-width ≈5.8 cm, z half-depth ≈8.6 cm). Replaces
    black_socks.glb, a 10 cm placeholder cube that rendered as a blob."""
    band = trimesh.creation.cylinder(radius=1.0, height=0.03, sections=48)
    band.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2, [1, 0, 0]))
    band.apply_scale([0.062, 1.0, 0.09])
    band.visual.vertex_colors = np.tile([18, 18, 20, 255], (len(band.vertices), 1))
    return band


def _load_mesh(stem: str) -> trimesh.Trimesh | None:
    if stem == "procedural_socks":
        return _socks_mesh()
    mesh = _load_accessory_mesh(stem)
    if mesh is not None and stem in _ROTATE_Y_DEG:
        mesh = mesh.copy()
        mesh.apply_transform(trimesh.transformations.rotation_matrix(math.radians(_ROTATE_Y_DEG[stem]), [0, 1, 0]))
    return mesh


def _place(mesh: trimesh.Trimesh, anchor: dict, offset_cm, mirror_x: bool) -> trimesh.Trimesh:
    """`offset_cm` is authored for the wearer's-LEFT (+x) side; the
    mirrored right-side copy gets its x offset mirrored too."""
    placed = mesh.copy()
    if mirror_x:
        placed.apply_transform(np.diag([-1, 1, 1, 1]))
    dx, dy, dz = (v / 100.0 for v in offset_cm)
    if mirror_x:
        dx = -dx
    placed.apply_translation([anchor["x"] + dx, anchor["y"] + dy, anchor["z"] + dz])
    return placed


def choose_accessories(rng: random.Random) -> dict[str, str | None]:
    chosen: dict[str, str | None] = {}
    for slot, spec in SLOTS.items():
        requires = spec.get("requires")
        if requires and chosen.get(requires[0]) != requires[1]:
            chosen[slot] = None
            continue
        if rng.random() > spec["p_present"]:
            chosen[slot] = None
            continue
        stems = [v[0] for v in spec["variants"]]
        weights = [v[3] for v in spec["variants"]]
        chosen[slot] = rng.choices(stems, weights=weights)[0]
    return chosen


def placed_accessories(chosen: dict[str, str | None], anchors: dict, overrides: dict | None = None):
    """Yields (class_name, slot, stem, mesh). `overrides[slot]` may replace
    (anchor_names, offset_cm) — used by the violation benchmark to
    displace an item or put it on the wrong side."""
    overrides = overrides or {}
    for slot, stem in chosen.items():
        if stem is None:
            continue
        spec = SLOTS[slot]
        variant = next(v for v in spec["variants"] if v[0] == stem)
        anchor_names, offset_cm = overrides.get(slot, (variant[1], variant[2]))
        base = _load_mesh(stem)
        if base is None:
            continue
        for i, anchor_name in enumerate(anchor_names):
            anchor = anchors.get(anchor_name)
            if anchor is None:
                continue
            mirror = anchor_name.startswith("right_") and len(anchor_names) > 1
            yield spec["class"], slot, stem, _place(base, anchor, offset_cm, mirror_x=mirror)


# --- rendering ----------------------------------------------------------------

def _camera_pose(rng: random.Random, wide: bool = True) -> tuple[np.ndarray, float]:
    camera = RenderCamera(
        azimuth_deg=rng.uniform(-35, 35) if wide else rng.uniform(-10, 10),
        elevation_deg=rng.uniform(-8, 12) if wide else rng.uniform(-3, 6),
        distance_m=rng.uniform(1.8, 3.2) if wide else rng.uniform(2.2, 2.8),
        target_height_m=rng.uniform(0.85, 1.1),
    )
    pose = camera.pose_matrix()
    # hand-held roll about the viewing axis
    roll = math.radians(rng.uniform(-5, 5) if wide else rng.uniform(-2, 2))
    c, s = math.cos(roll), math.sin(roll)
    roll_m = np.array([[c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
    pose = pose @ roll_m
    # subject off-centre: shift camera sideways in its own frame
    pose[:3, 3] += pose[:3, 0] * rng.uniform(-0.25, 0.25)
    yfov = math.radians(rng.uniform(38, 60) if wide else rng.uniform(45, 55))
    return pose, yfov


def _random_light_pose(rng: random.Random, cam_pose: np.ndarray) -> np.ndarray:
    az, el = math.radians(rng.uniform(-70, 70)), math.radians(rng.uniform(-10, 60))
    direction = np.array([math.sin(az) * math.cos(el), math.sin(el), math.cos(az) * math.cos(el)])
    forward = -direction / np.linalg.norm(direction)
    up = np.array([0.0, 1.0, 0.0])
    right = np.cross(forward, up)
    if np.linalg.norm(right) < 1e-6:
        right = np.array([1.0, 0.0, 0.0])
    right /= np.linalg.norm(right)
    true_up = np.cross(right, forward)
    pose = np.eye(4)
    pose[:3, 0], pose[:3, 1], pose[:3, 2] = right, true_up, -forward
    pose[:3, 3] = direction * 3
    return pose


def render_scene(rng: random.Random, rgb_meshes, seg_placements, body_scale, cam_pose, yfov, wide=True):
    import pyrender

    scale_m = np.diag([body_scale[0], body_scale[1], body_scale[0], 1.0])

    ambient = rng.uniform(0.15, 0.45) if wide else 0.3
    rgb_scene = pyrender.Scene(bg_color=[0, 0, 0, 0], ambient_light=[ambient] * 3)
    for mesh in rgb_meshes:
        rgb_scene.add(pyrender.Mesh.from_trimesh(mesh), pose=scale_m)
    rgb_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    key = rng.uniform(2.0, 5.0) if wide else 3.0
    rgb_scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=key),
                  pose=_random_light_pose(rng, cam_pose) if wide else cam_pose)
    rgb_scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=key * rng.uniform(0.2, 0.6)), pose=cam_pose)

    seg_scene = pyrender.Scene(bg_color=[0, 0, 0, 255])
    seg_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    seg_node_map = {}
    for i, (class_name, mesh) in enumerate(seg_placements):
        node = seg_scene.add(pyrender.Mesh.from_trimesh(mesh), name=f"seg_{i}", pose=scale_m)
        seg_node_map[node] = CLASS_COLOR[class_name] if class_name else (0, 0, 0)

    renderer = pyrender.OffscreenRenderer(IMAGE_WIDTH, IMAGE_HEIGHT)
    try:
        rgb, depth = renderer.render(rgb_scene)
        seg, _ = renderer.render(seg_scene, flags=pyrender.RenderFlags.SEG, seg_node_map=seg_node_map)
    finally:
        renderer.delete()
    return rgb, depth, seg


def procedural_background(rng: random.Random, h: int, w: int) -> np.ndarray:
    kind = rng.choice(["solid", "gradient", "wall_floor", "noise", "stripes", "clutter"])
    base = np.array([rng.randint(30, 240) for _ in range(3)], dtype=np.float32)
    if kind == "solid":
        bg = np.ones((h, w, 3), np.float32) * base
    elif kind == "gradient":
        other = np.array([rng.randint(30, 240) for _ in range(3)], dtype=np.float32)
        t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
        bg = base * (1 - t) + other * t
        bg = np.broadcast_to(bg, (h, w, 3)).copy()
    elif kind == "wall_floor":
        horizon = int(h * rng.uniform(0.6, 0.85))
        floor = np.array([rng.randint(20, 160) for _ in range(3)], dtype=np.float32)
        bg = np.ones((h, w, 3), np.float32) * base
        bg[horizon:] = floor
    elif kind == "noise":
        small = np.random.default_rng(rng.randint(0, 1 << 30)).uniform(0, 255, (h // 16 + 1, w // 16 + 1, 3)).astype(np.float32)
        bg = cv2.resize(small, (w, h), interpolation=cv2.INTER_CUBIC)
        bg = 0.5 * bg + 0.5 * base
    elif kind == "stripes":
        bg = np.ones((h, w, 3), np.float32) * base
        period = rng.randint(20, 120)
        other = np.array([rng.randint(30, 240) for _ in range(3)], dtype=np.float32)
        cols = (np.arange(w) // period) % 2 == 1
        bg[:, cols] = other
    else:
        bg = np.ones((h, w, 3), np.float32) * base
        for _ in range(rng.randint(3, 12)):
            x1, y1 = rng.randint(0, w - 1), rng.randint(0, h - 1)
            x2, y2 = min(w, x1 + rng.randint(20, w // 2)), min(h, y1 + rng.randint(20, h // 2))
            bg[y1:y2, x1:x2] = [rng.randint(0, 255) for _ in range(3)]
    return np.clip(bg, 0, 255)


def photometric(rng: random.Random, img: np.ndarray) -> np.ndarray:
    """HSV jitter, gamma, blur, noise, resampling, JPEG. `img` is RGB uint8."""
    hsv = cv2.cvtColor(img, cv2.COLOR_RGB2HSV).astype(np.float32)
    hsv[..., 0] = (hsv[..., 0] + rng.uniform(-6, 6)) % 180
    hsv[..., 1] *= rng.uniform(0.7, 1.3)
    hsv[..., 2] *= rng.uniform(0.7, 1.25)
    img = cv2.cvtColor(np.clip(hsv, 0, 255).astype(np.uint8), cv2.COLOR_HSV2RGB)
    gamma = rng.uniform(0.75, 1.35)
    img = np.clip(255.0 * (img / 255.0) ** gamma, 0, 255).astype(np.uint8)
    r = rng.random()
    if r < 0.25:
        k = rng.choice([3, 5])
        img = cv2.GaussianBlur(img, (k, k), 0)
    elif r < 0.4:
        k = rng.randint(3, 9)
        kernel = np.zeros((k, k), np.float32)
        kernel[k // 2, :] = 1.0 / k
        rot = cv2.getRotationMatrix2D((k / 2 - 0.5, k / 2 - 0.5), rng.uniform(0, 180), 1)
        kernel = cv2.warpAffine(kernel, rot, (k, k))
        kernel /= max(kernel.sum(), 1e-6)
        img = cv2.filter2D(img, -1, kernel)
    if rng.random() < 0.5:
        noise = np.random.default_rng(rng.randint(0, 1 << 30)).normal(0, rng.uniform(2, 9), img.shape)
        img = np.clip(img.astype(np.float32) + noise, 0, 255).astype(np.uint8)
    if rng.random() < 0.3:
        h, w = img.shape[:2]
        f = rng.uniform(0.45, 0.8)
        img = cv2.resize(cv2.resize(img, (int(w * f), int(h * f)), interpolation=cv2.INTER_AREA), (w, h), interpolation=cv2.INTER_LINEAR)
    ok, enc = cv2.imencode(".jpg", cv2.cvtColor(img, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, rng.randint(35, 95)])
    return cv2.cvtColor(cv2.imdecode(enc, cv2.IMREAD_COLOR), cv2.COLOR_BGR2RGB)


def composite(rng: random.Random, rgb: np.ndarray, depth: np.ndarray) -> np.ndarray:
    bg = procedural_background(rng, rgb.shape[0], rgb.shape[1])
    fg = (depth > 0)[..., None]
    out = np.where(fg, rgb[..., :3].astype(np.float32), bg)
    return out.astype(np.uint8)


def seg_to_yolo(seg_color: np.ndarray) -> list[str]:
    lines = []
    for class_name, class_id in CLASS_ID.items():
        color = np.array(CLASS_COLOR[class_name])
        mask = np.all(np.abs(seg_color.astype(int) - color) <= 4, axis=-1)
        if mask.any():
            lines.extend(_mask_to_yolo_polygons(mask, class_id))
    return lines


# --- worker -------------------------------------------------------------------

_WORKER: dict = {}


def _init_worker() -> None:
    anchors = load_anchors()
    _WORKER["anchors"] = anchors
    _WORKER["body"] = load_body_parts_v2(anchors)


def _render_task(args: tuple[int, int, str, str]) -> bool:
    seed, index, images_dir, labels_dir = args
    rng = random.Random(seed * 100_003 + index)
    anchors, body = _WORKER["anchors"], _WORKER["body"]
    chosen = choose_accessories(rng)
    rgb_meshes = list(body["rgb"])
    seg_placements = [(None if n.startswith("_occluder") else n, m) for n, m in body["seg"].items()]
    for class_name, _slot, _stem, mesh in placed_accessories(chosen, anchors):
        rgb_meshes.append(mesh)
        seg_placements.append((class_name, mesh))
    body_scale = (rng.uniform(0.9, 1.12), rng.uniform(0.94, 1.06))
    cam_pose, yfov = _camera_pose(rng)
    rgb, depth, seg = render_scene(rng, rgb_meshes, seg_placements, body_scale, cam_pose, yfov)
    image = photometric(rng, composite(rng, rgb, depth))
    name = f"segv2_{seed}_{index:05d}"
    cv2.imwrite(str(Path(images_dir) / f"{name}.jpg"), cv2.cvtColor(image, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 95])
    (Path(labels_dir) / f"{name}.txt").write_text("\n".join(seg_to_yolo(seg)))
    return True


def generate_split(n: int, out_dir: Path, split: str, seed: int, workers: int) -> None:
    images_dir, labels_dir = out_dir / "images" / split, out_dir / "labels" / split
    images_dir.mkdir(parents=True, exist_ok=True)
    labels_dir.mkdir(parents=True, exist_ok=True)
    tasks = [(seed, i, str(images_dir), str(labels_dir)) for i in range(n)
             if not (labels_dir / f"segv2_{seed}_{i:05d}.txt").exists()]  # resumable
    print(f"{split}: {n - len(tasks)} already rendered, {len(tasks)} to go", flush=True)
    ctx = mp.get_context("spawn")
    with ctx.Pool(workers, initializer=_init_worker) as pool:
        for done, _ in enumerate(pool.imap_unordered(_render_task, tasks), 1):
            if done % 25 == 0:
                print(f"  {split}: {done}/{len(tasks)}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n-train", type=int, default=1000)
    parser.add_argument("--n-val", type=int, default=150)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/seg_v2")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    out_dir = repo_root / args.out
    generate_split(args.n_train, out_dir, "train", seed=11, workers=args.workers)
    generate_split(args.n_val, out_dir, "val", seed=12, workers=args.workers)
    (out_dir / "data.yaml").write_text(yaml.safe_dump({
        "path": str(out_dir), "train": "images/train", "val": "images/val",
        "names": {i: name for name, i in CLASS_ID.items()},
    }, sort_keys=False))
    print(f"Wrote dataset to {out_dir}")


if __name__ == "__main__":
    main()
