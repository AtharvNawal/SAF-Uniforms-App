#!/usr/bin/env python3
"""Operator-only: extract per-accessory PNGs from the SAF No.4 Dress PDF.

Sibling of `tool/extract_pdf_accessories.py` (the No.3 extractor). The
No.4 PDF embeds every accessory photo as a discrete image, so instead of
detecting table rows on a rasterised page this script renders an exact
clip rectangle (PDF points, taken from `page.get_image_rects()`) per
manifest entry with PyMuPDF — no `pdftoppm` needed.

Writes `assets/accessories/<id>/{image,placement}.png` for the No.4-only
accessory ids. Accessories shared with No.3 (berets, cap badges, turbans,
black socks, name tag) keep their existing No.3 imagery and are not in
the manifest. Re-runnable: overwrites in place.

Prerequisite (one-time):
    .venv-tools/bin/pip install pymupdf Pillow

Run from the repo root:
    .venv-tools/bin/python tool/extract_pdf_accessories_no4.py <SAF_No_4_Dress.pdf>

Then push with `tool/upload_accessory_images.py` and re-seed Firestore.
"""
from __future__ import annotations

import io
import sys
from pathlib import Path

try:
    import pymupdf
    from PIL import Image, ImageChops, ImageOps
except ImportError:  # pragma: no cover
    sys.exit("PyMuPDF + Pillow are required: .venv-tools/bin/pip install pymupdf Pillow")

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_ROOT = REPO_ROOT / "assets" / "accessories"

# Render scale (1 PDF point → ZOOM px). 4 ≈ 288 DPI, above the source
# images' native resolution, so nothing is lost.
ZOOM = 4.0
_TRIM_PAD = 12

# (1-based page, (x0, y0, x1, y1) in PDF points, [targets])
MANIFEST: list[tuple[int, tuple[float, float, float, float], list[str]]] = [
    # --- Army (pp 1-6) ---
    (2, (115, 118, 249, 234), ["army_jockey_cap/image.png"]),
    (2, (356, 123, 479, 238), ["sikh_field_turban_green/image.png"]),
    (2, (249, 528, 349, 624), ["army_jungle_hat/image.png"]),
    (3, (84, 152, 281, 222), ["army_no4_rank_epaulette/image.png"]),
    (3, (358, 152, 476, 222), ["army_no4_rank_epaulette_cadet_trainee/image.png"]),
    (3, (123, 255, 252, 354), ["army_no4_belt/image.png"]),
    (3, (347, 255, 469, 354), ["combat_boots/image.png"]),
    (3, (169, 380, 266, 473), ["green_socks/image.png"]),
    # Picture C-1: chest layout (name tag / Singapore tag / centre rank tab).
    (4, (109, 163, 253, 271), [
        "singapore_tag/placement.png",
        "army_no4_rank_epaulette/placement.png",
        "army_no4_rank_epaulette_cadet_trainee/placement.png",
    ]),
    # --- Navy (pp 7-12) ---
    (8, (132, 87, 252, 176), ["navy_jockey_cap/image.png"]),
    (8, (119, 390, 253, 485), ["navy_kevlar_helmet/image.png"]),
    (8, (341, 377, 467, 477), ["navy_jungle_hat/image.png"]),
    (9, (88, 65, 279, 132), ["navy_no4_rank_epaulette/image.png"]),
    (9, (328, 64, 484, 131), ["navy_no4_rank_epaulette_cadet_trainee/image.png"]),
    (10, (144, 161, 262, 271), ["no4_belt_black/image.png"]),
    (10, (299, 116, 509, 303), ["navy_no4_inner_shirt_grey/image.png"]),
    (10, (105, 361, 215, 469), ["safety_boots_mid_cut/image.png"]),
    (10, (233, 370, 362, 450), ["safety_shoes_low_cut/image.png"]),
    (11, (92, 126, 282, 248), [
        "navy_no4_rank_epaulette/placement.png",
        "navy_no4_rank_epaulette_cadet_trainee/placement.png",
    ]),
    # --- RSAF (pp 13-18) ---
    (14, (112, 148, 254, 257), ["rsaf_jockey_cap/image.png"]),
    (14, (356, 147, 484, 264), ["rsaf_ball_cap/image.png"]),
    # Picture B-8 holds both rows in one image: top = standard, bottom = cadet / trainee.
    (15, (85, 106, 510, 198), ["rsaf_no4_rank_epaulette/image.png"]),
    (15, (85, 198, 510, 288), ["rsaf_no4_rank_epaulette_cadet_trainee/image.png"]),
    (15, (331, 360, 493, 515), ["rsaf_no4_inner_tshirt/image.png"]),
    (15, (87, 611, 252, 761), ["safety_boots/image.png"]),
    (17, (126, 161, 469, 401), [
        "rsaf_vocation_badge/placement.png",
        "rsaf_no4_rank_epaulette/placement.png",
        "rsaf_no4_rank_epaulette_cadet_trainee/placement.png",
    ]),
    (18, (168, 446, 428, 701), ["rsaf_unit_patch/placement.png"]),
    # --- DIS (pp 19-26) ---
    (21, (135, 140, 459, 213), ["dis_no4_rank_epaulette/image.png"]),
    (21, (135, 210, 459, 280), ["dis_no4_rank_epaulette_cadet_trainee/image.png"]),
    (21, (309, 349, 512, 493), ["dis_no4_inner_tshirt/image.png"]),
    (24, (129, 98, 465, 297), [
        "dis_service_patch/placement.png",
        "dis_formation_patch/placement.png",
    ]),
    (24, (78, 477, 290, 619), [
        "dis_no4_rank_epaulette/placement.png",
        "dis_no4_rank_epaulette_cadet_trainee/placement.png",
    ]),
]


def _render(doc: "pymupdf.Document", page_no: int, rect: tuple) -> Image.Image:
    page = doc[page_no - 1]
    pix = page.get_pixmap(
        matrix=pymupdf.Matrix(ZOOM, ZOOM), clip=pymupdf.Rect(*rect), alpha=False
    )
    img = Image.open(io.BytesIO(pix.tobytes("png"))).convert("RGB")
    # Auto-trim near-white borders, then pad (same treatment as the No.3 tool).
    bg = Image.new("RGB", img.size, (255, 255, 255))
    diff = ImageChops.add(ImageChops.difference(img, bg), ImageChops.difference(img, bg),
                          scale=2.0, offset=-30)
    box = diff.getbbox()
    if box is not None:
        img = ImageOps.expand(img.crop(box), border=_TRIM_PAD, fill=(255, 255, 255))
    return img


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__)
        return 2
    pdf = Path(argv[1])
    if not pdf.exists():
        print(f"ERROR: PDF not found: {pdf}", file=sys.stderr)
        return 1
    doc = pymupdf.open(pdf)
    if doc.page_count != 26:
        print(f"WARNING: expected the 26-page SAF No.4 PDF, got {doc.page_count} pages; "
              "manifest coordinates may be wrong.", file=sys.stderr)
    written = 0
    for page_no, rect, targets in MANIFEST:
        try:
            img = _render(doc, page_no, rect)
        except Exception as e:  # noqa: BLE001 — report and continue with the rest
            print(f"ERROR: page {page_no} {rect}: {e}", file=sys.stderr)
            continue
        for rel in targets:
            out = OUT_ROOT / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            img.save(out, "PNG", optimize=True)
            written += 1
            print(f"  wrote {rel} ({img.width}x{img.height})")
    print(f"Wrote {written} PNG(s) under {OUT_ROOT.relative_to(REPO_ROOT)}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
