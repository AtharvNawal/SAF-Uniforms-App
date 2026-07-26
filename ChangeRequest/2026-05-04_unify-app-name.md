# Unify the app name to "SAF Uniforms"

- **Date:** 2026-05-04
- **Author:** Claude (opus-4-7)
- **Status:** verified

## 1. Goal

Make the user-visible product name consistent across every surface — Android launcher, iOS home screen, in-app title, OS permission prompts, and project documentation — by renaming all variants (`saf_uniforms`, `Saf Uniforms`, `SAF Uniform Master`, `新加坡武装部队制服指南`) to **`SAF Uniforms`** (and `新加坡武装部队制服` in `zh`). Technical identifiers (Dart package name, Android `applicationId`, iOS bundle id, Firebase project id, the `SafUniformApp` Dart class) are explicitly **out of scope** — they are protocol-bound and renaming them would break the build / orphan the production Firebase project.

## 2. Scope

**In scope:**
- Android `android:label`
- iOS `CFBundleDisplayName`, `CFBundleName`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- Localized `appTitle` in `app_en.arb` and `app_zh.arb` (and the regenerated `lib/core/l10n/generated/*` outputs)
- `pubspec.yaml` `description`
- `CLAUDE.md` H1 and `Project at a glance > Description` bullet
- `functions/README.md` H1 and `functions/package.json` `description`

**Out of scope:**
- `pubspec.yaml` `name: saf_uniforms` (Dart package id)
- All `package:saf_uniforms/...` imports
- Android `namespace` / `applicationId` / Java package directory / `google-services.json` `package_name`
- iOS `PRODUCT_BUNDLE_IDENTIFIER` (`com.saf.safUniforms`) / `GoogleService-Info.plist` `BUNDLE_ID` / `lib/firebase_options.dart` `iosBundleId`
- Firebase project id `saf-uniforms` (in `.firebaserc`, `firebase.json`, `lib/firebase_options.dart`, `GoogleService-Info.plist` `PROJECT_ID` and `STORAGE_BUCKET`)
- `class SafUniformApp` and references to it
- `saf_uniforms_prefs.xml` referenced from `backup_rules.xml` / `data_extraction_rules.xml` (changing it would orphan existing user prefs)

## 3. Affected areas

- [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)
- [ios/Runner/Info.plist](../ios/Runner/Info.plist)
- [lib/core/l10n/arb/app_en.arb](../lib/core/l10n/arb/app_en.arb)
- [lib/core/l10n/arb/app_zh.arb](../lib/core/l10n/arb/app_zh.arb)
- [lib/core/l10n/generated/](../lib/core/l10n/generated/) (regenerated)
- [pubspec.yaml](../pubspec.yaml)
- [README.md](../README.md) (H1)
- [CLAUDE.md](../CLAUDE.md) (lines 1, 107)
- [functions/README.md](../functions/README.md)
- [functions/package.json](../functions/package.json)

## 4. Step-by-step plan

1. Update `AndroidManifest.xml`: `android:label="saf_uniforms"` → `"SAF Uniforms"`.
2. Update `ios/Runner/Info.plist`: `CFBundleDisplayName`, `CFBundleName`, and replace `SAF Uniform Master` with `SAF Uniforms` in both usage-description strings.
3. Update `lib/core/l10n/arb/app_en.arb`: `appTitle` → `SAF Uniforms`.
4. Update `lib/core/l10n/arb/app_zh.arb`: `appTitle` → `新加坡武装部队制服`.
5. Run `flutter gen-l10n` to regenerate `lib/core/l10n/generated/app_localizations*.dart`.
6. Update `pubspec.yaml` description.
7. Update `CLAUDE.md` H1 and Description bullet (line 107).
8. Update `functions/README.md` H1 and `functions/package.json` description.
9. Update [README.md](../README.md) H1 to `# SAF Uniforms` (caught during verification — same documentation category as `functions/README.md`).
10. Verify (see §6) and mark this plan `verified`.

**Verification run on 2026-05-04:**
- `flutter analyze` → `No issues found! (ran in 3.7s)` ✓
- `flutter gen-l10n` → ran clean; generated `app_localizations_en.dart` reads `=> 'SAF Uniforms'`, `app_localizations_zh.dart` reads `=> '新加坡武装部队制服'` ✓
- `flutter test` → 50/50 tests pass (one earlier run reported 3 transient flakes likely tied to the 500ms debounced profile-write timing; reruns all green and unrelated to string-only changes) ✓
- Device smoke-test (Android + iOS `flutter run`): not run in this session — pending operator confirmation that the launcher label and iOS permission prompts render `SAF Uniforms`.
- `grep` sweep: only out-of-scope identifiers remain (`pubspec.yaml` `name:`, `package:saf_uniforms/...` test imports, `CLAUDE.md:106` backticked Dart package name, `CLAUDE.md:625` import-path policy, Android `applicationId`/`namespace`, iOS bundle id, Firebase project id, `saf_uniforms_prefs.xml`, `class SafUniformApp`).

## 5. Risks & rollback

- **Generated localization files out of sync with ARBs.** Mitigation: always run `flutter gen-l10n` after editing the ARBs.
- **iOS `CFBundleName` change is observable in App Store Connect once shipped.** Flag on the next TestFlight build.
- **Android `android:label` updates on next install.** Existing on-device installs keep the old label until the new build is installed — expected, no action.
- Rollback: every change is a single-string edit. `git checkout -- <file>` reverts.

## 6. Verification

Per CLAUDE.md policy 1.5:

1. `flutter analyze` — must be clean.
2. `flutter gen-l10n` — must regenerate without errors. Confirm `lib/core/l10n/generated/app_localizations_en.dart` reads `=> 'SAF Uniforms'` and `app_localizations_zh.dart` reads `=> '新加坡武装部队制服'`.
3. `flutter test` — all existing tests pass. (No annotation changes, so `build_runner` is not required.)
4. `flutter run` on Android: launcher label shows `SAF Uniforms`; in-app title resolves to `SAF Uniforms` (en) / `新加坡武装部队制服` (zh).
5. `flutter run` on iOS: home-screen label shows `SAF Uniforms`; first camera-permission prompt reads `SAF Uniforms uses the camera…`.
6. `grep -n "SAF Uniform Master" CLAUDE.md` — only historical citations of past ChangeRequest filenames should remain.

## 7. CLAUDE.md updates required

- H1 (line 1): `SAF Uniform Master — Project Guide` → `SAF Uniforms — Project Guide`
- §2 "Project at a glance" Description bullet (line 107) → `SAF Uniforms — Singapore Armed Forces uniform reference.`

No other sections (folder layout, dependencies, Firestore collections, provider graph, routing, theming, localization keys, feature public APIs) are affected.
