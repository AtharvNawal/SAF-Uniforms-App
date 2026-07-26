# Fix duplicate-app Firebase init crash on Android (white screen on launch)

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## Context

First-launch on Android shows a white screen. Logs:

```
E/flutter: Unhandled Exception: [core/duplicate-app] A Firebase App named "[DEFAULT]" already exists
  at bootstrap (package:saf_uniforms/bootstrap.dart:46:5)
  at main (package:saf_uniforms/main.dart:11:18)
```

`bootstrap()` rethrows on failure, so `main()` aborts before `runApp(...)` ever runs — that's why nothing renders. The duplicate-app exception itself is the symptom of two issues stacked on top of each other:

1. **`firebase_options.dart` returns the wrong options per platform.** The switch in `DefaultFirebaseOptions.currentPlatform` has Android and iOS swapped: both cases fall through to `return ios;`, while `default:` returns `android`. So on the user's Android device, `Firebase.initializeApp(options: ...)` is invoked with iOS options (iOS bundle id, iOS app id).
2. **The Android `com.google.gms.google-services` Gradle plugin already auto-initialized the `[DEFAULT]` Firebase app** from `android/app/google-services.json` at process start (via a `ContentProvider` in `firebase-common`). Calling `Firebase.initializeApp` again with options that *don't match* the auto-init throws `[core/duplicate-app]`. (If the options matched, the platform side would silently return the existing app.)

Fixing only #1 would mask #2. The correct fix is to (a) repair the platform switch, and (b) make the explicit init no-op when a default app already exists, which is also the right behavior across hot restarts (the platform-side Firebase app outlives the Dart VM, so re-running `initializeApp` after a Dart hot restart can throw too).

## 1. Goal

App launches successfully on Android (and iOS) and reaches the Welcome screen on cold start. Hot restart no longer crashes bootstrap.

## 2. Scope

- **In scope:**
  - Correct the platform switch in [lib/firebase_options.dart](lib/firebase_options.dart).
  - Guard the explicit `Firebase.initializeApp` call in [lib/bootstrap.dart](lib/bootstrap.dart) against an already-initialized `[DEFAULT]` app.
- **Out of scope:**
  - Any change to Cloud Functions, Firestore rules, or seed scripts.
  - Re-running `flutterfire configure` (the existing `firebase_options.dart` values are already correct per platform — only the dispatch was wrong).
  - Changes to Android `google-services.json` / iOS `GoogleService-Info.plist`.

## 3. Affected areas

- [lib/firebase_options.dart](lib/firebase_options.dart) — fix the `currentPlatform` switch.
- [lib/bootstrap.dart](lib/bootstrap.dart) — guard the `Firebase.initializeApp` call; add `info`/`debug` logs for the two branches.

## 4. Step-by-step plan

### Step 1 — Fix `DefaultFirebaseOptions.currentPlatform`

In [lib/firebase_options.dart](lib/firebase_options.dart), replace the broken switch:

```dart
switch (defaultTargetPlatform) {
  case TargetPlatform.android:
  case TargetPlatform.iOS:
    return ios;
  default:
    return android;
}
```

with:

```dart
switch (defaultTargetPlatform) {
  case TargetPlatform.android:
    return android;
  case TargetPlatform.iOS:
    return ios;
  default:
    throw UnsupportedError(
      'DefaultFirebaseOptions: ${defaultTargetPlatform.name} is not supported.',
    );
}
```

Rationale: Android must get the Android `FirebaseOptions` (project `saf-uniforms`, app id `1:612500938654:android:...`) and iOS must get the iOS bundle. Falling through to a wrong option object is what triggered the platform-side mismatch with the auto-initialized default app. The `default:` arm now throws explicitly instead of silently returning Android options on, e.g., desktop builds.

### Step 2 — Guard `Firebase.initializeApp` in `bootstrap()`

In [lib/bootstrap.dart](lib/bootstrap.dart) around line 46, replace the unconditional call with a guarded one:

```dart
if (Firebase.apps.isEmpty) {
  developer.log('bootstrap: initializing Firebase', name: _logName);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} else {
  developer.log(
    'bootstrap: Firebase already initialized (${Firebase.apps.length} app(s)) — skipping',
    name: _logName,
    level: 700,
  );
}
```

Rationale:
- On Android, the `google-services` Gradle plugin auto-initializes the `[DEFAULT]` app via a `ContentProvider`. After Step 1 the options *match*, so the platform side would silently return the existing app — but skipping the call entirely is cheaper and removes the dependence on that platform-side dedupe behavior.
- On Dart hot restart, the platform-side Firebase app survives the Dart VM reset, so re-running `initializeApp` after a hot restart would otherwise throw. The guard makes hot restart safe.
- Logs follow CLAUDE.md policy 1.3: an `info`-ish line for either branch and a `debug`/`info` mix to make the path taken visible.

### Step 3 — Move this plan into `ChangeRequest/`

Per CLAUDE.md policy 1.1, plan files live under `ChangeRequest/`. Once execution starts, copy this file to `ChangeRequest/2026-05-02_fix-firebase-duplicate-app-on-android.md` and update its `Status:` line through `in-progress` → `executed` → `verified`.

## 5. Risks & rollback

- **Risk: a third platform (e.g., desktop) hits the new `throw` in `default:`.** Today the project only targets Android and iOS (`pubspec.yaml`, no desktop folders). If desktop is added later, extend the switch with the corresponding cases.
- **Risk: the guard hides a *real* misconfiguration** (e.g., someone calls `Firebase.initializeApp` from elsewhere with conflicting options). Mitigation: the `else` branch logs the count of existing apps so the situation is visible in logs.
- **Rollback:** revert the two file changes via `git revert`. No schema, no Firestore data, no Cloud Function, no asset is touched, so rollback is purely code.

## 6. Verification

Per CLAUDE.md policy 1.5:

1. `flutter analyze` — must be clean (no new warnings).
2. No codegen needed (no `@freezed` / `@riverpod` / `drift` / `json_serializable` annotations changed). Skip `build_runner`.
3. `flutter test` — existing tests still pass. (No new logic to test: the platform-switch correctness is exercised implicitly by any test that runs on a platform; the guard is dev-environment behavior.)
4. `flutter run` on Android device:
   - Cold launch reaches the Welcome screen.
   - `adb logcat` shows `bootstrap: initializing Firebase` (cold) or `bootstrap: Firebase already initialized` (after hot restart).
   - No `[core/duplicate-app]` exception in logs.
5. `flutter run` on iOS simulator (smoke): Welcome screen renders, `bootstrap: ok` log present.
6. Update the moved plan file's `Status:` to `verified` and note which device + OS the smoke test ran on.

## 7. CLAUDE.md updates required

None expected. The folder layout, dependencies, Drift schema, Firestore collections, provider graph, routing table, theming, localization, and feature public APIs are all unchanged. The bootstrap sequence in §5.3 already says "`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`" — that line stays accurate; the guard is an internal robustness detail not worth surfacing in the architectural overview.

If desired, a single-sentence note can be added to §8 ("Known gaps / TODOs") mentioning that bootstrap tolerates an already-initialized default app (helpful for hot restart). Optional, not required.
