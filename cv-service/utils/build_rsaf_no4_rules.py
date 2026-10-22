"""Writes `rules/rsaf_no4_{male,female}.json` — RSAF No.4 doctrine for the
geometric verdict engine, from one table, so men's and ladies' rules can't
drift apart.

Source: SAF No.4 Dress PDF, RSAF section (pp.13-18). Where the PDF states
a measurement it is used (unit patch 20 mm below the shoulder seam,
collar vocation badge 10 mm); where it shows placement only in a picture,
the offset is measured from the operator's RSAF No.4 dressed figure
(`rules/anchors.rsaf_no4_*.json` → `items`), which is treated as the
correctly-worn reference. The PDF gives **no tolerances** for No.4, so
every `tolerance_cm` reuses the Army No.3 file's value for the same kind
of item and says so (`tolerance_source: "assumed"`).

Not checked, by design:
- socks: covered by the boots;
- belt: covered by the untucked No.4 shirt (Pictures A-1..A-3);
- inner T-shirt: not reliably visible.
Each is listed in `_meta.not_checked` so a report can say why.

Usage:
    .venv-tools/bin/python cv-service/utils/build_rsaf_no4_rules.py

See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
"""

from __future__ import annotations

import json
from pathlib import Path

CV_ROOT = Path(__file__).resolve().parents[1]
PDF = "SAF No.4 Dress PDF, RSAF section"
ASSUMED = "assumed — the No.4 PDF states no tolerance; Army No.3 value for the same item kind"


def build(gender: str) -> dict:
    anchors_doc = json.loads((CV_ROOT / "rules" / f"anchors.rsaf_no4_{gender}.json").read_text())
    a, items = anchors_doc["anchors"], anchors_doc["items"]
    cm = lambda metres: round(metres * 100, 2)  # noqa: E731

    # Name tag (right) / SINGAPORE tag (left): bottom edge above the chest-pocket top edge.
    tape_above_pocket = cm(items["name_tape"]["bottom_y"] - a["right_chest_pocket"]["y"])
    # Chest rank tab: centre below the chest-pocket line, centred on the placket.
    tab = items["rank_tab_assembly"]["center"]
    tab_dy, tab_dz = cm(tab[1] - a["chest_center"]["y"]), cm(tab[2] - a["chest_center"]["z"])
    # Unit patch top edge 20 mm below the shoulder seam, expressed from the
    # upper-sleeve anchor (which carries the patch's x — offsets aren't mirrored per side).
    patch_dy = cm((a["left_shoulder_seam"]["y"] - 0.020) - a["left_sleeve_upper"]["y"])
    # Boots: presence check centred on the boot (the foot_top anchor is the
    # instep, ~8 cm below the boot's centre — outside a presence-sized box).
    boots_dy = cm(items["boots"]["center"][1] - a["left_foot_top"]["y"])

    sikh = gender == "male"
    rules = [
        {"object": "rsaf_beret", "category": "headdress_beret",
         "doctrine_ref": f"{PDF}, Picture B-3 (Beret); Pictures A-1..A-3",
         "required": True, "condition": "profile.isSikh != true" if sikh else None,
         "mutually_exclusive_with": ["rsaf_sikh_turban"] if sikh else [],
         "expected_anchor": "head_top", "search_radius_cm": 12.0,
         "position_rule": "presence + region only — the PDF gives no cm placement for the beret", "tolerance_cm": None},
    ]
    if sikh:
        rules.append({"object": "rsaf_sikh_turban", "category": "headdress_sikh_turban",
                      "doctrine_ref": f"{PDF}, Picture B-4 (Turban with Blue Fifty)",
                      "required": True, "condition": "profile.isSikh == true",
                      "mutually_exclusive_with": ["rsaf_beret"],
                      "expected_anchor": "head_top", "search_radius_cm": 14.0, "tolerance_cm": None})
    for obj, cond, ref in (
        ("rsaf_cap_badge_sltc_me6_below", "cap_badge_tier == sltc_me6_and_below", "Picture B-5 (All Other Ranks)"),
        ("rsaf_cap_badge_col_me7", "cap_badge_tier == col_me7", "Picture B-6 (COL and ME7)"),
        ("rsaf_cap_badge_bg_me8_above_beret", "cap_badge_tier == bg_me8_and_above", "Picture B-7 (BG to LG and ME8)"),
    ):
        rules.append({"object": obj, "category": "cap_badge", "doctrine_ref": f"{PDF}, {ref}",
                      "required": True, "condition": cond, "expected_anchor": "cap_band_front",
                      "offset_x_cm": 0, "offset_y_cm": 0, "offset_z_cm": 0,
                      "position_rule": "worn on the front of the headdress, as pictured (B-3, B-4)",
                      "tolerance_cm": 1.3, "tolerance_source": ASSUMED})
    for obj, cond, ref in (
        ("rsaf_no4_rank_epaulette", "rank_tier != officer_cadet_and_mxt_trainee", "Picture B-8 (top row)"),
        ("rsaf_no4_rank_epaulette_cadet_trainee", "rank_tier == officer_cadet_and_mxt_trainee", "Picture B-8 (bottom row)"),
    ):
        rules.append({"object": obj, "category": "rank_epaulette_chest", "doctrine_ref": f"{PDF}, {ref}; Pictures A-1..A-3",
                      "required": True, "condition": cond, "expected_anchor": "chest_center",
                      "offset_x_cm": 0, "offset_y_cm": tab_dy, "offset_z_cm": tab_dz,
                      "position_rule": "single rank epaulette on the shirt placket, centred, below the chest-pocket line "
                                       "(offset measured from the reference figure)",
                      "tolerance_cm": 1.0, "tolerance_source": ASSUMED})
    rules += [
        {"object": "name_tag_standard", "reference_point": "bottom_edge", "category": "name_tag",
         "doctrine_ref": f"{PDF}, Pictures A-1..A-3, C-1..C-3 (name tag above the right chest pocket)",
         "required": True, "expected_anchor": "right_chest_pocket",
         "offset_x_cm": 0, "offset_y_cm": tape_above_pocket, "offset_z_cm": 0, "angle_deg": 0,
         "tolerance_cm": 1.5, "tolerance_deg": 8, "tolerance_source": ASSUMED,
         "rule_text": "Name tag centred, immediately above and parallel to the top edge of the right chest pocket."},
        {"object": "singapore_tag", "reference_point": "bottom_edge", "category": "country_tag",
         "doctrine_ref": f"{PDF}, Pictures A-1..A-3, C-1..C-3 (SINGAPORE tag above the left chest pocket)",
         "required": True, "expected_anchor": "left_chest_pocket",
         "offset_x_cm": 0, "offset_y_cm": tape_above_pocket, "offset_z_cm": 0, "angle_deg": 0,
         "tolerance_cm": 1.5, "tolerance_deg": 8, "tolerance_source": ASSUMED,
         "rule_text": "SINGAPORE tag centred, immediately above and parallel to the top edge of the left chest pocket."},
        {"object": "rsaf_unit_patch", "reference_point": "top_edge", "category": "sleeve_patch",
         "doctrine_ref": f"{PDF}, Pictures C-1 ('20' mm, both sleeves) and C-4 (unit patch 20 mm below the shoulder seam)",
         # Not required: the patch sits on the OUTER face of the upper arm, which a
         # front photo sees almost edge-on (benchmark: detected in 2/46 correct
         # scenes). Reported for the wearer to check by eye; a side photo is the
         # real fix. See ChangeRequest/2026-10-05_cv-service-rsaf-no4.md.
         "required": False, "check_by_eye_reason": "on the outer upper arm — barely visible in a front photo",
         "paired": True, "expected_anchor": "left_sleeve_upper,right_sleeve_upper",
         "offset_x_cm": 0, "offset_y_cm": patch_dy, "offset_z_cm": 0,
         "position_rule": "top edge 20 mm below the shoulder seam (offset expressed from the upper-sleeve anchor)",
         "tolerance_cm": 1.0, "tolerance_source": ASSUMED},
        {"object": "rsaf_vocation_badge", "category": "vocation_badge",
         "doctrine_ref": f"{PDF}, Pictures C-1..C-3 ('Sewn Centrally', 10 mm)",
         "required": False, "expected_anchor": "right_collar_tip",
         "offset_x_cm": 0, "offset_y_cm": 1.0, "offset_z_cm": 0,
         "position_rule": "sewn centrally on the collar, 10 mm from the collar point", "tolerance_cm": 0.8,
         "tolerance_source": ASSUMED},
        {"object": "saf_badges_chest", "category": "saf_badge",
         "doctrine_ref": f"{PDF}, Pictures C-1..C-3 (vocation / skill badges above the SINGAPORE tag)",
         "required": False, "expected_anchor": "left_chest_pocket", "tolerance_cm": 1.0, "tolerance_source": ASSUMED},
        {"object": "safety_boots", "expected_color": "black", "category": "footwear",
         "doctrine_ref": f"{PDF}, Pictures B-11 (Safety Boots), B-12 (Combat Boots)",
         "required": True, "paired": True, "expected_anchor": "left_foot_top,right_foot_top",
         "offset_x_cm": 0, "offset_y_cm": boots_dy, "offset_z_cm": 0, "search_radius_cm": 14.0,
         "position_rule": "presence + colour only — no cm placement for footwear", "tolerance_cm": None},
    ]
    for r in rules:
        if r.get("condition") is None:
            r.pop("condition", None)
    return {
        "_meta": {
            "dress_code": "No4", "branch": "rsaf", "gender": "men" if gender == "male" else "ladies",
            "schema_version": 1,
            "source": f"{PDF} (pp.13-18); offsets not stated in the PDF measured from "
                      f"assets/3d/bodies/rsaf_no4_{gender}.glb via rules/anchors.rsaf_no4_{gender}.json",
            "anchor_file": f"cv-service/rules/anchors.rsaf_no4_{gender}.json",
            "tolerance_note": "The No.4 PDF gives no tolerances; every tolerance_cm is the Army No.3 value for the "
                              "same kind of item (tolerance_source: assumed).",
            "not_checked": {
                "socks": "covered by the boots",
                "belt": "covered by the untucked No.4 shirt (Pictures A-1..A-3)",
                "inner_tshirt": "not reliably visible in a front photo",
            },
            "generated_by": "cv-service/utils/build_rsaf_no4_rules.py",
        },
        "rules": rules,
    }


def main() -> None:
    for gender in ("male", "female"):
        out = CV_ROOT / "rules" / f"rsaf_no4_{gender}.json"
        doc = build(gender)
        out.write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {out.relative_to(CV_ROOT.parent)}: {len(doc['rules'])} rules")
        for r in doc["rules"]:
            print(f"   {r['object']:40s} {r['expected_anchor']:38s} "
                  f"dy={r.get('offset_y_cm', '-')} tol={r.get('tolerance_cm')}")


if __name__ == "__main__":
    main()
