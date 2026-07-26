# Architecture Gap Closure

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7)
- **Status:** verified

## Verification log (2026-05-02)
- `flutter pub get` — succeeded (4 new deps resolved: `camera`, `model_viewer_plus`, `google_mlkit_pose_detection`, `permission_handler`).
- `flutter pub run build_runner build` — generated freezed/json/riverpod outputs for `medal_vertical_shift_rule`, `uniform_profile`, `global_rules_provider`, etc. 111 outputs.
- `flutter analyze` — clean (no issues).
- `flutter test` — all 11 tests pass, including 8 new cases under `test/features/ar_engine/coordinate_map_provider_test.dart`.
- iOS / Android smoke run — **deferred** (no simulator/device run done in this session). Manual smoke remains a gate before promoting to production.
- Firestore seed run — **deferred** (requires dev Firebase project credentials; gated by `kDebugMode` and a future dev-menu trigger).

## 1. Goal
Close the gaps between the current SAF Uniforms codebase and the
"Senior Flutter Architect" architecture spec the user shared. Specifically:
add missing AR/permissions dependencies, scaffold the `checklist` and
`ar_scanner` features, correct collar offsets in the seed, introduce a
`global_logic_rules` Firestore collection for the **Vertical Shift** badge
rule (medals ≥ 3 rows), and apply that rule inside the AR coordinate map.

## 2. Scope

**In scope**
- Add deps: `camera`, `model_viewer_plus`, `google_mlkit_pose_detection`, `permission_handler`.
- New empty feature scaffolds: `lib/features/checklist/`, `lib/features/ar_scanner/`.
- iOS / Android permission strings for camera + photo library.
- Fix RSAF / DIS `collarOffsetCm` in `assets/data/branch_configs.v1.json` to `1.0` (Army stays at `3.0`).
- New dev-only `firestore_seeder.dart` to push `branch_configs` and `global_logic_rules` documents.
- New `global_rules_repository.dart` (Firestore → Drift `rules` table sync), wired into `bootstrap.dart`.
- New freezed entity `MedalVerticalShiftRule`.
- `coordinate_map_provider.dart` consumes the rule and shifts `chestBadgeAnchor` Y when `medalRowCount >= minRows`.
- `medalRowCount` field on `UniformProfile` (if not already present).
- New tests for coordinate-map shift and global-rules sync.

**Out of scope**
- Project rename (`saf_uniforms` stays).
- Creating `lib/data/models` (DTOs stay feature-local).
- Collapsing the multi-file theme into a single `theme.dart`.
- Implementing the actual checklist or AR scanner UI — only scaffolding.

## 3. Affected areas

- `pubspec.yaml`
- `assets/data/branch_configs.v1.json`
- `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`
- New: `lib/features/checklist/{data,domain,presentation}/`
- New: `lib/features/ar_scanner/{data,domain,presentation}/`
- New: `lib/core/local_db/seed/firestore_seeder.dart`
- New: `lib/features/profile/data/global_rules_repository.dart`
- New: `lib/features/profile/domain/entities/medal_vertical_shift_rule.dart`
- `lib/bootstrap.dart`
- `lib/features/ar_engine/presentation/providers/coordinate_map_provider.dart`
- `lib/features/profile/domain/entities/uniform_profile.dart` (add `medalRowCount` if missing)
- `CLAUDE.md` (§3, §4, §5.4, §5.5, §8)
- New tests under `test/features/`

## 4. Step-by-step plan

1. **Phase A — Deps + scaffolds.** Add 4 deps to `pubspec.yaml`. Create `lib/features/checklist/{data,domain,presentation}/.gitkeep` and `lib/features/ar_scanner/{data,domain,presentation}/.gitkeep`. Add iOS `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription`, Android `<uses-permission android:name="android.permission.CAMERA" />`.
2. **Phase B — Collar offsets.** Edit JSON: RSAF `2.0 → 1.0`, DIS `2.5 → 1.0`, bump each branch's `version` (1 → 2).
3. **Phase C — Firestore seeder.** Write `lib/core/local_db/seed/firestore_seeder.dart`: reads JSON via `rootBundle`, writes branch docs to `branch_configs/{branchId}` (matches `BranchConfigRepository._fromFirestore` shape), writes the vertical-shift rule to `global_logic_rules/medal_vertical_shift`. Idempotent `set` with `merge: true`. Not called from bootstrap.
4. **Phase D — Global rules repository.** Mirror `BranchConfigRepository.startRemoteSync` pattern. Listen to Firestore `global_logic_rules` snapshots, upsert into the existing Drift `rules` table (`ruleKey`/`valueJson`). Expose a `watchVerticalShiftRule()` `Stream<MedalVerticalShiftRule?>`. Provide a `globalRulesRepositoryProvider` (keepAlive). Wire `startRemoteSync()` into `bootstrap.dart` after the branch-config one.
5. **Phase E — Vertical Shift in coordinate map.** Add `MedalVerticalShiftRule` freezed entity. Add `medalRowCount` to `UniformProfile` if missing. In `_calculateCoordinateMap`, shift `chestBadgeAnchor.y` downward by `(medalRowCount - minRows + 1) * verticalShiftCmPerExtraRow` when `medalRowCount >= minRows`.
6. **Phase F — Tests + verification.** Unit tests for the shift math (boundary, 0/2/3/5 rows). Smoke-test pub get → build_runner → analyze → flutter test.
7. **Phase G — Doc sync.** Update `CLAUDE.md` §3 (deps), §4 (folder tree), §5.4 (rules table actively synced), §5.5 (new `global_logic_rules` collection), §8 (close the vertical-shift gap). Flip this plan's `Status:` to `executed` after Phase F passes, then `verified`.

## 5. Risks & rollback

- **`google_mlkit_pose_detection`** ships large native binaries (~MB-scale APK/IPA growth) and may bump min iOS / Android SDK levels. If it forces an SDK bump that breaks the build, defer it to a follow-up plan and remove from `pubspec.yaml`.
- **`model_viewer_plus`** uses a WebView — verify `applicationQueriesSchemes` / network usage descriptions on iOS.
- **Firestore seeder** is a write path. It is gated behind a debug check and is **not** called from `bootstrap.dart`. Rollback = delete the new file; no production caller exists.
- **Schema bump on JSON `version`** triggers the existing remote-wins conflict resolution. If the in-prod Firestore has higher versions already, do not run the seeder — the local seed will lose. Verify before pushing.
- Rollback for everything else = revert the commit; no destructive DB migrations.

## 6. Verification

- `flutter pub get` clean.
- `flutter pub run build_runner build --delete-conflicting-outputs` clean.
- `flutter analyze` clean.
- `flutter test` green, including new coordinate-map shift tests.
- Manual: invoke `firestore_seeder` once against the dev Firebase project; verify `branch_configs/{army,navy,rsaf,dis}` and `global_logic_rules/medal_vertical_shift` exist with expected fields.
- Manual: set `medalRowCount = 3` on a test `UniformProfile`; observe `coordinateMapProvider` returns a `chestBadgeAnchor.y` that is shifted downward by `verticalShiftCmPerExtraRow`.
- `flutter run` smoke on Android + iOS — home placeholder + Ghost Model placeholder render with no regressions.

## 7. CLAUDE.md updates required

- §3 — add the 4 new dependencies.
- §4 — add `lib/features/checklist/`, `lib/features/ar_scanner/`, `lib/core/local_db/seed/firestore_seeder.dart`, `lib/features/profile/data/global_rules_repository.dart`, `lib/features/profile/domain/entities/medal_vertical_shift_rule.dart`.
- §5.4 — note that the `rules` Drift table is now actively synced from Firestore.
- §5.5 — list new `global_logic_rules/{ruleId}` Firestore collection.
- §8 — remove the "vertical-shift rule not encoded" gap.
