# Enable Maternity Gender Selection

**Status:** verified
**Date:** 2026-05-04
**Author:** Claude (via user request)

---

## Goal
Allow users to select "Maternity" as their gender in both the Config wizard and the Profile tab. The option was visually present but permanently disabled.

## Scope
- `lib/features/profile/domain/entities/gender.dart` — add `maternity` enum value
- `lib/core/l10n/l10n_extensions.dart` — extend `GenderL10n` switch
- `lib/features/profile/presentation/screens/config_screen.dart` — wire Maternity tile
- `lib/features/dashboard/presentation/tabs/profile_tab.dart` — wire Maternity pill

No Firestore schema change, no DTO change, no migration needed.

## Risks & Rollback
Low risk. Maternity follows ladies' accessory resolution (correct SAF behaviour). Rollback: revert the four files.

## Verification
1. `flutter analyze` — clean
2. `flutter pub run build_runner build --delete-conflicting-outputs` — no errors
3. Config wizard Step 2: tap Maternity → tile highlights, others deselect
4. Profile tab Section 02: tap Maternity pill → activates, persists across navigation

## CLAUDE.md Sections Affected
None — no architecture, routing, or provider graph changes.
