# Seed `dress_requirements/no_3_dress_requirements` to Firestore

- **Date:** 2026-05-02
- **Author:** Claude (opus-4-7)
- **Status:** verified

> **Verification log (2026-05-02):**
> - `flutter pub get` — OK (no new deps; resolved cleanly).
> - `flutter analyze` — `No issues found! (ran in 2.5s)`.
> - `flutter test` — 11/11 passed.
> - Manual debug-mode seed against live Firestore: **deferred to the user**
>   (requires a configured Firebase project + simulator). Seeder is dev-only,
>   guarded by `kDebugMode`, idempotent (`SetOptions(merge: true)`), and not
>   wired into bootstrap, so no production behavior changes.

## 1. Goal
Populate the new `dress_requirements` Firestore collection with the `no_3_dress_requirements` document so downstream work (UI, validators, repository, sync) has live data to read against. Scope is intentionally narrow — *seeder only, for now*.

## 2. Scope
- **In scope**
  - New seed asset `assets/data/dress_requirements.v1.json` containing the No.3 document verbatim.
  - New `FirestoreSeeder.seedDressRequirements()` method, called from `seedAll()`.
  - Asset registration in `pubspec.yaml`.
  - CLAUDE.md § 5.5 + § 8 updates.
- **Out of scope**
  - Drift table for dress requirements.
  - Repository / provider / `startRemoteSync` wiring.
  - UI consumption.
  - Documents for No.1 / No.2 / No.4 / No.5 (asset is structured to accept them as a one-line append later).

## 3. Affected areas
| File | Change |
|---|---|
| `assets/data/dress_requirements.v1.json` | **Create** — `{ version, dressRequirements: [no_3_dress_requirements] }`. |
| `pubspec.yaml` | **Edit** — register the new asset under `flutter.assets`. |
| `lib/core/local_db/seed/firestore_seeder.dart` | **Edit** — add asset-path + collection-name constants, new `seedDressRequirements()` method, hook into `seedAll()`, refresh class doc-comment. |
| `CLAUDE.md` | **Edit** — § 5.5 collections list + dev-only seeder sentence; § 8 known-gap note. |

## 4. Step-by-step plan
1. Write `assets/data/dress_requirements.v1.json` with `version: 1` and a `dressRequirements` array whose first entry is the No.3 doc the user provided, verbatim.
2. Add `assets/data/dress_requirements.v1.json` to `pubspec.yaml` under `flutter.assets`.
3. In `firestore_seeder.dart`:
   - Add file-level constants `_dressRequirementsAssetPath` and `_dressRequirementsCollection`.
   - Add `seedDressRequirements()` modeled on `seedBranchConfigs`: load asset → decode → read top-level `version` → batch-write each entry to `dress_requirements/{doc['id']}` with `{...doc, version, updatedAt: FieldValue.serverTimestamp()}` and `SetOptions(merge: true)`. Wrap in `try / catch` per policy 1.4, log per-doc at level 700 with name `firestore.seed`.
   - Update class doc-comment to mention the third collection.
   - Call `await seedDressRequirements();` from `seedAll()` after `seedGlobalLogicRules()`.
4. Update `CLAUDE.md` § 5.5 (add `dress_requirements/{dressId}` bullet, mention in dev-only seeder sentence) and § 8 (known-gap note).
5. Run verification (§ 6) and flip Status to `verified`.

## 5. Risks & rollback
- **Risk:** Asset not registered in `pubspec.yaml` → `rootBundle.loadString` throws at runtime. *Mitigation:* explicit step 2; a plain `flutter pub get` + `flutter analyze` won't catch it but the manual debug-mode seed in § 6 will.
- **Risk:** Seed accidentally runs in release. *Mitigation:* the existing `kDebugMode` guard at `seedAll()` line 31 wraps the new method since it's called from there.
- **Rollback:** revert seeder edits, remove pubspec entry, delete the asset, and (if pushed) delete `dress_requirements/no_3_dress_requirements` from the Firebase console.

## 6. Verification
1. `flutter pub get` — picks up the new asset registration.
2. `flutter analyze` — must be clean.
3. `flutter test` — all existing tests pass. (No new test added: seeder is dev-only with no production behavior; if coverage is wanted later, mock `FirebaseFirestore` and assert one merged write to `dress_requirements/no_3_dress_requirements`.)
4. **Manual debug-mode seed** (only end-to-end check that proves the data landed):
   - `flutter run` on a debug build with Firebase configured.
   - Invoke `FirestoreSeeder(firestore: FirebaseFirestore.instance).seedAll()` from a temporary entry-point (e.g. a debug button or `bootstrap.dart` breakpoint).
   - In the Firebase console, confirm `dress_requirements/no_3_dress_requirements` exists with `dress_name`, `mandatory_rules`, `optional_logic`, `version: 1`, populated `updatedAt`.
   - Re-run once: `updatedAt` updates, no duplicate, no error in logs (idempotency check).

## 7. CLAUDE.md updates required
- § 5.5 — add `dress_requirements/{dressId}` to the Firestore collections bullet list, and extend the dev-only seeder sentence to name dress requirements alongside the Vertical-Shift rule.
- § 8 — add a known-gap note: "`dress_requirements` is seeded but not yet mirrored to Drift / wrapped in a repository — next step when UI consumes it."
- § 4 source tree — no change (asset lives under `assets/data/`, already represented as a directory; no new Dart files).
