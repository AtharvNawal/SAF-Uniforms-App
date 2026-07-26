#!/usr/bin/env python3
"""Operator-only: extract per-accessory PNGs from the SAF No.3 Dress PDF.

Walks the manifest below and writes
    assets/accessories/<id>/{image,placement}.png
by cropping the rendered PDF pages produced by `pdftoppm -r 220`. For
product-photo pages (the accessory tables on pp 4-7, 18-20, 30-33, 43-45)
the script auto-detects table-row boundaries from horizontal black lines
and lets the manifest reference rows by index — much more robust than
hand-measured pixel coordinates. For placement-diagram pages (free-form
illustrations on pp 1-3, 8-17, 21-29, 34-42, 46-54) the manifest uses
explicit (left, top, right, bottom) pixel boxes.

After cropping, the script auto-trims near-white borders and pads a small
margin so the output looks tidy regardless of slight imprecision in the
source coordinates.

Re-runnable: overwrites existing PNGs in place.

Prerequisites (one-time):
    brew install poppler
    pip install --user --break-system-packages Pillow numpy

Workflow:
    1. Render the PDF once:
         mkdir -p /tmp/saf-pdf-extract/pages
         pdftoppm -png -r 220 <SAF_No_3_Dress.pdf> /tmp/saf-pdf-extract/pages/page
    2. Run this script from the repo root:
         python3 tool/extract_pdf_accessories.py

The output is committed to git so the seed-script `--upload-images`
flag can push them to Firebase Storage.
"""
from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable

try:
    import numpy as np
    from PIL import Image, ImageChops, ImageOps
except ImportError:  # pragma: no cover
    sys.exit(
        "Pillow + numpy are required. Install with: "
        "python3 -m pip install --user --break-system-packages Pillow numpy"
    )

REPO_ROOT = Path(__file__).resolve().parent.parent
PAGE_DIR = Path("/tmp/saf-pdf-extract/pages")
OUT_ROOT = REPO_ROOT / "assets" / "accessories"

# Auto-trim margin (pixels of white padding kept around the trimmed image).
_TRIM_PAD = 12
# Rows shorter than this are header/caption rows, not image rows.
_IMAGE_ROW_MIN_H = 100

# Standard column ranges for image cells. Pages render at 220 DPI = 1818 wide;
# the accessory tables are inset ~225 px on each side.
COL_L = (225, 905)
COL_R = (925, 1605)
COL_FULL = (225, 1605)
COL_3_1 = (225, 685)
COL_3_2 = (690, 1140)
COL_3_3 = (1145, 1605)


# ---------------------------------------------------------------------------
# Page row detection (auto from horizontal table borders)
# ---------------------------------------------------------------------------

_ROW_CACHE: dict[int, list[tuple[int, int]]] = {}


def _detect_rows(page_idx: int) -> list[tuple[int, int]]:
    if page_idx in _ROW_CACHE:
        return _ROW_CACHE[page_idx]
    arr = np.asarray(_open_page(page_idx).convert("L"))
    H, W = arr.shape
    black = (arr < 100).sum(axis=1) > (W * 0.6)
    boundaries: list[int] = []
    in_block, block_start = False, None
    for y, b in enumerate(black):
        if b and not in_block:
            block_start = y
            in_block = True
        elif not b and in_block:
            boundaries.append((block_start + y - 1) // 2)
            in_block = False
    rows: list[tuple[int, int]] = []
    for i in range(len(boundaries) - 1):
        t, b = boundaries[i], boundaries[i + 1]
        if b - t > 30:
            rows.append((t, b))
    _ROW_CACHE[page_idx] = rows
    return rows


def _row_y(page_idx: int, row_index: int) -> tuple[int, int]:
    """Return (top, bottom) for the row at `row_index` (0-based, absolute)."""
    rows = _detect_rows(page_idx)
    if row_index >= len(rows):
        raise IndexError(
            f"page {page_idx}: requested row {row_index} but only "
            f"{len(rows)} rows detected: {rows}"
        )
    return rows[row_index]


# ---------------------------------------------------------------------------
# Image utilities
# ---------------------------------------------------------------------------

_PAGE_CACHE: dict[int, Image.Image] = {}


def _open_page(page_idx: int) -> Image.Image:
    if page_idx in _PAGE_CACHE:
        return _PAGE_CACHE[page_idx]
    p = PAGE_DIR / f"page-{page_idx:02d}.png"
    if not p.exists():
        raise FileNotFoundError(
            f"Rendered page missing: {p}. Run `pdftoppm -png -r 220 <pdf> "
            "/tmp/saf-pdf-extract/pages/page` first."
        )
    img = Image.open(p).convert("RGB")
    _PAGE_CACHE[page_idx] = img
    return img


def _crop_and_trim(page_idx: int, bbox: tuple[int, int, int, int]) -> Image.Image:
    page = _open_page(page_idx)
    crop = page.crop(bbox)
    bg = Image.new("RGB", crop.size, (255, 255, 255))
    diff = ImageChops.difference(crop, bg)
    diff = ImageChops.add(diff, diff, scale=2.0, offset=-30)
    trim_box = diff.getbbox()
    if trim_box is not None:
        crop = crop.crop(trim_box)
        crop = ImageOps.expand(crop, border=_TRIM_PAD, fill=(255, 255, 255))
    return crop


def _save(img: Image.Image, targets: Iterable[str]) -> None:
    for rel in targets:
        out = OUT_ROOT / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out, "PNG", optimize=True)


# ---------------------------------------------------------------------------
# Manifest helpers
# ---------------------------------------------------------------------------


def img_row(page: int, row_index: int, cols: tuple[int, int]) -> tuple:
    """Build a manifest spec referencing a tabled row by **absolute** index.

    `row_index` is the 0-based position of the row in the auto-detected
    list of horizontal table cells on the page. Use the helper output
    of `_detect_rows` (or the `--debug-rows` flag) to look up which row
    holds which content. This is more deterministic than filtering by
    height because Notes / caption blocks do not get auto-promoted to
    image rows accidentally.
    """
    return ("row", page, row_index, cols)


def manual(page: int, bbox: tuple[int, int, int, int]) -> tuple:
    """Build a manifest spec with explicit pixel coordinates."""
    return ("box", page, bbox)


def _resolve(spec: tuple) -> tuple[int, tuple[int, int, int, int]]:
    kind = spec[0]
    if kind == "row":
        _, page, ridx, cols = spec
        y0, y1 = _row_y(page, ridx)
        return page, (cols[0], y0, cols[1], y1)
    if kind == "box":
        _, page, bbox = spec
        return page, bbox
    raise ValueError(f"Unknown spec kind: {kind}")


# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------

# Each entry: (spec, [output_paths])
MANIFEST: list[tuple[tuple, list[str]]] = [
    # =====================================================================
    # ARMY product photos (pages 4-7)
    # =====================================================================
    (img_row(4, 1, COL_L),     ["army_beret/image.png"]),
    (img_row(4, 1, COL_R),     ["army_sikh_turban_standard/image.png"]),
    (img_row(4, 3, COL_FULL),  ["army_sikh_turban_col_me7_above/image.png"]),
    (img_row(4, 7, COL_L),     ["army_ladies_hat_officer_wo_me3_to_me8/image.png"]),
    (img_row(4, 7, COL_R),     ["army_ladies_hat_specialist_enlistee_me1_me2/image.png"]),
    (img_row(4, 10, COL_L),    ["army_cap_badge_bg_me8_above/image.png"]),
    (img_row(4, 10, COL_R),    ["army_cap_badge_col_me7/image.png"]),
    (img_row(4, 12, COL_L),    ["army_cap_badge_sltc_me6_below/image.png"]),
    (img_row(4, 12, COL_R),    ["army_cap_badge_military_police/image.png"]),

    (img_row(5, 0, COL_L),     ["epaulettes_standard/image.png"]),
    (img_row(5, 0, COL_R),     ["epaulettes_officer_cadet_me_trainee/image.png"]),
    (img_row(5, 2, COL_FULL),  ["collar_rank_pins/image.png"]),
    (img_row(5, 5, COL_L),     ["gorgette_lady_officer_cadet/image.png"]),
    (img_row(5, 5, COL_R),     ["gorgette_lady_me_trainee/image.png"]),

    (img_row(6, 1, COL_L),     ["army_specialist_insignia/image.png"]),
    (img_row(6, 1, COL_R),     ["army_enlistee_insignia/image.png"]),
    (img_row(6, 5, COL_FULL),  ["army_arms_badge/image.png"]),
    (img_row(6, 9, COL_FULL),  ["name_tag_standard/image.png"]),
    (img_row(6, 13, COL_FULL), [
        "army_lanyard_sa_ma/image.png",
        "navy_lanyard_ma_na/image.png",
        "rsaf_lanyard_sa_ma/image.png",
        "dis_lanyard_ma_sa/image.png",
    ]),

    (img_row(7, 1, COL_L),     ["nylon_belt/image.png"]),
    (img_row(7, 1, COL_R),     ["leather_belt/image.png"]),
    (img_row(7, 5, COL_L),     ["leather_shoes_low_cut/image.png"]),
    (img_row(7, 5, COL_R),     ["patent_shoes_low_cut/image.png"]),
    (img_row(7, 7, COL_L),     ["court_shoes/image.png", "patent_court_shoes/image.png"]),
    (img_row(7, 7, COL_R),     ["black_socks/image.png"]),

    # =====================================================================
    # ARMY placement diagrams (free-form pages 1, 8-13)
    # =====================================================================
    # p8 — C-1 collar + arms badge (Lady Officer)
    (manual(8, (250, 380, 1605, 1200)),  ["army_arms_badge/placement.png"]),
    # p8 — C-2 gorgettes for Lady Officer cadet
    (manual(8, (250, 1190, 1605, 1545)), [
        "gorgette_lady_officer_cadet/placement.png",
        "gorgette_lady_me_trainee/placement.png",
    ]),
    # p9 — C-3 specialist sleeve
    (manual(9, (130, 250, 905, 700)),  ["army_specialist_insignia/placement.png"]),
    # p9 — C-4 enlistee sleeve
    (manual(9, (905, 250, 1700, 700)), ["army_enlistee_insignia/placement.png"]),
    # p10 — C-6/C-7 nametag (top half) — keep both male + female frames
    (manual(10, (130, 270, 1700, 605)), ["name_tag_standard/placement.png"]),
    # p10 — C-8 nylon belt male
    (manual(10, (350, 830, 1450, 1230)), [
        "nylon_belt/placement.png",
        "leather_belt/placement.png",
    ]),
    # p11 — Medal ribbons placement (D-1..D-6 grid)
    (manual(11, (130, 200, 1700, 2080)), ["medal_ribbons/placement.png"]),
    # p12 — SAF badges (D-7..D-10)
    (manual(12, (130, 250, 1700, 1430)), ["saf_badges_chest/placement.png"]),
    # p12 — D-11..D-14 sleeve markers (lower half)
    (manual(12, (130, 1480, 1700, 2390)), ["skill_tabs_sleeve/placement.png"]),
    # p13 — D-15/D-16 sleeve badges on chevrons (top)
    (manual(13, (130, 200, 1700, 950)),  ["skill_badges_sleeve/placement.png"]),
    # p13 — D-17 foreign badges male (lower)
    (manual(13, (130, 1000, 1700, 1750)), ["foreign_badges/placement.png"]),

    # Headdress / lanyard / epaulette placement: re-use Army A-1 from p1
    (manual(1, (430, 200, 1100, 850)), [
        "army_beret/placement.png",
        "army_sikh_turban_standard/placement.png",
        "army_sikh_turban_col_me7_above/placement.png",
        "army_ladies_hat_officer_wo_me3_to_me8/placement.png",
        "army_ladies_hat_specialist_enlistee_me1_me2/placement.png",
        "army_cap_badge_bg_me8_above/placement.png",
        "army_cap_badge_col_me7/placement.png",
        "army_cap_badge_sltc_me6_below/placement.png",
        "army_cap_badge_military_police/placement.png",
        "army_lanyard_sa_ma/placement.png",
        "epaulettes_standard/placement.png",
        "epaulettes_officer_cadet_me_trainee/placement.png",
        "collar_rank_pins/placement.png",
    ]),
    # Footwear placement: A-1 lower body
    (manual(1, (380, 1100, 1000, 1900)), [
        "leather_shoes_low_cut/placement.png",
        "patent_shoes_low_cut/placement.png",
        "court_shoes/placement.png",
        "patent_court_shoes/placement.png",
        "black_socks/placement.png",
    ]),

    # =====================================================================
    # NAVY product photos (pp 18-20)
    # =====================================================================
    (img_row(18, 1, COL_L),    ["navy_beret/image.png"]),
    (img_row(18, 1, COL_R),    ["navy_sikh_turban_standard/image.png"]),
    (img_row(18, 3, COL_FULL), ["navy_sikh_turban_3wo_me3_above/image.png"]),
    (img_row(18, 7, COL_L),    ["navy_ladies_hat_officer_wo_me3_to_me8/image.png"]),
    (img_row(18, 7, COL_R),    ["navy_ladies_hat_specialist_rating_cadet_me_trainee/image.png"]),
    (img_row(18, 10, COL_3_1), ["navy_cap_embellishment_bg_me8_above/image.png"]),
    (img_row(18, 10, COL_3_2), ["navy_cap_embellishment_col_me7/image.png"]),
    (img_row(18, 10, COL_3_3), ["navy_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6/image.png"]),

    (img_row(19, 0, COL_L),    ["navy_cap_badge_col_me7_above/image.png"]),
    (img_row(19, 0, COL_R),    ["navy_cap_badge_sltc_me6_below/image.png"]),
    (img_row(19, 11, COL_L),   ["navy_specialist_insignia/image.png"]),
    (img_row(19, 11, COL_R),   ["navy_rating_insignia/image.png"]),

    # =====================================================================
    # NAVY placement diagrams (pp 21-22, p15)
    # =====================================================================
    # p21 has 4 boxed regions (C-1, C-2, C-3, C-4)
    (manual(21, (130, 200, 1700, 920)),  ["navy_specialist_insignia/placement.png"]),  # uses C-1 + C-3 visual
    (manual(21, (130, 940, 1700, 1500)), ["navy_rating_insignia/placement.png"]),       # uses C-4 visual
    # p22 — name tag + belt diagrams (apply to all branches)
    (manual(22, (130, 200, 1700, 580)),  ["navy_name_tag/placement.png"]),
    # Headdress / lanyard placements: Navy A-1 from p15
    (manual(15, (430, 200, 1050, 1000)), [
        "navy_beret/placement.png",
        "navy_sikh_turban_standard/placement.png",
        "navy_sikh_turban_3wo_me3_above/placement.png",
        "navy_ladies_hat_officer_wo_me3_to_me8/placement.png",
        "navy_ladies_hat_specialist_rating_cadet_me_trainee/placement.png",
        "navy_cap_embellishment_bg_me8_above/placement.png",
        "navy_cap_embellishment_col_me7/placement.png",
        "navy_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6/placement.png",
        "navy_cap_badge_col_me7_above/placement.png",
        "navy_cap_badge_sltc_me6_below/placement.png",
        "navy_lanyard_ma_na/placement.png",
    ]),

    # =====================================================================
    # RSAF product photos (pp 30-33)
    # =====================================================================
    (img_row(30, 1, COL_L),    ["rsaf_beret/image.png"]),
    (img_row(30, 1, COL_R),    ["rsaf_sikh_turban/image.png"]),
    (img_row(30, 5, COL_FULL), ["rsaf_ladies_hat_bg_me8_above/image.png"]),
    (img_row(30, 7, COL_L),    ["rsaf_ladies_hat_officer_wo_me3_to_me8/image.png"]),
    (img_row(30, 7, COL_R),    ["rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee/image.png"]),

    (img_row(31, 0, COL_3_1),  ["rsaf_cap_embellishment_bg_me8_above/image.png"]),
    (img_row(31, 0, COL_3_2),  ["rsaf_cap_embellishment_col_me7/image.png"]),
    (img_row(31, 0, COL_3_3),  ["rsaf_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6/image.png"]),
    (img_row(31, 3, COL_L),    ["rsaf_cap_badge_bg_me8_above_beret/image.png"]),
    (img_row(31, 3, COL_R),    ["rsaf_cap_badge_bg_me8_above_service_hat/image.png"]),
    (img_row(31, 5, COL_L),    ["rsaf_cap_badge_col_me7/image.png"]),
    (img_row(31, 5, COL_R),    ["rsaf_cap_badge_sltc_me6_below/image.png"]),

    # p32 — Specialist + Enlistee (3 chevrons in one big row, full-width)
    (img_row(32, 8, COL_FULL), [
        "rsaf_specialist_insignia/image.png",
        "rsaf_enlistee_insignia/image.png",
    ]),

    # =====================================================================
    # RSAF placement diagrams (pp 34, 27)
    # =====================================================================
    # p34 — C-3 specialist + C-4 enlistee sleeve (lower half of page)
    (manual(34, (130, 1080, 905, 1530)),  ["rsaf_specialist_insignia/placement.png"]),
    (manual(34, (905, 1080, 1700, 1530)), ["rsaf_enlistee_insignia/placement.png"]),
    # Headdress / lanyard placement: RSAF A-1 from p27
    (manual(27, (430, 200, 1050, 1000)), [
        "rsaf_beret/placement.png",
        "rsaf_sikh_turban/placement.png",
        "rsaf_ladies_hat_bg_me8_above/placement.png",
        "rsaf_ladies_hat_officer_wo_me3_to_me8/placement.png",
        "rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee/placement.png",
        "rsaf_cap_embellishment_bg_me8_above/placement.png",
        "rsaf_cap_embellishment_col_me7/placement.png",
        "rsaf_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6/placement.png",
        "rsaf_cap_badge_bg_me8_above_beret/placement.png",
        "rsaf_cap_badge_bg_me8_above_service_hat/placement.png",
        "rsaf_cap_badge_col_me7/placement.png",
        "rsaf_cap_badge_sltc_me6_below/placement.png",
        "rsaf_lanyard_sa_ma/placement.png",
    ]),

    # =====================================================================
    # DIS product photos (pp 43-45)
    # =====================================================================
    (img_row(43, 1, COL_L),    ["dis_beret/image.png"]),
    (img_row(43, 1, COL_R),    ["dis_sikh_turban/image.png"]),
    (img_row(43, 5, COL_3_1),  ["dis_cap_badge_sltc_me6_below/image.png"]),
    (img_row(43, 5, COL_3_2),  ["dis_cap_badge_col_me7/image.png"]),
    (img_row(43, 5, COL_3_3),  ["dis_cap_badge_bg_me8_radm_above/image.png"]),
    (img_row(43, 8, COL_L),    ["dis_epaulettes_standard/image.png"]),
    (img_row(43, 8, COL_R),    ["dis_epaulettes_me_trainee/image.png"]),

    (img_row(44, 3, COL_L),    ["dis_specialist_insignia/image.png"]),
    (img_row(44, 3, COL_R),    ["dis_enlistee_insignia/image.png"]),
    (img_row(44, 8, COL_L),    ["dis_vocation_badge/image.png"]),
    (img_row(44, 8, COL_R),    ["dis_arms_badge/image.png"]),
    (img_row(44, 11, COL_R),   ["dis_protocol_name_tag/image.png"]),

    # =====================================================================
    # DIS placement diagrams (pp 46-50)
    # =====================================================================
    # p46 — C-1/C-2/C-3 cap badge on beret (3-col, top half)
    (manual(46, (180, 380, 700, 700)),  ["dis_cap_badge_sltc_me6_below/placement.png"]),
    (manual(46, (700, 380, 1180, 700)), ["dis_cap_badge_col_me7/placement.png"]),
    (manual(46, (1180, 380, 1700, 700)), ["dis_cap_badge_bg_me8_radm_above/placement.png"]),
    # p46 — C-4/C-5/C-6 cap badge on turban (full row, lower half)
    (manual(46, (180, 850, 1700, 1700)), [
        "dis_beret/placement.png",
        "dis_sikh_turban/placement.png",
    ]),
    # p47 — C-7 collar position (with/without arms badge)
    (manual(47, (130, 290, 1700, 950)), [
        "dis_arms_badge/placement.png",
        "dis_epaulettes_standard/placement.png",
        "dis_epaulettes_me_trainee/placement.png",
    ]),
    # p48 — C-9/C-10 sleeve insignia
    (manual(48, (130, 200, 905, 700)),  ["dis_specialist_insignia/placement.png"]),
    (manual(48, (905, 200, 1700, 700)), ["dis_enlistee_insignia/placement.png"]),
    # p49 — C-11/C-12 nametag, C-13 lanyard
    (manual(49, (130, 200, 1700, 600)),  ["dis_protocol_name_tag/placement.png"]),
    (manual(49, (130, 620, 1700, 1180)), ["dis_lanyard_ma_sa/placement.png"]),
    # p52 — D-9 SAF badges with vocation on top
    (manual(52, (130, 350, 1700, 950)), ["dis_vocation_badge/placement.png"]),
]


def main() -> int:
    if not PAGE_DIR.exists():
        sys.exit(
            f"Rendered page dir not found: {PAGE_DIR}\n"
            "Run: pdftoppm -png -r 220 <pdf> /tmp/saf-pdf-extract/pages/page"
        )

    written, skipped = 0, 0
    for spec, targets in MANIFEST:
        if not targets:
            continue
        try:
            page, bbox = _resolve(spec)
            img = _crop_and_trim(page, bbox)
        except Exception as e:
            print(f"  [skip] {spec}: {e}", file=sys.stderr)
            skipped += 1
            continue
        _save(img, targets)
        for t in targets:
            print(f"  wrote assets/accessories/{t}  ({img.size[0]}x{img.size[1]})")
        written += len(targets)
    print(f"\nDone. {written} files written, {skipped} crops skipped.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
