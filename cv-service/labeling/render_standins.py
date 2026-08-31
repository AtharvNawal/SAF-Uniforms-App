"""Renders 3 synthetic stand-in photos into `cv-service/data/real_photos/`,
used ONLY because zero real photographs exist anywhere in this repository
(confirmed by search — see the plan file this script belongs to). These
are NOT real photos and every label produced from them sets
`is_synthetic_stand_in: true`.

Same offscreen-render technique as `tests/fixtures/generate_fixture.py`
(bare reference body GLB, `pyrender`), at 3 different camera
distances/heights/light intensities so the set exercises both a
fully-in-frame case and a cropped one (for the anchor "not visible" path).
Also computes each anchor's true projected pixel position from the same
camera pose/intrinsics used to render, and writes it alongside the image
as `<stem>.anchors.json` — a ground-truth "answer key" this milestone's
own labeling pass (`label_standins.py`) reads instead of guessing pixel
coordinates by eye.

Needs `pyrender` + `PyOpenGL` (fixture-authoring-time only, not a service
runtime dependency — see `generate_fixture.py`'s docstring for why).

    .venv-tools/bin/python cv-service/labeling/render_standins.py
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
import PIL.Image
import pyrender
import trimesh

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "cv-service"))

from utils.extract_anchors import extract_anchors  # noqa: E402

BODY_GLB = REPO_ROOT / "assets" / "3d" / "bodies" / "male_apose.glb"
OUT_DIR = REPO_ROOT / "cv-service" / "data" / "real_photos" / "standin01"
YFOV_DEG = 50.0
WIDTH, HEIGHT = 800, 1200

# (subject_id, angle, lighting, camera_z_distance_m, camera_y_height_m, light_intensity)
VARIANTS = [
    ("standin01", "front", "indoor_bright", 2.4, 1.0, 4.0),
    ("standin02", "front", "indoor_dim", 1.7, 1.35, 1.2),  # closer + higher -> crops feet
    ("standin03", "front", "outdoor_overcast", 3.2, 0.95, 2.0),
]


def project(point_xyz: tuple[float, float, float], camera_translation: tuple[float, float, float]) -> tuple[float, float, bool]:
    """Projects a world point into pixel space for a camera at
    `camera_translation` with identity rotation, looking down -Z (the
    same convention `generate_fixture.py` places its camera in)."""
    tx, ty, tz = camera_translation
    cam_x = point_xyz[0] - tx
    cam_y = point_xyz[1] - ty
    cam_z = point_xyz[2] - tz
    depth = -cam_z
    f = HEIGHT / (2 * math.tan(math.radians(YFOV_DEG) / 2))
    u = WIDTH / 2 + f * (cam_x / depth)
    v = HEIGHT / 2 - f * (cam_y / depth)
    visible = depth > 0 and 0 <= u < WIDTH and 0 <= v < HEIGHT
    return u, v, visible


def render_variant(subject_id: str, angle: str, lighting: str, distance: float, height: float, intensity: float, anchors: dict) -> None:
    scene_tm = trimesh.load(str(BODY_GLB), force="scene")
    scene = pyrender.Scene.from_trimesh_scene(scene_tm, bg_color=[200, 200, 200, 255])

    camera_translation = (0.0, height, distance)
    camera_pose = np.array(
        [
            [1, 0, 0, camera_translation[0]],
            [0, 1, 0, camera_translation[1]],
            [0, 0, 1, camera_translation[2]],
            [0, 0, 0, 1],
        ]
    )
    scene.add(pyrender.PerspectiveCamera(yfov=math.radians(YFOV_DEG)), pose=camera_pose)
    scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=intensity), pose=camera_pose)

    renderer = pyrender.OffscreenRenderer(WIDTH, HEIGHT)
    color, _depth = renderer.render(scene)
    renderer.delete()

    out_dir = REPO_ROOT / "cv-service" / "data" / "real_photos" / subject_id
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = f"{subject_id}__{angle}__{lighting}"
    image_path = out_dir / f"{stem}.jpg"
    PIL.Image.fromarray(color).convert("RGB").save(image_path, quality=95)

    projected = {}
    for name, point in anchors.items():
        if name == "chest_center":
            continue  # derived, not a clickable socket
        u, v, visible = project((point["x"], point["y"], point["z"]), camera_translation)
        projected[name] = {"x_px": round(u, 1), "y_px": round(v, 1), "visible": visible}

    answer_key_path = out_dir / f"{stem}.anchors.json"
    answer_key_path.write_text(json.dumps(projected, indent=2) + "\n")
    print(f"wrote {image_path} + {answer_key_path}")


def main() -> None:
    if not BODY_GLB.exists():
        raise SystemExit(f"reference body GLB not found: {BODY_GLB}")
    anchors = extract_anchors(BODY_GLB)["anchors"]
    for subject_id, angle, lighting, distance, height, intensity in VARIANTS:
        render_variant(subject_id, angle, lighting, distance, height, intensity, anchors)


if __name__ == "__main__":
    main()
