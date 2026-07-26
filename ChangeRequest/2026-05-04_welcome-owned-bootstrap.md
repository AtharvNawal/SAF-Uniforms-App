# Move bootstrap work into the Welcome screen

- **Date:** 2026-05-04
- **Author:** Claude (Opus 4.7)
- **Status:** executed

## 1. Goal

Eliminate the white-screen flash on cold start, and make the Welcome
screen visible briefly on every launch (not skipped for returning users).
Achieve both by moving every async startup step out of `main.dart` /
`bootstrap.dart` and into a single Riverpod-owned pipeline that the
Welcome screen drives.

## 2. Scope

In scope:

- New `appBootstrapProvider` (FutureProvider via `@Riverpod` codegen)
  that owns Firebase init, device-id resolution, cached-session
  hydration, and the `claimDeviceIdentity` + `signInWithCustomToken`
  round-trip.
- Strip `main.dart` to `WidgetsFlutterBinding.ensureInitialized()` +
  `runApp(...)`.
- Delete `lib/bootstrap.dart`.
- Rewrite Welcome screen as `ConsumerStatefulWidget`: 1.5 s minimum
  display, thin progress strip in CTA slot during loading, auto-route
  to `/dashboard` for returning users, reveal "Get Started" CTA for
  new users (or after an 8 s timeout if auth is unreachable).
- Drop the "Welcome → Dashboard" auto-redirect from
  `appRouterProvider` (Welcome owns that decision now).

Out of scope:

- Cloud Functions, Firestore rules, seeders.
- Any Firestore data shape or `UniformProfile` changes.
- Tests for `appBootstrapProvider` (deferred — mocking
  `claim` + Firebase init is non-trivial and the existing
  smoke-test verification on device covers the cold-start paths).

## 3. Affected areas

| File | Change |
|---|---|
| `lib/main.dart` | Stripped to ensureInitialized + runApp. |
| `lib/bootstrap.dart` | **Deleted.** |
| `lib/features/onboarding/presentation/providers/app_bootstrap_provider.dart` | **New.** Owns the whole startup pipeline. |
| `lib/features/onboarding/presentation/providers/app_bootstrap_provider.g.dart` | **New** (codegen). |
| `lib/features/onboarding/presentation/screens/welcome_screen.dart` | Rewritten as `ConsumerStatefulWidget`; watches `appBootstrapProvider` and a 1.5 s timer; CTA slot shows progress strip during loading. |
| `lib/core/routing/app_router.dart` | Redirect no longer auto-bounces returning users from `/` to `/dashboard`. |
| `lib/features/auth/presentation/providers/auth_providers.dart` | Doc comment on `authSessionProvider` updated to point at the new provider. |
| `CLAUDE.md` | §§ 4, 5.3, 5.6 refreshed (see § 7). |

## 4. Step-by-step plan

1. Create this ChangeRequest file (done).
2. Create `app_bootstrap_provider.dart` with a function-form
   `@Riverpod(keepAlive: true) Future<BootstrapOutcome> appBootstrap(Ref ref)`
   that runs the pipeline described in § 2.
3. Rewrite `welcome_screen.dart` per the plan in
   `/Users/meet/.claude/plans/in-the-main-thread-hashed-cat.md`.
4. Update `app_router.dart`: drop the `/` → `/dashboard` redirect.
5. Strip `main.dart`.
6. Delete `bootstrap.dart`.
7. Update the doc comment on `authSessionProvider` in
   `auth_providers.dart`.
8. `dart run build_runner build --delete-conflicting-outputs`.
9. `flutter analyze`.
10. `flutter test`.
11. Refresh CLAUDE.md §§ 4, 5.3, 5.6.
12. Update this file's `Status:` to `executed`, then `verified`
    after on-device smoke testing.

## 5. Risks & rollback

| Risk | Mitigation |
|---|---|
| Welcome navigates twice | `_didNavigate` flag guards `context.go`. |
| Returning user briefly sees the "Get Started" CTA before auto-route | The CTA slot shows the progress strip whenever bootstrap is loading **or** the outcome is `returningUser`. Only `newUser` ever renders the button. |
| Firebase consumer reads `firebaseFirestoreProvider` before init | `hydratedProfileProvider` is the only early Firebase consumer and short-circuits when `authSessionProvider` is null. Verified by reading `uniform_provider.dart:282-289`. |
| `ConfigScreen` waits on `authSessionProvider` for up to 30 s — its log message references "kickoffAuthFlow" | Functionally unchanged: `appBootstrapProvider` still pushes the live session via the same `authSessionProvider.notifier.set(...)` call. The diagnostic string in `config_screen.dart` lines 75/90/114-115/139 is now stale text but not a bug; refresh in a follow-up rather than expand this change set. |
| Auth times out (no internet) for a real returning user with no cached session | They briefly see new-user CTA → tap → Config. Same outcome as today's failure path. |

Rollback: revert the commit. `bootstrap.dart` and the old `main.dart`
return verbatim; the new provider file and Welcome rewrite disappear.
No data migration involved.

## 6. Verification

1. `dart run build_runner build --delete-conflicting-outputs` — clean.
2. `flutter analyze` — clean.
3. `flutter test` — all green (existing tests untouched).
4. `flutter run` — manually verify on iOS simulator + an Android device:
   - Cold start, returning user with `profileComplete=true`: Welcome
     visible ~1.5 s with progress strip → auto-routes to Dashboard.
   - Cold start, returning user with `profileComplete=false`: Welcome
     visible briefly → router guard sends them to `/config`.
   - Cold start, brand-new install: Welcome visible until auth lands
     → CTA appears → tap goes to `/config`.
   - Cold start, brand-new install + airplane mode: Welcome visible
     ~8 s with strip → CTA appears → tap goes to `/config`.

## 7. CLAUDE.md updates required

- **§ 4 (Source tree)** — add
  `features/onboarding/presentation/providers/app_bootstrap_provider.dart`;
  remove `bootstrap.dart` from the `lib/` tree listing.
- **§ 5.3 (Bootstrap sequence)** — rewrite to describe the
  Welcome-owned, Riverpod-driven flow.
- **§ 5.6 (Routing)** — remove the bullet that says Welcome redirects
  returning users with `profileComplete=true` straight to `/dashboard`.
