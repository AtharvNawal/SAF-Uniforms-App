# SAF Crest — Logo Integration & New "SAF Crest" Theme

- **Date:** 2026-05-04
- **Author:** Claude (Opus 4.7) for Meet
- **Status:** verified

## Verification log (2026-05-04)

- `flutter analyze` — clean (no issues found).
- `flutter test` — 50/50 passing, including the four new
  `theme_accent_provider_test.dart` cases (default state, hydrate from
  persisted key, malformed value fallback, persistence round-trip across
  containers) and the four new `active_branch_theme_provider_test.dart`
  cases (`FollowBranch` returns `branchThemeFor(currentBranch)`, reacts to
  branch changes, `SafCrest` overrides regardless of branch, switching
  back to `FollowBranch` restores the branch theme).
- `flutter gen-l10n` — regenerated `app_localizations*.dart` exposes
  `themeAccentSafCrest` (EN: "SAF Crest", ZH: "SAF 徽章").
- `dart run flutter_launcher_icons` — overwrote
  `android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png`
  and the 15 iOS `Icon-App-*.png` files in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- `flutter run` smoke (Android + iOS) — **deferred**, requires a paired
  device + a working `flutterfire configure` (placeholder
  `firebase_options.dart` still throws). Operator should perform the
  manual smoke steps listed in §6.

## 1. Goal

Replace the current placeholder shield/Material-icon branding with the
official SAF crest in the four places it appears, and add a new
optional "SAF Crest" visual theme to the settings sheet without
disturbing the four existing branch themes.

Goals:
1. Use the SAF crest as the Android + iOS launcher icon.
2. Use it on the Welcome screen (replacing the custom-painted shield).
3. Use it in the Dashboard app bar (replacing the gradient `Icons.shield`).
4. Add a 5th theme tile ("SAF Crest" — navy/gold palette) to the
   accent picker. The four existing branch themes remain unchanged and
   the existing tile behavior (selecting a branch sets the user's
   service) is preserved.

## 2. Scope

In scope:
- New asset directory `assets/branding/`.
- Adding `flutter_svg` runtime dep + `flutter_launcher_icons` dev dep.
- Decoupling visual theme from `BranchId` via a new `themeAccentProvider`.
- Refactoring `AppTheme.light/.dark` to accept `BranchTheme` instead of
  `BranchId`.
- New reusable widget `SafCrestLogo` for in-app rendering.
- Settings sheet picker grows from 4 to 5 tiles.

Out of scope:
- BranchId enum is unchanged. Firestore wire formats unchanged.
  `accessory_library` IDs prefixed `army_`/`navy_`/etc. are untouched.
- AR ghost model branch derivation — still keyed off
  `currentBranchProvider` (the user's profile branch), not the visual
  theme.

## 3. Approach

| Concern | Decision |
| --- | --- |
| In-app rendering | `flutter_svg ^2.0.10+1`, one SVG used at 26 px (app bar) and 132 px (Welcome). |
| Launcher icons | `flutter_launcher_icons ^0.14.3` generates Android mipmaps + iOS AppIcon set from `assets/branding/saf_crest_1024.png`. |
| Theme decoupling | `themeAccentProvider` (`FollowBranch` / `SafCrest`) persisted via `LocalStorageService.readThemeAccent` / `writeThemeAccent`. New `activeBranchThemesProvider` returns a `(light, dark)` `BranchTheme` record consumed by `app.dart`. |
| Hydrate-vs-set race | `ThemeAccentNotifier` tracks `_userOverride` so a user tap immediately wins over a still-pending disk read on first launch. |
| `BranchId` enum | **Unchanged.** SAF Crest theme's `BranchTheme.branch` is `BranchId.army` as a no-op placeholder — the field is only consulted by the theme system itself. |

## 4. Affected areas

### New files
- `assets/branding/saf_crest.svg` (in-app render)
- `assets/branding/saf_crest_1024.png` (launcher icon master, not declared as Flutter asset)
- `lib/core/theme/theme_accent.dart` (sealed class)
- `lib/core/theme/theme_accent_provider.dart` (NotifierProvider with persistence)
- `lib/core/theme/active_branch_theme_provider.dart` (record-returning Provider)
- `lib/core/theme/saf_crest_theme.dart` (light + dark variants)
- `lib/core/design/widgets/saf_crest_logo.dart` (`SafCrestLogo({size, withGlow, accentColor})`)
- `test/core/theme/theme_accent_provider_test.dart`
- `test/core/theme/active_branch_theme_provider_test.dart`

### Modified files
- `pubspec.yaml` — version bump `1.0.0+1` → `1.0.0+2`; `flutter_svg` runtime dep; `flutter_launcher_icons` dev dep + config block; new asset entry.
- `lib/app.dart` — watches `activeBranchThemesProvider` instead of `currentBranchProvider` for theme.
- `lib/core/theme/app_theme.dart` — `light(BranchTheme)` / `dark(BranchTheme)` (was `BranchId`).
- `lib/core/persistence/local_storage_service.dart` — `_kThemeAccent` key + `readThemeAccent` / `writeThemeAccent`; `clear()` updated.
- `lib/features/onboarding/presentation/screens/welcome_screen.dart` — `_Crest` and `_CrestPainter` deleted; replaced with `SafCrestLogo(size: 132, withGlow: true)`.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — gradient `Icons.shield` replaced with `SafCrestLogo(size: 26)`; obsolete `palette` local removed.
- `lib/features/dashboard/presentation/widgets/settings_sheet.dart` — accent picker grows to 5 tiles; branch tiles also reset accent to `FollowBranch`; new `_SafCrestAccentTile` shows the crest + label.
- `lib/core/l10n/arb/app_en.arb` — `"themeAccentSafCrest": "SAF Crest"`.
- `lib/core/l10n/arb/app_zh.arb` — `"themeAccentSafCrest": "SAF 徽章"`.
- Generated launcher icons in `android/app/src/main/res/mipmap-*/ic_launcher.png` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png`.

## 5. Risks & rollback

- **Risk:** `BranchTheme.branch` field unused everywhere except `lerp`.
  Verified by repo grep before relying on the placeholder. If a future
  consumer reads `branchTheme.branch` for service-derived data, it would
  silently get `BranchId.army` for SAF Crest users. Mitigation: long-term,
  migrate `branchTheme.branch` away or make it nullable.
- **Risk:** Hydrate race could revert a user's choice on first launch.
  Mitigated by `_userOverride` flag in `ThemeAccentNotifier`.
- **Risk:** SVG render performance at 26 px on low-end Android. Acceptable
  — `flutter_svg` caches the parsed picture.
- **Rollback:** Revert this commit. The launcher icon directories will
  need a manual restore from git history; the `pubspec.yaml` deps roll
  back cleanly via `flutter pub get`.

## 6. Verification

1. `flutter analyze` — must be clean. ✅
2. `flutter test` — 50/50 pass. ✅
3. **Operator smoke (Android)**: `flutter run`. Confirm:
   - Launcher icon on home screen is the SAF crest, not the placeholder.
   - Welcome screen renders the crest sharp at 132 px with branch-tinted glow.
   - Dashboard app bar shows the crest at 26 px.
   - Settings sheet shows 5 accent tiles. Tap "SAF Crest" → app re-themes
     to navy/gold immediately. Profile tab still shows the user's chosen
     service branch (not changed).
   - Tap any branch tile after SAF Crest → app reverts to that branch's
     theme; profile branch updates accordingly.
   - Toggle dark mode while on SAF Crest → confirm tuned dark variant
     (lighter navy `#4F4FCC`, gold still visible).
4. **Operator smoke (iOS)**: same checks, plus verify the launcher icon
   has no transparent corners on a light home screen (alpha removed
   correctly via `remove_alpha_ios`).

## 7. CLAUDE.md sections refreshed

- §3 Tech stack — added `flutter_svg`.
- §5.7 Theming — documented `themeAccentProvider` + the visual-theme
  decoupling from `BranchId`.
- §8 Known gaps — noted that `BranchTheme.branch` field semantics now
  allow non-branch themes (placeholder value).
