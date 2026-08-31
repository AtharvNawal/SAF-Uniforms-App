"""Accessory bounding-box dataset generator — Milestone 3's real data
prerequisite. Same rendering technique as
`generate_segmentation_dataset.py` (pyrender renders of the reference
body + doctrine-anchored accessories from randomized cameras), but
producing YOLO **detection** labels (axis-aligned boxes) instead of
segmentation polygons, for the same small-accessory classes
segmentation turned out weakest on (`belt` 0.556, `arms_badge` 0.524,
`epaulette` 0.496, `sleeve_rank` 0.222 mAP50 — see
`ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md`).

Boxes are derived by projecting each placed accessory mesh's actual
vertices through the exact render camera — the same ground-truth
technique `generate_synthetic_dataset.py`'s COCO exporter uses, reused
directly here (`_project`, `_camera_intrinsics`), not estimated or
hand-drawn. No SEG double-render pass is needed for boxes (unlike
segmentation's masks), so this generates noticeably faster per image —
confirmed empirically before committing to a full run (see the
ChangeRequest plan's verification section).

**This produces training data and trains a real model — it does not
validate real-world accuracy.** Every image is a synthetic pyrender
render of the one reference body GLB; zero real photographs are
involved anywhere in generation, training, or the validation split
below. Same caveat as the segmentation model, restated because it's
the load-bearing one: real-world accuracy is completely unvalidated.

Usage:
    .venv-tools/bin/python cv-service/training/generate_detection_dataset.py \
        --n-train 400 --n-val 80 --out cv-service/synthetic_data/det_v1
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
    _camera_intrinsics,
    _load_accessory_mesh,
    _place_accessory,
    _project,
    load_anchors,
)
from generate_segmentation_dataset import ACCESSORY_STEM_TO_CLASS  # noqa: E402

# Deliberately matches generate_synthetic_dataset.py's resolution — its
# `_camera_intrinsics` derives focal length from that module's own
# IMAGE_HEIGHT global, so rendering at a different size here without
# re-deriving intrinsics locally would silently mis-project every box.
IMAGE_WIDTH, IMAGE_HEIGHT = 800, 1200

CLASSES = ["headwear", "cap_badge", "epaulette", "sleeve_rank", "arms_badge", "belt"]
CLASS_ID = {name: i for i, name in enumerate(CLASSES)}


def _load_body_meshes() -> list[trimesh.Trimesh]:
    scene = trimesh.load(str(BODY_GLB), force="scene")
    meshes = []
    for node_name in scene.graph.nodes_geometry:
        transform, geom_name = scene.graph[node_name]
        geom = scene.geometry[geom_name]
        if geom.vertices.shape[0] <= 16:
            continue  # socket marker cubes injected by tool/inject_sockets.py
        world_geom = geom.copy()
        world_geom.apply_transform(transform)
        meshes.append(world_geom)
    return meshes


def render_sample(
    rng: random.Random, anchors: dict, body_meshes: list[trimesh.Trimesh]
) -> tuple[np.ndarray, list[str]]:
    rgb_meshes: list[trimesh.Trimesh] = list(body_meshes)
    boxed: list[tuple[int, trimesh.Trimesh]] = []

    for stem, _category, anchor_names, offset_cm, _mirror in ACCESSORY_SPECS:
        class_name = ACCESSORY_STEM_TO_CLASS.get(stem)
        if class_name is None:
            continue  # no detection class mapped for this accessory (e.g. none today — kept for parity with the segmentation generator's dispatch table)
        if stem in OPTIONAL_ACCESSORY_NAMES and rng.random() < 0.4:
            continue  # randomly omit — combinatorial coverage, same as the other generators
        base_mesh = _load_accessory_mesh(stem)
        if base_mesh is None:
            continue
        for i, anchor_name in enumerate(anchor_names):
            anchor = anchors.get(anchor_name)
            if anchor is None:
                continue
            placed = _place_accessory(base_mesh, anchor, offset_cm, mirror_x=(i == 1))
            rgb_meshes.append(placed)
            boxed.append((CLASS_ID[class_name], placed))

    camera = RenderCamera(
        azimuth_deg=rng.uniform(-25, 25),
        elevation_deg=rng.uniform(-5, 8),
        distance_m=rng.uniform(2.1, 2.7),
        target_height_m=rng.uniform(0.95, 1.05),
    )
    cam_pose = camera.pose_matrix()
    yfov = math.radians(rng.uniform(42, 55))

    scene = trimesh.Scene()
    for i, mesh in enumerate(rgb_meshes):
        scene.add_geometry(mesh, node_name=f"m_{i}")
    pr_scene = pyrender.Scene.from_trimesh_scene(
        scene, bg_color=rng.choice([[200, 200, 200, 255], [150, 160, 170, 255], [230, 225, 215, 255]])
    )
    pr_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    pr_scene.add(
        pyrender.DirectionalLight(color=[255, 255, 255], intensity=rng.uniform(2.2, 3.6)), pose=cam_pose
    )

    renderer = pyrender.OffscreenRenderer(IMAGE_WIDTH, IMAGE_HEIGHT)
    try:
        color, _depth = renderer.render(pr_scene)
    finally:
        renderer.delete()

    focal, cx, cy = _camera_intrinsics(yfov)
    labels: list[str] = []
    for class_id, mesh in boxed:
        px = _project(mesh.vertices, cam_pose, focal, cx, cy)
        x1, y1 = max(0.0, float(px[:, 0].min())), max(0.0, float(px[:, 1].min()))
        x2, y2 = min(float(IMAGE_WIDTH), float(px[:, 0].max())), min(float(IMAGE_HEIGHT), float(px[:, 1].max()))
        if x2 <= x1 or y2 <= y1:
            continue  # projected fully outside frame
        cx_n = ((x1 + x2) / 2) / IMAGE_WIDTH
        cy_n = ((y1 + y2) / 2) / IMAGE_HEIGHT
        w_n = (x2 - x1) / IMAGE_WIDTH
        h_n = (y2 - y1) / IMAGE_HEIGHT
        labels.append(f"{class_id} {cx_n:.5f} {cy_n:.5f} {w_n:.5f} {h_n:.5f}")

    return color, labels


def generate_split(
    n: int, out_images: Path, out_labels: Path, anchors: dict, body_meshes: list[trimesh.Trimesh], seed_offset: int
) -> int:
    out_images.mkdir(parents=True, exist_ok=True)
    out_labels.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed_offset)
    written = 0
    for i in range(n):
        color, labels = render_sample(rng, anchors, body_meshes)
        if not labels:
            continue  # no accessories landed in frame this render — skip rather than train on an empty-label image
        filename = f"det_{seed_offset}_{i:05d}"
        cv2.imwrite(str(out_images / f"{filename}.jpg"), cv2.cvtColor(color, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 92])
        (out_labels / f"{filename}.txt").write_text("\n".join(labels))
        written += 1
        if (i + 1) % 50 == 0:
            print(f"  {i + 1}/{n}")
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n-train", type=int, default=400)
    parser.add_argument("--n-val", type=int, default=80)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/det_v1")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    out_dir = repo_root / args.out

    anchors = load_anchors()
    body_meshes = _load_body_meshes()
    print(f"Body meshes loaded: {[m.vertices.shape[0] for m in body_meshes]}")

    print(f"Rendering {args.n_train} train images...")
    n_train_written = generate_split(
        args.n_train, out_dir / "images" / "train", out_dir / "labels" / "train", anchors, body_meshes, seed_offset=1
    )
    print(f"Rendering {args.n_val} val images...")
    n_val_written = generate_split(
        args.n_val, out_dir / "images" / "val", out_dir / "labels" / "val", anchors, body_meshes, seed_offset=2
    )

    data_yaml = {
        "path": str(out_dir),
        "train": "images/train",
        "val": "images/val",
        "names": {i: name for name, i in CLASS_ID.items()},
    }
    (out_dir / "data.yaml").write_text(yaml.safe_dump(data_yaml, sort_keys=False))
    print(f"Wrote {n_train_written} train + {n_val_written} val images to {out_dir}")


if __name__ == "__main__":
    main()
