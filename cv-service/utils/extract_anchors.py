"""Extract the canonical body-anchor coordinate system from a reference GLB.

The reference body GLBs under `assets/3d/bodies/` already carry 15 named
scene-graph nodes ("sockets") at fixed 3D positions — head_top, collar
tips, chest pockets, shoulder seams, sleeve-upper points, belt_center,
ankles, and foot-tops. They were authored for `composeUniformModel` (see
`functions/src/glb_compose.ts`), which parents accessory meshes under
them at render time.

This script gives those same sockets a second job: read their world-space
translation once, offline, and freeze them into a small static JSON file
("anchors.<variant>.json") that the compliance-inspection pipeline treats
as its ruler. Nothing downstream re-parses a GLB per request — every
inspection reads this file instead.

Run standalone:

    .venv-tools/bin/python cv-service/utils/extract_anchors.py \
        --glb assets/3d/bodies/male_apose.glb \
        --out cv-service/rules/anchors.male.json

Or import `extract_anchors(glb_path)` directly (used by the test suite).
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import NamedTuple

import trimesh

# The 15 sockets `tool/inject_sockets.py` writes into every reference body
# GLB. Keep this list in sync with that script and with the socket names
# `glb_compose.ts` looks up by name.
SOCKET_NAMES = [
    "head_top",
    "cap_band_front",
    "left_collar_tip",
    "right_collar_tip",
    "left_chest_pocket",
    "right_chest_pocket",
    "left_shoulder_seam",
    "right_shoulder_seam",
    "left_sleeve_upper",
    "right_sleeve_upper",
    "belt_center",
    "left_ankle",
    "right_ankle",
    "left_foot_top",
    "right_foot_top",
]


class Point3(NamedTuple):
    x: float
    y: float
    z: float

    def as_dict(self) -> dict[str, float]:
        return {"x": round(self.x, 4), "y": round(self.y, 4), "z": round(self.z, 4)}


def _midpoint(a: Point3, b: Point3, *, force_x: float | None = None) -> Point3:
    return Point3(
        x=force_x if force_x is not None else (a.x + b.x) / 2,
        y=(a.y + b.y) / 2,
        z=(a.z + b.z) / 2,
    )


def extract_anchors(glb_path: str | Path) -> dict:
    """Load `glb_path` and return the canonical anchor record.

    Raises `KeyError` (via trimesh) if any expected socket is missing —
    fail loudly rather than silently ship an incomplete anchor file, since
    every rule in `rules/army_no3_male.json` assumes the full set exists.
    """
    scene = trimesh.load(str(glb_path), force="scene")

    raw: dict[str, Point3] = {}
    for name in SOCKET_NAMES:
        transform, _geom_name = scene.graph.get(name)
        translation = transform[:3, 3]
        raw[name] = Point3(*(float(v) for v in translation))

    chest_center = _midpoint(
        raw["left_chest_pocket"], raw["right_chest_pocket"], force_x=0.0
    )

    anchors = {name: {**point.as_dict(), "source": "socket"} for name, point in raw.items()}
    anchors["chest_center"] = {
        **chest_center.as_dict(),
        "source": "derived: midpoint(left_chest_pocket, right_chest_pocket), x forced to symmetry plane",
    }

    # Standing-height proxy: top-of-head marker, not the mesh bounding box
    # (head_top sits slightly above the scalp to leave room for headdress
    # offsets — see accessory `render_logic.offset_y_cm` for beret/turban).
    reference_height_m = raw["head_top"].y

    return {
        "source_glb": str(glb_path),
        "reference_height_m": round(reference_height_m, 4),
        "coordinate_frame": {
            "units": "meters",
            "origin": "feet at y=0, x/z centered on the body's vertical symmetry axis",
            "up_axis": "y",
            "forward_axis": "+z (body-front)",
        },
        "anchors": anchors,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--glb", required=True, help="Path to the reference body GLB")
    parser.add_argument(
        "--out", required=True, help="Output path for the anchors JSON file"
    )
    args = parser.parse_args()

    result = extract_anchors(args.glb)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2) + "\n")

    print(f"Wrote {len(result['anchors'])} anchors to {out_path}")
    print(f"reference_height_m = {result['reference_height_m']}")


if __name__ == "__main__":
    main()
