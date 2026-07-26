# Dynamic Dress Generation State

- **Date:** 2026-05-04
- **Author:** Claude (claude-sonnet-4-6)
- **Status:** verified

## 1. Goal

Replace the hardcoded `No.3 = ready` dress state on the Home screen with a
dynamic system that persists a per-dress generation timestamp in Firestore.
When a user successfully completes the 3D model generation animation the dress
is marked as built, the Home card shows the build date, and subsequent taps go
directly to the ghost model screen instead of the dress-accessories setup flow.

## 2. Scope

- **In scope:**
  - New `generatedDresses: Map<String, DateTime>` field on `UniformProfile`.
  - DTO serialization / deserialization of that field.
  - `markDressGenerated(DressCode)` setter on `UniformProfileNotifier`.
  - Calling `markDressGenerated` at the end of `GeneratingScreen`.
  - Deriving `dressStates` dynamically in `DashboardScreen`.
  - Smart routing in `_onOpenDress`: ready → ghost-model, idle → dress-accessories.
  - Displaying build date on the hero card in `HomeTab`.

- **Out of scope:**
  - Actual 3D model generation (still a timed animation placeholder).
  - Re-generation / reset flow.
  - Updating small grid cards to full-width when generated (only No.3 hero card today).

## 3. Affected areas

| File | Change |
|------|--------|
| `lib/features/profile/domain/entities/uniform_profile.dart` | Add field |
| `lib/features/profile/domain/entities/uniform_profile.freezed.dart` | Regenerate |
| `lib/features/profile/data/dtos/uniform_profile_dto.dart` | Serialize new field |
| `lib/features/profile/presentation/providers/uniform_provider.dart` | New setter |
| `lib/features/dashboard/presentation/screens/generating_screen.dart` | Call setter on complete |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Dynamic states + routing |
| `lib/features/dashboard/presentation/tabs/home_tab.dart` | Build date on hero card |

## 4. Step-by-step plan

1. Add `generatedDresses: Map<String, DateTime>` to `UniformProfile` (`@Default(<String, DateTime>{})` ).
2. Update `UniformProfileDto` to serialize as `Map<wireKey, millisSinceEpoch>` and deserialize safely.
3. Add `markDressGenerated(DressCode dress)` to `UniformProfileNotifier`.
4. In `GeneratingScreen._GeneratingScreenState.initState` timer block: call `markDressGenerated` before the 250 ms nav delay.
5. In `DashboardScreen.build()`: watch profile, compute `dressStates` from `generatedDresses`; pass an inline closure that routes to ghost-model when ready.
6. Remove hardcoded `_dressStates` field from `_DashboardScreenState`.
7. In `HomeTab.build()`: read `profile.generatedDresses[DressCode.no3.wireName]`; pass `builtAt` to `_DressCardHero`.
8. Update `_DressCardHero` to accept `builtAt: DateTime?`; show `'BUILT · DD MMM YYYY'` using `intl`'s `DateFormat` when ready.
9. Run `dart run build_runner build --delete-conflicting-outputs`.
10. Run `flutter analyze` and `flutter test`.

## 5. Risks & rollback

- Freezed codegen with a `Map<String, DateTime>` default may require using
  `@Default(<String, DateTime>{})` syntax carefully — fall back to nullable
  `Map<String, DateTime>?` if codegen fails.
- Existing Firestore documents that lack `generatedDresses` will deserialize as
  an empty map (safe — no behaviour change for returning users).
- Routing change: tapping a generated card bypasses dress-accessories. There is
  currently no re-build/reset entry point from the home card; that is acceptable
  for this milestone.

## 6. Verification

1. `dart run build_runner build --delete-conflicting-outputs` — zero errors.
2. `flutter analyze` — clean.
3. `flutter test` — all pass.
4. Manual smoke test:
   - Cold launch → Home → No.3 card shows "NOT BUILT" (no longer hardcoded ready).
   - Tap No.3 → dress-accessories screen → tap "View 3D" → generating → ghost model.
   - Back to Home → No.3 shows "BUILT · [today]" with green status.
   - Tap No.3 again → goes directly to ghost model.

## 7. CLAUDE.md updates required

- **§ 5.2 State management:** document `generatedDresses` field and `markDressGenerated` setter.
- **§ 5.4 Local persistence:** (no change; this goes to Firestore).
- **§ 5.5 Backend — Firestore collections:** note `generatedDresses` sub-map in `users/{uid}/profile/current`.
