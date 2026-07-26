# Device-Bound Identity & Profile Sync

- **Date:** 2026-05-02
- **Author:** Claude (opus-4.7) + user
- **Status:** executed (pending operator deploy + on-device smoke; flip to `verified` after §6.5–§6.7)

## 1. Goal

Wire up the end-of-Configuration handshake so that:

1. The Configuration wizard persists the `UniformProfile` to Firestore on
   completion (instead of dropping it into in-memory state and forgetting it).
2. The user is bound to a stable device identity (UUIDv4 in keychain), so an
   uninstall + reinstall on the same device recovers the same Firebase uid
   and routes straight to the Dashboard rather than re-running the wizard.
3. The Welcome screen no longer blocks app launch on a Firebase round-trip:
   it reads a local cache, renders immediately, and verifies / refreshes
   auth in the background.
4. Subsequent edits to the profile flow back to Firestore in real time
   (debounced 500 ms) without requiring an explicit Save button.

## 2. Scope

### In scope
- New persistent device identity (UUIDv4 in `flutter_secure_storage`).
- New Cloud Functions project (`functions/`) with two HTTPS callables:
  `claimDeviceIdentity`, `markProfileComplete`.
- New `device_registrations/{deviceId}` Firestore collection (admin-only).
- New `LocalStorageService` (secure storage + shared_preferences).
- Refactor of `AuthRepository`, `bootstrap()`, `main.dart` to a non-blocking
  custom-token sign-in flow.
- Debounced auto-sync inside `UniformProfileNotifier`.
- Welcome / Config / router updates for the "skip-wizard-if-complete" branch.
- Android Auto Backup enabled with a `backup_rules.xml` whitelist.

### Out of scope
- Multi-device bidirectional sync (we keep the existing `profile.watch()`
  hydrate-on-launch pattern; not subscribing for live updates yet).
- Full profile shape expansion (`vocation`, `name`, `badges`,
  `profileComplete` are still local UI state in `ConfigScreen` — that
  graduation to the freezed entity is its own plan).
- Web admin portal that would write to `device_registrations` directly.
- Migration of pre-existing users (none in production).

## 3. Affected areas

### New files
- `lib/core/persistence/local_storage_service.dart`
- `lib/features/auth/data/device_identity_service.dart`
- `lib/features/auth/data/device_registry_service.dart`
- `lib/features/auth/domain/device_identity.dart`
- `lib/features/profile/presentation/providers/profile_sync_listener.dart`
- `functions/package.json`, `functions/tsconfig.json`, `functions/src/index.ts`
- `android/app/src/main/res/xml/backup_rules.xml`
- Tests under `test/features/auth/`, `test/features/profile/`,
  `test/features/onboarding/`.

### Modified files
- `pubspec.yaml` — add `flutter_secure_storage`, `shared_preferences`,
  `uuid`, `cloud_functions`.
- `lib/bootstrap.dart` — split into `bootstrap()` (Firebase init + cache
  read) and `kickoffAuthFlow(container)` (background sign-in).
- `lib/main.dart`
- `lib/features/auth/data/auth_repository_impl.dart`
- `lib/features/auth/data/device_auth_service.dart` (delete or thin-wrap)
- `lib/features/auth/presentation/providers/auth_providers.dart`
- `lib/features/profile/presentation/providers/uniform_provider.dart`
- `lib/features/profile/presentation/screens/config_screen.dart`
- `lib/features/onboarding/presentation/screens/welcome_screen.dart`
- `lib/core/routing/app_router.dart`
- `firestore.rules`
- `firebase.json`
- `android/app/src/main/AndroidManifest.xml`

### Schemas / Firestore
- New collection `device_registrations/{deviceId}`:
  `{uid, platform, profileComplete, createdAt, lastSeenAt}` — admin only.
- `users/{uid}.hardwareId` semantics change: now the stable UUIDv4 (not
  `Build.ID` / `identifierForVendor`).

## 4. Step-by-step plan

1. Save this plan; mark `in-progress`.
2. `pubspec.yaml`: add `flutter_secure_storage ^9`, `shared_preferences ^2`,
   `uuid ^4`, `cloud_functions ^6`. `flutter pub get`.
3. `firestore.rules`: add the admin-only `device_registrations` block.
4. AndroidManifest: `android:allowBackup="true"`,
   `android:fullBackupContent="@xml/backup_rules"`. Add
   `res/xml/backup_rules.xml` whitelisting FlutterSecureStorage prefs.
5. New domain types: `DeviceIdentity { deviceId, platform }` and
   `ClaimResult { uid, customToken, profileComplete }`.
6. `LocalStorageService` — async getters/setters for `deviceId`, `cachedUid`,
   `profileComplete`, plus a `clear()` for tests.
7. `DeviceIdentityService.resolve()` — read or generate a UUID, write it
   back to secure storage, tag with `Platform.isIOS ? 'ios' : 'android'`.
8. Scaffold `functions/` (Node 20 + TypeScript). Implement
   `claimDeviceIdentity` and `markProfileComplete`.
9. `DeviceRegistryService` — wraps `FirebaseFunctions.instance.httpsCallable`.
10. Refactor `AuthRepositoryImpl`: drop `signInAnonymously`, accept a
    `ClaimResult`, call `signInWithCustomToken`, upsert `users/{uid}` with
    the new stable hardware id.
11. Refactor `bootstrap()` + `main.dart`: Firebase init + local cache only;
    `kickoffAuthFlow` runs in parallel with `runApp`.
12. Update `auth_providers.dart`: introduce `localStorageServiceProvider`,
    `deviceIdentityServiceProvider`, `deviceRegistryServiceProvider`,
    `firebaseFunctionsProvider`. `authSessionProvider` becomes async-friendly.
13. `UniformProfileNotifier`: add `Timer? _debounce` and `hydrate()`;
    every setter schedules `_scheduleSync()`; `persist()` cancels the timer
    and awaits the upsert.
14. `WelcomeScreen`: route based on cached `profileComplete`. New users
    flow → `/config`; returning users → `/dashboard`.
15. `ConfigScreen._next()`: on the final step, await `persist()`, await
    `markProfileComplete`, set local flag, then `context.go('/dashboard')`.
16. `app_router.dart`: add a `redirect:` that respects `profileComplete`
    (so deep links don't bypass the wizard).
17. `flutter pub run build_runner build --delete-conflicting-outputs`.
18. `flutter analyze`, `flutter test`. Add new tests.
19. Operator: deploy functions + rules
    (`firebase deploy --only functions,firestore:rules`).
20. Smoke test on iOS sim + Android device per §6.
21. Update `CLAUDE.md` per policy 1.2.
22. Mark plan `executed` → `verified`.

## 5. Risks & rollback

- **Cloud Function failure mode.** If `claimDeviceIdentity` is unreachable
  on launch (offline, function cold-start), the user still sees the cached
  Dashboard. Sign-in retries on next foreground. Profile writes queue in
  the Firestore SDK's offline cache. No rollback needed.
- **Custom-token replacing anonymous auth.** If we mis-issue a token, the
  user is still anonymous in spirit (no email/password). To roll back,
  revert `AuthRepositoryImpl` to `signInAnonymously` and ignore
  `ClaimResult` — local UID will diverge from the cached one but app
  remains functional. Cloud Function can be left deployed but unused.
- **Android backup misconfiguration.** A bad `backup_rules.xml` could
  block backup of FlutterSecureStorage and silently regress reinstall
  recovery. Smoke test specifically covers `bmgr backupnow` between
  uninstall and reinstall. Rollback = remove `android:allowBackup`.
- **Firestore rules deploy** is the only step that affects existing users.
  The new `device_registrations` rule defaults to `allow read, write: if
  false` so we cannot accidentally over-share. Rollback = redeploy
  prior rules from git history.

## 6. Verification (per CLAUDE.md §1.5)

1. `flutter pub get`
2. `flutter pub run build_runner build --delete-conflicting-outputs`
3. `flutter analyze` clean
4. `flutter test` — all green, including:
   - `device_identity_service_test.dart` — UUID generated once, reused
   - `device_registry_service_test.dart` — payload + custom-token call
   - `uniform_profile_sync_test.dart` — debounced upsert, awaited persist
   - `welcome_routing_test.dart` — routes by `profileComplete`
5. Operator: `firebase deploy --only functions,firestore:rules`.
6. iOS simulator smoke:
   - First launch → Welcome → `/config` → Done → `/dashboard`. Console
     shows `users/{uid}/profile/current` and
     `device_registrations/{deviceId}.profileComplete = true`.
   - Force-quit + relaunch → straight to `/dashboard`.
   - Uninstall + reinstall → straight to `/dashboard`, **same uid**.
   - Toggle a badge → Console reflects the change within ~500 ms.
7. Android device smoke (Auto Backup enabled):
   `adb shell bmgr enable true`,
   `adb shell bmgr backupnow com.example.saf_uniforms`, uninstall,
   reinstall, confirm same uid.
8. Mark plan `verified`.

## 7. CLAUDE.md updates required

- §3 stack table — add `flutter_secure_storage`, `shared_preferences`,
  `uuid`, `cloud_functions`.
- §4 source tree — `lib/core/persistence/`, new `auth/data/*` files,
  `auth/domain/device_identity.dart`, `functions/` mention.
- §5.3 bootstrap sequence — describe the new non-blocking flow and the
  `claimDeviceIdentity` round-trip.
- §5.4 local persistence — was "None"; now describes
  `LocalStorageService` (deviceId, cachedUid, profileComplete) and notes
  Firestore SDK still owns reference-content offline cache.
- §5.5 backend — add `device_registrations/{deviceId}` collection, the
  two callables, and `firestore.rules` admin-only block.
- §5.6 routing — add the `redirect:` and the Welcome → Config branch for
  new users.
- §8 known gaps — drop "Profile is in-memory only" / "Welcome always goes
  to Dashboard"; add note on Android Auto Backup best-effort behavior.
