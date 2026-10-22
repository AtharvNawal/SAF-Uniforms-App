# No.4: combat boots required, safety boots optional

- **Date:** 2026-10-19
- **Author:** Claude (agent)
- **Status:** executed (not device-verified)

## 1. Goal
Product-owner decision (overrides the PDF's per-service default): in
No.4, **combat boots are compulsory** for every service and **safety
boots are optional**.

## 2. Scope
- `no_4_dress_requirements.branch_overrides`:
  - Navy: `footwear` `safety_boots_mid_cut` → `combat_boots`;
    `safety_boots_mid_cut` moves to `additional_optional` (with
    `safety_shoes_low_cut`).
  - RSAF / DIS: `footwear` `safety_boots` → `combat_boots`; `safety_boots`
    moves to `additional_optional`.
  - Army unchanged (already combat boots). Footwear rule text updated.
- RSAF No.4 dressed figure: its built-in boots are declared
  `combat_boots` (`assets/3d/figures/rsaf_no4.json`), otherwise compose
  would strip the artist boots and attach the placeholder combat-boot GLB.
  Re-prepare both figures and upload them.
- Out: cv-service (its RSAF footwear rule is presence + black only).

## 3. Steps
1. Data + figure config; tests (`reference_data_integrity_test`).
2. Re-prepare `rsaf_no4_{male,female}.glb`; `upload_models.py --only
   'bodies/rsaf_no4_*'`.
3. Seed Firestore; analyze / test.

## 4. Risks & rollback
Existing cached RSAF No.4 GLBs keep their boots (unchanged look). Ticking
safety boots as an optional item keeps the built-in boots (optional
alternatives never strip a built-in part). Rollback: revert JSON + config,
re-prepare, re-upload, re-seed.

## 5. Verification
`flutter analyze`, `flutter test`, seed + upload output.

## 6. CLAUDE.md updates
No.4 footwear notes (§5.5 accessory list, §8 No.4 summary).

## 7. Execution notes (2026-10-19)
- Data + figure config changed; `reference_data_integrity_test` gains a
  combat-boots-compulsory test. `flutter analyze` clean, `flutter test`
  198/198.
- `prepare_unified_figure.mjs` failed locally: iCloud Drive had offloaded
  ~6 500 files of `functions/node_modules` ("dataless"), which Node reads
  as empty. Ran the tool against a fresh `npm ci` of `functions/` outside
  iCloud instead (tool unchanged). Both figures re-prepared; the only
  difference vs. the previous files is `saf_baked_slots.footwear.accessory`
  (`safety_boots` → `combat_boots`).
- Uploaded `models/bodies/rsaf_no4_{male,female}.glb` (2, failed 0), then
  re-seeded Firestore. No app rebuild needed (data only).
