# Dashboard Home — dynamic dress grid from Firestore

- **Date:** 2026-05-04
- **Author:** Claude (Opus 4.7)
- **Status:** verified (`flutter analyze` clean; `dart run build_runner build` produced new `dressRequirementsAllProvider`; `flutter test` 42/42 passing). Simulator smoke test pending — Home tab UI change requires user-driven device verification.

## 1. Goal

Replace the hardcoded 2×2 dress grid on the Dashboard Home tab with a live
list rendered from the `dress_requirements` Firestore collection. The
collection can grow or shrink, so the grid must reflect whatever is in
Firestore at any moment. Each tile uses the Firestore `dress_name` field
as its label.

The full-width hero card (currently `DressCode.no3`) is left untouched in
this pass — the user has signalled that the hero treatment will graduate
to a "generated dress model" lane in a follow-up change, at which point
all generated dresses will likely become hero cards. Touching the hero
now would just create churn.

## 2. Scope

- **In scope:**
  - New `dressRequirementsAllProvider` (keep-alive) wrapping the existing
    `DressRequirementsRepository.watchAll()`.
  - `_DressCard` widget refactored to take `(dressId, dressName)` instead
    of a `DressCode` enum, so it can render arbitrary Firestore docs.
  - Grid block in `HomeTab.build` replaced with `AsyncValue.when` that
    streams the provider, filtering out the hero (`'No3'`) so it isn't
    duplicated.
  - Loading + error states inline in the grid area.

- **Out of scope:**
  - `_DressCardHero` and its invocation (left byte-identical).
  - `WardrobeTab` (still uses the enum-keyed `_dressStates` map).
  - `DashboardScreen._dressStates` map shape.
  - `_onOpenDress(DressCode)` signature.
  - Quick actions row, setup card, app bar, bottom nav.

## 3. Affected areas

- `lib/features/checklist/presentation/providers/dress_requirements_provider.dart` — append new provider.
- `lib/features/checklist/presentation/providers/dress_requirements_provider.g.dart` — regenerated.
- `lib/features/dashboard/presentation/tabs/home_tab.dart` — refactor grid + `_DressCard`.
- `CLAUDE.md` — §5.2 Riverpod provider list (add `dressRequirementsAllProvider`); §8 Known gaps (resolve "Home grid still hardcoded" implication).

## 4. Step-by-step plan

1. Add `dressRequirementsAll` provider to
   `dress_requirements_provider.dart` (keep-alive,
   `Stream<List<DressRequirement>>`).
2. Run `dart run build_runner build --delete-conflicting-outputs` to
   regenerate `dress_requirements_provider.g.dart`.
3. In `home_tab.dart`:
   - Add import for the dress requirements provider.
   - Add a top-level `_safeDressCode(String id)` helper that wraps
     `DressCode.fromWireName` in try/catch.
   - Replace the static `[no1, no2, no4, no5]` grid block with an
     `AsyncValue.when` over `dressRequirementsAllProvider`, filtering
     `req.id != DressCode.no3.wireName`.
   - Refactor `_DressCard` constructor + build to accept
     `String dressId` + `String dressName`. Use `dress_name` as the
     bottom mono label; use the localized `dressCodeLabel` only when
     the id maps to a known `DressCode`, else fall back to the
     `dressId` string.
4. `flutter analyze` — must be clean.
5. Update CLAUDE.md per policy 1.2.
6. Smoke test on simulator: cold launch, mutate Firestore docs and
   confirm grid updates live.
7. Mark this plan `verified`.

## 5. Risks & rollback

- **Empty grid risk:** if Firestore is unseeded the grid is empty; the
  hero is unaffected so the screen still renders meaningful UI.
- **Unknown dressId risk:** new docs outside the `DressCode` enum (e.g.
  `No6`) render the tile but `onTap` is a no-op (string-based routing
  is deferred). Acceptable for this pass.
- **Rollback:** revert `home_tab.dart` and remove the new provider plus
  its generated entries. No DB / schema impact.

## 6. Verification

1. `flutter analyze` — clean.
2. `dart run build_runner build --delete-conflicting-outputs` — runs
   without conflicts.
3. `flutter test` — full suite green.
4. Manual smoke (simulator, with Firestore reachable):
   - Hero `No.3` card unchanged.
   - Grid shows tiles for every non-`No3` doc in `dress_requirements`,
     each labelled with the Firestore `dress_name`.
   - Editing a doc's `dress_name` in the Firebase Console live-updates
     the tile.
   - Adding/deleting a doc adds/removes a tile in real time.
5. Update this file's `Status:` line to `verified` and note what was run.

## 7. CLAUDE.md updates required

- §5.2 Riverpod providers — list the new
  `dressRequirementsAllProvider` next to `dressRequirementByIdProvider`
  / `dressRequirementForBranchProvider`.
- §8 Known gaps — remove or update any phrasing that implies the Home
  grid is still hardcoded (the "structured No.3 keys" bullet is
  unaffected; nothing else in §8 mentioned the grid explicitly, but
  re-skim during execution to confirm).
