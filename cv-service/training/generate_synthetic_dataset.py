"""Synthetic training-data generator — real progress toward Milestones
2/3, NOT the milestones themselves.

The architecture memo (§16) describes this job as a Blender `bpy`
script. No Blender binary is available in the environment this was
built in, so this uses `pyrender` instead — same job (render the
reference body + accessories from randomized cameras, derive labels
for free from known 3D geometry instead of hand-annotation), different
renderer. Swap in a Blender-based version later if/when Blender is
available; nothing downstream cares which renderer produced the
dataset as long as the COCO-shaped output is the same.

**This produces training data. It does not train anything.** Running
this script does not complete Milestone 2 (segmentation) or Milestone
3 (accessory detection) — those need an actual training run against a
dataset like the one this generates, plus real photos to fine-tune the
synthetic-to-real domain gap away (see the memo's §15 training
strategy). What this script proves: the "labels come free from known
3D geometry" claim in the memo is real, not aspirational — every
bounding box below is computed by projecting actual mesh vertices
through the exact camera used to render, not estimated or hand-drawn.

Usage:
    .venv-tools/bin/pip install pyrender   # not in requirements.txt —
                                            # generation-time only, see
                                            # tests/fixtures/generate_fixture.py
    .venv-tools/bin/python cv-service/training/generate_synthetic_dataset.py \
        --n-renders 200 --out cv-service/synthetic_data/army_no3_male_v1
"""

from __future__ import annotations

import argparse
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import PIL.Image
import pyrender
import trimesh

REPO_ROOT = Path(__file__).resolve().parents[2]
BODY_GLB = REPO_ROOT / "assets" / "3d" / "bodies" / "male_apose.glb"
ACCESSORY_DIR = REPO_ROOT / "assets" / "3d" / "accessories"

IMAGE_WIDTH, IMAGE_HEIGHT = 800, 1200

# (accessory glb stem, category, anchor name(s), offset_cm (x, y, z), mirror)
# Subset of the Army No.3 Male set with a real 3D anchor in
# accessory_library.v1.json's render_logic — mirrors what
# glb_compose.ts itself attaches. Excludes name_tag (texture-baked, no
# mesh anchor) and lanyard (side-based anchor, more setup than this
# proof-of-concept needs).
ACCESSORY_SPECS = [
    ("army_beret", "headdress_beret", ["head_top"], (0, -16.0, 0), False),
    ("army_cap_badge_sltc_me6_below", "cap_badge", ["cap_band_front"], (0, -1.0, 3.0), False),
    ("epaulettes_standard", "epaulette", ["left_shoulder_seam", "right_shoulder_seam"], (0, 0.0, 0), False),
    ("army_specialist_insignia", "sleeve_rank_specialist", ["left_shoulder_seam", "right_shoulder_seam"], (0, 0, 0), False),
    ("army_arms_badge", "arms_badge", ["right_collar_tip"], (0, -3.0, -3.0), False),
    ("nylon_belt", "belt", ["belt_center"], (0, -3.0, -16.0), False),
]

# Optional accessories randomly included/excluded per render, to get
# combinatorial coverage the way real dressed soldiers vary (some wear
# the arms badge + belt, some don't have every accessory equipped in a
# given photo, etc.) — mirrors dress_accessory_resolver's mandatory vs
# optional split.
OPTIONAL_ACCESSORY_NAMES = {"army_arms_badge"}


def load_anchors() -> dict:
    return json.loads((REPO_ROOT / "cv-service" / "rules" / "anchors.male.json").read_text())["anchors"]


@dataclass
class RenderCamera:
    """Camera pose expressed the way this render script controls it —
    NOT the same object as `calibration.pnp_solve.CameraSolution`
    (that one is *recovered* from a photo; this one is *chosen* to
    render one)."""

    azimuth_deg: float
    elevation_deg: float
    distance_m: float
    target_height_m: float

    def pose_matrix(self) -> np.ndarray:
        az, el = math.radians(self.azimuth_deg), math.radians(self.elevation_deg)
        x = self.distance_m * math.sin(az) * math.cos(el)
        z = self.distance_m * math.cos(az) * math.cos(el)
        y = self.target_height_m + self.distance_m * math.sin(el)

        eye = np.array([x, y, z])
        target = np.array([0, self.target_height_m, 0])
        up = np.array([0, 1, 0])
        forward = (target - eye)
        forward /= np.linalg.norm(forward)
        right = np.cross(forward, up)
        right /= np.linalg.norm(right)
        true_up = np.cross(right, forward)

        pose = np.eye(4)
        pose[:3, 0] = right
        pose[:3, 1] = true_up
        pose[:3, 2] = -forward
        pose[:3, 3] = eye
        return pose


def _camera_intrinsics(yfov_rad: float) -> tuple[float, float, float]:
    focal = (IMAGE_HEIGHT / 2) / math.tan(yfov_rad / 2)
    return focal, IMAGE_WIDTH / 2, IMAGE_HEIGHT / 2


def _project(points_world: np.ndarray, cam_pose: np.ndarray, focal: float, cx: float, cy: float) -> np.ndarray:
    """Project world-space points through the camera used for
    rendering — glTF/OpenGL camera convention (camera looks down -Z in
    its own frame), matching `pyrender`'s own convention so the boxes
    line up with the pixels it actually rendered."""
    cam_to_world = cam_pose
    world_to_cam = np.linalg.inv(cam_to_world)
    points_h = np.hstack([points_world, np.ones((len(points_world), 1))])
    points_cam = (world_to_cam @ points_h.T).T[:, :3]

    x, y, z = points_cam[:, 0], points_cam[:, 1], points_cam[:, 2]
    z_safe = np.where(z < -1e-6, z, -1e-6)  # camera looks down -Z
    px = cx + focal * (x / -z_safe)
    py = cy - focal * (y / -z_safe)
    return np.stack([px, py], axis=1)


def _load_accessory_mesh(stem: str) -> trimesh.Trimesh | None:
    path = ACCESSORY_DIR / f"{stem}.glb"
    if not path.exists():
        return None
    return trimesh.load(str(path), force="mesh")


def _place_accessory(mesh: trimesh.Trimesh, anchor: dict, offset_cm: tuple[float, float, float], mirror_x: bool) -> trimesh.Trimesh:
    placed = mesh.copy()
    if mirror_x:
        placed.apply_transform(np.diag([-1, 1, 1, 1]))
    dx, dy, dz = (v / 100.0 for v in offset_cm)
    translation = np.array([anchor["x"] + dx, anchor["y"] + dy, anchor["z"] + dz])
    placed.apply_translation(translation)
    return placed


def render_one(
    index: int,
    anchors: dict,
    rng: random.Random,
) -> dict | None:
    body_scene = trimesh.load(str(BODY_GLB), force="scene")
    body_only = trimesh.Scene()
    for node_name in body_scene.graph.nodes_geometry:
        transform, geom_name = body_scene.graph[node_name]
        geom = body_scene.geometry[geom_name]
        # keep only real body/uniform-shaped meshes; skip the 1cm
        # marker cubes injected at socket positions (see
        # tool/inject_sockets.py) so they don't render as visible bumps
        if geom.vertices.shape[0] > 16:
            world_geom = geom.copy()
            world_geom.apply_transform(transform)
            body_only.add_geometry(world_geom, node_name=node_name)

    placed_accessories: list[tuple[str, str, trimesh.Trimesh]] = []
    for stem, category, anchor_names, offset_cm, _ in ACCESSORY_SPECS:
        if stem in OPTIONAL_ACCESSORY_NAMES and rng.random() < 0.4:
            continue  # randomly omit — combinatorial coverage
        base_mesh = _load_accessory_mesh(stem)
        if base_mesh is None:
            continue
        for i, anchor_name in enumerate(anchor_names):
            anchor = anchors.get(anchor_name)
            if anchor is None:
                continue
            mirror = i == 1  # second entry in a paired anchor list = right side
            placed = _place_accessory(base_mesh, anchor, offset_cm, mirror_x=mirror)
            body_only.add_geometry(placed, node_name=f"{stem}_{anchor_name}")
            placed_accessories.append((stem, category, placed))

    pyrender_scene = pyrender.Scene.from_trimesh_scene(body_only, bg_color=rng.choice(
        [[200, 200, 200, 255], [150, 160, 170, 255], [230, 225, 215, 255]]
    ))

    camera = RenderCamera(
        azimuth_deg=rng.uniform(-25, 25),
        elevation_deg=rng.uniform(-5, 8),
        distance_m=rng.uniform(2.1, 2.7),
        target_height_m=rng.uniform(0.95, 1.05),
    )
    cam_pose = camera.pose_matrix()
    yfov = math.radians(rng.uniform(42, 55))
    pyrender_scene.add(pyrender.PerspectiveCamera(yfov=yfov), pose=cam_pose)
    pyrender_scene.add(
        pyrender.DirectionalLight(color=[255, 255, 255], intensity=rng.uniform(2.2, 3.6)),
        pose=cam_pose,
    )

    renderer = pyrender.OffscreenRenderer(IMAGE_WIDTH, IMAGE_HEIGHT)
    try:
        color, _depth = renderer.render(pyrender_scene)
    finally:
        renderer.delete()

    focal, cx, cy = _camera_intrinsics(yfov)
    annotations = []
    for stem, category, mesh in placed_accessories:
        px = _project(mesh.vertices, cam_pose, focal, cx, cy)
        x1, y1 = px[:, 0].min(), px[:, 1].min()
        x2, y2 = px[:, 0].max(), px[:, 1].max()
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(IMAGE_WIDTH, x2), min(IMAGE_HEIGHT, y2)
        if x2 <= x1 or y2 <= y1:
            continue  # projected fully outside frame
        annotations.append(
            {
                "category": stem,
                "category_group": category,
                "bbox": [round(float(x1), 1), round(float(y1), 1), round(float(x2 - x1), 1), round(float(y2 - y1), 1)],
            }
        )

    return {
        "image": PIL.Image.fromarray(color).convert("RGB"),
        "annotations": annotations,
        "camera": {
            "azimuth_deg": round(camera.azimuth_deg, 2),
            "elevation_deg": round(camera.elevation_deg, 2),
            "distance_m": round(camera.distance_m, 2),
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n-renders", type=int, default=20)
    parser.add_argument("--out", type=str, default="cv-service/synthetic_data/army_no3_male_v1")
    parser.add_argument("--seed", type=int, default=0)
    args = parser.parse_args()

    out_dir = REPO_ROOT / args.out
    images_dir = out_dir / "images"
    images_dir.mkdir(parents=True, exist_ok=True)

    anchors = load_anchors()
    rng = random.Random(args.seed)

    coco = {"images": [], "annotations": [], "categories": []}
    category_ids = {stem: i for i, (stem, *_r) in enumerate(ACCESSORY_SPECS)}
    coco["categories"] = [{"id": i, "name": stem} for stem, i in category_ids.items()]

    ann_id = 0
    written = 0
    for i in range(args.n_renders):
        result = render_one(i, anchors, rng)
        if result is None:
            continue
        filename = f"render_{i:05d}.jpg"
        result["image"].save(images_dir / filename, quality=92)
        image_id = i
        coco["images"].append(
            {"id": image_id, "file_name": filename, "width": IMAGE_WIDTH, "height": IMAGE_HEIGHT, "camera": result["camera"]}
        )
        for ann in result["annotations"]:
            coco["annotations"].append(
                {
                    "id": ann_id,
                    "image_id": image_id,
                    "category_id": category_ids[ann["category"]],
                    "category_group": ann["category_group"],
                    "bbox": ann["bbox"],
                }
            )
            ann_id += 1
        written += 1
        if (i + 1) % 10 == 0:
            print(f"rendered {i + 1}/{args.n_renders}")

    (out_dir / "annotations.json").write_text(json.dumps(coco, indent=2))
    print(f"wrote {written} images + {ann_id} annotations to {out_dir}")


if __name__ == "__main__":
    main()
