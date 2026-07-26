# Make SAF Crest the default theme accent

- **Date:** 2026-05-09
- **Author:** Claude (Opus 4.7)
- **Status:** verified

  Verification (2026-05-09):
  - `flutter analyze` → "No issues found! (ran in 11.2s)".
  - `flutter test test/core/theme/` → 9/9 pass.
  - `flutter test` → 73/73 pass.
  - Live `flutter run` smoke test deferred to operator (per policy 1.5
    item 4 — at least one of Android/iOS); the analyzer + full unit
    suite cover the only behavioural change (initial state +
    `fromWireName` fallback).

## 1. Goal
Flip the default visual accent from `FollowBranch()` to `SafCrest()` so a
fresh install (and any user who has never opened the Settings sheet) renders
the navy/gold SAF Crest palette across Welcome, Dashboard, and the rest of
the app. The branch-derived theme is still available — users opt in by
tapping a service tile in the Settings sheet.

## 2. Scope
- In scope:
  - Initial state of `themeAccentProvider` before hydration.
  - Fallback returned by `ThemeAccent.fromWireName(null)` for users who
    have never persisted a choice (preserves explicit `'follow'` writes).
  - Tests covering both code paths.
  - CLAUDE.md §5.7 default annotation.
- Out of scope:
  - The Settings sheet UI (already lets the user pick either).
  - The SAF Crest theme palette / assets.
  - Any data-layer behaviour (Firestore, branch_configs, etc. still keyed
    on the user's actual branch — only the visual accent changes).

## 3. Affected areas
- [lib/core/theme/theme_accent.dart](../lib/core/theme/theme_accent.dart) —
  flip the `fromWireName` switch so unknown / null falls to `SafCrest`,
  add an explicit `'follow'` case so existing users who tapped a branch
  tile still get `FollowBranch`. Update the docstring.
- [lib/core/theme/theme_accent_provider.dart](../lib/core/theme/theme_accent_provider.dart) —
  initial `build()` state returns `const SafCrest()`. Update the docstring
  about first-frame default.
- [test/core/theme/theme_accent_provider_test.dart](../test/core/theme/theme_accent_provider_test.dart) —
  flip the "default state" + "malformed value" assertions; add a case
  proving `'follow'` still hydrates to `FollowBranch`.
- [test/core/theme/active_branch_theme_provider_test.dart](../test/core/theme/active_branch_theme_provider_test.dart) —
  the two FollowBranch-by-default tests must explicitly opt back into
  `FollowBranch` before reading the theme.
- [CLAUDE.md](../CLAUDE.md) §5.7 — flip the `(default)` annotation.

## 4. Step-by-step plan
1. Update `ThemeAccent.fromWireName`:
   ```dart
   return switch (value) {
     'follow'    => const FollowBranch(),
     'saf_crest' => const SafCrest(),
     _           => const SafCrest(), // null + unknown default to crest
   };
   ```
2. Update `ThemeAccent` docstring so `SafCrest` is annotated as default.
3. Update `ThemeAccentNotifier.build()` to return `const SafCrest()`.
4. Update the docstring above `ThemeAccentNotifier` accordingly.
5. Update tests:
   - `theme_accent_provider_test.dart`: rename "default state is
     FollowBranch" → "default state is SafCrest"; rename "malformed
     persisted value falls back to FollowBranch" → "...falls back to
     SafCrest"; add a new test "hydrate restores FollowBranch from
     persisted 'follow' key".
   - `active_branch_theme_provider_test.dart`: in the two tests that
     assert `branchThemeFor(currentBranch)` is returned, first call
     `set(const FollowBranch())` to opt out of the new default.
6. Update `CLAUDE.md` §5.7 prose.
7. Run policy 1.5 verification.

## 5. Risks & rollback
- **User-visible flip on existing installs:** any user who has not
  opened the Settings sheet had `null` persisted; on next launch they
  will see the SAF Crest palette instead of their service-derived one.
  This is the *intent* of the change. Users who opted into a branch
  tile previously persisted `'follow'` and are explicitly preserved by
  the new switch arm.
- **Dark mode:** `safCrestBranchThemeDark` is already defined and
  exercised by existing tests; no extra work.
- **Rollback:** revert this CR's commits — single-file change in two
  files plus tests + CLAUDE.md.

## 6. Verification
1. `flutter analyze` — must be clean.
2. `flutter test test/core/theme/` — both updated suites pass.
3. `flutter test` — full suite passes.
4. `flutter run` — Welcome + Dashboard render in navy/gold; Settings
   sheet's branch tiles still flip back to `FollowBranch`; the choice
   round-trips after a hot restart.

## 7. CLAUDE.md updates required
- §5.7 Theming: swap the `(default)` marker from `FollowBranch()` to
  `SafCrest()`; tweak the surrounding sentence so the default-vs-opt-in
  framing matches.
