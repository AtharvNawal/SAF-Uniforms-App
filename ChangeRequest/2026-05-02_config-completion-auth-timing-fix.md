# Config Completion — Auth Timing Fix

| Field       | Value                                          |
| ----------- | ---------------------------------------------- |
| Date        | 2026-05-02                                     |
| Author      | Claude                                         |
| Status      | draft → executed → verified                   |
| Refs        | CLAUDE.md §1.1, §1.3, §1.4                    |

---

## Goal

Fix the bug where pressing "Build Ghost Model" at the end of the
Configuration wizard navigates the user back to the Welcome screen
instead of the Dashboard.

## Root Cause

`kickoffAuthFlow()` in `main.dart` is fire-and-forget. On a fresh install
it takes 1–5 s to call `claimDeviceIdentity` (Cloud Function) and then
`signInWithCustomToken`. If the user finishes the 4 config steps before
the network round-trip completes, `authSessionProvider` is still `null`
when `_completeConfiguration()` runs:

- `persist()` → `_writeNow()` silently drops the write (session == null guard).
- The `markProfileComplete`, local-storage, and notifier updates are all
  skipped (`if (session != null)` block).
- `context.go(Routes.dashboard)` fires, but GoRouter's redirect sees
  `session == null` and bounces to `/` (Welcome).

## Scope

Single file: `lib/features/profile/presentation/screens/config_screen.dart`

## Affected Areas

- Config wizard completion UX
- Profile persistence on first run
- `device_registrations/{deviceId}.profileComplete` flag (now reliably set)
- `users/{uid}/profile/current` document (now reliably written before navigate)

## Step-by-Step Plan

1. Add `dart:async` to imports (provides `Completer` + `TimeoutException`).
2. Add `bool _loading = false` state variable.
3. Add `_awaitAuthSession()` helper — uses `ref.listenManual` to subscribe
   to `authSessionProvider` changes; resolves the first non-null value or
   returns null after a 30-second timeout.
4. Rewrite `_completeConfiguration()`:
   a. Set `_loading = true`.
   b. `await _awaitAuthSession()` — waits for `kickoffAuthFlow` to land.
   c. `await persist()` — profile now has a uid, so write succeeds.
   d. Best-effort `markProfileComplete` Cloud Function call.
   e. Write `profileComplete = true` to local storage.
   f. Update `authSessionProvider` notifier so router allows `/dashboard`.
   g. Clear `_loading` in `finally`.
   h. `context.go(Routes.dashboard)`.
5. Guard `_next()` against double-tap: early return if `_loading`.
6. Update button: `onPressed: _loading ? null : _next`,
   `trailingIcon` switches between arrow and `CircularProgressIndicator`.

## Risks & Rollback

- **Risk:** Network outage — user may wait up to 30 s then see the
  timeout fallback (navigates to Dashboard with session null, router
  bounces to Config again). Acceptable; the user can retry.
- **Rollback:** revert config_screen.dart to the previous `_completeConfiguration`.

## Verification

- [ ] `flutter analyze` clean
- [ ] Fresh install: rapid wizard completion → lands on Dashboard
- [ ] Returning user (`profileComplete = true` in storage): skips to Dashboard
- [ ] Network off: 30-second wait, then navigates (graceful degradation)
- [ ] `flutter test` — all existing tests pass

## CLAUDE.md Sections Refreshed

None — no folder layout, provider graph, routing, or schema changes.
