# Persist Full Name, Vocation, Medals & Ribbons, Badges & Qualifications

- **Date:** 2026-05-02
- **Author:** Claude (Opus 4.7) for Meet
- **Status:** verified

## Verification log (2026-05-02)

- `flutter analyze` — clean (no issues found).
- `dart run build_runner build --delete-conflicting-outputs` — succeeded;
  regenerated `uniform_profile.freezed.dart` exposes `fullName`,
  `vocation`, and `selectedBadgeIds` accessors.
- `flutter test` — 42/42 passing, including the new
  `uniform_provider_test.dart` cases (setFullName / setVocation /
  setMedalRowCount / toggleBadge mutex / clearBadges), the new
  `test/features/profile/data/uniform_profile_dto_test.dart` (round-trip
  + legacy-doc default hydration), and a new end-to-end
  `test/features/profile/wizard_persist_test.dart` that drives the
  wizard's setters against `FakeFirebaseFirestore` and asserts
  `users/{uid}/profile/current` ends up with `fullName`, `vocation`,
  `medalRowCount`, and `selectedBadgeIds` (covers the user's reported
  scenario "new user opens app, fills wizard step-by-step").
- The diagnostic log inside `_writeNow` now includes
  `fullName.len`, `vocation`, and `badges` alongside the existing
  fields so an operator can confirm the four fields are in `state` at
  write time when running `flutter run` against a real device.
- `flutter run` smoke (Android + iOS) — **deferred**, requires a paired
  device + a working `flutterfire configure` (placeholder
  `firebase_options.dart` still throws). Operator should perform the four
  manual smoke steps listed in §6 before shipping a build.
- CLAUDE.md §5.2 + §8 refreshed.

## 1. Goal

Persist the three profile fields the user can already enter on screen but
that today never reach Firestore: **full name**, **medal-ribbon row count**,
and **badges & qualifications**. After this change, a user's profile fully
round-trips across cold starts and across the
`Configuration → Dashboard → Profile tab` boundary.

## 2. Scope

**In scope**
- Extend `UniformProfile` with `fullName: String` and
  `selectedBadgeIds: Set<String>`. `medalRowCount` already exists.
- Update `UniformProfileDto` to serialize/deserialize `fullName`,
  `medalRowCount`, `selectedBadgeIds`. (Persisting `medalRowCount` also
  fixes a latent bug — the field was on the entity but silently dropped.)
- New notifier setters (`setFullName`, `setMedalRowCount`, `toggleBadge`,
  `clearBadges`) that piggyback on the existing 500 ms debounced sync.
- Move the `marksman ↔ sniper ↔ fitness` badge mutex (currently duplicated
  in two screens) into the notifier as the single source of truth.
- Wire the Config wizard (Steps 3 & 4) and Profile tab (header + Sections
  04 & 05) to drive the notifier instead of widget-local state.
- Tests for the new setters + a DTO round-trip test.

**In scope (added 2026-05-02 follow-up)**
- `vocation` field (Rank & Vocation section). Same pattern as `fullName`:
  notifier setter `setVocation`, default `'Infantry'`, persisted via the
  existing debounced sync.

**Out of scope**
- Richer schemas for medals, ribbons, or qualifications — current UI
  captures only a row count + a `Set<String>` of badge ids; we persist
  exactly that.
- Validation rules (required name, max badge count, etc.).
- Backfill / migration of existing `users/{uid}/profile/current` docs —
  missing fields hydrate to defaults (`''`, `0`, `{}`).

## 3. Affected areas

| File | Change |
|------|--------|
| `lib/features/profile/domain/entities/uniform_profile.dart` | Add `fullName` and `selectedBadgeIds`. |
| `lib/features/profile/data/dtos/uniform_profile_dto.dart` | Add `fullName`, `medalRowCount`, `selectedBadgeIds` to both `toFirestore` and `fromFirestore`. |
| `lib/features/profile/presentation/providers/uniform_provider.dart` | New setters; badge mutex; logging per CLAUDE.md §1.3. |
| `lib/features/profile/presentation/screens/config_screen.dart` | Step 3 name field + Step 4 medal stepper / badge pills routed through the notifier. |
| `lib/features/dashboard/presentation/tabs/profile_tab.dart` | Header name + Sections 04/05 routed through the notifier. Avatar initial sourced from `profile.fullName`. |
| `test/features/profile/uniform_provider_test.dart` | New cases for the new setters + debounced sync. |
| `test/features/profile/data/uniform_profile_dto_test.dart` (new) | Round-trip test ensuring all three new fields survive `toFirestore`/`fromFirestore`. |
| `firestore.rules`, `lib/firebase_options.dart` | No change — owner-scoped rule on `users/{uid}` already covers the new fields. |

## 4. Step-by-step plan

1. Extend `UniformProfile` with `@Default('') String fullName` and
   `@Default(<String>{}) Set<String> selectedBadgeIds`. Run codegen.
2. Update `UniformProfileDto.toFirestore` / `fromFirestore` to include
   `fullName`, `medalRowCount`, `selectedBadgeIds`. Use the existing
   `(json['x'] as List?) ?? const []` cast pattern for safe hydration of
   pre-migration docs.
3. Add `setFullName`, `setMedalRowCount`, `toggleBadge`, `clearBadges`
   to `UniformProfileNotifier`. Each schedules `_scheduleSync()`. The
   `toggleBadge` implementation owns the
   `marksman ↔ sniper ↔ fitness` mutex.
4. In `config_screen.dart`: drop `_medalRows` and `_badges` local state;
   read `profile.medalRowCount` and `profile.selectedBadgeIds` directly.
   Seed `_nameCtrl.text` from `profile.fullName` in `initState` and on
   the `hydratedProfile` listen. Route the three callbacks
   (`_nameCtrl.onChanged`, medal stepper, badge pill) to the new setters.
5. In `profile_tab.dart`: identical refactor for header + Sections 04
   & 05. Avatar initial reads from `profile.fullName`.
6. Add tests: extend
   `test/features/profile/uniform_provider_test.dart` with three groups
   (name, medal rows, badges including the mutex). Add a new
   `uniform_profile_dto_test.dart` that asserts a profile populated with
   all new fields round-trips through the DTO.
7. Verify (CLAUDE.md §1.5).

## 5. Risks & rollback

- **Risk:** Existing `users/{uid}/profile/current` docs lack the new
  fields. **Mitigation:** `fromFirestore` defaults each new field to `''`
  / `0` / empty set, so older docs hydrate cleanly.
- **Risk:** A regression in `toggleBadge`'s mutex logic (the rule lives in
  two places today). **Mitigation:** consolidate into one place + cover
  with a unit test that exercises the mutex.
- **Risk:** A test using `mockProfile.copyWith(...)` may fail to compile
  after the freezed regen if it depends on positional args. **Mitigation:**
  the entity uses named-only constructors, so adding fields with defaults
  is non-breaking.
- **Rollback:** revert the seven listed files; `git revert` is enough.
  Old docs without the new fields keep working because the fields default.

## 6. Verification (CLAUDE.md §1.5)

1. `flutter analyze` — zero issues.
2. `dart run build_runner build --delete-conflicting-outputs` — succeeds;
   the regenerated `uniform_profile.freezed.dart` exposes accessors for
   `fullName` and `selectedBadgeIds`.
3. `flutter test` — all green, including the new cases.
4. `flutter run` smoke (Android **and** iOS):
   1. Uninstall, then cold-start. Run the wizard with name **"Smoke
      Test"**, 4 medal rows, badges `{airborne, ippt}`. Tap "Build Ghost
      Model".
   2. Force-stop, relaunch. The avatar initial should be **S**, the medal
      stepper at **4**, `airborne` + `ippt` pills active.
   3. Edit the name to **"Edited"** in the Profile tab, wait > 500 ms,
      force-stop, relaunch — name persists.
   4. Firebase Console → `users/{uid}/profile/current` shows
      `fullName: "Edited"`, `medalRowCount: 4`,
      `selectedBadgeIds: ["airborne", "ippt"]`.

## 7. CLAUDE.md updates required

- **§5.2** — `UniformProfileNotifier`'s responsibility list should mention
  full name, medal row count, and badge ids alongside branch/rank/etc.
- **§8** — drop the bullet referring to `name`, `medalRowCount`, and
  `badges` not being persisted; leave only `vocation` in the gap list.
