# Close the Asset-Data Relation Gaps (`assets/data/*.json`)

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7)
- **Status:** executed (pending device-level smoke test for `verified`)

## Verification log (2026-05-02)

- `flutter pub run build_runner build` — 71 outputs, no errors.
- `flutter analyze` — `No issues found! (ran in 1.2s)`.
- `flutter test` — 15/15 passed (11 pre-existing + 4 new for `DressRequirement.mergedFor`).
- Pending for `verified` status: `flutter run` smoke-test on Android + iOS, and re-run of `FirestoreSeeder.seedAll()` to push the v2 docs to Firestore.

## 1. Goal

Close four cross-file relation gaps between [`assets/data/branch_configs.v1.json`](../assets/data/branch_configs.v1.json), [`assets/data/dress_requirements.v1.json`](../assets/data/dress_requirements.v1.json), and [`assets/data/accessory_library.v1.json`](../assets/data/accessory_library.v1.json), and wire the latter two collections into Drift so they are readable at runtime. Without this, the planned checklist feature and AR engine cannot resolve a dress-code selection into concrete accessories.

## 2. Scope

**In scope**
- Add 13 missing accessory entries in `accessory_library.v1.json` (full stubs with placeholder `rules` / `render_logic`).
- Add 4 missing dress requirements (`no_1`, `no_2`, `no_4`, `no_5`) in `dress_requirements.v1.json`.
- Introduce a `branch_overrides` field on every dress requirement so per-branch divergence is representable.
- Add a `dress_requirements` Drift table and extend the existing `accessories` Drift table with the columns needed for `accessory_library` (display name, image url, placement diagram url, render logic).
- Drift schema bump `1 → 2` with destructive migration on `accessories` (no current writers).
- Add `AccessoryLibraryRepository` and `DressRequirementsRepository` mirroring Firestore → Drift, following the existing [`GlobalRulesRepository`](../lib/features/profile/data/global_rules_repository.dart) pattern.
- Add `Accessory` and `DressRequirement` `@freezed` domain entities + DTOs.
- Add Riverpod providers and wire `startRemoteSync()` calls into bootstrap.
- Add asset seeders for the two new collections (mirror [`BranchConfigSeeder`](../lib/core/local_db/seed/branch_config_seeder.dart)).
- Update `CLAUDE.md` per policy 1.2.

**Out of scope**
- Build-time validation / schema enforcement (user explicitly opted out).
- Wiring the new data into the checklist UI or AR engine — those features stay scaffolds.
- Doctrine-accurate values for the placeholder `rules` / `render_logic` blobs — flagged as TODO for future doctrine review.

## 3. Affected areas

**Modify**
- [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json)
- [assets/data/dress_requirements.v1.json](../assets/data/dress_requirements.v1.json)
- [lib/core/local_db/tables/accessories_table.dart](../lib/core/local_db/tables/accessories_table.dart)
- [lib/core/local_db/app_database.dart](../lib/core/local_db/app_database.dart)
- [lib/bootstrap.dart](../lib/bootstrap.dart)
- [lib/app.dart](../lib/app.dart)
- [CLAUDE.md](../CLAUDE.md)

**Add**
- `lib/core/local_db/tables/dress_requirements_table.dart`
- `lib/core/local_db/seed/accessory_library_seeder.dart`
- `lib/core/local_db/seed/dress_requirements_seeder.dart`
- `lib/features/ar_engine/data/accessory_library_repository.dart` + `dtos/accessory_dto.dart`
- `lib/features/checklist/data/dress_requirements_repository.dart` + `dtos/dress_requirement_dto.dart`
- `lib/features/profile/domain/entities/accessory.dart`
- `lib/features/checklist/domain/entities/dress_requirement.dart`
- `lib/features/ar_engine/presentation/providers/accessory_library_provider.dart`
- `lib/features/checklist/presentation/providers/dress_requirements_provider.dart`

## 4. Step-by-step plan

1. Bump `accessory_library.v1.json` to version 2 and add the 13 missing entries (full stubs).
2. Bump `dress_requirements.v1.json` to version 2, add `no_1`/`no_2`/`no_4`/`no_5`, add empty `branch_overrides: {}` to every entry.
3. Add `DressRequirements` Drift table.
4. Extend `Accessories` Drift table with `displayName`, `imageUrl`, `placementDiagramUrl`, `renderLogicJson`; relax `branchId`/`category`/`gender` to nullable. Bump `schemaVersion` to 2 with a destructive migration on `accessories`.
5. Run `build_runner` to regenerate `app_database.g.dart`.
6. Add `Accessory` `@freezed` entity + DTO.
7. Add `DressRequirement` `@freezed` entity (with `mergedFor(BranchId)` deep-merge) + DTO.
8. Add `AccessoryLibraryRepository` (Firestore → Drift mirror).
9. Add `DressRequirementsRepository` (Firestore → Drift mirror).
10. Add `AccessoryLibrarySeeder` and `DressRequirementsSeeder` (asset → Drift on first launch).
11. Add Riverpod providers; wire seeders into `bootstrap.dart` and `startRemoteSync()` calls into `app.dart`.
12. Update `CLAUDE.md` (§4, §5.3, §5.4, §5.5, §8).
13. Verify per § 6.

## 5. Risks & rollback

- **Destructive Drift migration**: dropping/recreating `accessories` loses local data. Safe today (no writers). Rollback: revert schema bump and codegen.
- **Placeholder rules/render_logic**: stub values are not doctrine-verified. Mitigation: do not consume from AR engine until reviewed; version 2 marks them as not-final.
- **branch_overrides deep-merge**: if merge semantics drift from consumer expectation, branch-specific rules silently fall back to base. Mitigation: unit-test `DressRequirement.mergedFor(BranchId)`.
- **Firestore version skew**: local seed at v2, Firestore still at v1 → `local.version >= remote.version` blocks remote upserts. Mitigation: re-run `FirestoreSeeder.seedAll()` after JSON change lands so Firestore docs also reach v2.

## 6. Verification

1. `flutter analyze` — clean.
2. `flutter pub run build_runner build --delete-conflicting-outputs` — regenerate freezed + drift outputs.
3. `flutter test` — add unit tests for `DressRequirement.mergedFor()` and a JSON-shape sanity test (loose, asserts every accessory ID referenced by `dress_requirements` exists in `accessory_library`; not enforced at build).
4. `flutter run` (Android + iOS) — first-launch smoke: confirm seeders populate Drift; trigger `FirestoreSeeder.seedAll()` from a debug entry point and confirm Firestore → Drift sync logs; open `/ghost-model` to confirm no regression in `coordinateMapProvider`.
5. Update Status to `verified` and note commands run.

## 7. CLAUDE.md updates required

- §4 (source tree) — add new table file, repos, providers, entities, seeders.
- §5.3 (Bootstrap sequence) — append two new `startRemoteSync()` calls and two new seeder invocations.
- §5.4 (Drift) — bump `schemaVersion` to 2, add `dress_requirements` row to the table list, expand `accessories` row description, note destructive migration.
- §5.5 (Firestore) — `accessory_library` and `dress_requirements` are now mirrored to Drift; remove the "no repository yet" caveats.
- §8 (Known gaps) — strike the bullets about `accessories` and `dress_requirements` lacking repositories.
