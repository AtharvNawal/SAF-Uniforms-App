# Fix: Config wizard silently proceeds even when the profile write fails

- **Date:** 2026-08-11
- **Author:** Claude
- **Status:** verified

## 1. Goal

Fix the root cause behind the "Finish your profile first" error surfacing
during a compliance check: the Config wizard's completion step can mark
onboarding done and navigate to Dashboard **even when the Firestore
profile write actually failed**, leaving `users/{uid}/profile/current`
missing. Any later `checkUniformCompliance` call then throws
`not-found`/`failed-precondition`, which the previous plan
(`ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md`)
correctly surfaces as "Finish your profile first" — that message is
accurate; the bug is upstream, in Config, not in the AR Scanner.

## 2. Root cause (confirmed by reading the code, not guessed)

`UniformProfileNotifier._writeNow()` (`uniform_provider.dart`) wraps its
Firestore `upsert` in a try/catch that **only logs** on failure — it
never rethrows, and `persist()` (called by `ConfigScreen._completeConfiguration()`)
just calls `_writeNow()` and returns `Future<void>`, so a failed write is
completely invisible to the caller. `_completeConfiguration()`'s own
`context.go(Routes.dashboard)` sits **outside** its try/catch/finally,
so it runs unconditionally — even when step 2 (`persist()`) silently
failed, or when any other step threw and was caught by the outer
`catch` (which also just logs). Net effect: the user sees the app
proceed normally to Dashboard, `profileComplete` gets marked `true`
locally and (best-effort) server-side, but the actual profile document
was never written. Nothing surfaces this until something else tries to
read that profile — which could be much later, disconnected in time
from the actual failure, exactly matching the confusing symptom
reported.

## 3. Scope

- In scope:
  - `UniformProfileNotifier._writeNow()`: returns `Future<bool>`
    (`true` = write succeeded) instead of `Future<void>`, keeping the
    existing log-and-swallow behavior (the debounced auto-sync path
    still fire-and-forgets it, unchanged UX there — only the *return
    value* changes, which the debounced caller already discards).
  - `persist()`: returns `Future<bool>`, propagating `_writeNow()`'s
    result. Sole call site is `ConfigScreen`.
  - `ConfigScreen._completeConfiguration()`:
    - Checks `persist()`'s result; on failure, retries once (a single
      automatic retry absorbs a transient blip without bothering the
      user); if the retry also fails, **stops here** — does not mark
      `profileComplete`, does not call `markProfileComplete`, does not
      navigate to Dashboard — shows an error with a retry affordance
      and leaves the user on the Config screen so "Done" can be pressed
      again.
    - The outer `catch` (any other unexpected error during steps 3-5)
      also stops and shows an error instead of silently navigating
      away — same principle: never treat an unexpected exception as
      success.
  - New ARB strings (en + zh) for the failure message.
- Out of scope:
  - Retroactively fixing any profile that's already missing due to
    this bug having already fired — that's a one-off data question for
    whichever account hit it (see §6), not something a code change can
    repair after the fact.
  - Changing `markProfileComplete`'s existing best-effort (non-fatal)
    error handling — that one's already correctly scoped: the device
    registration flag being slightly stale is a much smaller problem
    than the profile document not existing at all.

## 4. Risks & rollback

- **Low risk, single call site.** `persist()`'s return type change
  only affects `ConfigScreen` — confirmed by grep, no other caller
  exists.
- **A user who repeatedly fails to save (e.g. genuinely offline)** now
  correctly gets stuck on Config with a visible error instead of being
  silently waved through to a broken state — this is the intended
  behavior change, not a regression: better to block onboarding
  completion than to complete it on a lie.
- Rollback: revert `uniform_provider.dart` and `config_screen.dart`,
  remove the new ARB entries.

## 5. Verification

- `flutter analyze` — **clean, 0 issues.**
- `flutter test` — **all 104 tests passed** (103 pre-existing + 1 new:
  `persist() returns false when there is no auth session`, exercising
  the exact "write never attempted" path via `authSessionProvider`'s
  default `null` state — no repository mocking needed since that
  branch returns before ever touching the repository).
- `flutter gen-l10n` — regenerated; `configSaveFailed` confirmed
  present in `app_localizations_en.dart`.

## 6. For the requester — checking whether your own account already hit this

Since this bug could have silently skipped the write on your device the
first time you completed Configuration, this fix prevents it from
happening again but doesn't retroactively repair a profile that's
already missing. Easiest check: open the app, go to Settings/Profile —
if your branch/rank/name show up correctly, your profile write
succeeded and this was a one-off; if the Config wizard reappears when
you shouldn't need it (or fields are blank), you may need to run
through Configuration once more with this fix in place.

## 7. CLAUDE.md updates required

- §5.2 (`UniformProfileNotifier`): note `persist()` now returns
  `Future<bool>` and Config's completion step reacts to failure instead
  of proceeding unconditionally.
