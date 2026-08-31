# AR Scanner: in-app live camera + accurate failure messaging

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** executed (not yet verified — see §6, manual device check pending)

## 1. Goal

Two bugs reported together against the AR Scanner's capture flow:

1. Tapping capture leaves the app and opens the OS camera app instead of
   capturing in-app.
2. After capturing, the app shows a generic "check your connection"
   error even when the network is confirmed fine.

## 2. Decision: migrating to the `camera` plugin (supersedes an earlier decision)

`ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md` explicitly
scoped a prior bug fix to **not** migrate off `image_picker`, keeping
the OS-camera hand-off as-is and fixing only the state-loss symptom.
The requester has now explicitly asked for the opposite: a true in-app
live camera preview. This plan supersedes that earlier scope decision
for this one flow — the state-loss fix itself (last-route persistence)
stays in place regardless and remains useful for any other cause of a
process kill.

## 3. Diagnosis — bug 2 (the "network" error)

Confirmed by reading `functions/src/checkUniformCompliance.ts`: it
requires the caller to be signed in (`if (!req.auth) throw
HttpsError("unauthenticated", ...)`). This app's own architecture
(`CLAUDE.md` §5.3) deliberately lets a user navigate around on a
**cached** session before the real Firebase custom-token sign-in
finishes in the background — "the UI never blocks on the network." So
reaching the AR Scanner and capturing before that background sign-in
lands is a real, reachable state; separately, `readProfile()` throws
`not-found`/`failed-precondition` if the Firestore profile doc isn't
there yet, and other `HttpsError` codes are possible too.

**The actual client-side bug, confirmed in code, not guessed:**
`_FailedPhase` in `ar_scanner_screen.dart` shows the same hardcoded
"Check your connection and try again" for **every** failure, with zero
inspection of what actually threw. This is why the requester sees a
network-flavored message regardless of the real cause — the message is
wrong, not necessarily the diagnosis of "network." This plan fixes the
message to actually reflect the thrown error; it cannot, from this
environment, confirm which specific server-side cause the requester hit
on their device (no live logs available here — see §7).

## 4. Scope

- In scope:
  - **Live in-app camera** for the AR Scanner's capture flow only (both
    the default tap → Phase 1 path and the long-press dev → Phase 2
    path share the same on-screen preview; gallery upload
    (`gallery_tab.dart`) is a separate feature/purpose and keeps
    `image_picker` — not part of this bug report).
    - `_ARScannerScreenState` owns a `CameraController`, initialized in
      `initState`, disposed in `dispose`.
    - A `WidgetsBindingObserver` (this app's **first** lifecycle
      observer — see the state-loss fix's own finding that none existed
      anywhere) disposes the controller on `inactive`/`paused` and
      reinitializes on `resumed`, per the `camera` package's own
      documented pattern — avoids holding the camera hardware while
      backgrounded and avoids Android camera-in-use conflicts.
    - `_ScanningPhase` renders `CameraPreview(controller)` once
      initialized; falls back to the existing dark-gradient placeholder
      while initializing, and to a permission/hardware-error state
      (with a retry affordance) if `CameraController.initialize()`
      throws.
    - `_capture()`/`_captureCvService()` both switch from
      `ImagePicker().pickImage(...)` to `_cameraController.takePicture()`
      — an `XFile`, identical surface to what `image_picker` already
      returned, so `CaptureQualityGate.evaluate(path)` and everything
      downstream of capture is **unchanged**. The near-duplicate
      capture+gate logic between the two handlers is factored into one
      shared helper as a natural consequence, not a separate refactor.
    - iOS `NSCameraUsageDescription` already exists (`image_picker`'s
      camera source already required it) — no Info.plist change needed.
      Android already declares `android.permission.CAMERA`.
  - **Accurate failure messaging:**
    - `_ARScannerScreenState` tracks the actual thrown error (not just a
      phase enum) from both `ref.listen` blocks.
    - A new mapping function distinguishes `FirebaseFunctionsException`
      codes (`unauthenticated`, `not-found`/`failed-precondition`,
      `invalid-argument`, `deadline-exceeded`/`unavailable`) and
      `CvServiceInspectionException` (no HTTP response at all vs. a
      real error response) into distinct, accurate title/subtitle pairs
      — only the genuine connectivity-flavored codes keep a
      "check your connection" style message.
    - New ARB strings (en + zh) for each distinct message.
- Out of scope:
  - Any change to `gallery_tab.dart`'s capture flow.
  - Camera UI niceties not requested: flash toggle, front/back switch,
    zoom, manual focus.
  - Actually fixing whatever server-side condition the requester's
    device hit — this plan makes the *symptom* (misleading message)
    accurate; the underlying cause needs the requester's device logs
    (tag `arScanner.compliance`) or Firebase Console function logs to
    pin down definitively (see §7).

## 5. Risks & rollback

- **Camera resource conflicts are the main real risk** with any
  `camera`-plugin integration — mitigated by the lifecycle observer
  (§4) disposing/reinitializing around backgrounding, the documented
  correct pattern.
- **Simulators/emulators without camera hardware, or a denied
  permission,** must degrade to a clear in-place error with retry, never
  a crash or a silently-blank preview — covered by catching
  `CameraException` around `initialize()`.
- **The error-message fix cannot be verified against the requester's
  actual failure** without their device logs — flagged explicitly
  rather than assumed fixed (see §7).
- Rollback: revert `ar_scanner_screen.dart`, the new ARB entries, and
  regenerated l10n files. No other files touched.

## 6. Verification

- `flutter analyze` — **clean, 0 issues** (project-wide).
- `flutter gen-l10n` — regenerated; new getters
  (`arErrorSignInTitle`/`Sub`, `arErrorProfileTitle`/`Sub`,
  `arErrorPhotoTitle`/`Sub`, `arErrorConnectionTitle`/`Sub`,
  `arErrorCvUnreachableSub`, `arErrorCameraTitle`/`Sub`) confirmed
  present in both `app_localizations_en.dart` and the base class.
- `flutter test` — **all 103 tests passed** (93 pre-existing + 10 new
  in `test/features/ar_scanner/capture_error_message_test.dart`,
  covering every `FirebaseFunctionsException` code branch,
  `CvServiceInspectionException` with and without a status code, and
  the generic/null fallback).
- The error-mapping logic was extracted to a standalone public function
  (`describeCaptureError` in
  `lib/features/ar_scanner/presentation/utils/capture_error_message.dart`)
  specifically so it could be unit-tested directly, rather than staying
  private inside the 700-line screen file.
- Manual device check — **not run by this plan; still pending.** No
  device/emulator was available in this environment, same constraint as
  the prior state-loss fix. Two things need confirming on a real
  device: (1) the capture flow shows a live in-app preview, not the OS
  camera app; (2) a deliberately-forced failure (airplane mode for a
  genuine connectivity error, or catching the app right after a fresh
  install before background sign-in completes, for the unauthenticated
  case) shows a message matching the actual cause, not always "check
  your connection." §7 also still needs the requester's actual device
  logs to close the loop on which specific cause they originally hit.

## 7. What's needed from the requester to close the network-error diagnosis

This plan fixes the *display* of the error, not necessarily the
underlying cause (which could be several things — see §3). To confirm
which one actually hit: reproduce the failure again, then check
`flutter logs` / Android Studio Logcat / Xcode console for the line
`[E] arScanner.compliance | check: FAILED` (or `cv service` equivalent)
— `UniformComplianceRepository` already logs the real exception via
`AppLog.e`, it's just never surfaced to the UI. That log line has the
real answer.

## 8. CLAUDE.md updates required

- §5.10 / AR Scanner feature description: note the live in-app camera
  (replacing the OS-camera hand-off) and the error-message mapping.
- `capture_quality_gate.dart`'s own doc comment claims "this app has no
  live camera feed" — now stale, needs updating.
