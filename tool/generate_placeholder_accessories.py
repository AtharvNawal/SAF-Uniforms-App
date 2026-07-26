#!/usr/bin/env python3
"""Generate placeholder accessory GLBs from `accessory_library.v1.json`.

The `composeUniformModel` Cloud Function attaches accessories under named
sockets on the body. Without GLB files at `models/accessories/{id}.glb`,
every resolved accessory is logged + skipped, and the rendered model has
just the body. This script emits **procedural geometric placeholders** —
visibly distinct, branch-coloured, sized roughly to a human head/chest —
so the merger has something to attach for every active No.3 entry.

Each accessory's geometry is **centred on the origin** (the merger
applies the offset translation when re-parenting under the socket).
The placeholders are deliberately ugly — they're stand-ins until artist
GLBs land, not production assets.

USAGE:

    .venv-tools/bin/pip install trimesh numpy Pillow
    .venv-tools/bin/python tool/generate_placeholder_accessories.py

OUTPUT:

    assets/3d/accessories/{id}.glb   (one file per active library entry
                                      whose category we know how to draw)

Categories supported (most of No.3's resolver output):
    headdress_beret, headdress_sikh_turban, headdress_ladies_hat,
    cap_badge, cap_embellishment, sleeve_rank_specialist,
    sleeve_rank_enlistee, epaulette, lanyard, arms_badge, vocation_badge

Out of scope (skipped — see ChangeRequest 2026-05-09):
    footwear, socks, belt (no body sockets), gorgette, collar_rank_pin,
    medal_ribbons, saf_badge, skill_tab, skill_badge, foreign_badge,
    name_tag (handled by the bake step, not socket-attach).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import trimesh
from trimesh.visual.material import PBRMaterial

REPO_ROOT = Path(__file__).resolve().parent.parent
LIBRARY_JSON = REPO_ROOT / "assets" / "data" / "accessory_library.v1.json"
OUT_DIR = REPO_ROOT / "assets" / "3d" / "accessories"


# ---------------------------------------------------------------------------
# Per-branch colour palette. Used as a fallback when the entry's
# `rules.color` doesn't resolve to a known doctrine colour. Keeping the
# palette muted so the placeholder doesn't scream against the body.
# ---------------------------------------------------------------------------

BRANCH_COLORS = {
    "army": (0.18, 0.30, 0.18, 1.0),    # dark olive green
    "navy": (0.10, 0.14, 0.32, 1.0),    # navy blue
    "rsaf": (0.30, 0.50, 0.70, 1.0),    # RSAF light blue
    "dis":  (0.20, 0.20, 0.24, 1.0),    # charcoal
    "gold": (0.85, 0.65, 0.20, 1.0),    # cap badges
    "white": (0.94, 0.94, 0.94, 1.0),   # rank stripes
    "red":   (0.62, 0.16, 0.16, 1.0),   # lanyard accent
    "neutral": (0.55, 0.55, 0.58, 1.0), # fallback
}

# Per-doctrine-name colour overrides — see `rules.color` strings on the
# library entries (e.g. `dark_green`, `red`, `silver`).
COLOR_NAMES = {
    "dark_green": (0.16, 0.28, 0.16, 1.0),
    "navy_blue":  (0.10, 0.14, 0.32, 1.0),
    "light_blue": (0.30, 0.50, 0.70, 1.0),
    "black":      (0.06, 0.06, 0.06, 1.0),
    "white":      (0.94, 0.94, 0.94, 1.0),
    "red":        (0.62, 0.16, 0.16, 1.0),
    "silver":     (0.78, 0.78, 0.80, 1.0),
    "gold":       (1.00, 0.82, 0.20, 1.0),  # bright saturated yellow-gold so it reads
                                              # as gold under model_viewer_plus's blue-ish
                                              # ambient lighting instead of looking olive
    "khaki":      (0.62, 0.54, 0.34, 1.0),
}


def pick_color(entry: dict) -> tuple:
    """Best-effort colour for an entry: rules.color → branch palette → neutral."""
    rules_color = (entry.get("rules") or {}).get("color")
    if isinstance(rules_color, str) and rules_color.lower() in COLOR_NAMES:
        return COLOR_NAMES[rules_color.lower()]
    branch = entry.get("branch_id")
    if branch in BRANCH_COLORS:
        return BRANCH_COLORS[branch]
    return BRANCH_COLORS["neutral"]


def _coloured(geom: trimesh.Trimesh, name: str, color: tuple,
              roughness: float = 0.7, metallic: float = 0.0) -> trimesh.Trimesh:
    mat = PBRMaterial(
        name=name,
        baseColorFactor=color,
        metallicFactor=metallic,
        roughnessFactor=roughness,
    )
    geom.visual = trimesh.visual.TextureVisuals(material=mat)
    return geom


# ---------------------------------------------------------------------------
# Per-category builders. Each returns a list of (sub_name, Trimesh)
# tuples — most accessories are a single mesh but berets are crown +
# band + cap-badge plate, etc.
# ---------------------------------------------------------------------------


# Headdress geometries are positioned with their **bottom-of-volume at
# origin, extending downward** along -Y. Reason: the body's `head_top`
# socket sits ~3 cm above the head crown (per
# tool/inject_sockets.py:_socket_positions). When an accessory whose
# centre is at origin gets re-parented under that socket, it ends up
# *floating above the head* (we saw this on-device — a giant turban
# sphere stacked on top of the head). By placing the geometry's
# vertices in the y range [-h, 0] instead of [-h/2, h/2], the
# accessory hangs DOWN from the socket and wraps around the head crown
# the way a real beret/turban/hat would.


def _build_beret(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    color = pick_color(entry)
    band_color = (color[0] * 0.7, color[1] * 0.7, color[2] * 0.7, 1.0)

    crown = trimesh.creation.icosphere(radius=0.10, subdivisions=2)
    crown.apply_scale([1.05, 0.42, 1.05])
    # Slight cant so it reads as "worn" rather than "stacked"
    crown.apply_transform(
        trimesh.transformations.rotation_matrix(np.deg2rad(8), [0, 0, 1])
    )
    # Drop the crown so its top sits at origin (head_top socket).
    crown.apply_translation([0.025, -0.04, 0])
    band = trimesh.creation.cylinder(radius=0.097, height=0.025, sections=24)
    band.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    band.apply_translation([0, -0.078, 0])
    return [
        ("beret_crown", _coloured(crown, "beret_mat", color)),
        ("beret_band", _coloured(band, "beret_band_mat", band_color)),
    ]


def _build_sikh_turban(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Turban geometry sized to wrap a real human head (~0.18 m
    diameter), bottom-aligned to origin so it hangs from the head_top
    socket and envelops the head crown rather than stacking above."""
    color = pick_color(entry)
    turban = trimesh.creation.icosphere(radius=0.090, subdivisions=3)
    # Slightly oblong: wider at the front for the typical SAF turban
    # silhouette; flattened on top.
    turban.apply_scale([1.10, 0.95, 1.00])
    # Drop so the turban's top is at origin — the bulk sits below
    # head_top, around the head.
    turban.apply_translation([0, -0.090, 0])
    return [("turban", _coloured(turban, "turban_mat", color))]


def _build_ladies_hat(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    color = pick_color(entry)
    # Crown: small cylinder sitting just below origin (= head_top).
    crown = trimesh.creation.cylinder(radius=0.085, height=0.07, sections=24)
    crown.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    crown.apply_translation([0, -0.035, 0])
    # Brim: wider disk at the bottom of the crown.
    brim = trimesh.creation.cylinder(radius=0.13, height=0.012, sections=32)
    brim.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    brim.apply_translation([0, -0.075, 0])
    return [
        ("hat_crown", _coloured(crown, "hat_crown_mat", color)),
        ("hat_brim", _coloured(brim, "hat_brim_mat", color)),
    ]


def _build_cap_badge(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Flat oval-ish badge sitting on the front of the cap band/turban.

    The body's `cap_band_front` socket is on the front face of the
    head; the doctrine offset (`offset_y_cm: 1.3`) lifts the badge
    slightly above the band centerline. We just emit a flat plate
    centered at origin — the merger applies the cm-to-metres offset.
    """
    # 4.5 × 3 cm flat plate. Higher emissive-like base color (saturated
    # yellow-gold + low metallic) so it reads as gold even when
    # model_viewer_plus's default IBL lighting is cool/blue-tinted.
    badge = trimesh.creation.box(extents=[0.045, 0.030, 0.004])
    gold_mat = PBRMaterial(
        name="cap_badge_mat",
        baseColorFactor=COLOR_NAMES["gold"],
        emissiveFactor=(0.45, 0.36, 0.05),  # warm gold "glow"
        metallicFactor=0.85,
        roughnessFactor=0.25,
    )
    badge.visual = trimesh.visual.TextureVisuals(material=gold_mat)
    return [("cap_badge", badge)]


def _build_cap_embellishment(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    embell = trimesh.creation.box(extents=[0.055, 0.040, 0.004])
    color = pick_color(entry)
    return [("cap_embellishment", _coloured(embell, "cap_embellishment_mat", color, roughness=0.4))]


# Sleeve insignia — the library anchors them at `shoulder_seam` (per
# SAF doctrine "on the shoulder seam"), but the chevron geometry needs
# to extend DOWN onto the upper arm, not float at the shoulder peak.
# We position the geometry so its TOP edge is at origin and the rest
# hangs into the y range [-h, 0]. With the merger attaching at the
# shoulder_seam socket, the chevrons land on the upper arm ~3 cm below
# the shoulder line, where they'd be on a real uniform. Boxes are
# rotated 90° around X so the flat face points outward (away from the
# body) when re-parented under the side-of-body shoulder socket.


def _build_sleeve_specialist(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Three chevron stripes hanging below the shoulder seam."""
    parts = []
    for i in range(3):
        stripe = trimesh.creation.box(extents=[0.06, 0.014, 0.004])
        # Stack stripes vertically, top stripe at y ≈ -0.03 (3 cm below
        # the shoulder seam), each subsequent stripe ~2.2 cm below.
        stripe.apply_translation([0, -0.03 - i * 0.022, 0])
        parts.append(
            (
                f"chevron_{i + 1}",
                _coloured(stripe, f"chevron_{i+1}_mat", COLOR_NAMES["white"], roughness=0.5),
            )
        )
    return parts


def _build_sleeve_enlistee(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Two chevron stripes (smaller than specialist) below the shoulder seam."""
    parts = []
    for i in range(2):
        stripe = trimesh.creation.box(extents=[0.05, 0.012, 0.003])
        stripe.apply_translation([0, -0.03 - i * 0.018, 0])
        parts.append(
            (
                f"chevron_{i + 1}",
                _coloured(stripe, f"chevron_{i+1}_mat", COLOR_NAMES["white"], roughness=0.5),
            )
        )
    return parts


def _build_epaulette(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Flat slab on top of the shoulder — merger mirrors to both sides.

    Geometry is rotated so the long axis points along Z (front-to-back)
    so the slab follows the shoulder's curve from front of shoulder
    pocket to back. Origin at the inboard end so it extends along the
    shoulder when attached at the seam socket.
    """
    color = pick_color(entry)
    slab = trimesh.creation.box(extents=[0.04, 0.012, 0.10])
    # Sit the slab just below the shoulder-seam plane so it rests on
    # the shoulder rather than poking up into the air.
    slab.apply_translation([0, -0.005, 0])
    return [("epaulette", _coloured(slab, "epaulette_mat", color, roughness=0.5))]


def _build_lanyard(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Compact tag-on-loop — small, anchored under the shoulder.

    The previous design (30 cm cord + sphere) was way too long and
    looked like a stick poking out of the shoulder. SAF doctrine has
    the lanyard wrap around the shoulder with a tag against the chest;
    placeholder is a small loop + tag clearly visible at the shoulder
    without pretending to model the whole drape.
    """
    color = pick_color(entry)
    # Small loop ring just below origin (= shoulder_seam socket).
    loop = trimesh.creation.torus(major_radius=0.018, minor_radius=0.004)
    loop.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    loop.apply_translation([0, -0.025, 0])
    # Short cord dropping from the loop toward the chest.
    cord = trimesh.creation.cylinder(radius=0.004, height=0.06, sections=12)
    cord.apply_translation([0, -0.06, 0])
    # Small tag at the bottom of the cord.
    tag = trimesh.creation.box(extents=[0.020, 0.030, 0.004])
    tag.apply_translation([0, -0.105, 0])
    return [
        ("lanyard_loop", _coloured(loop, "lanyard_loop_mat", color, roughness=0.6)),
        ("lanyard_cord", _coloured(cord, "lanyard_cord_mat", color, roughness=0.6)),
        ("lanyard_tag", _coloured(tag, "lanyard_tag_mat", color, roughness=0.6)),
    ]


def _build_arms_badge(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    badge = trimesh.creation.box(extents=[0.05, 0.06, 0.004])
    color = pick_color(entry)
    return [("arms_badge", _coloured(badge, "arms_badge_mat", color, roughness=0.5))]


def _build_vocation_badge(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    badge = trimesh.creation.box(extents=[0.05, 0.06, 0.004])
    color = pick_color(entry)
    return [("vocation_badge", _coloured(badge, "vocation_badge_mat", color, roughness=0.5))]


# Belt / socks / shoes — base accessories shared across all No.X dress
# codes. The merger attaches these via `belt_center` (single anchor),
# `ankle` (paired via mirror), and `foot_top` (paired via mirror)
# respectively.


def _build_belt(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Thin torus wrapping the waist. Centred at origin so the
    `belt_center` socket places it at the waist plane; the torus's
    major-axis ring sits in the XZ plane so it encircles the body
    when oriented +Y up."""
    color = COLOR_NAMES["black"] if "leather" in entry["id"] else (0.30, 0.30, 0.32, 1.0)
    belt = trimesh.creation.torus(major_radius=0.14, minor_radius=0.012)
    # Default torus is in the XY plane; rotate to lay in XZ plane so it
    # rings around the body's vertical axis.
    belt.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    return [("belt", _coloured(belt, "belt_mat", color, roughness=0.4))]


def _build_socks(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Short cylinder representing the cuff of a sock. Centred at origin
    so the `ankle` socket places the cuff at ankle height; the merger
    mirrors to both ankles automatically (mirror_left_right=true)."""
    sock = trimesh.creation.cylinder(radius=0.040, height=0.08, sections=20)
    # Default cylinder lies along Z; rotate so it stands along Y.
    sock.apply_transform(
        trimesh.transformations.rotation_matrix(np.pi / 2, [1, 0, 0])
    )
    return [
        ("sock", _coloured(sock, "sock_mat", COLOR_NAMES["black"], roughness=0.85)),
    ]


def _build_footwear(entry: dict) -> list[tuple[str, trimesh.Trimesh]]:
    """Simple shoe-shaped block (toe + heel). Centred at origin so the
    `foot_top` socket places the shoe on top of the instep; merger
    mirrors to both feet."""
    is_court = "court" in entry["id"]
    color = COLOR_NAMES["black"]
    # Sole: longer in Z (toe-to-heel), thin in Y.
    sole = trimesh.creation.box(extents=[0.085, 0.020, 0.250])
    sole.apply_translation([0, -0.020, 0])
    # Upper: rounded dome over the instep (rear half of foot).
    upper = trimesh.creation.icosphere(radius=0.045, subdivisions=2)
    upper.apply_scale([0.95, 0.55, 1.35])
    upper.apply_translation([0, 0.0, -0.035])
    parts = [
        ("shoe_sole", _coloured(sole, "shoe_sole_mat", color, roughness=0.5)),
        ("shoe_upper", _coloured(upper, "shoe_upper_mat", color, roughness=0.5, metallic=0.1)),
    ]
    if is_court:
        # Ladies court shoes have a visible low heel — add a small block.
        heel = trimesh.creation.box(extents=[0.045, 0.04, 0.04])
        heel.apply_translation([0, -0.040, 0.080])
        parts.append(("shoe_heel", _coloured(heel, "shoe_heel_mat", color, roughness=0.5)))
    return parts


# ---------------------------------------------------------------------------
# Category dispatch. A category not in this map → the entry is skipped
# (footwear, medal_ribbons, etc. are out of scope this round).
# ---------------------------------------------------------------------------

CATEGORY_BUILDERS = {
    "headdress_beret": _build_beret,
    "headdress_sikh_turban": _build_sikh_turban,
    "headdress_ladies_hat": _build_ladies_hat,
    "cap_badge": _build_cap_badge,
    "cap_embellishment": _build_cap_embellishment,
    "sleeve_rank_specialist": _build_sleeve_specialist,
    "sleeve_rank_enlistee": _build_sleeve_enlistee,
    "epaulette": _build_epaulette,
    "lanyard": _build_lanyard,
    "arms_badge": _build_arms_badge,
    "vocation_badge": _build_vocation_badge,
    "belt": _build_belt,
    "socks": _build_socks,
    "footwear": _build_footwear,
}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> int:
    if not LIBRARY_JSON.exists():
        print(f"ERROR: {LIBRARY_JSON} not found", file=sys.stderr)
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    with LIBRARY_JSON.open() as f:
        data = json.load(f)
    entries = data.get("accessories", [])

    written = 0
    skipped_legacy = 0
    skipped_oos = 0
    by_category: dict[str, int] = {}

    for entry in entries:
        rl = entry.get("render_logic") or {}
        if rl.get("legacy_placeholder"):
            skipped_legacy += 1
            continue

        category = entry.get("category") or ""
        builder = CATEGORY_BUILDERS.get(category)
        if not builder:
            skipped_oos += 1
            continue

        scene = trimesh.Scene()
        for sub_name, geom in builder(entry):
            scene.add_geometry(geom, geom_name=sub_name, node_name=sub_name)

        out_path = OUT_DIR / f"{entry['id']}.glb"
        scene.export(out_path)
        written += 1
        by_category[category] = by_category.get(category, 0) + 1

    print(f"Wrote {written} placeholder GLB(s) to {OUT_DIR.relative_to(REPO_ROOT)}/")
    for cat, n in sorted(by_category.items(), key=lambda x: -x[1]):
        print(f"  {n:>3}  {cat}")
    print(f"Skipped {skipped_legacy} legacy placeholder(s) "
          f"and {skipped_oos} out-of-scope categor(ies).")
    print()
    print("Next: tool/upload_models.py --only 'accessories/*' to push these to Storage.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
