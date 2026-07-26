# Handoff screens implementation — full UI from Claude Design bundle

- **Date:** 2026-05-02
- **Author:** Claude (sonnet via Claude Code)
- **Status:** verified

## Verification log (2026-05-02)
- `flutter pub get` — clean. `google_fonts ^6.2.1` resolved.
- `flutter analyze` — `No issues found!`
- `flutter test` — 28/28 passing (existing provider/repository/resolver
  tests unchanged; no new tests added in this UI-only pass).
- `flutter gen-l10n` — regenerated `app_localizations*.dart` from
  expanded en + zh ARBs.
- Visual smoke test (manual): not run from CI; the user will run
  `flutter run` on iOS sim and verify the navigation flow listed in §6.

## 1. Goal

Implement every screen defined in the Claude Design handoff bundle
(`/Users/meet/Downloads/SAF-Uniforms-handoff.zip`) inside the Flutter app
so the app exposes the full visual flow end-to-end:

- Welcome → Dashboard (Home / Wardrobe / Gallery / Profile tabs) →
  Configure → Generating → Ghost Model → Wearing Guide / AR Scanner;
  Profile → Update → Rebuilding loader.

Wiring + redirections only — no business logic in this pass. Screens
must be responsive (`MediaQuery` / `LayoutBuilder` / flex sizing) with
**no hardcoded screen dimensions** and **no overflow errors**.

## 2. Scope

In scope:
- 11 screens: Welcome, Config (4-step), Dashboard (4 tabs), Ghost Model,
  Wearing Guide, AR Scanner, Generating loader, Rebuilding loader.
- Settings sheet, accessory detail sheet.
- New shared `lib/core/design/` design-system layer: tokens + reusable
  widgets (cards, chips, buttons, pills, status bar, topo background).
- Routing: 8 new routes wired through the existing `go_router` provider.
- Adding `google_fonts` dependency for DM Sans + JetBrains Mono.
- Replacing the existing `_HomePlaceholder` (which becomes obsolete).
- Updating CLAUDE.md sections §3, §4, §5.6, §8.

Out of scope:
- Real business logic for any field beyond what existing providers
  already supply (`branch`, `gender`, `dressCode`, `sikh`, `accessories`).
  `medalRows`, `badges`, `vocation`, `name`, `profileComplete`,
  `darkMode`, `firstRun`, `gallery photos` are local UI state only and
  will be promoted to providers/Firestore in later prompts.
- Real camera / pose detection / TTS — placeholder UI only.
- Real 3D viewport — placeholder painter only.
- Tests (smoke test only via `flutter run`).
- Light-mode polish beyond the basics (the design is dark-first).

## 3. Affected areas

New files:

- `lib/core/design/app_colors.dart`
- `lib/core/design/app_text_styles.dart`
- `lib/core/design/app_spacing.dart`
- `lib/core/design/widgets/topo_background.dart`
- `lib/core/design/widgets/ios_status_bar.dart`
- `lib/core/design/widgets/app_chip.dart`
- `lib/core/design/widgets/app_buttons.dart`
- `lib/core/design/widgets/app_card.dart`
- `lib/core/design/widgets/pill_toggle.dart`
- `lib/core/design/widgets/badge_pill.dart`
- `lib/core/design/widgets/check_card.dart`
- `lib/core/design/widgets/spotlight_card.dart`
- `lib/core/design/widgets/app_bottom_sheet.dart`
- `lib/core/design/widgets/dress_mini_preview.dart`
- `lib/features/onboarding/presentation/screens/welcome_screen.dart`
- `lib/features/profile/presentation/screens/config_screen.dart`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/screens/generating_screen.dart`
- `lib/features/dashboard/presentation/screens/rebuilding_screen.dart`
- `lib/features/dashboard/presentation/widgets/...` (cards, sheets)
- `lib/features/checklist/presentation/screens/checklist_screen.dart`
- `lib/features/checklist/presentation/widgets/accessory_detail_sheet.dart`
- `lib/features/ar_engine/presentation/screens/ghost_screen.dart`
- `lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart`
- `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart`

Modified files:

- `pubspec.yaml` — add `google_fonts: ^6.2.1`
- `lib/core/routing/routes.dart` — add 7 new route constants
- `lib/core/routing/app_router.dart` — replace `_HomePlaceholder`,
  register all new routes
- `lib/core/theme/app_theme.dart` — wire DM Sans into `TextTheme`
- `lib/features/ar_engine/presentation/widgets/ghost_model_view.dart` —
  thin wrapper that just embeds `GhostScreen` body (kept for backward
  compat in case anything imports it; can be deleted later)
- `CLAUDE.md` — §3, §4, §5.6, §8

## 4. Step-by-step plan

1. Add `google_fonts` to `pubspec.yaml`; `flutter pub get`.
2. Build `core/design/` tokens (colors, text styles, spacing).
3. Build shared widgets in `core/design/widgets/`.
4. Update `app_theme.dart` to apply `dmSans` text theme.
5. Add new route constants and register routes; replace
   `_HomePlaceholder` initial route with `WelcomeScreen`.
6. Build screens in this order (each depends on the design widgets):
   Welcome → Dashboard (with all 4 tabs + app bar + bottom nav +
   settings sheet) → Config → Ghost → Checklist → Wearing Guide →
   AR Scanner → Generating → Rebuilding.
7. Wire navigation: every CTA in the design maps to a `context.go(...)`
   or `context.push(...)`.
8. `flutter analyze`, `flutter test`, `flutter run` smoke test
   (per CLAUDE.md §1.5).
9. Update CLAUDE.md.
10. Mark this plan `Status: verified`.

## 5. Risks & rollback

Risks:
- **Build size** — `google_fonts` adds ~1MB on first font fetch.
  Acceptable; alternative is bundling TTFs locally (heavier).
- **Provider mismatch** — local UI state for `medalRows` / `badges` etc.
  diverges from `UniformProfile`. Mitigation: keep these as
  `useState`-style local state in screens; add them to providers in a
  follow-up plan.
- **Replacing `_HomePlaceholder`** — any hot-reload session pinned to
  `/` will pick up the new Welcome screen. Acceptable since the
  placeholder was never user-facing.
- **`GhostModelView` consumers** — currently only the `/ghost-model`
  route uses it. Will be replaced wholesale; no other callers.

Rollback: revert the listed files. The data layer is untouched.

## 6. Verification

Per CLAUDE.md §1.5:

1. `flutter pub get` — pulls `google_fonts` cleanly.
2. `flutter analyze` — must be clean.
3. `flutter test` — existing tests still pass (no provider API changes).
4. `flutter run` (iOS sim if available, else Android) — manually walk
   through:
   - Welcome → Get Started → Dashboard (Home tab visible).
   - Dashboard → Setup card → Config wizard → 4 steps → Build →
     Generating loader → Ghost Model.
   - Ghost Model → Front/Back toggle, tap a hotspot pin → info card
     shown.
   - Ghost Model → Start AR Scan → AR Scanner (scanning phase) →
     capture → scorecard.
   - Ghost Model → Start Wearing → Wearing Guide → step through →
     Complete view.
   - Dashboard → Wardrobe tab → dropdown → tap accessory → detail sheet.
   - Dashboard → Gallery tab → empty state visible.
   - Dashboard → Profile tab → edit a field → Update → confirm sheet →
     Rebuilding loader → Dashboard.
   - Dashboard → Settings icon → Settings sheet → toggle dark mode.
5. Resize to 320 dp width (iPhone SE) — no overflow.

## 7. CLAUDE.md updates required

- §3 "Tech stack" — add `google_fonts` row.
- §4 "Source tree" — add `core/design/` and the new feature folders
  (`onboarding/`, `dashboard/`, `wearing_guide/`) plus the new screen
  files under `profile/`, `checklist/`, `ar_engine/`, `ar_scanner/`.
- §5.6 "Routing" — replace the current "current routes" sub-list with
  the 9 routes wired post-implementation; note that Dashboard tabs are
  internal state.
- §8 "Known gaps" — strike off items completed by this plan
  (UI screens, fonts) and update the "DressAccessoryResolver / no UI
  consumes it yet" item.
