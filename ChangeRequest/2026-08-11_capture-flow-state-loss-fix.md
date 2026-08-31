# Fix: app resets to Dashboard after external camera round-trip

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** executed (not yet verified — see §6, manual device check pending)

## 1. Goal

Fix the bug where returning from the OS camera app (launched by the
photo-capture button) leaves the user back at Dashboard Home instead of
wherever they actually were, with any in-progress flow state gone.

## 2. Diagnosis (done before this plan was written — see the conversation for the full trace)

**Problem 1 — why it leaves the app: not a bug.** The capture button
(`ar_scanner_screen.dart`'s `_capture()`/`_captureCvService()`) uses
`ImagePicker().pickImage(source: ImageSource.camera)`. This is
`image_picker`, not the unused `camera` plugin dependency — launching
the OS camera app is expected behavior for this API, not a defect.
Confirmed via the requester: keep `image_picker`, no migration to a live
in-app camera preview as part of this fix.

**Problem 2 — why it resets to home: confirmed root cause.** This app
has zero state-restoration mechanism (`main.dart` is a bare `runApp()`,
no `WidgetsBindingObserver`, no `RestorationMixin`/`restorationScopeId`
anywhere — grepped, zero matches). `GoRouter`'s `initialLocation` is
hardcoded to `Routes.welcome`, and `WelcomeScreen` unconditionally sends
a returning user to `Routes.dashboard`
(`welcome_screen.dart:70-77`). So: `image_picker` backgrounds the
Flutter activity → Android is free to kill the now-invisible process
under memory pressure (camera operations are memory-intensive) → the
user returns → Android recreates the task → Flutter cold-starts `main()`
from scratch with no memory of the prior route → lands on Welcome →
auto-redirects to Dashboard. This reproduces for any screen, not
specifically the AR scanner (e.g. a user mid-`ConfigScreen` wizard would
be bounced back to step 1 for the identical reason). Not a navigation
bug in the capture handlers — neither calls `Navigator`/`context.go`
incorrectly; there is simply no state saved to lose.

**Confirmed with the requester: lightweight fix, not full Flutter state
restoration.** Persist + restore the last route only. This returns the
user to the correct *screen*; it does not restore fine-grained
in-progress state within that screen (e.g. an exact Config wizard step
resets to step 1 of Config, not preserved mid-step). Full
`RestorationMixin` adoption across every stateful screen was explicitly
declined as out of scope for this bug fix — flagged here as a known,
accepted limitation, not an oversight.

## 3. Scope

- In scope:
  - `lib/core/persistence/local_storage_service.dart`: new
    `saf.lastRoute` shared_preferences key, `readLastRoute()` /
    `writeLastRoute(String path)` / `clearLastRoute()`, matching the
    existing key's exact pattern (try/catch, `developer.log` per
    policy 1.3, included in `clear()`).
  - `lib/core/routing/routes.dart`: `Routes.restorable` — the explicit
    allowlist of routes safe to cold-restore into: `dashboard`,
    `config`, `ghostModel`, `wearing`, `ar`, `/checklist`,
    `dressAccessories`. **Deliberately excludes**: `welcome` (it's the
    default anyway), `generating`/`rebuilding` (transient,
    animation-driven screens that auto-navigate onward — restoring
    directly into one mid-transition doesn't make sense as a "resume
    point"), `galleryViewer` (requires a typed `state.extra` record
    that cannot be reconstructed from a persisted URL string alone —
    restoring into it would crash on the type cast).
  - `lib/core/routing/app_router.dart`: `appRouterProvider` attaches a
    listener (`GoRouter` is itself a `Listenable`, notifying on every
    navigation) that persists the current matched location to
    `LocalStorageService` whenever it's in the restorable allowlist —
    silently does nothing (leaves the previously-persisted value alone)
    when the current route isn't restorable, so e.g. being on
    `/generating` when killed still resumes wherever `/generating` was
    launched *from*, not a broken mid-animation restore.
  - `lib/features/onboarding/presentation/screens/welcome_screen.dart`:
    on `BootstrapOutcome.returningUser`, read the persisted last route
    (re-validated against the allowlist at restore time, defensive
    against a stale/corrupted stored value from an older app version)
    and `context.go()` there instead of unconditionally
    `Routes.dashboard`; falls back to `Routes.dashboard` when nothing
    valid is persisted (first-ever cold start, or the persisted route
    is no longer in the allowlist).
  - New tests: `test/core/persistence/local_storage_service_test.dart`
    (read/write/clear round-trip for the new key, mirroring how the
    existing keys would be tested); a focused test on the
    restorable-route validation logic.
  - `flutter analyze` + `flutter test`.
- Out of scope (confirmed with requester):
  - Migrating `image_picker` → `camera` plugin.
  - Full `RestorationMixin` adoption / restoring in-progress widget
    state within a screen (e.g. Config wizard step, AR scanner capture
    phase) — only the route itself is restored.
  - A device-level "Don't Keep Activities" repro run — no device/emulator
    attached in this environment; see §5 for the manual verification
    steps the requester should run.

## 4. Risks & rollback

- **This does not fully satisfy "state intact"** in the most literal
  sense — landing back on `/ar` after a restore starts that screen at
  its own default initial state (aligning phase), not mid-capture. This
  is the explicitly accepted trade-off of the lightweight approach (§2).
- **Persisting on every navigation is a small amount of extra
  `shared_preferences` I/O** — negligible in practice (single string
  write, same mechanism `lastBranchId`/`themeAccent` already use), and
  only for routes in the allowlist (most navigations elsewhere are
  no-ops for this listener).
- **A stale persisted route from a version where the allowlist was
  different** is defended against by re-validating against the current
  allowlist at restore time (§3), not just at persist time.
- Low blast radius: additive to `LocalStorageService` and `Routes`;
  the only behavior change to existing code is `WelcomeScreen`'s
  redirect target and the router listener. Rollback: revert the 4
  touched files, remove the new test file.

## 5. Manual verification (requires a device/emulator — cannot be run in this environment)

Two checks the requester should run before considering this fixed:

1. **Isolate the process-lifecycle mechanism from `image_picker`
   entirely:** enable Developer Options → "Don't keep activities,"
   navigate to at least two different non-Dashboard screens in turn
   (e.g. `/ar` and mid-`/config` wizard), background the app (home
   button, no camera involved), switch back. Confirm the app now
   returns to `/ar` / `/config` respectively instead of bouncing through
   Welcome → Dashboard.
2. **The actual reported bug:** with "Don't keep activities" still on
   (or on a low-RAM device where this reproduces naturally), trigger
   photo capture from at least two different screens/steps, take a
   photo in the OS camera app, return. Confirm the app lands back on the
   same screen (not full in-progress state — see §2's accepted
   limitation) rather than Dashboard Home.

## 6. Verification

- `flutter analyze` — **clean, 0 issues.**
- `flutter test` — **all 93 tests passed**, including the 11 new ones
  across `test/core/persistence/local_storage_service_test.dart` (5
  tests: round-trip, overwrite, clear, query-param preservation) and
  `test/core/routing/routes_test.dart` (6 tests: `Routes.resolveRestoreTarget`
  covering null/valid/query-params/every-excluded-route/garbage-input/
  every-allowlisted-route-round-trips).
- Manual device verification (§5) — **not run by this plan; still
  pending.** No device/emulator was available in this environment. Per
  the requester's own acceptance criteria ("do not consider this fixed
  until you've tested..."), this plan's status stays `executed`, not
  `verified`, until the requester runs the two checks in §5 on a real
  device/emulator: (1) the "Don't keep activities" repro isolating the
  process-lifecycle mechanism from `image_picker` entirely, and (2) the
  actual reported bug — capture from at least two different
  screens/steps, confirm the app returns to the same screen after
  taking a photo.

## 7. CLAUDE.md updates required

- §5.4 (local persistence table): add `saf.lastRoute`.
- §5.6 (routing): note the restorable-route allowlist and
  `WelcomeScreen`'s restore-to-last-route behavior, replacing the
  current "always /dashboard for returning users" description.
