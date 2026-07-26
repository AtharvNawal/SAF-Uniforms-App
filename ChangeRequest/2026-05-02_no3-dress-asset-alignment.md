# SAF No. 3 Dress — Asset Data Alignment with Doctrine PDF

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7)
- **Status:** executed (pending device smoke test for `verified`)
- **Verification log (executed step):**
  - `python3 -c "import json; ..."` on all 3 files: PASS
  - `flutter analyze`: clean (`No issues found! (ran in 2.7s)`)
  - `flutter test`: 15/15 PASS (uniform_provider_test, coordinate_map_provider_test, dress_requirement_test)
  - Cross-reference scan: 76/76 candidate accessory IDs in `dress_requirements.v1.json` resolve against `accessory_library.v1.json` (the 10 unresolved candidates are all non-IDs: dress_requirement IDs, doctrine_status enums, free-form labels, and the deliberately-named `*_per_branch` placeholder strings that callers will resolve via `branch_overrides`).

## 1. Goal

Align the three bundled asset files
([assets/data/branch_configs.v1.json](../assets/data/branch_configs.v1.json),
[assets/data/dress_requirements.v1.json](../assets/data/dress_requirements.v1.json),
[assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json))
with the official **SAF No. 3 Dress** specification PDF (Army, Navy,
RSAF, DIS — men, ladies, maternity).

The current entries are stubs (CLAUDE.md §8 flags them as "placeholder
values pending doctrine review"). This change replaces the stubs with
PDF-derived data for No. 3 only. Other dress codes (No. 1, 2, 4, 5)
remain stubs until their doctrine PDFs are provided.

## 2. Scope

### In scope

- Refresh `branch_configs.v1.json`: per-branch `ladiesMedalAnchor`
  numerics, `sikhTurbanLogic.color` documentary strings; bump to v3.
- Replace `accessory_library.v1.json` content: ~22 stubs → ~80
  per-branch+rank-tier entries (berets, sikh turbans, ladies hats, cap
  badges, cap embellishments, epaulettes, gorgettes, sleeve ranks,
  arms/vocation badges, name tags, lanyards, belts, footwear, ribbons,
  badges, tabs); bump to v3.
- Restructure only `no_3_dress_requirements` in
  `dress_requirements.v1.json` to populate `branch_overrides` per branch
  with the new accessory IDs and PDF-derived rank-tier maps; bump to v3.
- Update [CLAUDE.md](../CLAUDE.md) §5.5 and §8 to reflect the new
  doctrine-aligned No. 3 baseline.

### Out of scope

- Maternity uniform modeling (deferred — requires `UniformProfile`
  changes; will be its own plan).
- Other dress codes (No. 1, 2, 4, 5) — they keep current generic
  branch-agnostic stubs until their doctrine PDFs land.
- Drift schema migration / freezed regen / DTO changes — this is an
  asset-only update. All new structure lives inside the existing
  `rules` / `render_logic` JSON columns on accessories and inside the
  existing `branch_overrides` opaque map on dress requirements.
- Real CDN art — image URLs stay as `https://cdn.saf.sg/...` stubs
  (matches existing convention; CLAUDE.md §8 flags art review as a
  separate workstream).
- Wiring `branch_overrides`'s new structured keys into the checklist UI
  / AR engine — those consumers will read the new shape in a future
  plan; today the data is schema-ready but inert (`mergedFor` does not
  yet deep-merge the structured keys, only swaps top-level
  `mandatory_rules` / `optional_logic` lists).

## 3. Affected areas

- [assets/data/branch_configs.v1.json](../assets/data/branch_configs.v1.json)
- [assets/data/dress_requirements.v1.json](../assets/data/dress_requirements.v1.json)
- [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json)
- [CLAUDE.md](../CLAUDE.md) §5.5 and §8

Not touched: `lib/`, Drift tables/migrations, codegen output,
seeders, repositories, tests.

## 4. Step-by-step plan

1. ✅ Create this plan file.
2. Edit `branch_configs.v1.json`:
   - Bump `version: 2 → 3`.
   - Update `ladiesMedalAnchor` per branch to anchor names that match
     the PDF: Army/RSAF/DIS use `nameTagBaseLine` (y=0); Navy uses
     `shoulderSeamCenter` (y=15.0).
   - Update `sikhTurbanLogic.color` per branch to documentary strings:
     `darkBlueWithRedFifti` (Army), `darkBlueWithBlackFifti` (Navy),
     `blueWithBlueFifti` (RSAF), `darkGreyWithBlackFifti` (DIS).
   - Keep all other top-level keys unchanged
     ([branch_config_seeder.dart](../lib/core/local_db/seed/branch_config_seeder.dart)
     reads them positionally as `as String` / `as num`).
3. Rewrite `accessory_library.v1.json`:
   - Bump `version: 2 → 3`.
   - Replace stub generics with per-branch+rank-tier entries
     (categories listed in the linked plan file at
     `/Users/meet/.claude/plans/here-is-the-attached-structured-turtle.md`).
   - Each new entry uses the existing nullable `branch_id` /
     `category` / `gender` columns appropriately.
   - Encode known measurement rules in `rules` (e.g. allowance 8–12 cm
     on lanyard, cadet white-backing 53 mm on cap badges, marksmanship
     0.5 cm above IPPT for Army).
   - Branch-aware `medal_ribbons.render_logic.ladies_anchor_per_branch`.
4. Edit `dress_requirements.v1.json`:
   - Bump `version: 2 → 3`.
   - In `no_3_dress_requirements`:
     - Restructure `mandatory_rules` to add `Headdress`, `Cap_Badge`,
       and refined `Rank_Insignia` categories pointing to
       `branch_overrides`.
     - Rename `name_tag` → `name_tag_standard` to track the
       library rename (also propagate the rename in the No. 1, 2, 4,
       5 entries' `Identification` rules).
     - Rename `epaulettes` → `epaulettes_standard` (likewise across
       No. 1, 2 entries).
     - Rename `arms_badge_vocation` → `arms_badge_or_vocation` (placeholder
       resolved via `branch_overrides`) in optional_logic.
     - Rename `rank_insignia_sleeve` → `sleeve_rank_specialist` /
       `sleeve_rank_enlistee` per rank group.
     - Populate `branch_overrides` for `army`, `navy`, `rsaf`, `dis`
       with full per-branch maps.
   - For other dress codes (No. 1, 2, 4, 5), apply only the renames
     `name_tag` → `name_tag_standard`, `epaulettes` →
     `epaulettes_standard`, `rank_insignia_sleeve` →
     `sleeve_rank_specialist` / `sleeve_rank_enlistee`,
     `gorgettes_ladies_only` → `gorgette_lady_officer_cadet`. Do not
     restructure these — their doctrine review is deferred.
5. Run `python3 -c "import json; ..."` to validate all three files
   parse cleanly.
6. Run `flutter analyze` (no Dart files changed; expected clean).
7. Update [CLAUDE.md](../CLAUDE.md) §5.5 and §8.
8. Mark this plan `Status: executed`, then `verified` after smoke-test
   (next launch — owner verifies seeder logs).

## 5. Risks & rollback

### Risks

- **Renamed accessory IDs.** Anything that hard-codes `name_tag`,
  `epaulettes`, `gorgettes_ladies_only`, `rank_insignia_sleeve`, or
  `arms_badge_vocation` will break. Mitigation: grep for each old ID
  before edit (none should exist outside the asset files); the renames
  ripple through the `dress_requirements.v1.json` references.
- **Version bump triggers Firestore replace.** Once the bundled v3
  hits a device, the local "v3 wins" rule means a Firestore that
  still holds v2 is *not* picked up; that is the intended direction
  (bundled is fresher than not-yet-seeded Firestore). When
  `FirestoreSeeder.seedAll()` is run from debug mode, it re-uploads
  the new bundled v3 to Firestore, restoring parity.
- **branch_overrides shape is new.** Today's
  `DressRequirement.mergedFor` only swaps top-level
  `mandatory_rules` / `optional_logic` if the override supplies them.
  The new structured keys (`headdress`, `cap_badge`,
  `rank_insignia_sleeve`, `lanyard`, etc.) are stored verbatim and
  ignored by current callers — no crash, no visual change. Future
  consumers will deep-merge.
- **No image art** — images stay as `https://cdn.saf.sg/...` stub
  URLs; UI loaders should already gracefully handle missing remote
  art (CLAUDE.md §8). New stub URLs follow the same pattern.

### Rollback

`git checkout HEAD~1 -- assets/data/branch_configs.v1.json
assets/data/dress_requirements.v1.json
assets/data/accessory_library.v1.json` and bump version back to 2.

## 6. Verification

Per CLAUDE.md policy 1.5:

1. JSON validity:
   `python3 -c "import json; [json.load(open(f)) for f in ['assets/data/branch_configs.v1.json','assets/data/dress_requirements.v1.json','assets/data/accessory_library.v1.json']]"`
   — must exit 0.
2. `flutter analyze` — must be clean (no Dart changes).
3. **Skip** `flutter pub run build_runner build` — no annotated source
   touched.
4. `flutter test` — full suite passes. Watch
   [test/features/profile/uniform_provider_test.dart](../test/features/profile/uniform_provider_test.dart)
   in particular.
5. `flutter run` on Android *and* iOS — fresh install seeds 4 branches,
   5 dress requirements, and the new accessory count; second launch is
   idempotent (seeders log "skipped (n rows present)"). On a device
   that already had v2 data, the asset-only seeders are no-ops; to
   pick up v3 locally, wipe app data or invoke
   [FirestoreSeeder.seedAll](../lib/core/local_db/seed/firestore_seeder.dart)
   once in debug mode (it re-uploads bundled v3 → Firestore →
   `*Repository._handleRemoteSnapshot` mirrors v3 into Drift).
6. Mark `Status: verified` after the smoke test reports green.

## 7. CLAUDE.md updates required

- **§5.5 "Backend — Firebase":** qualify the "placeholder values
  pending doctrine review" bullet as applying to No. 1, 2, 4, 5 only —
  No. 3 is now PDF-aligned. List the new accessory categories
  introduced by this plan.
- **§8 "Known gaps / TODOs":** mark No. 3 doctrine alignment done;
  keep the No. 1, 2, 4, 5 review and the AR engine wiring as open
  TODOs. Add a one-line note that `DressRequirement.mergedFor` deep
  merge for the new structured keys is the next plan in this
  workstream.

No other CLAUDE.md sections need updates: folder layout (§4), tech
stack (§3), Drift schema (§5.4), provider graph (§5.2), bootstrap
sequence (§5.3), routing (§5.6), theming (§5.7), l10n (§5.8), error
model (§5.9) are all untouched.
