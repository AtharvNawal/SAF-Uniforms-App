"""Segmentation dataset — RSAF No.4 dressed figures (men + ladies).

Renders `assets/3d/bodies/rsaf_no4_{male,female}.glb` through the same
domain randomisation as dataset v2 (camera, lighting, procedural
backgrounds, photometric degradation — imported from
`generate_segmentation_dataset_v2.py`), with pixel-perfect masks from the
figure's own node ancestry (`training/rsaf_figure.py`). Per render it
randomly removes items, swaps in a Sikh turban (men) or the cadet rank
tab, and writes a random surname on the name tape.

Labels use the 14-class `CLASSES_V3` list (v2's 12 + `rank_tab`,
`sleeve_patch`), so these images train alongside the existing seg_v2 Army
set — see ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.

Usage:
    .venv-tools/bin/python cv-service/training/generate_segmentation_dataset_rsaf.py \\
        --n-train 450 --n-val 60 --workers 4 --out cv-service/synthetic_data/seg_rsaf
"""

from __future__ import annotations

import argparse
import multiprocessing as mp
import random
import sys
from pathlib import Path

import cv2
import numpy as np
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_segmentation_dataset_v2 as v2  # noqa: E402
from generate_segmentation_dataset import _mask_to_yolo_polygons  # noqa: E402
from rsaf_figure import CLASSES_V3, build_scene, load_figure  # noqa: E402

_PALETTE_V3 = v2._PALETTE + [(255, 255, 255), (128, 255, 0)]
CLASS_COLOR_V3 = {name: _PALETTE_V3[i] for i, name in enumerate(CLASSES_V3)}


def render(rng: random.Random, placements, cam_pose, yfov, body_scale, wide: bool = True):
    """v2.render_scene with the v3 colour table (v2's has no rank_tab /
    sleeve_patch). Returns (rgb, depth, seg)."""
    import pyrender

    scale_m = np.diag([body_scale[0], body_scale[1], body_scale[0], 1.0])
    ambient = rng.uniform(0.15, 0.45) if wide else 0.3
    rgb_scene = pyrender.Scene(bg_color=[0, 0, 0, 0], ambient_light=[ambient] * 3)
    seg_scene = pyrender.Scene(bg_color=[0, 0, 0, 255])
    seg_node_map = {}
    for i, (mesh, class_name) in enumerate(placements):
        rgb_scene.add(pyrender.Mesh.from_trimesh(mesh), pose=scale_m)
        node = seg_scene.add(pyrender.Mesh.from_trimesh(mesh), name=f"seg_{i}", pose=scale_m)
        seg_node_map[node] = CLASS_COLOR_V3[class_name] if class_name else (0, 0, 0)
    for scene in (rgb_scene, seg_scene):
        scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    key = rng.uniform(2.0, 5.0) if wide else 3.0
    rgb_scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=key),
                  pose=v2._random_light_pose(rng, cam_pose) if wide else cam_pose)
    rgb_scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=key * rng.uniform(0.2, 0.6)), pose=cam_pose)
    renderer = pyrender.OffscreenRenderer(v2.IMAGE_WIDTH, v2.IMAGE_HEIGHT)
    try:
        rgb, depth = renderer.render(rgb_scene)
        seg, _ = renderer.render(seg_scene, flags=pyrender.RenderFlags.SEG, seg_node_map=seg_node_map)
    finally:
        renderer.delete()
    return rgb, depth, seg


def seg_to_yolo(seg_color: np.ndarray) -> list[str]:
    lines = []
    for class_id, class_name in enumerate(CLASSES_V3):
        mask = np.all(np.abs(seg_color.astype(int) - np.array(CLASS_COLOR_V3[class_name])) <= 4, axis=-1)
        if mask.any():
            lines.extend(_mask_to_yolo_polygons(mask, class_id))
    return lines


_WORKER: dict = {}


def _init_worker() -> None:
    _WORKER["figures"] = {g: load_figure(g) for g in ("male", "female")}


def _render_task(args: tuple[int, int, str, str]) -> bool:
    seed, index, images_dir, labels_dir = args
    rng = random.Random(seed * 100_003 + index)
    gender = "male" if index % 2 == 0 else "female"
    placements = build_scene(_WORKER["figures"][gender], rng)
    body_scale = (rng.uniform(0.92, 1.1), rng.uniform(0.95, 1.05))
    cam_pose, yfov = v2._camera_pose(rng)
    rgb, depth, seg = render(rng, placements, cam_pose, yfov, body_scale)
    image = v2.photometric(rng, v2.composite(rng, rgb, depth))
    name = f"segrsaf_{seed}_{index:05d}"
    cv2.imwrite(str(Path(images_dir) / f"{name}.jpg"), cv2.cvtColor(image, cv2.COLOR_RGB2BGR), [cv2.IMWRITE_JPEG_QUALITY, 95])
    (Path(labels_dir) / f"{name}.txt").write_text("\n".join(seg_to_yolo(seg)))
    return True


def generate_split(n: int, out_dir: Path, split: str, seed: int, workers: int) -> None:
    images_dir, labels_dir = out_dir / "images" / split, out_dir / "labels" / split
    images_dir.mkdir(parents=True, exist_ok=True)
    labels_dir.mkdir(parents=True, exist_ok=True)
    tasks = [(seed, i, str(images_dir), str(labels_dir)) for i in range(n)
             if not (labels_dir / f"segrsaf_{seed}_{i:05d}.txt").exists()]  # resumable
    print(f"{split}: {n - len(tasks)} already rendered, {len(tasks)} to go", flush=True)
    ctx = mp.get_context("spawn")
    with ctx.Pool(workers, initializer=_init_worker) as pool:
        for done, _ in enumerate(pool.imap_unordered(_render_task, tasks), 1):
            if done % 25 == 0:
                print(f"  {split}: {done}/{len(tasks)}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n-train", type=int, default=450)
    parser.add_argument("--n-val", type=int, default=60)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--seed", type=int, default=11)
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parents[1] / "synthetic_data" / "seg_rsaf")
    args = parser.parse_args()
    generate_split(args.n_train, args.out, "train", args.seed, args.workers)
    generate_split(args.n_val, args.out, "val", args.seed + 1, args.workers)
    (args.out / "data.yaml").write_text(yaml.safe_dump({
        "path": str(args.out.resolve()), "train": "images/train", "val": "images/val",
        "names": {i: n for i, n in enumerate(CLASSES_V3)},
    }, sort_keys=False))
    print(f"done → {args.out}", flush=True)


if __name__ == "__main__":
    main()
