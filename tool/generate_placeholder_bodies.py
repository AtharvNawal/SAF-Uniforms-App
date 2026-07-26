#!/usr/bin/env python3
"""Generate placeholder humanoid GLBs for the SAF Uniforms 3D pipeline.

These are NOT production assets — they're stand-ins that let the
`composeUniformModel` pipeline render *something* recognisable in the
GhostScreen viewport while the real MakeHuman + Blender authoring is
in progress (see docs/3d-body-authoring.md for the recipe). When real
GLBs land, drop them in `assets/3d/bodies/` with the same filenames
and re-run `tool/upload_models.py` — no other code changes needed.

Outputs four GLBs in `assets/3d/`:

    bodies/male_apose.glb              # standard male, trousers
    bodies/female_apose.glb            # female with skirt
    bodies/female_maternity_apose.glb  # maternity blouse + trousers
    placeholder.glb                    # a single grey cube (CF fallback)

Each body is a Scene of named geometries (head, torso, arm_left_upper,
trouser_left, etc.) so future merge code can target specific parts.
The figure is anatomically rough but visually distinguishable per
variant — broad shoulders for male, skirt for female, rounded belly
for maternity. Roughly 1.65–1.75m tall, A-pose, neutral colours
(white shirt, dark trousers/skirt, dark beret, black shoes) so the
silhouette reads as "soldier in uniform" without claiming to be
doctrine-accurate.

Usage:
    python3 -m venv .venv-tools
    .venv-tools/bin/pip install trimesh numpy
    .venv-tools/bin/python tool/generate_placeholder_bodies.py
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
import trimesh
from PIL import Image
from trimesh.visual.material import PBRMaterial

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_ROOT = REPO_ROOT / "assets" / "3d"
BODIES_DIR = OUT_ROOT / "bodies"


# ---------------------------------------------------------------------------
# Material palette — kept deliberately neutral so the placeholder reads as
# "uniformed soldier" without misrepresenting any specific branch's livery.
# ---------------------------------------------------------------------------

COLORS = {
    "skin": (0.86, 0.72, 0.58, 1.0),
    "hair": (0.16, 0.12, 0.09, 1.0),
    "shirt": (0.94, 0.94, 0.94, 1.0),
    "trouser": (0.30, 0.32, 0.36, 1.0),
    "skirt": (0.30, 0.32, 0.36, 1.0),
    "belt": (0.10, 0.10, 0.11, 1.0),
    "shoe": (0.06, 0.06, 0.06, 1.0),
    "beret": (0.22, 0.24, 0.27, 1.0),
    "name_tag": (0.04, 0.04, 0.04, 1.0),
    "medal_ribbon": (0.62, 0.16, 0.16, 1.0),
    "placeholder": (0.55, 0.58, 0.62, 1.0),
}


def _coloured(geom: trimesh.Trimesh, key: str) -> trimesh.Trimesh:
    """Apply a flat PBR material to a primitive."""
    mat = PBRMaterial(
        name=key,
        baseColorFactor=COLORS[key],
        metallicFactor=0.0,
        roughnessFactor=0.85,
    )
    geom.visual = trimesh.visual.TextureVisuals(material=mat)
    return geom


def _name_tag_textured(geom: trimesh.Trimesh) -> trimesh.Trimesh:
    """Apply a textured PBR material (`name_tag_mat`) carrying a 1024×256
    white base-color texture so the Phase-2 server bake step can swap the
    image bytes in place. The merger looks up the material by the exact
    name `name_tag_mat`; do not rename without updating the CF."""
    blank = Image.new("RGB", (1024, 256), (245, 245, 245))
    mat = PBRMaterial(
        name="name_tag_mat",
        baseColorTexture=blank,
        baseColorFactor=(1.0, 1.0, 1.0, 1.0),
        metallicFactor=0.0,
        roughnessFactor=0.6,
    )
    # Flat unwrap: the visible face of the patch maps to the full texture.
    # Trimesh boxes ship with default UVs that cover [0,1] per face, which
    # is good enough for the placeholder — the artist deliveries will
    # provide a proper UV island for the patch face only.
    uvs = np.zeros((len(geom.vertices), 2), dtype=np.float32)
    for i, v in enumerate(geom.vertices):
        uvs[i, 0] = (v[0] - geom.vertices[:, 0].min()) / max(
            geom.vertices[:, 0].max() - geom.vertices[:, 0].min(), 1e-6
        )
        uvs[i, 1] = (v[1] - geom.vertices[:, 1].min()) / max(
            geom.vertices[:, 1].max() - geom.vertices[:, 1].min(), 1e-6
        )
    geom.visual = trimesh.visual.TextureVisuals(uv=uvs, material=mat)
    return geom


def _socket_marker() -> trimesh.Trimesh:
    """A near-zero-volume cube used as a named scene node (a 'socket').

    The Phase-2 server merger looks up sockets by node name and re-parents
    accessory roots under them, so the socket only needs to *exist as a
    named node at the right local origin* — the geometry itself is
    irrelevant. We use a 5 mm cube so the GLB still parses cleanly through
    `@gltf-transform/core` (which rejects empty primitives) without being
    visually obtrusive in development viewers."""
    marker = trimesh.creation.box(extents=[0.005, 0.005, 0.005])
    mat = PBRMaterial(
        name="socket_marker",
        baseColorFactor=(0.0, 0.0, 0.0, 0.0),  # alpha 0 — invisible
        metallicFactor=0.0,
        roughnessFactor=1.0,
        alphaMode="BLEND",
    )
    marker.visual = trimesh.visual.TextureVisuals(material=mat)
    return marker


# ---------------------------------------------------------------------------
# Socket positions per body variant (in metres, world-space).
#
# These mirror the parent-relative offsets in docs/3d-body-authoring.md but
# expressed as world-space positions on the *placeholder* skeleton (which
# has no real bones — we just place the markers where the real artist rig
# would put them once it lands). Real artist GLBs will satisfy the same
# contract via parented-bone offsets; either way the merger only needs to
# look up the named nodes and trust their world transforms.
# ---------------------------------------------------------------------------


def _socket_positions(p: dict) -> dict[str, tuple[float, float, float]]:
    h = p["height"]
    head_r = p["head_r"]
    torso_top = p["torso_top"]
    torso_bot = p["torso_bot"]
    torso_d = p["torso_d"]
    shoulder_w = p["shoulder_w"]
    arm_top = p["arm_top"]
    arm_bot = p["arm_bot"]
    return {
        # Head
        "head_top": (0.0, h + 0.03, 0.0),
        "cap_band_front": (0.0, h - head_r * 0.4, 0.10),
        # Collar
        "left_collar_tip": (-0.06, torso_top - 0.05, torso_d / 2 + 0.005),
        "right_collar_tip": (0.06, torso_top - 0.05, torso_d / 2 + 0.005),
        # Chest pockets / sleeve seams / belt
        "left_chest_pocket": (-0.09, torso_top - 0.20, torso_d / 2 + 0.005),
        "right_chest_pocket": (0.09, torso_top - 0.20, torso_d / 2 + 0.005),
        "left_shoulder_seam": (-(shoulder_w / 2 - 0.02), arm_top, 0.0),
        "right_shoulder_seam": (shoulder_w / 2 - 0.02, arm_top, 0.0),
        "left_sleeve_upper": (
            -(shoulder_w / 2 + 0.04),
            (arm_top + arm_bot) / 2 + 0.05,
            0.0,
        ),
        "right_sleeve_upper": (
            shoulder_w / 2 + 0.04,
            (arm_top + arm_bot) / 2 + 0.05,
            0.0,
        ),
        "belt_center": (0.0, torso_bot - 0.02, torso_d / 2 + 0.005),
        # Feet — paired sockets (merger maps the generic library anchors
        # `ankle` and `foot_top` to both sides via mirror_left_right).
        # Placed at floor level (the bodies stand on y=0 in the inject
        # pipeline; the procedural placeholder generator has its leg
        # bottoms at y ≈ 0.08). For both, X = ±10 cm = standard stance.
        "left_ankle": (-0.10, 0.10, 0.0),
        "right_ankle": (0.10, 0.10, 0.0),
        "left_foot_top": (-0.10, 0.03, 0.08),
        "right_foot_top": (0.10, 0.03, 0.08),
    }


def _y_cylinder(radius: float, height: float) -> trimesh.Trimesh:
    """Cylinder oriented along Y (default trimesh cylinder is Z-aligned)."""
    cyl = trimesh.creation.cylinder(radius=radius, height=height, sections=24)
    cyl.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    return cyl


def _y_cone_apex_up(base_radius: float, height: float) -> trimesh.Trimesh:
    """Cone with the wide base on the XZ plane and the apex pointing up.

    trimesh's default cone has base on XY, apex at +Z. We rotate it so
    +Z maps to +Y (apex up) and the base sits on the XZ plane.
    """
    cone = trimesh.creation.cone(radius=base_radius, height=height, sections=24)
    cone.apply_transform(
        trimesh.transformations.rotation_matrix(-np.pi / 2, [1, 0, 0])
    )
    return cone


# ---------------------------------------------------------------------------
# Per-variant proportions (very rough, in metres). Tuned against the SAF
# doctrine reference PDF figures so the silhouettes read correctly:
#  - male: broad shoulders, trousers
#  - female: narrower frame, knee-length skirt
#  - female_maternity: rounded torso (Picture B-7 reference), trousers
# ---------------------------------------------------------------------------


def _proportions(variant: str) -> dict:
    if variant == "male":
        return dict(
            height=1.75,
            shoulder_w=0.46,
            torso_d=0.22,
            torso_top=1.42,
            torso_bot=0.95,
            arm_top=1.40,
            arm_bot=0.75,
            hip_w=0.40,
            head_r=0.11,
            wear="trousers",
            maternity=False,
        )
    if variant == "female":
        return dict(
            height=1.65,
            shoulder_w=0.40,
            torso_d=0.20,
            torso_top=1.34,
            torso_bot=0.90,
            arm_top=1.32,
            arm_bot=0.72,
            hip_w=0.36,
            head_r=0.10,
            wear="skirt",
            maternity=False,
        )
    if variant == "female_maternity":
        return dict(
            height=1.65,
            shoulder_w=0.40,
            torso_d=0.20,
            torso_top=1.34,
            torso_bot=0.90,
            arm_top=1.32,
            arm_bot=0.72,
            hip_w=0.40,
            head_r=0.10,
            wear="trousers",
            maternity=True,
        )
    raise ValueError(f"Unknown variant: {variant}")


# ---------------------------------------------------------------------------
# Body assembly
# ---------------------------------------------------------------------------


def _build_humanoid(variant: str) -> trimesh.Scene:
    p = _proportions(variant)
    parts: list[tuple[str, trimesh.Trimesh]] = []

    # --- Head + face hint ---
    head = trimesh.creation.icosphere(radius=p["head_r"], subdivisions=3)
    head.apply_scale([1.0, 1.08, 0.95])
    head.apply_translation([0, p["height"] - p["head_r"], 0])
    parts.append(("head", _coloured(head, "skin")))

    # Hair dome — ladies get a slightly wider one, hinting at tied-back hair
    hair_r = p["head_r"] * (1.05 if variant.startswith("female") else 1.02)
    hair = trimesh.creation.icosphere(radius=hair_r, subdivisions=2)
    hair.apply_scale([1.0, 0.55, 1.0])
    hair.apply_translation([0, p["height"] - p["head_r"] * 0.4, -0.005])
    parts.append(("hair", _coloured(hair, "hair")))

    # --- Beret (slight tilt — SAF wears it canted) ---
    beret = trimesh.creation.icosphere(radius=p["head_r"] * 1.22, subdivisions=2)
    beret.apply_scale([1.0, 0.34, 1.05])
    beret.apply_transform(
        trimesh.transformations.rotation_matrix(np.deg2rad(8), [0, 0, 1])
    )
    beret.apply_translation([0.025, p["height"] + 0.015, 0])
    parts.append(("beret", _coloured(beret, "beret")))

    # --- Neck ---
    neck = _y_cylinder(0.045, 0.10)
    neck.apply_translation([0, p["torso_top"] + 0.05, 0])
    parts.append(("neck", _coloured(neck, "skin")))

    # --- Torso ---
    if p["maternity"]:
        # Maternity gets a chest box + rounded belly bulge so the
        # silhouette reads correctly even at low resolution.
        chest_h = 0.30
        chest = trimesh.creation.box(
            extents=[p["shoulder_w"], chest_h, p["torso_d"]]
        )
        chest.apply_translation([0, p["torso_top"] - chest_h / 2, 0])
        parts.append(("chest", _coloured(chest, "shirt")))

        belly = trimesh.creation.icosphere(radius=0.21, subdivisions=3)
        belly.apply_scale([1.05, 0.85, 1.10])
        belly.apply_translation(
            [0, p["torso_top"] - chest_h - 0.10, p["torso_d"] * 0.18]
        )
        parts.append(("belly", _coloured(belly, "shirt")))
    else:
        torso = trimesh.creation.box(
            extents=[
                p["shoulder_w"],
                p["torso_top"] - p["torso_bot"],
                p["torso_d"],
            ]
        )
        torso.apply_translation(
            [0, (p["torso_top"] + p["torso_bot"]) / 2, 0]
        )
        parts.append(("torso", _coloured(torso, "shirt")))

    # --- Shoulders (smooth out the box-corner) ---
    for side, x_sign in (("left", -1), ("right", 1)):
        s = trimesh.creation.icosphere(radius=0.085, subdivisions=2)
        s.apply_translation([x_sign * (p["shoulder_w"] / 2 - 0.02), p["arm_top"], 0])
        parts.append((f"shoulder_{side}", _coloured(s, "shirt")))

    # --- Arms ---
    arm_len = p["arm_top"] - p["arm_bot"]
    for side, x_sign in (("left", -1), ("right", 1)):
        x_off = x_sign * (p["shoulder_w"] / 2 - 0.02)
        # Slight outward A-pose angle (~10°)
        tilt = np.deg2rad(10) * x_sign
        upper = _y_cylinder(0.055, arm_len)
        upper.apply_translation([x_off, (p["arm_top"] + p["arm_bot"]) / 2, 0])
        T = trimesh.transformations.rotation_matrix(
            tilt, [0, 0, 1], [x_off, p["arm_top"], 0]
        )
        upper.apply_transform(T)
        parts.append((f"arm_{side}", _coloured(upper, "shirt")))

        # Hand at the end of the arm
        hand_y = p["arm_bot"] + 0.02
        hand_x = x_off + np.sin(tilt) * arm_len / 2
        hand = trimesh.creation.icosphere(radius=0.05, subdivisions=2)
        hand.apply_translation([hand_x, hand_y, 0])
        parts.append((f"hand_{side}", _coloured(hand, "skin")))

    # --- Belt ---
    belt = trimesh.creation.box(
        extents=[p["hip_w"] + 0.04, 0.04, p["torso_d"] + 0.02]
    )
    belt.apply_translation([0, p["torso_bot"], 0])
    parts.append(("belt", _coloured(belt, "belt")))

    # --- Legs / skirt ---
    if p["wear"] == "skirt":
        # Knee-length tapered skirt: narrow at waist, wider at hem
        skirt_h = 0.45
        skirt = _y_cone_apex_up(
            base_radius=p["hip_w"] / 2 + 0.06, height=skirt_h
        )
        skirt.apply_translation([0, p["torso_bot"] - skirt_h, 0])
        parts.append(("skirt", _coloured(skirt, "skirt")))

        # Stockinged calves below the hem
        leg_top_y = p["torso_bot"] - skirt_h - 0.02
        leg_bot_y = 0.08
        for side, x_sign in (("left", -1), ("right", 1)):
            leg = _y_cylinder(0.05, leg_top_y - leg_bot_y)
            leg.apply_translation(
                [x_sign * 0.08, (leg_top_y + leg_bot_y) / 2, 0]
            )
            parts.append((f"leg_{side}", _coloured(leg, "skin")))
    else:
        # Trousers
        leg_top_y = p["torso_bot"] - 0.02
        leg_bot_y = 0.08
        for side, x_sign in (("left", -1), ("right", 1)):
            trouser = trimesh.creation.box(
                extents=[0.18, leg_top_y - leg_bot_y, 0.20]
            )
            trouser.apply_translation(
                [x_sign * 0.10, (leg_top_y + leg_bot_y) / 2, 0]
            )
            parts.append((f"trouser_{side}", _coloured(trouser, "trouser")))

    # --- Shoes ---
    for side, x_sign in (("left", -1), ("right", 1)):
        shoe = trimesh.creation.box(extents=[0.10, 0.05, 0.24])
        shoe.apply_translation([x_sign * 0.10, 0.04, 0.05])
        parts.append((f"shoe_{side}", _coloured(shoe, "shoe")))

    # --- Uniform hints: name-tag patch + 3-row medal ribbon ---
    # The name-tag mesh is now textured (1024×256 white base-color) so the
    # Phase-2 server can `sharp`-composite the user's surname onto the
    # texture and patch it back into the GLB without geometry changes.
    chest_y = p["torso_top"] - 0.18
    chest_z = p["torso_d"] / 2 + 0.001  # nudge in front of the torso to avoid z-fighting

    name_tag = trimesh.creation.box(extents=[0.10, 0.025, 0.005])
    name_tag.apply_translation([0.10, chest_y, chest_z])
    parts.append(("name_tag", _name_tag_textured(name_tag)))

    for i in range(3):
        ribbon = trimesh.creation.box(extents=[0.10, 0.012, 0.004])
        ribbon.apply_translation(
            [-0.10, chest_y + 0.018 - i * 0.014, chest_z]
        )
        parts.append((f"medal_ribbon_{i + 1}", _coloured(ribbon, "medal_ribbon")))

    # --- Named socket markers (Phase 2 attachment contract) ---
    # Each marker is a 5mm invisible cube the merger looks up by node
    # name and re-parents accessory roots under. Position MUST live on
    # the scene-graph node transform, NOT baked into the cube's vertex
    # coordinates — `socket.addChild(accessoryRoot)` inherits the
    # socket's world transform, so an identity-transform socket would
    # cluster every accessory at the world origin. We collect socket
    # positions separately and emit them via `add_geometry(..., transform=T)`
    # below.
    socket_marker_specs: list[tuple[str, tuple[float, float, float]]] = []
    for socket_name, (sx, sy, sz) in _socket_positions(p).items():
        socket_marker_specs.append((socket_name, (sx, sy, sz)))

    import trimesh.transformations as tt

    scene = trimesh.Scene()
    for name, geom in parts:
        scene.add_geometry(geom, geom_name=name, node_name=name)
    for name, (sx, sy, sz) in socket_marker_specs:
        T = tt.translation_matrix([sx, sy, sz])
        scene.add_geometry(
            _socket_marker(), geom_name=name, node_name=name, transform=T
        )
    return scene


def _build_placeholder() -> trimesh.Scene:
    """Tiny grey cube — used as a safety fallback if any specific
    body / uniform / accessory GLB is missing in Storage."""
    cube = trimesh.creation.box(extents=[0.30, 0.30, 0.30])
    cube.apply_translation([0, 0.15, 0])
    scene = trimesh.Scene()
    scene.add_geometry(
        _coloured(cube, "placeholder"),
        geom_name="placeholder",
        node_name="placeholder",
    )
    return scene


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    BODIES_DIR.mkdir(parents=True, exist_ok=True)

    targets = [
        ("male", BODIES_DIR / "male_apose.glb"),
        ("female", BODIES_DIR / "female_apose.glb"),
        ("female_maternity", BODIES_DIR / "female_maternity_apose.glb"),
    ]
    for variant, out_path in targets:
        scene = _build_humanoid(variant)
        scene.export(out_path)
        print(f"  ✓ {out_path.relative_to(REPO_ROOT)}  ({out_path.stat().st_size:,} bytes)")

    placeholder_path = OUT_ROOT / "placeholder.glb"
    _build_placeholder().export(placeholder_path)
    print(
        f"  ✓ {placeholder_path.relative_to(REPO_ROOT)}  "
        f"({placeholder_path.stat().st_size:,} bytes)"
    )

    print("\nDone. Next: tool/upload_models.py to push these to Firebase Storage.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
