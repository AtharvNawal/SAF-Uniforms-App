"""Fits per-anchor bias corrections for `pose/anchor_mapping.py`.

BlazePose landmarks and the reference body's doctrine sockets mean
different things: a landmark is a *joint centre* (hip joint, shoulder
joint), a socket is a *garment feature* (belt buckle, shoulder seam,
collar tip, pocket). The interpolation heuristics in `anchor_mapping.py`
were hand-set, and measured against known-camera renders they carry
large, *systematic* offsets — e.g. hip-midpoint lands ~0.37 shoulder
widths below the belt buckle, shoulder joints ~0.24 below the seam.
Systematic means correctable.

This script renders the reference body from N randomised near-frontal
cameras (capture-protocol range), projects every socket through the
exact render camera (ground truth, no labelling), runs the real pose →
anchor mapping, and fits the mean offset of each anchor in a
**body-aligned frame** — `outward` (away from the body midline; mirrored
for left/right) and `down` (along the torso axis) — normalised by the
detected shoulder width, so the correction scales with subject size and
rotates with camera roll. Output: `pose/anchor_offsets.male.json`,
applied by `anchor_mapping.map_pose_to_anchors` when present.

Caveat, stated plainly: fitted on synthetic renders of one body. The
offsets are anatomical (joint centre vs seam), so they should transfer to
real people approximately, not exactly — re-fit against real labelled
photos when they exist (same script shape, different image source).

    .venv-tools/bin/python cv-service/pose/calibrate_anchor_offsets.py --n 40
    .venv-tools/bin/python cv-service/pose/calibrate_anchor_offsets.py --n 60 --uniform rsaf_no4_female

`--uniform` (default `army_no3_male`) picks the reference body, anchor file
and output file from `uniforms.py`. RSAF No.4 uses the operator's dressed
figures (`training/rsaf_figure.py`), fully dressed — the landmarks are
fitted against the uniform as worn. ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import sys
import tempfile
from pathlib import Path

import cv2
import numpy as np

CV_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(CV_ROOT))
sys.path.insert(0, str(CV_ROOT / "training"))

import uniforms  # noqa: E402
from pose.anchor_mapping import body_frame, estimate_anchor_pose  # noqa: E402
from pose.detect_person import detect_person  # noqa: E402

OUT_PATH = CV_ROOT / "pose" / "anchor_offsets.male.json"
WIDTH, HEIGHT = 800, 1200


def _project(point: np.ndarray, cam_pose: np.ndarray, focal: float) -> tuple[float, float] | None:
    p_cam = np.linalg.inv(cam_pose) @ np.append(point, 1.0)
    if p_cam[2] >= -1e-6:
        return None
    return (WIDTH / 2 + focal * p_cam[0] / -p_cam[2], HEIGHT / 2 - focal * p_cam[1] / -p_cam[2])


def main() -> None:
    import pyrender
    import generate_segmentation_dataset_v2 as gen

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--n", type=int, default=40)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--bare", action="store_true",
                        help="render the bare body (the original fit); default renders it dressed in randomised "
                             "No.3 accessories, since a beret or belt shifts where pose landmarks land")
    parser.add_argument("--uniform", default="army_no3_male", choices=sorted(uniforms.UNIFORMS))
    args = parser.parse_args()
    spec = uniforms.UNIFORMS[args.uniform]
    out_path = spec.offsets_path
    figure = None
    if args.uniform.startswith("rsaf_no4_"):
        import rsaf_figure
        from rules.rule_engine import load_anchors

        anchors = load_anchors(spec.anchors_path)
        figure = rsaf_figure.load_figure(args.uniform.rsplit("_", 1)[1])
        body = None
    else:
        anchors = gen.load_anchors()
        body = gen.load_body_parts_v2(anchors)
    rng = random.Random(args.seed)
    samples: dict[str, list[tuple[float, float]]] = {}

    with tempfile.TemporaryDirectory() as tmp:
        for i in range(args.n):
            cam_pose, yfov = gen._camera_pose(rng, wide=False)
            focal = (HEIGHT / 2) / math.tan(yfov / 2)
            scene = pyrender.Scene(bg_color=[rng.randint(120, 230)] * 3 + [255], ambient_light=[0.3] * 3)
            if figure is not None:
                meshes = [m for m, _ in rsaf_figure.build_scene(figure, rng, removals={}, sikh=False, cadet=False)]
            else:
                meshes = list(body["rgb"])
                if not args.bare:
                    meshes += [m for _, _, _, m in gen.placed_accessories(gen.choose_accessories(rng), anchors)]
            for mesh in meshes:
                scene.add(pyrender.Mesh.from_trimesh(mesh))
            scene.add(pyrender.PerspectiveCamera(yfov=yfov, aspectRatio=WIDTH / HEIGHT), pose=cam_pose)
            scene.add(pyrender.DirectionalLight(color=[255, 255, 255], intensity=3.0), pose=cam_pose)
            renderer = pyrender.OffscreenRenderer(WIDTH, HEIGHT)
            try:
                rgb, _ = renderer.render(scene)
            finally:
                renderer.delete()
            path = f"{tmp}/calib_{i:03d}.jpg"
            cv2.imwrite(path, cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR))

            detection = detect_person(path)
            estimate = estimate_anchor_pose(path, person_box=detection.person, apply_offsets=False)
            frame = body_frame(estimate)
            if frame is None:
                continue
            origin, outward_x, down, shoulder_width = frame
            for name, est in estimate.items():
                if est["x_px"] is None or name not in anchors:
                    continue
                truth = _project(np.array([anchors[name][k] for k in "xyz"]), cam_pose, focal)
                if truth is None or not (0 <= truth[0] < WIDTH and 0 <= truth[1] < HEIGHT):
                    continue
                delta = np.array(truth) - np.array([est["x_px"], est["y_px"]])
                side = 1.0 if name.startswith("left_") else -1.0 if name.startswith("right_") else 0.0
                outward = float(delta @ outward_x) * (side if side else 1.0) / shoulder_width
                samples.setdefault(name, []).append((outward, float(delta @ down) / shoulder_width))
            print(f"  {i + 1}/{args.n}", flush=True)

    offsets = {}
    for name, values in sorted(samples.items()):
        arr = np.array(values)
        offsets[name] = {
            "outward": round(float(np.median(arr[:, 0])), 4),
            "down": round(float(np.median(arr[:, 1])), 4),
            "residual_std": round(float(np.linalg.norm(arr.std(axis=0))), 4),
            "n": len(arr),
        }
    source = (f"assets/3d/bodies/{args.uniform}.glb, fully dressed" if figure is not None else
              f"assets/3d/bodies/male_apose.glb, {'bare' if args.bare else 'dressed in randomised No.3 accessories'}")
    out_path.write_text(json.dumps({
        "fitted_on": f"{args.n} synthetic near-frontal renders of {source} (seed {args.seed})",
        "uniform_type": args.uniform,
        "units": "fraction of detected shoulder width; outward = away from body midline (mirrored per side, "
                 "image +x for midline anchors); down = along the torso axis",
        "real_photos_used": 0,
        "offsets": offsets,
    }, indent=2) + "\n")
    for name, o in offsets.items():
        print(f"{name:22s} outward {o['outward']:+.3f} down {o['down']:+.3f}  residual_std {o['residual_std']:.3f}  n={o['n']}")
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
