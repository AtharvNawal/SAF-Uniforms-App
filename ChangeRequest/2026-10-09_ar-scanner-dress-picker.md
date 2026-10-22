# AR Scanner — choose No.3 / No.4 and block unsupported uniforms up front

- **Date:** 2026-10-09
- **Author:** Claude (agent)
- **Status:** executed — analyze clean, 158/158 tests, APK built; device test pending

## 1. Goal
On an Android phone (RSAF, ladies, profile dress No.3) the scanner took the
photos, uploaded them and only then showed
`'rsaf_no3_female' is not a supported uniform_type`. The user wanted to scan
No.4 and had no way to pick it on the scanner.
(`2026-10-09_ar-scanner-follows-built-dress.md` only helps after a rebuild.)

## 2. Scope
- In scope:
  - A No.3 / No.4 toggle on the scanner, defaulting to the profile's dress
    (No.1/2/5 profiles default to No.3). Local to the scan; the profile is
    not changed.
  - A client-side list of uniforms `cv-service` can check
    (`supported_uniforms.dart`). When the chosen combination is not on it, the
    scanner shows "can't be checked yet" with the supported list and the
    capture button stays disabled, so no photo is uploaded for nothing.
  - The server stays authoritative: its 422 is still surfaced if the lists
    ever drift.
- Out of scope: adding cv-service support for more uniforms (needs
  production-team assets — see the requirements page shared with the user).

## 3. Affected areas
- `lib/features/ar_scanner/domain/supported_uniforms.dart` (new, pure)
- `lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart`
- `lib/core/l10n/arb/app_{en,zh}.arb` (+ regenerated `generated/`)
- `test/features/ar_scanner/supported_uniforms_test.dart` (new)

## 4. Step-by-step plan
1. Move `uniform_type` naming into `supported_uniforms.dart`
   (`uniformTypeFor`, `isCheckableUniform`, `kCheckableUniformTypes`).
2. Scanner: `_scanDress` state, toggle under the top bar, unsupported card,
   capture disabled when unsupported, `_capture` sends `_scanDress`.
3. ARB strings (en + zh), `flutter gen-l10n`.
4. Unit tests.

## 5. Risks & rollback
- The client list must be updated when cv-service gains a uniform; until then
  the new uniform shows "not yet" in the app. Noted in the file's doc comment
  and in CLAUDE.md.
- Rollback: revert the files above.

## 6. Verification
- `flutter analyze`, `flutter test`, release APK build.
- Device (pending): RSAF ladies → scanner → toggle No.4 → scan succeeds;
  toggle No.3 → "can't be checked yet", capture disabled.

## 7. CLAUDE.md updates required
- §4 `ar_scanner/` tree: new domain file + scanner toggle.

## 8. Revision (2026-10-09, same day) — toggle removed
The user confirmed the scan works, then asked to remove the No.3 / No.4
buttons from the scanner and choose the uniform on the Dashboard instead.
- Removed the scanner toggle; the scanner checks `profile.dressCode`.
- `DashboardScreen.onOpenDress` now sets the profile's active dress for any
  No.1–No.5 card tap. Before, tapping an already-built dress opened the 3D
  screen without switching the dress.
- The "can't be checked yet" card stays, with a "Choose uniform on
  Dashboard →" link (`arChooseUniform`, en + zh) back to `/dashboard`.
- Verified: `flutter analyze` clean, `flutter test` 158/158, release APK built.
  Device test pending.
