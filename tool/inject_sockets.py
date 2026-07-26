#!/usr/bin/env python3
"""Inject the Phase-2 merger contract into a raw body GLB.

Generative 3D services (Tripo3D, Meshy, Luma, etc.) export a single
merged mesh with one auto-generated material. The Phase-2
`composeUniformModel` Cloud Function expects each body GLB to expose:

  - 11 named empty/marker nodes the merger looks up by name and
    re-parents accessories under (`head_top`, `cap_band_front`,
    `left/right_collar_tip`, `left/right_chest_pocket`,
    `left/right_shoulder_seam`, `left/right_sleeve_upper`, `belt_center`).
  - A mesh node named `name_tag` carrying a material `name_tag_mat`
    with a base-color texture — the bake target for `sharp` to
    composite the user's surname onto.
  - Empty `head` and `hair` marker nodes so the merger's
    `detachNodeByName(doc, "hair")` step can succeed when a headdress
    accessory is mounted (see LIMITATIONS below).

This script reads an arbitrary input GLB, computes proportional socket
positions from its bounding box, and writes out a contract-compliant
GLB that drops cleanly into the existing pipeline:

    .venv-tools/bin/python tool/inject_sockets.py \\
        --in  assets/3d/bodies/male_apose.glb \\
        --out assets/3d/bodies/male_apose_compliant.glb

    # Or overwrite the input in place:
    .venv-tools/bin/python tool/inject_sockets.py \\
        --in assets/3d/bodies/male_apose.glb --in-place

LIMITATIONS

  - **Hair.** Tripo / Meshy / etc. fuse hair into the head mesh. The
    injected `hair` node is an empty marker, so the merger's hair-detach
    step succeeds structurally but the visible hair stays. Headdress
    accessories will sit on top of the hair rather than replacing it.
    For demo and dev work this is acceptable; for production a
    Blender-authored split per `docs/3d-body-authoring.md §3` is the
    real fix.

  - **Up axis.** glTF standard is +Y up. Most Tripo exports display
    Y-up correctly because their root node carries a 90° rotation that
    trimesh's `force="mesh"` bakes during load. If you ever see a
    body that's clearly lying down after running this script (i.e. the
    final Y-extent is much smaller than X- or Z-extent), pass
    `--up-axis z` to apply a 90° rotation around X before normalisation.
    Pass `--up-axis -z` if `z` produces an upside-down body.

    **Don't** trust raw vertex extents from gltf-transform's
    `getAttribute('POSITION').getMin/Max()` to decide this — those
    return mesh-local extents and ignore any node-level rotation the
    GLB carries. trimesh's post-bake bounds (which this script uses
    internally) are the truth.

  - **Body orientation (front-facing).** The script assumes the
    rotated body faces +Z (matches the placeholder generator's
    convention). Pass `--facing -z` if the Tripo body's chest pockets
    / name-tag end up on its back instead of the front.

  - **Anatomy heuristics.** Socket positions are computed from the
    bounding box, not from anatomic landmark detection. For
    proportional humans this works well; for stylised or non-standard
    figures the chest/sleeve sockets may be slightly off. Open the
    output in https://gltf-viewer.donmccurdy.com/ to eyeball.

  - **Scale + position.** Generative-3D services export at arbitrary
    scales (Tripo emits ~100m figures centred on origin; Meshy uses
    its own units). The script normalises the input to a target height
    (default 1.75m for male / 1.65m for female & maternity) and
    translates so the feet sit at y=0 — matching the rest of the
    pipeline's assumption that GLBs are real-world-scale, +Y up,
    standing on the floor. Override with `--target-height <metres>` if
    you want a custom scale.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image
from trimesh.visual.material import PBRMaterial


# ---------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------


def _socket_marker() -> trimesh.Trimesh:
    """5mm transparent cube used as a socket marker node.

    The merger only cares that a node with the right *name* exists at
    the right world position; the geometry itself is irrelevant. We use
    a tiny invisible cube so the GLB still parses cleanly through
    `@gltf-transform/core` (which rejects empty primitives) without
    being visually obtrusive in development viewers.
    """
    cube = trimesh.creation.box(extents=[0.005, 0.005, 0.005])
    mat = PBRMaterial(
        name="socket_marker",
        baseColorFactor=(0.0, 0.0, 0.0, 0.0),
        metallicFactor=0.0,
        roughnessFactor=1.0,
        alphaMode="BLEND",
    )
    cube.visual = trimesh.visual.TextureVisuals(material=mat)
    return cube


def _name_tag_mesh() -> trimesh.Trimesh:
    """A 10×2.5cm flat patch carrying the `name_tag_mat` material.

    The base-color texture is a 1024×256 light-grey PNG — Phase 2's
    `sharp` step composites the user's surname onto this texture before
    re-uploading the merged GLB. Texture size is fixed per the artist
    contract (`docs/3d-body-authoring.md`); shrinking it would soften
    the rendered text.
    """
    box = trimesh.creation.box(extents=[0.10, 0.025, 0.005])
    blank = Image.new("RGB", (1024, 256), (245, 245, 245))
    mat = PBRMaterial(
        name="name_tag_mat",
        baseColorTexture=blank,
        baseColorFactor=(1.0, 1.0, 1.0, 1.0),
        metallicFactor=0.0,
        roughnessFactor=0.6,
    )
    # Per-vertex UVs covering [0,1] on the X/Y plane so the texture
    # rasterises across the full visible face. Phase 2's bake doesn't
    # care about UV layout — it replaces the texture image bytes
    # wholesale — but a sane UV is required for the GLB to render at
    # all.
    uvs = np.zeros((len(box.vertices), 2), dtype=np.float32)
    xs = box.vertices[:, 0]
    ys = box.vertices[:, 1]
    uvs[:, 0] = (xs - xs.min()) / max(xs.max() - xs.min(), 1e-6)
    uvs[:, 1] = (ys - ys.min()) / max(ys.max() - ys.min(), 1e-6)
    box.visual = trimesh.visual.TextureVisuals(uv=uvs, material=mat)
    return box


# ---------------------------------------------------------------------------
# Bounding-box analysis → socket positions
# ---------------------------------------------------------------------------


def _socket_positions(
    bounds: np.ndarray, facing_z: float
) -> dict[str, tuple[float, float, float]]:
    """Compute world-space socket positions from the body's bounding box.

    Args:
      bounds: trimesh's `[(xmin, ymin, zmin), (xmax, ymax, zmax)]`. We
        don't assume the body is centred at origin or sitting on the
        floor — we work entirely in absolute world coordinates.
      facing_z: +1.0 if the body faces +Z, -1.0 if it faces -Z. The
        chest pockets / name tag / cap_band_front sit on the facing
        side; the script flips them when this is -1.

    Returns a dict mapping each of the 11 contract socket names to its
    `(x, y, z)` world position. Proportions are derived from human
    anatomy ratios so the output is reasonable across body sizes.
    """
    xmin, ymin, zmin = bounds[0]
    xmax, ymax, zmax = bounds[1]
    cx = (xmin + xmax) / 2.0
    cz = (zmin + zmax) / 2.0
    height = ymax - ymin
    width = xmax - xmin
    # Anatomic landmarks as fractions of total body height. Sourced
    # from the docs/3d-body-authoring.md placeholder proportions and
    # cross-checked against Vitruvian-style anthropometric ratios.
    head_top_y = ymax + 0.03
    crown_y = ymax - height * 0.02
    chin_y = ymax - height * 0.13
    shoulder_y = ymin + height * 0.83
    chest_y = ymin + height * 0.72
    waist_y = ymin + height * 0.58
    upper_arm_y = ymin + height * 0.78
    # X offsets — ANATOMIC CONSTANTS scaled by height, NOT bbox fractions.
    #
    # Tripo / Meshy / Luma bodies in A-pose or T-pose carry extended arms
    # that balloon the bbox X-extent to 1.5–1.6m (arm span) while the
    # actual shirt seams sit much closer to the torso centre. Using
    # `width * 0.22` for chest pockets would land the socket at the
    # armpit level (~35cm from centre on a 1.6m-wide figure).
    #
    # Real adult male anatomy at ~1.75m reference height:
    #   collar tip / chest pocket centre:  ±0.095m from centre
    #   shoulder seam (sleeve attachment): ±0.220m from centre
    #   mid-bicep / sleeve_upper socket:   ±0.280m from centre
    #
    # These scale linearly with body height (taller → broader).
    height_scale = height / 1.75
    half_chest = 0.095 * height_scale        # collar tips + chest pockets
    half_shoulder = 0.220 * height_scale     # shoulder seams (epaulettes / lanyard)
    half_arm_outer = 0.280 * height_scale    # mid-bicep sleeve (rank chevrons)
    # Front/back depth — ANATOMIC CONSTANTS, not bbox fractions.
    #
    # The bbox depth is unreliable on Tripo / Meshy bodies because A-pose
    # arms balloon the Z extent (~0.64m for an adult-sized Tripo body, vs
    # ~0.25m for the actual torso). Using `body_depth * 0.55` would land
    # chest features ~25cm in front of the shirt surface — a very visible
    # bug. Real adult human torso depth is ~0.25m, so the chest surface
    # sits ~0.10–0.13m in front of the body centroid regardless of how
    # tall the figure is. We fix the offsets at sensible anatomic values
    # and let X (shoulder span) + Y (height) keep their bbox-derived
    # logic since those DO scale linearly with body size.
    # Tuned empirically against a Tripo male body via vertex sampling
    # (`tool/probe_body_surface.py` if you ever need to repeat this):
    # the body's frontal silhouette p95 is at ~z=+0.16 at chest level,
    # ~z=+0.08 at forehead, ~z=+0.10 at neck, ~z=+0.18 at belt. The
    # shoulder Z extends much wider (~±0.18) because of A-pose arm
    # geometry, but the CHEVRON-bearing shoulder seam itself sits on
    # the front of the upper arm at z≈+0.10.
    #
    # Sockets for accessories that should sit on the body's frontal
    # surface go at slightly past those p95 values so the accessory
    # geometry reads cleanly on top of the shirt rather than half-
    # embedded.
    chest_z = 0.16 * facing_z          # chest_pocket, collar_tip, belt
    head_front_z = 0.10 * facing_z     # cap_band_front
    shoulder_front_z = 0.10 * facing_z # shoulder_seam (chevrons / epaulettes)
    # Foot sockets — placed at floor level with a modest forward bias
    # so shoes mounted there read as resting on the body's instep
    # rather than embedded in the calf. ankle Y ≈ 10 cm up from the
    # floor (anatomic ankle height); foot_top Y ≈ 3 cm (top of the
    # instep, where a low-cut shoe sits). X = ±10 cm (normal stance).
    foot_x = 0.10
    ankle_y = ymin + 0.10
    foot_top_y = ymin + 0.03
    foot_front_z = 0.08 * facing_z
    return {
        "head_top": (cx, head_top_y, cz),
        "cap_band_front": (cx, crown_y, cz + head_front_z),
        "left_collar_tip": (cx - half_chest, chin_y - 0.02, cz + chest_z),
        "right_collar_tip": (cx + half_chest, chin_y - 0.02, cz + chest_z),
        "left_chest_pocket": (cx - half_chest, chest_y, cz + chest_z),
        "right_chest_pocket": (cx + half_chest, chest_y, cz + chest_z),
        "left_shoulder_seam": (cx - half_shoulder, shoulder_y, cz + shoulder_front_z),
        "right_shoulder_seam": (cx + half_shoulder, shoulder_y, cz + shoulder_front_z),
        "left_sleeve_upper": (cx - half_arm_outer, upper_arm_y, cz + shoulder_front_z),
        "right_sleeve_upper": (cx + half_arm_outer, upper_arm_y, cz + shoulder_front_z),
        "belt_center": (cx, waist_y, cz + chest_z),
        # Feet — paired sockets (merger resolves the generic library
        # anchors `ankle` / `foot_top` to both sides via mirroring).
        "left_ankle": (cx - foot_x, ankle_y, cz),
        "right_ankle": (cx + foot_x, ankle_y, cz),
        "left_foot_top": (cx - foot_x, foot_top_y, cz + foot_front_z),
        "right_foot_top": (cx + foot_x, foot_top_y, cz + foot_front_z),
    }


def _name_tag_position(
    bounds: np.ndarray, facing_z: float
) -> tuple[float, float, float]:
    """Place the name-tag mesh on the wearer's RIGHT chest pocket.

    SAF doctrine: surname plate on the wearer's RIGHT chest pocket.
    Convention (confirmed empirically across all Tripo bodies): world
    +X = wearer's LEFT side. So wearer's right = NEGATIVE X offset.

    All offsets are anatomic constants scaled by height so they stay
    correct regardless of whether the body's bbox width is dominated by
    extended arms (Tripo A-pose) or by the torso alone.

    Z-offset is a constant 0.165m (chest surface 0.16m + 5mm nudge)
    to avoid z-fighting with the chest pocket socket at 0.16m.
    """
    xmin, ymin, _, xmax, ymax, _ = (*bounds[0], *bounds[1])
    cx = (xmin + xmax) / 2.0
    cz = (bounds[0][2] + bounds[1][2]) / 2.0
    height = ymax - ymin
    height_scale = height / 1.75
    return (
        cx - 0.075 * height_scale,       # wearer's right pocket (−X)
        ymin + height * 0.765,            # 1.36m on a 1.78m figure (above pocket centre)
        cz + 0.165 * facing_z,           # chest surface + 5mm z-fight nudge
    )


# ---------------------------------------------------------------------------
# Scene assembly
# ---------------------------------------------------------------------------


def _normalise_to_human_scale(
    body: trimesh.Trimesh, target_height_m: float
) -> None:
    """In-place scale + translate of a single Trimesh.

    The pipeline's downstream consumers (model_viewer_plus camera
    framing, accessory GLB offsets in cm, the per-user composed GLB
    cached at ~700 KB) all assume real-world scale: +Y up, feet at
    y≈0, head at y≈height. Tripo / Meshy / Luma exports violate this
    by emitting at arbitrary scales and centred on the origin. We
    normalise here so the rest of the script can reason in metres.

    Operates on a single concatenated Trimesh (with all original node
    transforms already baked in by `trimesh.load(..., force="mesh")`)
    so vertex-level scale + translate land at the right world
    positions without fighting any latent scene-graph transforms.
    """
    bounds = body.bounds
    height = bounds[1][1] - bounds[0][1]
    if height < 1e-6:
        raise SystemExit(
            "Input body has effectively zero height along +Y. The GLB "
            "may be using +Z up — re-export with +Y up."
        )
    scale = target_height_m / height
    body.apply_scale(scale)

    # Re-read bounds (now in metres) and translate so feet sit at
    # y=0 and the body is centred at x=0, z=0.
    bounds = body.bounds
    cx = (bounds[0][0] + bounds[1][0]) / 2.0
    cz = (bounds[0][2] + bounds[1][2]) / 2.0
    ymin = bounds[0][1]
    body.apply_translation([-cx, -ymin, -cz])


def inject(
    input_path: Path,
    output_path: Path,
    facing: str = "+z",
    target_height_m: float = 1.75,
    up_axis: str = "y",
    rotate_y_deg: float = 0.0,
    socket_overrides: dict[str, tuple[float, float, float]] | None = None,
) -> None:
    """
    ``socket_overrides`` maps socket names to absolute world-space
    ``(x, y, z)`` positions in **metres** (after normalisation).  Any
    socket listed here replaces the bbox-proportional value computed by
    ``_socket_positions()``.  Use this when the bbox heuristic places a
    socket noticeably off the actual geometry — measure the correct
    coordinates in https://gltf-viewer.donmccurdy.com/ (or Blender) and
    pass them via ``--socket-overrides overrides.json``.

    Example ``overrides.json``::

        {
          "left_chest_pocket":  [-0.085, 1.35, 0.16],
          "right_chest_pocket": [ 0.085, 1.35, 0.16],
          "belt_center":        [ 0.000, 1.10, 0.16]
        }
    """
    facing_z = 1.0 if facing.lower() in ("+z", "z", "z+") else -1.0

    # Load with `force="mesh"` so trimesh concatenates everything into
    # a single Trimesh with all original node transforms baked into
    # the vertex coordinates. This sidesteps any scene-graph transform
    # the source GLB carried (Tripo emits scenes with non-identity
    # node matrices) — once flattened we have a single coordinate
    # frame to reason about.
    body = trimesh.load(str(input_path), process=False, force="mesh")
    if not isinstance(body, trimesh.Trimesh):
        raise SystemExit(
            f"Unexpected loader output for {input_path}: "
            f"{type(body).__name__}. Expected a single Trimesh after "
            f"concatenation. The input may not contain renderable geometry."
        )

    # Rotate Z-up exports onto the +Y up convention before any
    # normalisation. The rotation maps the originally-vertical axis
    # to +Y so the rest of the script (height detection, foot placement,
    # socket positioning) reasons about a real upright figure.
    import trimesh.transformations as tt

    if up_axis.lower() == "z":
        # Tripo HD's typical convention: head at +Z, feet at -Z. Rotate
        # -90° around X so +Z → +Y.
        print("Rotating Z-up → Y-up (-90° around X axis).")
        body.apply_transform(tt.rotation_matrix(-np.pi / 2, [1, 0, 0]))
    elif up_axis.lower() == "-z":
        # Inverse Tripo convention: head at -Z, feet at +Z. Rotate +90°
        # around X so -Z → +Y.
        print("Rotating -Z-up → Y-up (+90° around X axis).")
        body.apply_transform(tt.rotation_matrix(np.pi / 2, [1, 0, 0]))
    elif up_axis.lower() != "y":
        raise SystemExit(f"Unknown --up-axis value: {up_axis}")

    if rotate_y_deg != 0.0:
        angle = np.radians(rotate_y_deg)
        print(f"Rotating {rotate_y_deg:+.1f}° around Y axis.")
        body.apply_transform(tt.rotation_matrix(angle, [0, 1, 0]))

    raw_height = body.bounds[1][1] - body.bounds[0][1]
    # Always normalise. Tripo HD and similar generators emit bodies at
    # arbitrary scale (sometimes ~100m, sometimes ~1m as a child-height
    # mesh-local placeholder). Skipping normalisation when the body
    # happens to land between 0.5m and 3m would silently leave a
    # child-sized soldier in the pipeline.
    print(
        f"Normalising scale: input height {raw_height:.3f}m → "
        f"{target_height_m:.3f}m, recentring x/z and dropping feet to y=0."
    )
    _normalise_to_human_scale(body, target_height_m)

    # Wrap the (possibly normalised) body in a fresh Scene we own.
    # Adding the sockets / name_tag / head / hair as named sibling
    # nodes is now straightforward: each geometry becomes its own node
    # with the requested name.
    scene = trimesh.Scene()
    scene.add_geometry(body, geom_name="body", node_name="body")

    bounds = body.bounds  # Real-world-scale bounds, post-normalisation.

    # Note: detection of pre-existing contract nodes is no longer
    # meaningful here because `force="mesh"` collapsed every named
    # node in the source down to a single concatenated `body` mesh.
    # The injection proceeds idempotently; running this script twice
    # produces the same output.

    print(f"Input  : {input_path}")
    print(
        f"Bounds : x[{bounds[0][0]:+.3f}, {bounds[1][0]:+.3f}]  "
        f"y[{bounds[0][1]:+.3f}, {bounds[1][1]:+.3f}]  "
        f"z[{bounds[0][2]:+.3f}, {bounds[1][2]:+.3f}]"
    )
    print(
        f"Size   : height={bounds[1][1] - bounds[0][1]:.3f}m  "
        f"width={bounds[1][0] - bounds[0][0]:.3f}m  "
        f"depth={bounds[1][2] - bounds[0][2]:.3f}m  "
        f"facing={'+Z' if facing_z > 0 else '-Z'}"
    )

    # IMPORTANT: positions go on the **scene-graph node transform**, not
    # baked into vertex coords. The Phase-2 merger re-parents accessories
    # under sockets via `socket.addChild(accessoryRoot)` and inherits the
    # socket's world transform — if we baked positions into vertices, the
    # node transform stays identity and `socket.getWorldTranslation()`
    # returns (0,0,0), causing every accessory to pile up at world origin.
    #
    # trimesh's `add_geometry(..., transform=T)` writes T as the node's
    # local matrix. We keep each marker geometry centred on its own
    # origin and let the node transform place it in the world.
    import trimesh.transformations as tt

    # 1. Inject socket markers as node transforms (vertices stay at
    #    origin; node carries the world position).
    #    Operator-supplied overrides replace bbox-proportional values for
    #    named sockets so placement can be fine-tuned without editing source.
    computed_positions = _socket_positions(bounds, facing_z)
    if socket_overrides:
        for name, pos in socket_overrides.items():
            if name in computed_positions:
                print(
                    f"  override: {name} {computed_positions[name]} → {pos}"
                )
                computed_positions[name] = tuple(pos)  # type: ignore[assignment]
            else:
                print(
                    f"  WARNING: --socket-overrides key '{name}' is not a "
                    f"recognised socket name; ignored."
                )
    for name, pos in computed_positions.items():
        T = tt.translation_matrix(list(pos))
        scene.add_geometry(
            _socket_marker(), geom_name=name, node_name=name, transform=T
        )

    # 2. Inject the name_tag mesh + name_tag_mat material at the right
    #    chest, again via node transform.
    name_tag_T = tt.translation_matrix(
        list(_name_tag_position(bounds, facing_z))
    )
    scene.add_geometry(
        _name_tag_mesh(),
        geom_name="name_tag",
        node_name="name_tag",
        transform=name_tag_T,
    )

    # 3. Inject empty head + hair markers (so detachNodeByName succeeds
    #    structurally — see LIMITATIONS in the module docstring).
    xmin, ymin, _ = bounds[0]
    xmax, ymax, _ = bounds[1]
    cx = (xmin + xmax) / 2.0
    head_y = ymax - (ymax - ymin) * 0.07
    head_T = tt.translation_matrix([cx, head_y, 0.0])
    for name in ("head", "hair"):
        scene.add_geometry(
            _socket_marker(),
            geom_name=name,
            node_name=name,
            transform=head_T,
        )

    # Export.
    output_path.parent.mkdir(parents=True, exist_ok=True)
    scene.export(str(output_path))

    print(f"Output : {output_path}  ({output_path.stat().st_size:,} bytes)")
    sockets_count = len(_socket_positions(bounds, facing_z))
    print(
        f"Injected: {sockets_count} sockets + name_tag(name_tag_mat) + head + hair "
        f"= {sockets_count + 3} named nodes."
    )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Inject Phase-2 merger contract nodes (sockets + name_tag + "
            "head/hair markers) into a raw body GLB."
        ),
    )
    parser.add_argument(
        "--in",
        dest="input",
        required=True,
        type=Path,
        help="Path to the input body GLB (e.g. a Tripo / Meshy export).",
    )
    out_grp = parser.add_mutually_exclusive_group(required=True)
    out_grp.add_argument(
        "--out",
        dest="output",
        type=Path,
        help="Path to write the contract-compliant GLB.",
    )
    out_grp.add_argument(
        "--in-place",
        action="store_true",
        help="Overwrite the input file with the contract-compliant version.",
    )
    parser.add_argument(
        "--facing",
        choices=["+z", "-z"],
        default="+z",
        help=(
            "Which way the body faces in world space. Default +z matches "
            "the placeholder generator's convention; pass -z if your "
            "Tripo export looks 'backwards' (chest pockets / name tag "
            "appearing on the back) after a first try."
        ),
    )
    parser.add_argument(
        "--up-axis",
        choices=["y", "z", "-z"],
        default="y",
        help=(
            "Which axis is 'up' in the input GLB. Default 'y' (glTF "
            "standard, no rotation) — works for most Tripo / Meshy / "
            "Luma exports because trimesh bakes their root-node "
            "rotation on load. Use 'z' only if you've confirmed the "
            "OUTPUT (not the raw gltf-transform vertex extents) shows "
            "the body lying flat with Y-extent < other axes. Use '-z' "
            "if 'z' produces an upside-down body."
        ),
    )
    parser.add_argument(
        "--target-height",
        type=float,
        default=1.75,
        metavar="METRES",
        help=(
            "Target body height in metres after normalisation. Default "
            "1.75 (male). Use 1.65 for female / maternity to match the "
            "placeholder generator's proportions."
        ),
    )
    parser.add_argument(
        "--rotate-y",
        dest="rotate_y",
        type=float,
        default=0.0,
        metavar="DEG",
        help=(
            "Rotate the body mesh by DEG degrees around the Y axis before "
            "socket injection and normalisation. Useful when the Tripo export "
            "faces ±X instead of +Z. Typical values: +90 (faces -X → +Z), "
            "-90 (faces +X → +Z), +180 (faces +Z → -Z / mirror)."
        ),
    )
    parser.add_argument(
        "--socket-overrides",
        dest="socket_overrides",
        type=Path,
        default=None,
        metavar="JSON_FILE",
        help=(
            "Optional JSON file mapping socket names to absolute [x, y, z] "
            "world positions in metres. Overrides the bbox-proportional "
            "heuristic for the listed sockets. Useful when a specific socket "
            "is visibly off after a first injection — measure the correct "
            "position in https://gltf-viewer.donmccurdy.com/ or Blender, "
            "then supply it here without touching source code. "
            "Example: {\"left_chest_pocket\": [-0.085, 1.35, 0.16]}"
        ),
    )
    args = parser.parse_args()

    if not args.input.is_file():
        print(f"ERROR: input file not found: {args.input}", file=sys.stderr)
        return 1

    socket_overrides: dict[str, tuple[float, float, float]] | None = None
    if args.socket_overrides is not None:
        import json
        if not args.socket_overrides.is_file():
            print(
                f"ERROR: --socket-overrides file not found: {args.socket_overrides}",
                file=sys.stderr,
            )
            return 1
        raw_overrides = json.loads(args.socket_overrides.read_text())
        socket_overrides = {
            k: (float(v[0]), float(v[1]), float(v[2]))
            for k, v in raw_overrides.items()
        }
        print(f"Socket overrides loaded: {list(socket_overrides.keys())}")

    output = args.input if args.in_place else args.output
    inject(
        args.input,
        output,
        facing=args.facing,
        target_height_m=args.target_height,
        up_axis=args.up_axis,
        rotate_y_deg=args.rotate_y,
        socket_overrides=socket_overrides,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
