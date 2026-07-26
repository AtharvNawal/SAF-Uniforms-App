# Seed `accessory_library` collection to Firestore

- **Date:** 2026-05-02
- **Author:** Claude (opus-4-7)
- **Status:** verified

> **Verification log (2026-05-02):**
> - `flutter pub get` — OK.
> - `flutter analyze` — `No issues found! (ran in 2.4s)`.
> - `flutter test` — 11/11 passed.
> - Manual debug-mode seed against live Firestore: **deferred to the user**
>   (same as the dress_requirements change). Seeder is dev-only,
>   guarded by `kDebugMode`, idempotent, and not wired into bootstrap.

## 1. Goal
Populate the new `accessory_library` Firestore collection with the eight accessory documents the user supplied (beret, collar rank pins, name tag, medal ribbons, SAF chest badges, sleeve rank, sleeve skill badges, lanyard, and the placement metadata for each). Scope mirrors the just-shipped `dress_requirements` change — *seeder only, no Drift / repository / UI*.

## 2. Scope
- **In scope**
  - New seed asset `assets/data/accessory_library.v1.json` containing all eight accessory documents.
  - New `FirestoreSeeder.seedAccessoryLibrary()` method, called from `seedAll()`.
  - Asset registration in `pubspec.yaml`.
  - CLAUDE.md § 5.5 + § 8 updates.
- **Out of scope**
  - Wiring into the existing local Drift `accessories` table (the table exists but has no repository — see § 8 of CLAUDE.md). When that repository lands, it will read from this collection.
  - Repository / provider / `startRemoteSync`.
  - UI consumption.
  - Note: this collection is **not** the same as the existing local `accessories` Drift table. The Firestore collection is named `accessory_library` per user request; the eventual repository will reconcile naming.

## 3. Affected areas
| File | Change |
|---|---|
| `assets/data/accessory_library.v1.json` | **Create** — `{ version, accessories: [...eight docs] }`. |
| `pubspec.yaml` | **Edit** — register the new asset under `flutter.assets`. |
| `lib/core/local_db/seed/firestore_seeder.dart` | **Edit** — add asset-path + collection-name constants, new `seedAccessoryLibrary()` method, hook into `seedAll()`, refresh class doc-comment. |
| `CLAUDE.md` | **Edit** — § 5.5 collections list + dev-only seeder sentence; § 8 known-gap note. |

## 4. Step-by-step plan
1. Write `assets/data/accessory_library.v1.json` with `version: 1` and an `accessories` array of all nine documents the user provided, verbatim.
2. Add the asset to `pubspec.yaml` under `flutter.assets`.
3. In `firestore_seeder.dart`:
   - Add `_accessoryLibraryAssetPath` and `_accessoryLibraryCollection` constants.
   - Add `seedAccessoryLibrary()` modeled exactly on `seedDressRequirements`: load → decode → read top-level `version` → batch-write each entry to `accessory_library/{doc['id']}` with `{...doc, version, updatedAt: serverTimestamp()}` and `merge: true`.
   - Update class doc-comment from "three collections" → "four collections".
   - Call `await seedAccessoryLibrary();` from `seedAll()` after `seedDressRequirements()`.
4. Update CLAUDE.md (§ 5.5 + § 8).
5. Run verification (§ 6) and flip Status to `verified`.

## 5. Risks & rollback
- **Risk:** Asset not registered → `rootBundle.loadString` throws at runtime. *Mitigation:* explicit step 2.
- **Risk:** Seed accidentally runs in release. *Mitigation:* existing `kDebugMode` guard in `seedAll()`.
- **Risk:** Naming confusion between Firestore `accessory_library` and Drift `accessories`. *Mitigation:* documented in § 5.5 + § 8 of CLAUDE.md so the next person wiring a repository knows what's what.
- **Rollback:** revert seeder edits, remove pubspec entry, delete the asset, and (if pushed) delete `accessory_library/*` from the Firebase console.

## 6. Verification
1. `flutter pub get`.
2. `flutter analyze` — must be clean.
3. `flutter test` — all existing tests pass. (No new test added — same rationale as `dress_requirements`.)
4. **Manual debug-mode seed** (deferred to user, requires configured Firebase): `FirestoreSeeder(firestore: FirebaseFirestore.instance).seedAll()` from a debug build, confirm all eight docs land at `accessory_library/{id}` with `version: 1` and a populated `updatedAt`. Re-run for idempotency.

## 7. CLAUDE.md updates required
- § 5.5 — add `accessory_library/{accessoryId}` bullet to the Firestore collections list, and extend the dev-only seeder sentence to mention it.
- § 8 — note that `accessory_library` is seeded but not yet wired into the local `accessories` Drift table / no repository yet.
