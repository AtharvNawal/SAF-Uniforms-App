# Firestore-First Migration — wire mobile app to Firestore + remove local seed/Drift

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7)
- **Status:** executed (awaiting on-device verification per CLAUDE.md §1.5 step 4)

## Execution log (2026-05-02)

- `flutter pub get` — clean.
- `dart run build_runner build` — 26 outputs regenerated, no Drift codegen
  remaining.
- `flutter analyze` — `No issues found! (ran in 2.3s)`.
- `flutter test` — 28 tests pass (3 new repository / resolver tests added,
  all existing pure-domain tests intact).
- Drift code (`lib/core/local_db/`, `pubspec` deps `drift`,
  `drift_flutter`, `sqlite3_flutter_libs`, `path`, `path_provider`,
  `drift_dev`) and the three row-DTOs deleted; bootstrap shrunk to
  Firebase init + anonymous auth.
- Operator gates progress:
  1. ✅ `flutterfire configure --project=saf-uniforms ...` — done.
     Generated real `firebase_options.dart`,
     `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`.
  2. ✅ `firebase deploy --only firestore:rules --project=saf-uniforms`
     — strict `firestore.rules` deployed (Firestore database auto-created
     during deploy). Anonymous Auth enabled in console.
  3. ⏳ Pending: `dart run tool/seed_firestore.dart <service-account.json>`.
     The operator must download a service account JSON from
     Firebase Console (Project settings → Service accounts → Generate new
     private key) and run the pure-Dart admin script. Admin SDK auth
     bypasses Firestore rules so strict rules stay live during seed.
  4. ⏳ Pending: smoke-test the app per §6 verification list, then flip
     Status → `verified`.

## Seed-flow architecture change (2026-05-02, post-execute)

The original plan had `tool/seed_firestore_main.dart` as a Flutter target
that needed a device + temporary permissive rules. That was replaced
mid-execution with a pure-Dart Firebase Admin SDK script
(`tool/seed_firestore.dart`) for these reasons:

- Admin SDK bypasses security rules → no `firestore.rules.seed`
  permissive-rules dance, no risk of forgetting to redeploy strict rules.
- Pure Dart → no Flutter, no device/simulator, runs from any terminal.
- Service-account auth matches how the future web admin portal will
  write to Firestore.

Cost: one extra dev dep (`firebase_admin_sdk ^0.5.1` +
`google_cloud_firestore`), and operator must download a service account
JSON one time. The `lib/core/seed/firestore_seeder.dart` (Flutter-coupled)
class was deleted along with the Flutter-target script.

## 1. Goal

Stop bundling content as `assets/data/*.json` + Drift seeds. Make Firestore
project `saf-uniforms` the single source of truth for branch configs, dress
requirements, accessory library, and global logic rules. The mobile app reads
those collections as real-time streams; Drift is removed entirely (Firestore
SDK already handles offline persistence). A separate web admin portal (future
work, out of scope here) will own writes.

After the migration the app must:

1. Connect to Firebase project `saf-uniforms` via real `firebase_options.dart`
   + native config files.
2. Stream all four reference collections from Firestore with Riverpod
   providers (no Drift mirror).
3. Drive the existing `coordinateMapProvider` (3D ghost-model anchors) from
   the live Firestore data.
4. Expose a new `dressAccessoriesProvider` that filters
   `accessory_library` by the active `UniformProfile` + the relevant
   `dress_requirement` — ready for a future screen to consume.
5. Be free of all Drift schema, DTOs, and the three asset seeders.

UI / screen work is **not** part of this plan.

## 2. Scope

**In scope**
- `firebase_options.dart` regenerated via `flutterfire configure` (project
  `saf-uniforms`, Android `com.saf.saf_uniforms`, iOS `com.saf.safUniforms`).
- `firestore.rules` + `firebase.json` for auth-required reads on the four
  reference collections + owner-scoped writes on `users/{uid}`.
- One-shot operator-run seed script `tool/seed_firestore_main.dart` that
  reuses the existing `FirestoreSeeder`. **Not** in the app build graph.
- Rewriting the four reference repositories (`BranchConfigRepository`,
  `GlobalRulesRepository`, `DressRequirementsRepository`,
  `AccessoryLibraryRepository`) as pure Firestore streams.
- New `dressAccessoriesProvider` for filtered accessory list.
- Deleting Drift (`AppDatabase`, `tables/*`, `seed/*` Drift seeders, the
  three `*_dto.dart` files with `fromRow`) and the Drift pubspec deps.
- Tests with `fake_cloud_firestore`.

**Out of scope**
- Web admin portal.
- Any UI / screen development.
- Hardened production Firestore security rules (basic auth-required rules
  only — production hardening lives in a follow-up plan once the admin
  portal contract is known).

## 3. Affected areas

### Created
- `tool/seed_firestore_main.dart` — manual one-off seed entry (Flutter target).
- `lib/core/seed/firestore_seeder.dart` — moved from `lib/core/local_db/seed/`.
- `lib/features/checklist/presentation/providers/dress_accessories_provider.dart`.
- `lib/features/profile/data/dtos/branch_config_firestore.dart` (replaces row DTO).
- `lib/features/checklist/data/dtos/dress_requirement_firestore.dart` (replaces row DTO).
- `lib/features/ar_engine/data/dtos/accessory_firestore.dart` (replaces row DTO).
- `firestore.rules`, `firebase.json` at project root.
- `assets/data/README.md` — frozen-snapshot warning.

### Modified
- `lib/firebase_options.dart` — regenerated.
- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — written by `flutterfire configure`.
- `lib/bootstrap.dart` — Firebase init + anonymous auth only; no Drift, no seeders.
- `lib/main.dart` — drop the four `startRemoteSync()` calls.
- `lib/features/profile/data/branch_config_repository.dart`,
  `lib/features/profile/data/global_rules_repository.dart`,
  `lib/features/checklist/data/dress_requirements_repository.dart`,
  `lib/features/ar_engine/data/accessory_library_repository.dart` — pure Firestore.
- The four `presentation/providers/*.dart` files — drop dispose/startRemoteSync plumbing.
- `pubspec.yaml` — add `fake_cloud_firestore` (dev); remove `drift`, `drift_flutter`,
  `sqlite3_flutter_libs`, `drift_dev`, and unused `path` / `path_provider`.

### Deleted
- `lib/core/local_db/` (entire dir): `app_database.dart`, `app_database.g.dart`,
  `tables/*`, and the three Drift seeders under `seed/`. The Firestore seeder
  is moved out before deletion.
- `lib/features/profile/data/dtos/branch_config_dto.dart`.
- `lib/features/checklist/data/dtos/dress_requirement_dto.dart`.
- `lib/features/ar_engine/data/dtos/accessory_dto.dart`.

### Retained per user direction (re-seed safety net)
- `assets/data/branch_configs.v1.json`, `accessory_library.v1.json`,
  `dress_requirements.v1.json`.
- `pubspec.yaml`'s `flutter.assets:` entry pointing at `assets/data/`.
- The `FirestoreSeeder` class (moved to `lib/core/seed/`).
- `tool/seed_firestore_main.dart`.

## 4. Step-by-step plan

1. **Project-policy plan files written** (this file).
2. **Firestore rules + Firebase config files** — `firestore.rules`,
   `firebase.json`, `assets/data/README.md`.
3. **Move FirestoreSeeder** out of `lib/core/local_db/seed/` to
   `lib/core/seed/` so it survives the Drift demolition.
4. **Create `tool/seed_firestore_main.dart`** — the operator script.
5. **Operator gate (manual):** the user runs
   `flutterfire configure --project=saf-uniforms ...` and then
   `flutter run -t tool/seed_firestore_main.dart -d <device>`. The
   implementation agent does not run these.
6. **Add `fromFirestore` factories** on `BranchConfig`, `Accessory`,
   `DressRequirement` (new files under each feature's `data/dtos/`).
7. **Rewrite the four repositories** as pure Firestore streams.
8. **Simplify the provider files** (drop `dispose` and `startRemoteSync` wiring).
9. **Shrink `bootstrap.dart` + `main.dart`** (Firebase init + anonymous
   auth + provider container only).
10. **Add `dressAccessoriesProvider`** with the No.3 structured-key
    resolution + gender / rank-tier id-suffix filter + legacy_placeholder skip.
11. **Demolition** — delete `lib/core/local_db/`, the three row DTOs, and
    the four Drift pubspec deps. Drop unused `path` / `path_provider`.
12. **Tests** — `fake_cloud_firestore` repository tests +
    `dressAccessoriesProvider` test. Pure-domain tests stay as-is.
13. **Verify** — `flutter analyze`, build_runner, `flutter test`,
    `flutter run` smoke test (per policy 1.5).
14. **Update CLAUDE.md** sections listed in §7. Mark this file
    `executed`, then `verified`.

## 5. Risks & rollback

- **`flutterfire configure` mis-detection** — pass package id + bundle id
  explicitly. Rollback by reverting the three written files from git.
- **Firestore offline cold start** is "spinner until cache hits"; acceptable
  while no screens exist. Re-introduce a local cache in a follow-up plan if
  it bites later.
- **Bundled JSON drift** — assets are now a frozen seed snapshot, not live
  config. Mitigated by the `assets/data/README.md` warning and by the fact
  that no runtime code path reads them outside `tool/`.
- **Stale `appDatabaseProvider` references** breaking build_runner regen.
  Mitigation: `flutter clean` between rewrite + demolition steps.
- **Wrong-project seed.** Script logs `Firebase.app().options.projectId`
  before writing.

## 6. Verification (per CLAUDE.md §1.5)

1. `flutter analyze` — clean.
2. `dart run build_runner build --delete-conflicting-outputs` — succeeds with
   no Drift codegen.
3. `flutter test` — all existing tests pass; new repository + filter tests pass.
4. `flutter run` on Android + iOS:
   - App boots to `_HomePlaceholder` without exceptions.
   - Transient logs confirm first emission of:
     - `branchConfigsProvider` — 4 entries
     - `dressRequirementByIdProvider('no_3_dress_requirements')` — non-null
     - `accessoryLibraryProvider` — 82 entries
     - `medalVerticalShiftRuleProvider` — `(minRows: 3, verticalShiftCmPerExtraRow: 1.0)`
     - `coordinateMapProvider` — `anchors` includes `collar`, `chestBadge`
     - `dressAccessoriesProvider` for default profile (Army/REC/male/No3) —
       non-empty filtered list with `army_*` ids
   - Airplane mode toggle: same data served from Firestore offline cache.
5. Set this file's `Status:` to `verified` with a list of what was run.

## 7. CLAUDE.md updates required

- §3 Tech stack: drop `drift`, `drift_flutter`, `sqlite3_flutter_libs`,
  `path`, `path_provider`.
- §4 Source tree: remove `core/local_db/` block; remove the three asset
  filenames from the source-tree listing (they remain on disk but are no
  longer part of the runtime architecture); remove the three row-DTO file
  references.
- §5.3 Bootstrap: collapse to (1) `Firebase.initializeApp`, (2) anonymous
  sign-in + `users/{uid}` upsert, (3) build `ProviderContainer`, (4)
  `runApp`. Drop seeder bullets and the `startRemoteSync` block.
- §5.4 Local persistence: delete entire section. Replace with one-liner
  "No local DB. Firestore SDK handles offline persistence."
- §5.5 Backend: rewrite "mirrored to Drift" wording to "read directly from
  Firestore real-time snapshots". Keep doc-shape descriptions.
- §5.2 State management: replace "watch Drift via Riverpod" wording with
  "watch Firestore streams via Riverpod"; describe the new
  `dressAccessoriesProvider`.
- §8 TODOs: remove Drift-mirror entries; add a note that
  `dressAccessoriesProvider` exists but no UI consumes it yet.
