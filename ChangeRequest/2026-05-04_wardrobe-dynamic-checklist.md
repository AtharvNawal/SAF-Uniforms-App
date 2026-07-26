# Wardrobe Tab — Dynamic Dress + Accessory Checklist

- **Date:** 2026-05-04
- **Author:** Claude (with Sukalkar)
- **Status:** verified — `flutter gen-l10n`, `dart run build_runner build`,
  `flutter analyze` (no issues), and `flutter test` (61/61 passing) all
  ran cleanly. Manual device smoke test pending on the user's hardware.

## 1. Goal

Replace the hardcoded Wardrobe tab with a dynamic, persistent accessory
checklist driven by `dress_requirements` + `accessory_library` + the user's
profile. The tab gets a dress-filter dropdown ("ALL" / per-dress), a
`VERIFIED  X / Y` progress card, and a scrollable accessory list whose
checks survive cold start because they are persisted to
`users/{uid}/profile/current.dressAccessoryChecks`.

## 2. Scope

- **In scope**
  - `wardrobe_tab.dart` rewrite + `dashboard_screen.dart` wiring.
  - One new `UniformProfile` field (`dressAccessoryChecks`) + DTO + notifier
    setters.
  - `DressAccessoryResolver.resolveSplit(...)` returning
    `(mandatory, optional)`.
  - New providers: `dressAccessoriesByIdProvider(dressId)`,
    `allDressesAccessoriesCombinedProvider`,
    `wardrobeProgressProvider(filter)`.
  - `Accessory`-accepting overload of `accessory_detail_sheet`.
  - New l10n keys for the `MANDATORY` / `OPTIONAL` chips, "ALL" trigger
    chip, and empty-state copy. Reuse existing
    `checklistVerified` / `checklistTapToView` /
    `checklistDressAll` / `checklistDressAllDesc` keys.
  - Tests: resolver split, DTO round-trip, notifier toggle.
- **Out of scope**
  - Standalone `/checklist` route (still uses static `AccessoryItem.all`).
  - Refactoring the placement-diagram painter beyond mapping
    `Accessory.category` to existing zone keys.

## 3. Affected areas

**Domain / data**
- `lib/features/profile/domain/entities/uniform_profile.dart`
- `lib/features/profile/data/dtos/uniform_profile_dto.dart`
- `lib/features/profile/presentation/providers/uniform_provider.dart`
- `lib/features/checklist/domain/services/dress_accessory_resolver.dart`
- `lib/features/checklist/presentation/providers/dress_accessories_provider.dart`

**Presentation**
- `lib/features/dashboard/presentation/tabs/wardrobe_tab.dart`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/checklist/presentation/widgets/accessory_detail_sheet.dart`

**Localization**
- `lib/core/l10n/arb/app_en.arb`
- `lib/core/l10n/arb/app_zh.arb`

**Tests**
- `test/features/checklist/dress_accessory_resolver_test.dart`
- `test/features/profile/uniform_provider_test.dart`
- `test/features/profile/data/uniform_profile_dto_test.dart`

## 4. Step-by-step plan

1. **Profile field**: add
   `Map<String, Set<String>> dressAccessoryChecks` to `UniformProfile`,
   regenerate freezed, round-trip in `UniformProfileDto` (encode as
   `Map<String, List<String>>`, decode defensively for older docs).
2. **Notifier**: add `toggleDressAccessory(dressId, accessoryId)`,
   `setDressAccessoryChecked(dressId, accessoryId, bool)`, and
   `clearDressAccessoryChecks(dressId)`. Each schedules the existing
   500 ms debounced sync.
3. **Resolver split**: add `resolveSplit(...)` returning
   `({List<Accessory> mandatory, List<Accessory> optional})`. Mandatory
   = headdress / cap_badge / cap_embellishment / rank_insignia_sleeve /
   epaulettes. Optional = lanyard / arms_badge / vocation_badge.
   `resolve(...)` becomes `resolveSplit(...).mandatory + .optional`.
4. **New providers** in `dress_accessories_provider.dart`:
   `dressAccessoriesByIdProvider(dressId)`,
   `allDressesAccessoriesCombinedProvider`,
   `wardrobeProgressProvider(filter)`. `WardrobeFilter` is a small
   sealed class living next to them.
5. **Detail sheet**: add `showAccessoryDetailSheetForAccessory(...)`
   alongside the existing `showAccessoryDetailSheet`. Internally builds
   the same view from `Accessory.displayName`, `category`, `id`,
   plus a category-mapped placement zone.
6. **Wardrobe tab rewrite**: dress-filter dropdown trigger
   (`AppCard` look matching the screenshot) → `showAppBottomSheet` listing
   "All Accessories" + every dress streamed by
   `dressRequirementsAllProvider`. `VERIFIED X / Y` card driven by
   `wardrobeProgressProvider`. List driven by either
   `allDressesAccessoriesCombinedProvider` or
   `dressAccessoriesByIdProvider`. `MANDATORY` / `OPTIONAL` chip on each
   row when in single-dress mode. Empty-state for
   `SingleDressFilter` returning 0 accessories.
7. **Dashboard wiring**: `WardrobeTab()` no longer takes `dressStates` /
   `onOpenDress`.
8. **Localization**: add new keys to `app_en.arb` + `app_zh.arb`.
9. **Codegen**: `dart run build_runner build --delete-conflicting-outputs`
   + `flutter gen-l10n`.
10. **Tests**: extend the three test files for the new logic.
11. **CLAUDE.md**: refresh §5.2 (providers + resolver split), §5.4
    (new field on `UniformProfile`), §8 (TODO list).

## 5. Risks & rollback

- The mandatory/optional split is doctrine-shaped guesswork; switching
  the classification later is a one-table change inside `resolveSplit`.
- The "All Accessories" toggle marks the accessory checked across every
  dress that lists it. If users want per-dress only, downgrade the "All"
  view to read-only and require switching to a single dress to toggle.
- The `dressAccessoryChecks` field is purely additive on Firestore; old
  docs hydrate with an empty map. Rollback = revert the four code areas;
  the orphan field on existing docs is harmless.

## 6. Verification

1. `flutter analyze` clean.
2. `dart run build_runner build --delete-conflicting-outputs` succeeds.
3. `flutter gen-l10n` succeeds.
4. `flutter test` all green (existing + new tests).
5. Manual smoke in iOS simulator + Android emulator:
   - Wardrobe tab launches with default `All Accessories` filter showing
     deduped accessories with `0 / N` count.
   - Tap accessory → modal opens with `displayName` / category / id.
     "Got It" closes modal AND ticks the row.
   - Tick three rows → progress flips to `3 / N`. Force-quit + relaunch
     → progress is still `3 / N`.
   - Switch dropdown to "No.3 Dress" → list narrows; each row shows
     `MANDATORY` or `OPTIONAL` chip; count reflects only No.3.
   - Switch to "No.1 Dress" → empty-state card with "Pending doctrine
     review."
6. Update this file's `Status:` to `verified` and note exact commands run.

## 7. CLAUDE.md updates required

- §5.2 — add new providers + resolver split.
- §5.4 — add `dressAccessoryChecks` to the `UniformProfile` shape note.
- §8 — strike the TODO line about `ChecklistScreen` using static
  view-models (clarifies that it is the Wardrobe tab that is dynamic
  now; the standalone `/checklist` route remains static).
