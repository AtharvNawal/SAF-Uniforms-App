# Theme Branding Consistency Fix

**Date:** 2026-05-04  
**Status:** verified  
**Author:** Claude

---

## Goal

Ensure every screen and widget reflects the **active** branch theme (`context.branchTheme`) rather than hard-wired service-palette values. Reported: selecting SAF Crest left certain elements (avatar, AppBar rank text, nav borders, Quick Action cards) still showing the raw service-branch colours.

---

## Scope

| File | Element | Problem | Fix |
|------|---------|---------|-----|
| `profile_tab.dart` | Avatar gradient | `ServicePalette.of(profile.branch)` bypasses the active theme — SAF Crest user sees Army/Navy/etc. colours on their avatar | Use `context.branchTheme.primary/.bright` |
| `dashboard_screen.dart` `_AppBar` | Rank/branch subtitle | `AppColors.inkMuted` — no accent at all; Profile tab already uses `branchTheme.bright` for the same text | Switch to `branchTheme.bright` |
| `dashboard_screen.dart` `_AppBar` | Bottom border | Hardcoded `AppColors.line` | Subtle `accent.withValues(alpha: 0.25)` tint |
| `dashboard_screen.dart` `_BottomNav` | Top border | Hardcoded `AppColors.line` | Subtle `accent.withValues(alpha: 0.25)` tint |
| `home_tab.dart` `_QuickAction` | Card border | `Colors.white.withValues(alpha: 0.10)` — all dress-cards use a themed border; Quick Actions don't | `accent.withValues(alpha: 0.22)` |

**Not changed** (intentionally use own colours):
- `_ServiceCard` in `config_screen.dart` — shows each branch's literal colour for selection.
- `_AccentTile` / `_SafCrestAccentTile` in `settings_sheet.dart` — theme picker tiles.

---

## Affected areas

- `lib/features/dashboard/presentation/tabs/profile_tab.dart`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/tabs/home_tab.dart`

---

## Step-by-step plan

1. **`profile_tab.dart`** — remove `ServicePalette.of(profile.branch)` usage in `_ProfileTabState.build()`; replace `palette.primary` / `palette.bright` in the avatar gradient with `context.branchTheme.primary` / `context.branchTheme.bright`.

2. **`dashboard_screen.dart` `_AppBar`** — inside `build()`, read `context.branchTheme.bright`; use it for the rank/branch mono text colour and for a tinted bottom border.

3. **`dashboard_screen.dart` `_BottomNav`** — `accent` is already read; change the `Border.top` from `AppColors.line` to `accent.withValues(alpha: 0.25)`.

4. **`home_tab.dart` `_QuickAction`** — `accent` is already passed as a parameter; change the `Border.all` colour from `Colors.white.withValues(alpha: 0.10)` to `accent.withValues(alpha: 0.22)`.

---

## Risks & rollback

- Low risk — all changes are purely cosmetic colour swaps inside `build()` methods.
- No state, routing, persistence, or codegen changes.
- Rollback: revert the three files.

---

## Verification

1. `flutter analyze` — must be clean.
2. Manual smoke test:
   - Switch theme to Army → accent green.
   - Switch theme to SAF Crest → gold avatar, gold AppBar text, gold tints on nav borders and Quick Action cards.
   - Switch theme to RSAF → accent blue.
3. Confirm `profile_tab.dart` imports `ServicePalette` is no longer needed and remove it if unused.

---

## CLAUDE.md sections to refresh

None — no architecture, routing, schema, or dependency changes.
