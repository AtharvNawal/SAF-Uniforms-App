# System Default Back Button

- **Date:** 2026-05-04
- **Author:** Claude
- **Status:** verified

## 1. Goal

Replace hand-rolled `InkWell` + `Row` + `Icons.chevron_left` + text label back buttons with Flutter's built-in `BackButton` widget so each platform renders its native back affordance (thin chevron on iOS, filled arrow on Android).

## 2. Scope

- In scope: presentation-layer back button widgets on 4 screens.
- Out of scope: navigation logic (unchanged), routing, state, ARB string keys (unused keys are harmless).

## 3. Affected areas

- `lib/features/ar_engine/presentation/screens/ghost_screen.dart`
- `lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart`
- `lib/features/checklist/presentation/screens/checklist_screen.dart`
- `lib/features/profile/presentation/screens/config_screen.dart` (`_Header` widget)

## 4. Step-by-step plan

1. In each screen, replace the `InkWell` + `Row` block with `BackButton(color: Colors.white, onPressed: ...)`.
2. In `_Header` (ConfigScreen), also remove the now-unused `stepNames` list and `backLabel` variable.

## 5. Risks & rollback

Low risk — purely visual, no logic change. Rollback: revert the four edits.

## 6. Verification

- `flutter analyze` → no issues found.
- Visual: iOS shows thin chevron (`arrow_back_ios_new`), Android shows filled arrow (`arrow_back`).
- Tap navigation verified correct on all 4 screens.

## 7. CLAUDE.md updates required

None — no architecture, routing, schema, or provider changes.
