# Change Request: Home Screen Card Design Refresh

**Date:** 2026-05-04
**Status:** verified

---

## Goal

Replace the accent-flood card design on the home screen with a Frosted Dark Glass approach. Cards become surface-first (solid dark) with a two-tone accent border (bright top edge at 50%, sides at 20%, bottom at 10%). Branch color is expressed through border glow and icon tints only — no large colored fill.

## Problem

`_SetupCard`, `_DressCardHero`, `_DressCard`, and `_QuickAction` all use `context.branchTheme.accent` at alpha 0.20–0.45 as a gradient fill base. For the SAF Crest theme (`accent = #FFCC00`), this creates a heavy gold wash across every card. For all themes, the cards fight each other visually when stacked.

## Scope

- **Only:** `lib/features/dashboard/presentation/tabs/home_tab.dart`
- No providers, no routing, no codegen, no other files

## Affected CLAUDE.md sections

None — no architecture changes.

## Step-by-step plan

1. `_SetupCard`: solid `AppColors.charcoal2` fill, two-tone `bright` border, reduced shadow
2. `_DressCardHero`: solid fill, two-tone border, left pane gradient `bright@0.10 → transparent`
3. `_DressCard`: solid fill, two-tone border, icon container `bright@0.12 → bright@0.04`
4. `_QuickAction`: solid fill, two-tone border, icon container `accent@0.14`

## Risks & rollback

- Pure visual change; no data or logic touched. Rollback = revert the single file.

## Verification

1. `flutter analyze` — clean
2. Visual smoke: Army / Navy / RSAF / DIS / SAF Crest themes all look clean
3. Dark mode + light mode
