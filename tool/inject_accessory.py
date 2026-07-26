#!/usr/bin/env python3
"""Normalise a raw artist GLB (Tripo / Meshy / Luma export) into a
contract-compliant accessory GLB.

The Phase-2 merger (`composeUniformModel`) attaches accessories under
named body sockets and applies the per-doctrine `render_logic.offset_*_cm`
translation. For that math to land on the body the way SAF doctrine
expects, every accessory GLB must be:

  - **Sized realistically** (~ 5 cm widest dim for cap badges, ~ 7 cm for
    sleeve insignia, ~ 20 cm for headdress, etc.).
  - **Oriented so the visible face points along +Z**, because the body's
    front-side sockets sit on the body's +Z half-space.
  - **Centred on the origin**, because the merger applies the cm offsets
    AFTER the socket transform — if the geometry's centroid is off the
    origin, every accessory inherits that shift.

Generative-3D services emit at arbitrary scales (Tripo: ~ 1 m max dim),
arbitrary orientations (thin axis on whichever axis the artist stood the
mesh up on), and arbitrary centres. This tool fixes all three with a
single call so artist GLBs drop into `assets/3d/accessories/{id}.glb`
ready for upload.

USAGE:

    .venv-tools/bin/python tool/inject_accessory.py \\
        --in   assets/3d_raw/<source>.glb \\
        --out  assets/3d/accessories/<id>.glb \\
        --target-size 0.05

Per-category target sizes (use `--target-size` to override):

    cap_badge / cap_embellishment    ≈ 0.05 m
    arms_badge / vocation_badge      ≈ 0.06 m
    sleeve insignia (chevron stack)  ≈ 0.08 m
    epaulette                        ≈ 0.10 m (length along shoulder)
    headdress (beret / turban / hat) ≈ 0.20 m

Iteration knobs:

    --rotate-{x,y,z} DEG    apply a manual rotation AFTER auto-orient
                            (useful when the badge faces -Z and you want
                            +Z: pass `--rotate-y 180`)
    --no-auto-orient        skip the auto-rotate-thin-axis-to-Z step
                            (useful when the source is already correctly
                            oriented and you only want scale + recentre)

CONVENTIONS:

  - Output is GLB (binary glTF), single scene, single root node named
    `"accessory"`. No skeletal rig — accessories are static.
  - Geometry is centred so the accessory's centroid is at (0, 0, 0). The
    merger applies the cm offsets from `render_logic.offset_*_cm`, and a
    centred-at-origin accessory means a 0-offset accessory lands exactly
    on the socket; positive Y offset lifts it; etc.
  - Thin axis aligned with Z. The merger's front-side sockets put +Z on
    the body's front; aligning the accessory's thin axis with Z means
    the flat face of the accessory is the body-facing face.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import trimesh


REPO_ROOT = Path(__file__).resolve().parent.parent


# ---------------------------------------------------------------------------
# Auto-orient: rotate so the bbox's thin axis ends up aligned with Z.
# ---------------------------------------------------------------------------


def _auto_orient_thin_to_z(geom: trimesh.Trimesh) -> tuple[str, str]:
    """Rotate `geom` in place so the smallest bbox extent is along Z.

    Returns a `(detected_thin_axis, rotation_description)` tuple for
    logging. When the thin axis is already Z, no rotation is applied.
    Note: signs of axes don't matter for centred geometry — a 90° vs
    -90° rotation around the same axis lands the thin axis on +Z vs -Z
    respectively, and either is fine because we recentre at origin and
    let the user's `--rotate-y 180` flag flip front/back if the face is
    on the wrong side.
    """
    extents = geom.bounds[1] - geom.bounds[0]
    thin_axis_idx = int(np.argmin(extents))  # 0=X, 1=Y, 2=Z
    thin_axis = "xyz"[thin_axis_idx]

    import trimesh.transformations as tt

    if thin_axis == "x":
        # Rotate -90° around Y so +X → -Z (thin axis now Z).
        geom.apply_transform(tt.rotation_matrix(-np.pi / 2, [0, 1, 0]))
        return ("x", "-90° around Y")
    if thin_axis == "y":
        # Rotate +90° around X so +Y → +Z (thin axis now Z).
        geom.apply_transform(tt.rotation_matrix(np.pi / 2, [1, 0, 0]))
        return ("y", "+90° around X")
    return ("z", "no rotation (already Z-thin)")


# ---------------------------------------------------------------------------
# Manual override rotations.
# ---------------------------------------------------------------------------


def _apply_manual_rotations(
    geom: trimesh.Trimesh, rx_deg: float, ry_deg: float, rz_deg: float
) -> str:
    """Apply user-specified Euler rotations (in degrees) around X, Y, Z
    in that order. Returns a brief log description of what was applied."""
    import trimesh.transformations as tt

    parts: list[str] = []
    if abs(rx_deg) > 1e-6:
        geom.apply_transform(tt.rotation_matrix(np.deg2rad(rx_deg), [1, 0, 0]))
        parts.append(f"rotate-x {rx_deg:+.0f}°")
    if abs(ry_deg) > 1e-6:
        geom.apply_transform(tt.rotation_matrix(np.deg2rad(ry_deg), [0, 1, 0]))
        parts.append(f"rotate-y {ry_deg:+.0f}°")
    if abs(rz_deg) > 1e-6:
        geom.apply_transform(tt.rotation_matrix(np.deg2rad(rz_deg), [0, 0, 1]))
        parts.append(f"rotate-z {rz_deg:+.0f}°")
    return ", ".join(parts) if parts else "(none)"


# ---------------------------------------------------------------------------
# Scale + recentre.
# ---------------------------------------------------------------------------


def _scale_to_target(geom: trimesh.Trimesh, target_size_m: float) -> float:
    """Apply uniform scale so the largest of the three bbox extents equals
    `target_size_m`. Returns the applied scale factor."""
    extents = geom.bounds[1] - geom.bounds[0]
    max_extent = float(extents.max())
    if max_extent < 1e-9:
        raise SystemExit("Source mesh has near-zero size; can't scale.")
    scale = target_size_m / max_extent
    geom.apply_scale(scale)
    return scale


def _recentre_at_origin(geom: trimesh.Trimesh) -> tuple[float, float, float]:
    """Translate so the geometry's centroid (= bbox centre) sits at
    origin. Returns the applied translation as `(tx, ty, tz)` for log."""
    bounds = geom.bounds
    cx = (bounds[0][0] + bounds[1][0]) / 2.0
    cy = (bounds[0][1] + bounds[1][1]) / 2.0
    cz = (bounds[0][2] + bounds[1][2]) / 2.0
    geom.apply_translation([-cx, -cy, -cz])
    return (-cx, -cy, -cz)


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------


def inject(
    input_path: Path,
    output_path: Path,
    target_size_m: float,
    rotate_x_deg: float,
    rotate_y_deg: float,
    rotate_z_deg: float,
    auto_orient: bool,
) -> None:
    print(f"Input  : {input_path}  ({input_path.stat().st_size:,} bytes)")

    # Step 1 — load and bake all node transforms into vertex coords.
    geom = trimesh.load(str(input_path), force="mesh", process=False)
    if not isinstance(geom, trimesh.Trimesh):
        raise SystemExit(
            f"Loader returned {type(geom).__name__}; expected Trimesh after "
            f"force='mesh'. Source may not contain renderable geometry."
        )
    pre_extents = geom.bounds[1] - geom.bounds[0]
    print(
        f"  pre-bounds  : "
        f"x[{geom.bounds[0][0]:+.3f},{geom.bounds[1][0]:+.3f}] "
        f"y[{geom.bounds[0][1]:+.3f},{geom.bounds[1][1]:+.3f}] "
        f"z[{geom.bounds[0][2]:+.3f},{geom.bounds[1][2]:+.3f}]   "
        f"size=({pre_extents[0]:.3f},{pre_extents[1]:.3f},{pre_extents[2]:.3f}) m"
    )

    # Step 2 — auto-orient: thin axis → Z.
    if auto_orient:
        thin_axis, rot_desc = _auto_orient_thin_to_z(geom)
        print(f"  auto-orient : detected thin axis = {thin_axis.upper()}, applied {rot_desc}")
    else:
        print(f"  auto-orient : SKIPPED (--no-auto-orient)")

    # Step 3 — manual rotations (after auto-orient so they compose predictably).
    manual_desc = _apply_manual_rotations(
        geom, rotate_x_deg, rotate_y_deg, rotate_z_deg
    )
    print(f"  manual rot  : {manual_desc}")

    # Step 4 — scale uniformly to target_size.
    scale = _scale_to_target(geom, target_size_m)
    print(f"  scale       : ×{scale:.4f} → max-dim = {target_size_m:.3f} m")

    # Step 5 — recentre at origin.
    translation = _recentre_at_origin(geom)
    print(
        f"  recentre    : translated by "
        f"({translation[0]:+.4f}, {translation[1]:+.4f}, {translation[2]:+.4f})"
    )

    final_extents = geom.bounds[1] - geom.bounds[0]
    print(
        f"  post-bounds : "
        f"x[{geom.bounds[0][0]:+.3f},{geom.bounds[1][0]:+.3f}] "
        f"y[{geom.bounds[0][1]:+.3f},{geom.bounds[1][1]:+.3f}] "
        f"z[{geom.bounds[0][2]:+.3f},{geom.bounds[1][2]:+.3f}]   "
        f"size=({final_extents[0]:.3f},{final_extents[1]:.3f},{final_extents[2]:.3f}) m"
    )

    # Step 6 — wrap in a Scene and export. Single root node named
    # "accessory" so the merger's mergeDocuments + per-accessory attach
    # path picks it up cleanly (any name works; "accessory" is a clear
    # debugging hint when reading composed GLBs).
    scene = trimesh.Scene()
    scene.add_geometry(geom, geom_name="accessory", node_name="accessory")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    scene.export(str(output_path))
    print(f"Output : {output_path}  ({output_path.stat().st_size:,} bytes)")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Normalise a raw artist GLB (Tripo / Meshy / Luma export) into "
            "a contract-compliant accessory GLB: scale, orient (thin axis "
            "→ Z), recentre at origin, and export."
        ),
    )
    parser.add_argument(
        "--in",
        dest="input",
        required=True,
        type=Path,
        help="Path to the source GLB.",
    )
    parser.add_argument(
        "--out",
        dest="output",
        required=True,
        type=Path,
        help=(
            "Path to write the contract-compliant accessory GLB "
            "(canonically `assets/3d/accessories/<id>.glb`)."
        ),
    )
    parser.add_argument(
        "--target-size",
        type=float,
        default=0.05,
        metavar="METRES",
        help=(
            "Target size in metres for the LARGEST bbox extent after "
            "scaling. Default 0.05 (5 cm — appropriate for a cap badge). "
            "See module docstring for per-category recommended sizes."
        ),
    )
    parser.add_argument(
        "--rotate-x",
        type=float,
        default=0.0,
        metavar="DEG",
        help="Manual rotation around X axis (degrees), applied AFTER auto-orient.",
    )
    parser.add_argument(
        "--rotate-y",
        type=float,
        default=0.0,
        metavar="DEG",
        help=(
            "Manual rotation around Y axis (degrees), applied AFTER auto-orient. "
            "Pass `--rotate-y 180` if the badge ends up facing -Z (away from "
            "the camera) — common one-flag fix."
        ),
    )
    parser.add_argument(
        "--rotate-z",
        type=float,
        default=0.0,
        metavar="DEG",
        help="Manual rotation around Z axis (degrees), applied AFTER auto-orient.",
    )
    parser.add_argument(
        "--no-auto-orient",
        action="store_true",
        help=(
            "Skip the auto-rotate-thin-axis-to-Z step. Use when the source "
            "already has the thin axis on Z and you want pure scale + "
            "recentre, or to debug auto-orient picking the wrong axis."
        ),
    )
    args = parser.parse_args()

    if not args.input.is_file():
        print(f"ERROR: input file not found: {args.input}", file=sys.stderr)
        return 1
    if args.target_size <= 0 or args.target_size > 1.0:
        print(
            f"ERROR: --target-size must be in (0, 1.0] m, got {args.target_size}",
            file=sys.stderr,
        )
        return 1

    inject(
        args.input,
        args.output,
        target_size_m=args.target_size,
        rotate_x_deg=args.rotate_x,
        rotate_y_deg=args.rotate_y,
        rotate_z_deg=args.rotate_z,
        auto_orient=not args.no_auto_orient,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
