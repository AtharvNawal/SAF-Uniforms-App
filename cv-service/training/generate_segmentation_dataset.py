"""Segmentation-mask dataset generator — Milestone 2's real data
prerequisite, using pyrender's built-in flat-color segmentation render
mode (`RenderFlags.SEG` + `seg_node_map`) for pixel-perfect,
occlusion-correct ground truth. No hand-labeling, no approximation —
every mask pixel is exactly which mesh actually occupies it.

**Class granularity is bounded by what the mesh geometry actually
supports, not by what would be ideal.** `assets/3d/bodies/male_apose.glb`'s
body is one continuous 53k-vertex mesh with no separate shirt/collar/
pocket sub-meshes (checked directly — see the ChangeRequest plan this
script belongs to). Two classes are derived from it via a horizontal
plane cut at waist height (`trimesh.intersections.slice_mesh_plane`),
the same y-slicing technique already used in this repo's own merger
pipeline to separate feet/hair sub-meshes (see `CLAUDE.md` §8's pass
history) — not a novel hack, precedented here:

  - `shirt`    = body vertices between waist and neck height
  - `trousers` = body vertices below waist height

This is a real limitation, stated plainly: it will misclassify parts
of a hanging forearm/hand near hip height as `trousers` (the cut plane
doesn't distinguish torso from arm at the same world height), and it
cannot produce `collar`/`pocket`/`sleeve` as distinct classes at all —
those need either hand-authored mesh sub-regions (a 3D modeling task)
or enough real-photo training data for a model to learn them from
appearance rather than exact geometry. Six more classes come from
actual separate accessory meshes (headwear, cap badge, epaulette,
sleeve rank insignia, arms badge, belt) plus the body's already-separate
`feet` node (footwear).

Usage:
    .venv-tools/bin/python cv-service/training/generate_segmentation_dataset.py \
        --n-train 150 --n-val 30 \
        --out cv-service/synthetic_data/seg_v1
"""

from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

import cv2
import numpy as np
import pyrender
import trimesh
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_synthetic_dataset import (  # noqa: E402
    ACCESSORY_SPECS,
    BODY_GLB,
    OPTIONAL_ACCESSORY_NAMES,
    RenderCamera,
    _load_accessory_mesh,
    _place_accessory,
    load_anchors,
)

IMAGE_WIDTH, IMAGE_HEIGHT = 512, 768  # smaller than the bbox generator — faster render + train

# category name -> (yolo class id, mask color used only internally for the SEG pass)
CLASSES = ["shirt", "trousers", "headwear", "cap_badge", "epaulette", "sleeve_rank", "arms_badge", "belt", "footwear"]
CLASS_ID = {name: i for i, name in enumerate(CLASSES)}
# distinct, well-separated flat colors for the SEG render pass — values
# chosen far apart so 8-bit JPEG-free PNG round-tripping never confuses
# two classes (we render SEG to PNG, not JPEG, precisely to avoid this).
_PALETTE = [
    (220, 20, 60), (30, 144, 255), (34, 139, 34), (255, 165, 0),
    (148, 0, 211), (0, 206, 209), (255, 20, 147), (139, 69, 19), (0, 128, 128),
]
CLASS_COLOR = {name: _PALETTE[i] for i, name in enumerate(CLASSES)}

ACCESSORY_STEM_TO_CLASS = {
    "army_beret": "headwear",
    "army_cap_badge_sltc_me6_below": "cap_badge",
    "epaulettes_standard": "epaulette",
    "army_specialist_insignia": "sleeve_rank",
    "army_arms_badge": "arms_badge",
    "nylon_belt": "belt",
}


def _slice_body(body_mesh: trimesh.Trimesh, waist_y: float, neck_y: float) -> dict[str, trimesh.Trimesh]:
    """Horizontal-plane cuts of the single continuous body mesh — see
    module docstring for why this is the ceiling of precision
    available without hand-authored mesh regions."""
    below_neck = trimesh.intersections.slice_mesh_plane(
        body_mesh, plane_normal=[0, -1, 0], plane_origin=[0, neck_y, 0], cap=True
    )
    above_neck = trimesh.intersections.slice_mesh_plane(
        body_mesh, plane_normal=[0, 1, 0], plane_origin=[0, neck_y, 0], cap=True
    )
    trousers = trimesh.intersections.slice_mesh_plane(
        below_neck, plane_normal=[0, -1, 0], plane_origin=[0, waist_y, 0], cap=True
    )
    shirt = trimesh.intersections.slice_mesh_plane(
        below_neck, plane_normal=[0, 1, 0], plane_origin=[0, waist_y, 0], cap=True
    )
    return {"shirt": shirt, "trousers": trousers, "head": above_neck}


def _load_body_parts(anchors: dict) -> dict[str, dict]:
    """Returns `{"rgb": [...meshes for the photo...], "seg": {class_name
    or '_occluder': mesh, ...}}`. Kept separate deliberately: the RGB
    pass should render the full, unsliced, textured body (best visual
    quality, no seam artefacts from capping); the SEG pass needs the
    sliced sub-regions to get per-class pixel colors, PLUS the head as
    an explicit `_occluder` (rendered in the same black as the
    background, present only so it correctly hides whatever's behind
    it — without this, an accessory positioned behind where the head
    sits would incorrectly show through in the mask, since the SEG
    scene would otherwise have no geometry there at all)."""
    scene = trimesh.load(str(BODY_GLB), force="scene")
    rgb_meshes = []
    seg_parts: dict[str, trimesh.Trimesh] = {}
    for node_name in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph[node_name]
        geom = scene.geometry[geom_name]
        if geom.vertices.shape[0] <= 16:
            continue  # socket marker cubes
        world_geom = geom.copy()
        world_geom.apply_transform(transform)
        rgb_meshes.append(world_geom)
        if node_name == "body":
            waist_y = anchors["belt_center"]["y"]
            neck_y = (anchors["left_collar_tip"]["y"] + anchors["right_collar_tip"]["y"]) / 2
            sliced = _slice_body(world_geom, waist_y, neck_y)
            seg_parts["shirt"] = sliced["shirt"]
            seg_parts["trousers"] = sliced["trousers"]
            seg_parts["_occluder_head"] = sliced["head"]
        elif node_name == "feet":
            seg_parts["footwear"] = world_geom
    return {"rgb": rgb_meshes, "seg": seg_parts}


def _mask_to_yolo_polygons(mask: np.ndarray, class_id: int) -> list[str]:
    contours, _ = cv2.findContours(mask.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    lines = []
    h, w = mask.shape
    for contour in contours:
        if cv2.contourArea(contour) < 25:
            continue
        epsilon = 0.005 * cv2.arcLength(contour, True)
        approx = cv2.approxPolyDP(contour, epsilon, True).reshape(-1, 2)
        if len(approx) < 3:
            continue
        coords = " ".join(f"{x / w:.5f} {y / h:.5f}" for x, y in approx)
        lines.append(f"{class_id} {coords}")
    return lines


def render_sample(rng: random.Random, anchors: dict, body_parts: dict):
    # `pyrender.Scene.from_trimesh_scene` does NOT preserve trimesh node
    # names on the resulting pyrender Nodes (verified directly — every
    # node comes back with `.name is None`), which `seg_node_map` needs
    # to key on. So the RGB scene still goes through that convenience
    # path (names irrelevant there), but the SEG scene is built by hand,
    # adding each mesh with an explicit `name=` and keeping the `Node`
    # objects `Scene.add()` returns directly — no name lookup needed.
    rgb_meshes: list[trimesh.Trimesh] = list(body_parts["rgb"])  # full, unsliced body + feet
    # (class_name_or_None, mesh) — None means "occluder only, not a labeled class"
    seg_placements: list[tuple[str | None, trimesh.Trimesh]] = [
        (None if name.startswith("_occluder") else name, mesh)
        for name, mesh in body_parts["seg"].items()
    ]

    for stem, category, anchor_names, offset_cm, _ in ACCESSORY_SPECS:
        class_name = ACCESSORY_STEM_TO_CLASS.get(stem)
        if class_name is None:
            continue
        if stem in OPTIONAL_ACCESSORY_NAMES and rng.random() < 0.4:
            continue
        base_mesh = _load_accessory_mesh(stem)
        if base_mesh is None:
            continue
        for i, anchor_name in enumerate(anchor_names):
            anchor = anchors.get(anchor_name)
            if anchor is None:
                continue
            placed = _place_accessory(base_mesh, anchor, offset_cm, mirror_x=(i == 1))
            rgb_meshes.append(placed)
            seg_placements.append((class_name, placed))

    camera = RenderCamera(
        azimuth_deg=rng.uniform(-25, 25),
        elevation_deg=rng.uniform(-5, 8),
        distance_m=rng.uniform(2.1, 2.7),
        target_height_m=rng.uniform(0.95, 1.05),
    )
    cam_pose = camera.pose_matrix()
    yfov = math.radians(rng.uniform(42, 55))

    rgb_scene = trimesh.Scene()
    for i, mesh in enumerate(rgb_meshes):
        rgb_scene.add_geometry(mesh, node_name=f"rgb_{i}")
    pr_rgb_scene = pyrender.Scene.from_trimesh_scene(
        rgb_scene, bg_color=rng.choice([[200, 200, 200, 255], [150, 160, 170, 255], [230, 225, 215, 255]])
    )
    pr_rgb_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    pr_rgb_scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=rng.uniform(2.2, 3.6)), pose=cam_pose)

    pr_seg_scene = pyrender.Scene(bg_color=[0, 0, 0, 255])
    pr_seg_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    seg_node_map = {}
    for i, (class_name, mesh) in enumerate(seg_placements):
        node = pr_seg_scene.add(pyrender.Mesh.from_trimesh(mesh), name=f"seg_{i}")
        seg_node_map[node] = CLASS_COLOR[class_name] if class_name is not None else (0, 0, 0)

    renderer = pyrender.OffscreenRenderer(IMAGE_WIDTH, IMAGE_HEIGHT)
    try:
        rgb_color, _ = renderer.render(pr_rgb_scene)
        seg_color, _ = renderer.render(pr_seg_scene, flags=pyrender.RenderFlags.SEG, seg_node_map=seg_node_map)
    finally:
        renderer.delete()

    return rgb_color, seg_color


def seg_image_to_yolo_labels(seg_color: np.ndarray) -> list[str]:
    lines = []
    for class_name, class_id in CLASS_ID.items():
        color = np.array(CLASS_COLOR[class_name])
        mask = np.all(np.abs(seg_color.astype(int) - color) <= 4, axis=-1)
        if not mask.any():
            continue
        lines.extend(_mask_to_yolo_polygons(mask, class_id))
    return lines


def generate_split(n: int, out_images: Path, out_labels: Path, anchors: dict, body_parts_template, seed_offset: int):
    out_images.mkdir(parents=True, exist_ok=True)
    out_labels.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed_offset)
    written = 0
    for i in range(n):
        rgb, seg = render_sample(rng, anchors, body_parts_template)
        labels = seg_image_to_yolo_labels(seg)
        filename = f"seg_{seed_offset}_{i:05d}"
        cv2.imwrite(str(out_images / f"{filename}.jpg"), cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 92])
        (out_labels / f"{filename}.txt").write_text("\n".join(labels))
        written += 1
        if (i + 1) % 20 == 0:
            print(f"  {i + 1}/{n}")
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n-train", type=int, default=150)
    parser.add_argument("--n-val", type=int, default=30)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/seg_v1")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    out_dir = repo_root / args.out

    anchors = load_anchors()
    body_parts = _load_body_parts(anchors)
    print(
        "Body parts loaded — rgb meshes:",
        [m.vertices.shape[0] for m in body_parts["rgb"]],
        " seg classes:",
        {k: v.vertices.shape[0] for k, v in body_parts["seg"].items()},
    )

    print(f"Rendering {args.n_train} train images...")
    generate_split(args.n_train, out_dir / "images" / "train", out_dir / "labels" / "train", anchors, body_parts, seed_offset=1)
    print(f"Rendering {args.n_val} val images...")
    generate_split(args.n_val, out_dir / "images" / "val", out_dir / "labels" / "val", anchors, body_parts, seed_offset=2)

    data_yaml = {
        "path": str(out_dir),
        "train": "images/train",
        "val": "images/val",
        "names": {i: name for name, i in CLASS_ID.items()},
    }
    (out_dir / "data.yaml").write_text(yaml.safe_dump(data_yaml, sort_keys=False))
    print(f"Wrote dataset to {out_dir}")


if __name__ == "__main__":
    main()
