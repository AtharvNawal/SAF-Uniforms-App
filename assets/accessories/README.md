# Accessory Imagery

Per-accessory PNGs that back `accessory_library.v1.json` /
`accessory_library/{accessoryId}` Firestore docs. Two files per accessory:

- `image.png` — the product / studio photo of the accessory itself.
- `placement.png` — the diagram showing where / how it's worn on the uniform.

Layout:

```
assets/accessories/
├── README.md                                    (this file)
├── <accessoryId>/
│   ├── image.png
│   └── placement.png
└── …
```

Each subdirectory id maps 1:1 to an `id` in
[`assets/data/accessory_library.v1.json`](../data/accessory_library.v1.json).
Some doctrine illustrations apply to many accessories (e.g. the male
nametag positioning diagram is identical across Army / Navy / RSAF / DIS) —
**duplicate the PNG into every relevant accessory folder**. Per design
decision in
[`ChangeRequest/2026-05-04_no3-accessory-images.md`](../../ChangeRequest/2026-05-04_no3-accessory-images.md)
we do not share via a `_shared/` folder; the seed script's logic stays
trivial when every entry is self-contained.

## Initial population (PDF-derived)

The PNGs currently committed are a first pass cropped programmatically
from the official **SAF No.3 Dress** PDF via
[`tool/extract_pdf_accessories.py`](../../tool/extract_pdf_accessories.py).
Each crop is auto-trimmed and padded with a small white border. Image
quality matches the source PDF (low-to-medium DPI raster). They are
**good enough to ship the UI** but should be replaced with higher-res
or vector assets when those land — the cheat sheet below remains useful
as the per-id source-picture map either way.

To regenerate from the PDF (operator workflow):

```bash
brew install poppler                           # one-time
python3 -m pip install --user --break-system-packages Pillow numpy
mkdir -p /tmp/saf-pdf-extract/pages
pdftoppm -png -r 220 <SAF_No_3_Dress.pdf> /tmp/saf-pdf-extract/pages/page
python3 tool/extract_pdf_accessories.py
```

The script's manifest references rows by their detected table-border
index — robust to small layout shifts but assumes the PDF structure
stays roughly the same. If a future PDF revision adds/removes table
rows, edit the row indices in the script's `MANIFEST` list.

## Operator workflow (replacing or refreshing images)

1. **Refresh / replace images**: either re-run the extraction script
   above (after dropping in a newer PDF), or manually replace any
   `assets/accessories/<accessoryId>/image.png` /
   `assets/accessories/<accessoryId>/placement.png` with a higher-res
   designer-supplied version. Naming + paths stay the same.
2. **Upload to Firebase Storage** via the Python uploader (Dart's
   `--upload-images` flag is broken — see CLAUDE.md §5.5):
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=<path-to-svc-account>.json \
     python3 tool/upload_accessory_images.py \
       --bucket saf-uniforms.firebasestorage.app
   ```
   It uploads each pair to
   `gs://saf-uniforms.firebasestorage.app/accessories/{id}/{image,placement}.png`,
   patches the JSON with the resolved `https://firebasestorage…` URLs,
   and writes the JSON file back. SHA-256 metadata makes reruns
   idempotent — only changed PNGs re-upload.
3. **Push the patched JSON to Firestore**:
   ```bash
   dart run tool/seed_firestore.dart <path-to-svc-account>.json
   ```
4. Commit the JSON change + the new PNGs.
5. Once on a fresh project: `firebase deploy --only storage` so the
   `storage.rules` ACL is live (auth-required reads with download-token
   bypass for in-app fetches).

## Source-picture cheat sheet — SAF No.3 Dress PDF

The PDF groups visuals four ways: **A-pictures** (full-figure dress),
**B-pictures** (full-figure ladies), **C-pictures** (placement diagrams
for collar / nametag / belt), and **D-pictures** (medal-ribbon and badge
placement). Below is the mapping per id; pages are the PDF page numbers.

### Army (No.3)

| Accessory id | image.png source | placement.png source |
|---|---|---|
| `army_beret` | p4 "Beret" | p4 same crop or A-1 (p1) |
| `army_sikh_turban_standard` | p4 "Turban with red fifti" | p4 same crop |
| `army_sikh_turban_col_me7_above` | p4 "Turban with red fifti and a red band (COL/ME7 and above)" | p4 same crop |
| `army_ladies_hat_officer_wo_me3_to_me8` | p4 "Hat for Officers and Warrant Officers/ME3 to ME8" | p4 same crop |
| `army_ladies_hat_specialist_enlistee_me1_me2` | p4 "Hat for Specialists and Enlistees/ME1 and ME2" | p4 same crop |
| `army_cap_badge_sltc_me6_below` | p4 "Standard cap badge for SLTC/ME6 and below" | p4 same crop |
| `army_cap_badge_col_me7` | p4 "Cap badge for COL/ME7" | p4 same crop |
| `army_cap_badge_bg_me8_above` | p4 "Cap badge for BG/ME8 and above" | p4 same crop |
| `army_cap_badge_military_police` | p4 "Cap badge for Military Police" | p4 same crop |
| `army_specialist_insignia` | p6 "Rank insignias for Specialists" | p9 Picture C-3 |
| `army_enlistee_insignia` | p6 "Rank insignias for Enlistees" | p9 Picture C-4 |
| `army_arms_badge` | p6 "Arms badge" | p9 Picture C-5 |
| `army_lanyard_sa_ma` | p6 "Lanyard for SA/MA" | A-1 / A-3 (p1) — left shoulder shown |

### Navy (No.3)

| Accessory id | image.png source | placement.png source |
|---|---|---|
| `navy_beret` | p18 "Beret" | p18 same crop |
| `navy_sikh_turban_standard` | p18 "Dark blue turban with black fitti" | p18 same crop |
| `navy_sikh_turban_3wo_me3_above` | p18 "White turban with black fitti (3WO/ME3 and above)" | p18 same crop |
| `navy_ladies_hat_officer_wo_me3_to_me8` | p18 "Hat for Officers and Warrant Officers/ME3 to ME8" | p18 same crop |
| `navy_ladies_hat_specialist_rating_cadet_me_trainee` | p18 "Hat for Specialists, Ratings, ME1 and ME2, Officer Cadets and Military Expert trainees" | p18 same crop |
| `navy_cap_embellishment_bg_me8_above` | p18 "Cap embellishment for BG/ME8 and above" | p18 same crop |
| `navy_cap_embellishment_col_me7` | p18 "Cap embellishment for COL/ME7" | p18 same crop |
| `navy_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6` | p18 "Cap embellishment for MAJ to SLTC, SWO to CWO and ME5 to ME6" | p18 same crop |
| `navy_cap_badge_col_me7_above` | p19 "Cap badge for COL/ME7 and above" | p19 same crop |
| `navy_cap_badge_sltc_me6_below` | p19 "Cap badge for SLTC/ME6 and below" | p19 same crop |
| `navy_specialist_insignia` | p19 "Rank insignias for Specialists" | p21 Picture C-3 |
| `navy_rating_insignia` | p19 "Rank insignias for Ratings" | p21 Picture C-4 |
| `navy_lanyard_ma_na` | p20 "Lanyard for MA/NA" | A-1 (p15) — left shoulder shown |

### RSAF (No.3)

| Accessory id | image.png source | placement.png source |
|---|---|---|
| `rsaf_beret` | p30 "Beret" | p30 same crop |
| `rsaf_sikh_turban` | p30 "Turban with blue fifty for Sikh personnel" | p30 same crop |
| `rsaf_ladies_hat_bg_me8_above` | p30 "Hat for BG/ME8 (Female) and above" | p30 same crop |
| `rsaf_ladies_hat_officer_wo_me3_to_me8` | p30 "Service Hat for Officers, Warrant Officers and ME3 to ME8" | p30 same crop |
| `rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee` | p30 "Service Hat for Specialists, ME1 to ME2, Officer Cadet / Military Expert Trainees" | p30 same crop |
| `rsaf_cap_embellishment_bg_me8_above` | p31 "Cap embellishment for BG/ME8 and above" | p31 same crop |
| `rsaf_cap_embellishment_col_me7` | p31 "Cap embellishment for COL/ME7" | p31 same crop |
| `rsaf_cap_embellishment_maj_to_sltc_swo_to_cwo_me5_to_me6` | p31 "Cap embellishment for MAJ to SLTC, SWO to CWO and ME5 to ME6" | p31 same crop |
| `rsaf_cap_badge_bg_me8_above_beret` | p31 "Cap badge for BG/ME8 and above (Beret)" | p31 same crop |
| `rsaf_cap_badge_bg_me8_above_service_hat` | p31 "Cap badge for BG/ME8 and above (Service Hat Only)" | p31 same crop |
| `rsaf_cap_badge_col_me7` | p31 "Cap badge for COL/ME7" | p31 same crop |
| `rsaf_cap_badge_sltc_me6_below` | p31 "Cap badge for SLTC/ME6 and below" | p31 same crop |
| `rsaf_specialist_insignia` | p32 "Rank insignias for Specialist" | p34 Picture C-3 |
| `rsaf_enlistee_insignia` | p32 "Rank insignias for Enlistees" | p34 Picture C-4 |
| `rsaf_lanyard_sa_ma` | p33 "Lanyard for SA/MA" | A-1 (p27) — left shoulder shown |

### DIS (No.3)

| Accessory id | image.png source | placement.png source |
|---|---|---|
| `dis_beret` | p43 "Beret (For Men and Ladies)" | p46 Pictures C-1 / C-2 / C-3 |
| `dis_sikh_turban` | p43 "Dark grey turban with black fifti" | p46 Pictures C-4 / C-5 / C-6 |
| `dis_cap_badge_sltc_me6_below` | p43 "Cap badge for SLTC/ME6 and below" | p46 Picture C-1 |
| `dis_cap_badge_col_me7` | p43 "Cap badge for COL/ME7" | p46 Picture C-2 |
| `dis_cap_badge_bg_me8_radm_above` | p43 "Cap badge for BG/ME8/RADM and above" | p46 Picture C-3 |
| `dis_epaulettes_standard` | p43 "Epaulettes for Officers, Warrant Officers, Military Experts, Specialists" | A-1 / B-1 (p40 / p41) |
| `dis_epaulettes_me_trainee` | p43 "Epaulettes for Military Expert trainees" | A-1 / B-1 (p40 / p41) |
| `dis_specialist_insignia` | p44 "Specialist (3SG)" | p48 Picture C-9 |
| `dis_enlistee_insignia` | p44 "Enlistees (LCP / CPL)" | p48 Picture C-10 |
| `dis_vocation_badge` | p44 "Vocation Badge (left chest)" | p52 Picture D-7 / D-9 |
| `dis_arms_badge` | p44 "Arms Badge (right collar)" | p47 Picture C-7 |
| `dis_protocol_name_tag` | p44 "Protocol Name Tag" | p49 Picture C-11 / C-12 |
| `dis_lanyard_ma_sa` | p45 "Lanyard for MA/SA" | p49 Picture C-13 / C-14 / C-15 |

### Generic / cross-branch (apply to No.3 across services)

Use the cleanest illustration available; many of these recur across all
four branch chapters of the PDF. Duplicate each PNG into every relevant
folder.

| Accessory id | image.png source | placement.png source |
|---|---|---|
| `name_tag_standard` | p6 "Name tag" (Army) or equivalent crop | p10 Pictures C-6 / C-7 |
| `nylon_belt` | p7 "Nylon belt for men" | p10 Picture C-8 |
| `leather_belt` | p7 "Leather belt for ladies" | p50 Picture C-16 (ladies sub-figure) |
| `leather_shoes_low_cut` | p7 "Black leather low-cut shoes for men" | A-1 / A-2 (p1) |
| `patent_shoes_low_cut` | p7 "Patent black low-cut shoes" | A-1 / A-2 (p1) |
| `court_shoes` | p7 "Black court shoes for ladies" | B-1 / B-2 (p2) |
| `patent_court_shoes` | p45 "Black court / Patent court shoes for ladies" | B-1 / B-2 (p2) |
| `black_socks` | p7 "Black socks" | A-1 (p1) |
| `epaulettes_standard` | p5 "Epaulettes for Officers, WOSEs, Military Experts, Specialists and Enlistees" | A-1 (p1) |
| `epaulettes_officer_cadet_me_trainee` | p5 "Epaulettes for Officer cadets and Military Expert trainee" | A-1 (p1) |
| `collar_rank_pins` | p5 "Collar rank pins for Officers, Warrant Officers and Military Experts" | p8 Picture C-1 |
| `gorgette_lady_officer_cadet` | p5 "Gorgette for Lady Officer cadet" | p8 Picture C-2 |
| `gorgette_lady_me_trainee` | p5 "Gorgette for Lady Military Expert trainee" | p8 Picture C-2 |
| `medal_ribbons` | p11 "Wearing of single medal ribbon" (Army) | p11 Pictures D-1 to D-6 |
| `saf_badges_chest` | p12 Picture D-7 (single badge) | p12 Pictures D-7 / D-8 / D-9 / D-10 |
| `foreign_badges` | p13 Picture D-17 (foreign badges, male) | p13 Pictures D-17 / D-18 |
| `skill_badges_sleeve` | p12 Picture D-11 (marksmanship) | p12 Pictures D-11 to D-16 |
| `skill_tabs_sleeve` | p12 Picture D-13 (tabs and IPPT badge) | p12 Pictures D-13 / D-14 |

## Out-of-scope ids

These are legacy placeholders (`render_logic.legacy_placeholder == true`)
that exist for No.1 / 2 / 4 / 5 dresses pending their doctrine PDFs.
**Do not** create folders for them yet — the resolver filters them out
and the UI handles the empty `imageUrl` gracefully:

`arms_badge_vocation`, `beret_standard`, `epaulettes`,
`gorgettes_ladies_only`, `ladies_service_hat_a`,
`ladies_service_hat_b`, `lanyard_ma_sa`, `name_tag`,
`rank_insignia_sleeve`, `turban_sikh`.
