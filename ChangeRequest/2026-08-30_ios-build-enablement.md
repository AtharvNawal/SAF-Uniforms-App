# iOS build enablement + FlutterFire upgrade

**Status:** verified — `flutter analyze` clean, `flutter test` 116/116,
`flutter build ios --release --no-codesign` → `Runner.app` (92.7 MB),
`flutter build apk --release` green. Not run on a physical device
(no device in the authoring environment); signing is the operator's
Apple ID step.

## Goal

Make the app actually build for iOS. It never has in this repo — the
Podfile was corrupt — so "does it run on iPhone" was untestable.

## What was broken (found in order)

1. **`ios/Podfile` line 3 was a raw shell command**
   (`sed -i '' "s/# platform :ios, '13.0'/platform :ios, '15.5'/" Podfile`)
   pasted in as Ruby source → `pod install` syntax error → every iOS
   build failed before compiling anything.
2. **Deployment target 13.0** in `project.pbxproj` vs. MLKit's required
   15.5.
3. **No ATS / local-network exception** — iOS blocks cleartext HTTP, so
   the app couldn't reach the LAN `cv-service` (`http://<ip>:8001`).
4. **`cloud_firestore` 6.3.0 doesn't compile** against the current
   firebase-ios-sdk (>= 12.16): `FLTPipelineParser.m` references
   `FIRCollectionSourceStageBridge -initWithRef:firestore:` /
   `FIRCollectionGroupSourceStageBridge -initWithCollectionId:` which
   don't exist in that SDK. Reverting the SDK to 12.16.0 didn't help —
   the mismatch is in cloud_firestore itself, fixed in 6.9.0.
5. **`fake_cloud_firestore` 4.1.x** (test-only) `MockWriteBatch.update`
   signature doesn't match `cloud_firestore` 6.9's generic
   `WriteBatch.update<T>` → 3 repo tests failed to compile.
6. Stale Xcode module cache after the failed builds.

## Changes

- `ios/Podfile` — line 3 → `platform :ios, '15.5'` (with a comment on
  why 15.5).
- `ios/Runner.xcodeproj/project.pbxproj` — `IPHONEOS_DEPLOYMENT_TARGET`
  13.0 → 15.5 (all 3 configs).
- `ios/Runner/Info.plist` — added `NSAppTransportSecurity ›
  NSAllowsLocalNetworking = true` and `NSLocalNetworkUsageDescription`
  (DEV concession; comment says remove before App Store). Firebase is
  HTTPS regardless.
- `pubspec.yaml` — FlutterFire family floors raised (kept in lockstep):
  `firebase_core ^4.14.0`, `firebase_auth ^6.6.1`, `cloud_firestore ^6.9.0`,
  `cloud_functions ^6.4.0`, `firebase_storage ^13.5.0`;
  `fake_cloud_firestore ^4.2.0` (dev).
- `pubspec.lock` — regenerated.
- `ios/Podfile.lock`, SPM `Package.resolved` — regenerated (firebase-ios-sdk
  now resolves fresh under the new plugin versions; the stale 12.18.0
  hand-bump in `Package.resolved` is gone).
- CLAUDE.md §3 (Firebase versions), §5.5 (iOS ATS note), §8.

## Not changed / out of scope

- No Dart/business-logic changes. The FlutterFire bump is API-compatible
  (analyze + full test pass unmodified).
- MLKit pods still lack arm64 slices for Apple-Silicon **simulators**
  (iOS 26+) — a plugin limitation, only affects the sim, not devices.
  Physical-iPhone builds are unaffected.
- Signing / provisioning — the operator sets their Apple ID team in
  Xcode; `flutter run --release` installs to a connected iPhone.

## Verification

1. `flutter analyze` — clean. ✅
2. `flutter test` — 116/116. ✅
3. `flutter build ios --release --no-codesign` — `Runner.app` built. ✅
4. `flutter build apk --release` — green (Firebase bump doesn't regress
   Android). ✅
5. Physical iPhone run — operator, with their Apple ID.

## CLAUDE.md sections refreshed

§3 (dependency table — Firebase rows), §5.5 (iOS cleartext / local
network), §8 (iOS build was blocked, now works).
