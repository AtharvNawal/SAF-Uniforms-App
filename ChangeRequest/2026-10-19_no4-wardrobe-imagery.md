# No.4 imagery + doctrine text in the Wardrobe detail sheet

- **Date:** 2026-10-19
- **Author:** Claude (agent)
- **Status:** executed (not device-verified)

## 1. Goal
In the Wardrobe (No.4 selected), tapping an item showed No.3 pictures
for items shared with No.3 (name tag on a khaki No.3 shirt, beret, cap
badges, turbans, SAF / sleeve / foreign badges) and the placeholder text
"Refer to branch doctrine for exact placement of this accessory."
Show the SAF No.4 Dress PDF pictures (per service where the PDF has
them) and the real doctrine text.

## 2. Scope
- In: dress-specific (and dress+branch-specific) image overrides on
  `accessory_library` entries; extraction from the No.4 PDF; upload to
  Storage; Firestore re-seed; detail sheet picks the override + doctrine
  text for the dress being viewed.
- Out: full-figure "how it's worn" pictures (too small in the 5:3 slot);
  No.1/2/5; cv-service.

## 3. Affected areas
- Data: `accessory_library.v1.json` gains optional
  `dress_images: {"no4" | "no4_<branch>": {image_url, placement_diagram}}`
  and a few `no4_placement` rule strings from the PDF.
- Assets: `assets/accessories/<id>/<variant>_{image,placement}.png`
  (flat names — fits the existing `accessories/{id}/{fileName}` Storage
  rule, no rules deploy). A few missing base `image.png`s (Singapore tag,
  RSAF unit patch / vocation badge, DIS patches) cropped from the PDF.
- `tool/extract_pdf_accessories_no4.py` (manifest), `tool/upload_accessory_images.py`
  (variant files → `dress_images`).
- `Accessory` entity (+ freezed regen), `AccessoryFirestore` DTO.
- New pure `checklist/domain/services/accessory_presentation.dart`:
  `imagesFor(accessory, dress, branch)` + `doctrineText(accessory, dress, gender)`
  (Wearing Guide's `pickDoctrineTip` moves here).
- `accessory_detail_sheet.dart` + its callers (Wardrobe tab, dress
  accessories screen) pass the dress being viewed.

## 4. Step-by-step plan
1. Extend extractor manifest; run it; eyeball a contact sheet.
2. Uploader support for variant files; run against `saf-uniforms` bucket.
3. Entity/DTO/domain helpers + sheet wiring; tests.
4. `dart run tool/seed_firestore.dart secrets/svc.json`.
5. analyze / test / build APK.

## 5. Risks & rollback
- Re-seed writes all four reference collections from the repo JSON
  (merge) — same as every previous seed. Rollback: revert JSON, re-seed.
- Old app builds ignore `dress_images` (unknown field) — safe.

## 6. Verification
- `flutter analyze`, `flutter test`, build APK; uploader + seed output
  counts; device check by the user.

## 7. CLAUDE.md updates required
- §5.5 `accessory_library` field list + Storage layout; §2 tool notes for
  the extractor/uploader; §4 checklist domain file.

## 8. Execution notes (2026-10-19)
- Extractor wrote 55 new PNGs (contact sheet checked by eye — every crop
  matches its label). Uploaded: `uploaded=55 skipped=178 failed=0
  json_patched=31`. 34 `no4*_placement` / `no4_applicability` rule
  strings added from the PDF notes. Seeded: 113 accessory docs. Spot-
  checked three `dress_images` URLs → HTTP 200 `image/png`.
- `flutter analyze` clean; `flutter test` 188/188 (new
  `test/features/checklist/accessory_presentation_test.dart` against the
  seed JSON). Release APK rebuilt.
- Mishap: a `dart format lib/features` run reformatted unrelated files.
  Clean-at-start files were restored from git and my edits replayed; the
  three files with pre-existing uncommitted edits
  (`ar_scanner_screen.dart`, `dashboard_screen.dart`,
  `generating_screen.dart`) and the untracked `supported_uniforms*.dart`
  stay formatted (whitespace / trailing-comma only, behaviour unchanged).
- Gaps: no PDF placement pictures for belts / boots / socks / inner
  shirts / alternative headdress (sheet shows its drawn fallback); RSAF
  has no tabs or foreign-badge pages (base pictures); patch close-ups are
  low-resolution in the source PDF.

## 9. Follow-up (2026-10-19) — placement pictures for the remaining items
- User asked for placement pictures on every accessory. Cropped from the
  full-uniform figures: feet (Army A-1 / Navy Fig. 1 / RSAF A-2 / DIS A-1)
  → `combat_boots`, `safety_boots` (+ `no4_dis`), `safety_boots_mid_cut`,
  `green_socks`, `black_socks` (`no4_<branch>`); RSAF A-3 head →
  `rsaf_jockey_cap`; DIS A-1 neckline → `dis_no4_inner_tshirt`.
  Uploaded 11, failed 0; re-seeded. Data only — no app change.
- Still none (no picture in the PDF shows them worn): belts (hidden under
  the shirt on every figure), Navy / RSAF inner shirts, low-cut safety
  shoes, Army / Navy jockey caps, jungle hats, Navy Kevlar helmet, RSAF
  ball cap, green field turban.
