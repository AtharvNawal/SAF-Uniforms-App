# No. 4 Dress — doctrine alignment (Army, Navy, RSAF, DIS)

- **Date:** 2026-10-02
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — not `verified`: the device smoke test needs Firestore seeded (operator action, §2)

## 1. Goal
Make No. 4 Dress a real, doctrine-aligned dress code the way No. 3 already
is. Source: the SAF No.4 Dress PDF (26 pp; Army pp 1-6, Navy pp 7-12, RSAF
pp 13-18, DIS pp 19-26). Today `no_4_dress_requirements` is
`stub_pending_pdf` and points only at legacy placeholders, which
`DressAccessoryResolver` filters out. So the No.4 Wardrobe checklist is
empty and the No.4 3D model is a bare body.

The app plumbing for No.4 is already there (`DressCode.no4`, Home/Wardrobe
tiles, `/generating?dress=No4`, the Cloud Function `DRESS_CODES` maps). The
work is doctrine data, a few resolver shapes No.4 needs, imagery and
placeholder 3D assets.

## 2. Scope
**In scope**
- `assets/data/accessory_library.v1.json`: about 30 new No.4 entries:
  - **Alternative headdress:** jockey caps, jungle hats, Navy Kevlar
    helmet, RSAF ball cap, green field turban.
  - **Chest rank epaulettes:** No.4 wears a single rank tab at the centre
    of the chest for *every* rank. There are no sleeve chevrons and no
    collar pins. One standard and one cadet/trainee variant per branch.
  - **Tags and shirts:** `singapore_tag`, per-branch inner T-shirts.
  - **Belts:** Army olive-green belt, black belt for Navy/RSAF/DIS.
  - **Footwear and socks:** combat boots, safety boots/shoes, green socks.
  - **RSAF/DIS badges:** RSAF collar vocation badge, RSAF sleeve unit
    patch, DIS service and formation patches.
- The Army/Navy/RSAF berets go from `gender: men` to unisex, because ladies
  wear the beret in No.4. No.3 is unaffected: its ladies' path only reads
  the `ladies.*` hat keys.
- `assets/data/dress_requirements.v1.json`: rewrite `no_4_dress_requirements`
  as `pdf_aligned`, with per-branch `branch_overrides` and the PDF's notes
  and cm rules.
- Resolver (Dart + the TypeScript port, kept in parity) gains these shapes:
  1. `headdress` with top-level `unisex` / `sikh` / `sikh_col_me7_above`
     keys (gender-neutral). **This also fixes DIS No.3**, whose
     `{unisex, sikh}` headdress never resolved, so DIS users had no beret
     in their No.3 checklist or model.
  2. `headdress.alternatives` and `headdress.sikh_alternatives` lists, both
     optional.
  3. A `rank_epaulette` key `{standard, cadet_trainee}`, mandatory for all
     ranks. `cadet_trainee` applies to `Rank.oct`, the only cadet rank in
     the enum.
  4. `additional_mandatory` and `additional_optional` id lists, for items
     that don't need selector logic (Singapore tag, inner shirt, chest/sleeve
     badges, patches).
- `tool/extract_pdf_accessories_no4.py`: crop `image.png` (and
  `placement.png` where the PDF has a diagram) for each new id. It renders
  the PDF itself with PyMuPDF; `pdftoppm` is not installed here.
- `tool/generate_placeholder_accessories.py`:
  - Add an `--only-missing` flag. Today it overwrites every GLB, including
    the hand-tuned artist beret, belt and shoes.
  - Add builders for the new categories that have anchors.
  - Generate GLBs for the new ids.
- l10n: the No.4 tag "Working · long sleeve" is wrong (the PDF uniform is
  pixelised with rolled sleeves). Change it to "Working · Pixelised".
- Tests: resolver tests per branch for No.4, a DIS No.3 headdress
  regression test, a TS parity test, and a data-integrity test (every id
  referenced by a dress requirement exists in the library).

**Out of scope (follow-ups)**
- **cv-service rules for No.4** (`army_no4_male.json`). `/check_uniform`
  keeps returning `UNSUPPORTED_UNIFORM` for No.4, which is honest. That
  needs its own plan: new anchors (chest-centre rank tab), segmentation
  classes for the camo uniform, and a benchmark.
- No.4 uniform GLBs (`models/uniforms/*_no4_*.glb`). The merger already
  degrades to body + accessories.
- **Operator actions** that need the service-account JSON:
  - Upload images: `tool/upload_accessory_images.py`.
  - Seed Firestore: `tool/seed_firestore.dart`.
  - Upload GLBs: `tool/upload_models.py --only 'accessories/*'`.
  - **Until these run, the app on a device keeps showing the old stub**,
    because the app reads Firestore and not the JSON.
- Existing No.3 data quirks found while reading the code (noted here, not
  changed):
  - DIS No.3 `cap_badge.bg_me8_radm_above` and RSAF
    `bg_me8_above_beret/_service_hat` keys are never picked by
    `_pickByOfficerTier`. BG+ falls through to the SLTC badge.
  - DIS No.3 `epaulettes {standard, me_trainee}` never resolves.
  - Changing either would change existing No.3 composed models, so they
    belong in a separate plan.
  - The Dart resolver maps only `Gender.female` to ladies, while the TS
    port also maps `maternity`. Parity bug; it changes No.3 output for
    maternity profiles, so it goes in a separate plan.
- Admin-portal mock data. The portal already maps `pdf_aligned` to
  "live", so No.4 shows as live once seeded.

## 3. Affected areas
- `assets/data/accessory_library.v1.json`, `assets/data/dress_requirements.v1.json`
- `lib/features/checklist/domain/services/dress_accessory_resolver.dart`
- `functions/src/dress_accessory_resolver.ts` (+ new `dress_accessory_resolver.test.ts`)
- `test/features/checklist/dress_accessory_resolver_test.dart`, new `test/data/reference_data_integrity_test.dart`
- `tool/extract_pdf_accessories_no4.py` (new), `tool/generate_placeholder_accessories.py`
- `assets/accessories/<new ids>/`, `assets/3d/accessories/<new ids>.glb`
- `lib/core/l10n/arb/app_{en,zh}.arb` (+ regenerated `lib/core/l10n/generated/`)
- `CLAUDE.md`

No Firestore schema change: these are new docs in existing collections,
with new optional keys inside `branch_overrides`. No `MODEL_BUNDLE_VERSION`
bump is needed, because the profile hash inputs are unchanged. A DIS No.3
user whose model was already composed keeps the beret-less cached GLB until
their profile hash changes. Bumping the bundle version would force a rebuild
on every device, so I'm leaving that call to the operator.

## 4. Step-by-step plan
1. Write the resolver tests first: No.4 per branch, the DIS No.3 headdress
   case, and the alternatives / rank_epaulette / additional_* keys.
2. Extend the Dart resolver, with logging per policy 1.3. Port the change
   to the TS resolver line for line.
3. Add the library entries and rewrite the No.4 requirement doc.
4. Add the data-integrity test.
5. Extract images from the PDF and eyeball every crop.
6. Add `--only-missing` and the new builders to the GLB generator, then
   generate the missing GLBs only.
7. Update l10n, then run `flutter gen-l10n`.
8. Verify (§6), update CLAUDE.md, and set the status.

## 5. Risks & rollback
- **Resolver regression on No.3.** Covered by the existing No.3 tests. New
  keys are only read when present, and the only No.3 behaviour change is the
  intended DIS headdress fix.
- **Dart/TS drift.** Mitigated by mirrored tests over the same fixture.
- **Rollback:** revert the commit. Firestore stays untouched until the
  operator seeds it. After seeding, re-seed from the reverted JSON.
  `SetOptions.merge()` will not delete the new library docs, but nothing
  references them once No.4 is reverted.

## 6. Verification
- `flutter analyze`, `flutter test`
- `cd functions && npm run build && npm test`
- `python3 -m json.tool` on both JSON files; the data-integrity test
- Visual check of every extracted PNG and a load test of every new GLB
- `flutter run` device smoke test: **not possible from this session**
  (needs Firestore seeded and a device). Recorded as pending.

## 7. CLAUDE.md updates required
- §5.2 `DressAccessoryResolver` bullet: new override keys and the No.4 split.
- §5.5 `accessory_library` / `dress_requirements` description (No.4 now
  `pdf_aligned`) and the `composeUniformModel` resolver paragraph.
- §2 tool list: `extract_pdf_accessories_no4.py`, generator `--only-missing`.
- §8: the No.1/2/4/5 legacy note becomes No.1/2/5; add a No.4 note and the
  No.3 data quirks above.

## 8. Execution notes (2026-10-02)

**Data**
- 31 new library entries (82 → 113).
- Army/Navy/RSAF berets made unisex.
- `no_4_dress_requirements` rewritten as `pdf_aligned`.
- Rank-tab `render_logic` tuned to `belt_center` +20 cm / +0.5 cm. The
  first pass (+24 cm / +2 cm) sat at pocket-top height, 2 cm in front of
  the shirt. Final on-device tuning is still pending.

**Imagery**
- `tool/extract_pdf_accessories_no4.py` wrote 26 `image.png` and 13
  `placement.png` files.
- I reviewed every crop visually; all are correct. The Army jockey cap
  crop has a faint border line.
- These ids have no standalone image in the PDF, so they get a
  placement diagram only: `singapore_tag`, `rsaf_vocation_badge`,
  `rsaf_unit_patch`, `dis_service_patch`, `dis_formation_patch`.

**GLBs**
- `--only-missing` generated 20 new GLBs and modified no existing file
  (`git status` shows only additions).
- All 20 load in trimesh.

**Verification**
- `flutter analyze`: no issues.
- `flutter test`: 151/151 pass, including 15 new data-driven tests in
  `test/data/reference_data_integrity_test.dart`.
- I confirmed the DIS No.3 regression test **fails on the pre-change
  resolver** (`Expected: contains 'dis_beret'`) and passes after.
- `cd functions && npm test`: 37/37 pass, including 9 new parity tests.
- Both JSON files pass `python3 -m json.tool`.
- `flutter run`: **not run**. The app reads Firestore, so the No.4
  changes only show on a device after these operator steps:
  ```bash
  GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_accessory_images.py --bucket saf-uniforms.firebasestorage.app
  dart run tool/seed_firestore.dart <svc>.json
  GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app --only 'accessories/*'
  ```
  The Cloud Function resolver change also needs
  `firebase deploy --only functions`.

## 9. Post-deploy fix (2026-10-02)
The RSAF-men review found that No.4 `footwear` / `socks` used the No.3
"list = alternatives, all mandatory" shape:
- RSAF/DIS had safety boots + combat boots, Navy had 3 footwear items,
  and Army had green + black socks, all mandatory.
- Every one of these has a GLB, so the composed model stacked two pairs
  of boots or socks per foot, and the Wardrobe demanded both.

Fix:
- Each branch now has exactly one mandatory footwear and one mandatory
  socks item (black socks everywhere).
- The doctrine alternatives move to `additional_optional`.
- New tests assert exactly one mandatory footwear/socks item per branch.

**Needs a re-seed** (`dart run tool/seed_firestore.dart secrets/svc.json`)
to reach Firestore. No Storage or function change.
