# AR Scanner / Ghost follow the dress the user built

- **Date:** 2026-10-09
- **Author:** Claude (agent)
- **Status:** executed

## 1. Goal
Bug: a user on RSAF / female opened the RSAF No.4 dress, tapped Build, then
scanned from the Ghost screen. The scanner sent `uniform_type=rsaf_no3_female`
and `cv-service` answered `UNSUPPORTED_UNIFORM`.

Cause: `DressAccessoriesScreen` pushes `/generating?dress=No4`, but that only
composes the No.4 model — `UniformProfile.dressCode` stays `No3`. `GhostScreen`
and `ARScannerScreen` both read `profile.dressCode`, so they show / scan No.3.

Fix: building a dress makes it the profile's active dress.

## 2. Scope
- In scope: `GeneratingScreen` sets the active dress before generating.
- Out of scope: passing the dress explicitly through `/ghost-model` and `/ar`
  routes; adding cv-service support for more uniforms.

## 3. Affected areas
- `lib/features/dashboard/presentation/screens/generating_screen.dart`

## 4. Step-by-step plan
1. In `GeneratingScreen.initState`'s post-frame callback, if
   `profile.dressCode != widget.dress`, call
   `uniformProfileProvider.notifier.setDressCode(widget.dress)` (debounced
   Firestore sync, same as every other setter) and log it.
2. Rebuild the release APK.

## 5. Risks & rollback
- The dashboard's "current dress" now changes when the user builds another
  dress. That is the intended meaning of the active dress.
- Rollback: revert the one block in `generating_screen.dart`.

## 6. Verification
- `flutter analyze`, `flutter test`.
- `flutter build apk --release --split-per-abi` with the Cloud Run URL.
- Device: build RSAF No.4 → Ghost → scan → request must carry
  `rsaf_no4_female` (not yet device-verified).

## 7. CLAUDE.md updates required
- §5.6 `/generating` route note: it also sets the profile's active dress.
