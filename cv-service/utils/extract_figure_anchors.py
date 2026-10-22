"""Reference anchors for a *dressed figure* (RSAF No.4) — measured from the
figure's own named parts, not from compose sockets.

`utils/extract_anchors.py` reads the 15 socket nodes of the bare Army
reference body. The RSAF No.4 figures' sockets were placed by
`tool/prepare_unified_figure.mjs` for 3D accessory *replacement* (e.g.
`belt_center` sits where a swapped-in rank tab lands), which is not what
the doctrine measures from. So this measures the same 16 anchor names
from the parts directly — head crown, cap badge, collar points, chest
pocket tops, shoulder seams, upper sleeves, waistband, boots — in the
coordinate frame and **anatomical** side convention of
`rules/anchors.male.json` (`left_*` = wearer's left = +x; the figures'
own `*_left` node names are camera-side, i.e. the wearer's right).

It also records `items` — where each modelled No.4 item actually sits —
which the doctrine rules (`rules/rsaf_no4_*.json`) and the violation
benchmark use as the "correctly worn" reference.

Usage:
    .venv-tools/bin/python cv-service/utils/extract_figure_anchors.py --gender male
    .venv-tools/bin/python cv-service/utils/extract_figure_anchors.py --gender female

See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import trimesh

CV_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = CV_ROOT.parent

# Doctrine: the RSAF sleeve unit patch sits 20 mm below the shoulder seam
# (SAF No.4 PDF, RSAF Pictures C-1 / C-4). The figure models no seam line,
# so the seam anchor is placed 20 mm above the modelled patch's top edge —
# i.e. the figure's patch placement is taken as the doctrine-correct one.
PATCH_BELOW_SEAM_M = 0.020


def _ancestry(scene: trimesh.Scene, node: str) -> list[str]:
    parents = scene.graph.transforms.parents
    out = []
    while node in parents:
        out.append(node)
        node = parents[node]
    return out


def part_points(scene: trimesh.Scene, name: str) -> np.ndarray:
    pts = []
    for node in scene.graph.nodes_geometry:
        if name in _ancestry(scene, node):
            transform, geom = scene.graph[node]
            pts.append(trimesh.transform_points(scene.geometry[geom].vertices, transform))
    if not pts:
        raise KeyError(f"figure has no part named {name!r}")
    return np.vstack(pts)


def _bounds(scene, name):
    p = part_points(scene, name)
    return p.min(axis=0), p.max(axis=0)


def _pt(x, y, z, source):
    return {"x": round(float(x), 4), "y": round(float(y), 4), "z": round(float(z), 4), "source": source}


def measure(glb: Path) -> dict:
    scene = trimesh.load(glb)
    b = lambda n: _bounds(scene, n)  # noqa: E731
    c = lambda n: (b(n)[0] + b(n)[1]) / 2  # noqa: E731

    anchors: dict[str, dict] = {}
    # head_top / belt_center / ankles are defined the way
    # geometry/mask_anchor_refinement.py MEASURES them, or the refined 2D
    # points and these 3D points disagree and bend the camera solve (the
    # first RSAF benchmark: chest items projected ~2.5 cm low):
    #   head_top    <- top of the headwear mask      => top of the beret
    #   belt_center <- shirt-bottom/trousers-top line => the shirt HEM (No.4
    #                  shirt is worn untucked)
    #   ankles      <- top of each footwear blob      => the boot tops
    head_lo, head_hi = b("head")
    beret_hi = b("beret")[1]
    anchors["head_top"] = _pt(0.0, beret_hi[1], (head_lo[2] + head_hi[2]) / 2,
                              "top of the beret (= what the headwear-mask refinement measures)")
    badge = c("beret_badge")
    anchors["cap_band_front"] = _pt(badge[0], badge[1], b("beret_badge")[1][2], "modelled cap badge centre, front face")

    # Anatomical sides: the figure's `*_left` parts are at -x = wearer's RIGHT.
    for figure_side, side in (("left", "right"), ("right", "left")):
        lo, hi = b(f"collar_point_{figure_side}")
        anchors[f"{side}_collar_tip"] = _pt((lo[0] + hi[0]) / 2, lo[1], hi[2], f"collar_point_{figure_side}: lowest point, front")
        lo, hi = b(f"chest_pocket_flap_{figure_side}")
        anchors[f"{side}_chest_pocket"] = _pt((lo[0] + hi[0]) / 2, hi[1], hi[2], f"chest_pocket_flap_{figure_side}: top edge centre")
        p_lo, p_hi = b(f"shoulder_patch_{figure_side}")
        ball = c(f"shoulder_ball_{figure_side}")
        anchors[f"{side}_shoulder_seam"] = _pt(ball[0], p_hi[1] + PATCH_BELOW_SEAM_M, 0.0,
                                               f"shoulder joint x; y = shoulder_patch_{figure_side} top + 20 mm (doctrine)")
        patch = (p_lo + p_hi) / 2
        outer_x = p_lo[0] if p_lo[0] < 0 else p_hi[0]
        anchors[f"{side}_sleeve_upper"] = _pt(outer_x, patch[1], patch[2], f"shoulder_patch_{figure_side}: outer face centre")
        lo, hi = b(f"boot_collar_{figure_side}")
        bx = (lo[0] + hi[0]) / 2
        anchors[f"{side}_ankle"] = _pt(bx, hi[1], 0.0, f"boot_collar_{figure_side}: top of the boot (= footwear-mask refinement)")
        anchors[f"{side}_foot_top"] = _pt(bx, 0.05, 0.10, f"boot_collar_{figure_side} centre x, instep")

    hem_lo, hem_hi = b("shirt_hem")
    anchors["belt_center"] = _pt(0.0, (hem_lo[1] + hem_hi[1]) / 2, hem_hi[2],
                                 "untucked shirt hem, front centre (= shirt/trousers-boundary refinement)")
    lp, rp = anchors["left_chest_pocket"], anchors["right_chest_pocket"]
    anchors["chest_center"] = _pt(0.0, (lp["y"] + rp["y"]) / 2, (lp["z"] + rp["z"]) / 2,
                                  "derived: midpoint(left_chest_pocket, right_chest_pocket), x forced to symmetry plane")

    items = {}
    for name in ("beret", "beret_badge", "rank_tab_assembly", "name_tape", "country_tape",
                 "shoulder_patch_left", "shoulder_patch_right", "wing_badge_assembly", "boots"):
        lo, hi = b(name)
        items[name] = {"center": [round(float(v), 4) for v in (lo + hi) / 2],
                       "top_y": round(float(hi[1]), 4), "bottom_y": round(float(lo[1]), 4),
                       "size_cm": [round(float(v) * 100, 1) for v in hi - lo]}
    return {"anchors": anchors, "items": items, "stature_m": round(float(head_hi[1]), 4)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--gender", choices=["male", "female"], required=True)
    args = parser.parse_args()
    glb = REPO_ROOT / "assets" / "3d" / "bodies" / f"rsaf_no4_{args.gender}.glb"
    m = measure(glb)
    out = CV_ROOT / "rules" / f"anchors.rsaf_no4_{args.gender}.json"
    out.write_text(json.dumps({
        "source_glb": str(glb.relative_to(REPO_ROOT)),
        "reference_height_m": m["stature_m"],
        "coordinate_frame": {
            "units": "meters",
            "origin": "feet at y=0, x/z centered on the body's vertical symmetry axis",
            "up_axis": "y", "forward_axis": "+z (body-front)",
            "side_convention": "anatomical — left_* is the wearer's left (+x); matches MediaPipe landmark naming",
        },
        "measured_by": "cv-service/utils/extract_figure_anchors.py (from named parts, not compose sockets)",
        "anchors": m["anchors"],
        "items": m["items"],
    }, indent=2) + "\n")
    print(f"wrote {out.relative_to(REPO_ROOT)}  stature={m['stature_m']} m")
    for k, v in m["anchors"].items():
        print(f"  {k:20s} {v['x']:+.3f} {v['y']:.3f} {v['z']:+.3f}")
    for k, v in m["items"].items():
        print(f"  item {k:22s} center={v['center']} size_cm={v['size_cm']}")


if __name__ == "__main__":
    main()
