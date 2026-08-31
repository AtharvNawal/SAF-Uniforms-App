"""Regenerates `rendered_army_no3_male_front.jpg` — an offscreen render
of the actual reference body GLB, front-on, ~2.4m back, chest height.
Used as the one real (if synthetic) test photo for the full-pipeline
test in `test_report_pipeline.py`, since no real soldier photo exists
yet to test against.

Needs `pyrender` + `PyOpenGL`, which are NOT in `requirements.txt` —
they're a fixture-authoring-time dependency only, not a runtime one for
the service itself. Install ad hoc to regenerate:

    .venv-tools/bin/pip install pyrender
    .venv-tools/bin/python cv-service/tests/fixtures/generate_fixture.py
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import PIL.Image
import pyrender
import trimesh

REPO_ROOT = Path(__file__).resolve().parents[3]
BODY_GLB = REPO_ROOT / "assets" / "3d" / "bodies" / "male_apose.glb"
OUT_PATH = Path(__file__).resolve().parent / "rendered_army_no3_male_front.jpg"


def main() -> None:
    scene_tm = trimesh.load(str(BODY_GLB), force="scene")
    scene = pyrender.Scene.from_trimesh_scene(scene_tm, bg_color=[200, 200, 200, 255])

    # ~2.4m back, roughly chest height, looking straight at the body —
    # matches the architecture memo's capture-protocol assumption
    # (front, mid-torso up, arms relaxed at sides).
    camera_pose = np.array(
        [
            [1, 0, 0, 0.0],
            [0, 1, 0, 1.0],
            [0, 0, 1, 2.4],
            [0, 0, 0, 1.0],
        ]
    )
    scene.add(pyrender.PerspectiveCamera(yfov=np.radians(50)), pose=camera_pose)
    scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=3.0), pose=camera_pose)

    renderer = pyrender.OffscreenRenderer(800, 1200)
    color, _depth = renderer.render(scene)
    PIL.Image.fromarray(color).convert("RGB").save(OUT_PATH, quality=95)
    print(f"wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
