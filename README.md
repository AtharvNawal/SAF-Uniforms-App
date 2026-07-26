# SAF Uniforms

**Singapore Armed Forces uniform reference app** — a Flutter mobile client (Android + iOS) that lets a service member configure their identity (branch / rank / gender / dress code) and get back a per-user 3D ghost-model render, an accessory checklist split into mandatory + optional items, and a step-by-step wearing guide. All content is grounded in official SAF doctrine and stored in Firestore so it can be updated without shipping a new app build.

This document is the single source of truth for understanding the project. For the internal working policies that apply to every commit, see [CLAUDE.md](CLAUDE.md).

---

## At a Glance

| Field             | Value                                                |
| ----------------- | ---------------------------------------------------- |
| Package name      | `saf_uniforms`                                       |
| Version           | `1.0.0+2`                                            |
| Flutter           | `>=3.41.0`                                           |
| Dart SDK          | `^3.11.1`                                            |
| Platforms         | Android, iOS                                         |
| Backend           | Firebase (Auth, Firestore, Storage, Cloud Functions) |
| Firebase region   | `asia-southeast1`                                    |
| Firebase project  | `saf-uniforms`                                       |
| Languages (UI)    | English, Simplified Chinese                          |
| State management  | Riverpod 3                                           |
| Routing           | go_router                                            |

---

## Tech Stack

Grouped by concern. Each package's exact version range lives in [pubspec.yaml](pubspec.yaml).

### State management

| Package                | Version    | Purpose                                                         |
| ---------------------- | ---------- | --------------------------------------------------------------- |
| `flutter_riverpod`     | `^3.3.1`   | Reactive state container (Riverpod 3).                          |
| `riverpod_annotation`  | `^4.0.2`   | `@Riverpod(...)` annotations for codegen-driven providers.      |
| `riverpod_generator`   | `^4.0.3`   | Codegen for the annotated providers (dev dep).                  |

### Backend / Firebase

| Package             | Version     | Purpose                                                |
| ------------------- | ----------- | ------------------------------------------------------ |
| `firebase_core`     | `^4.7.0`    | Firebase SDK initialization.                           |
| `firebase_auth`     | `^6.4.0`    | Custom-token sign-in, session management.              |
| `cloud_firestore`  | `^6.3.0`    | All app + reference data; SDK provides offline cache.  |
| `cloud_functions`   | `^6.0.0`    | Calls the 3 callable Functions in `functions/`.        |
| `firebase_storage`  | `^13.0.4`   | Accessory imagery, 3D models, user gallery uploads.    |

### Device identity

| Package             | Version     | Purpose                                                |
| ------------------- | ----------- | ------------------------------------------------------ |
| `device_info_plus`  | `^13.1.0`   | Reads `identifierForVendor` (iOS) for stable id.       |
| `android_id`        | `^0.5.1`    | Reads `Settings.Secure.ANDROID_ID` for stable id.      |
| `uuid`              | `^4.5.0`    | UUID v4 fallback + UUID v5 hash of Android id.         |

### Modeling / serialization

| Package                 | Version    | Purpose                                                       |
| ----------------------- | ---------- | ------------------------------------------------------------- |
| `freezed_annotation`    | `^3.1.0`   | Immutable data classes + sealed unions (`Result`, `Failure`). |
| `freezed`               | `^3.2.5`   | Codegen for the above (dev dep).                              |
| `json_annotation`       | `^4.11.0`  | DTO `fromJson` / `toJson`.                                    |
| `json_serializable`     | `^6.10.0`  | Codegen for DTOs (dev dep).                                   |
| `crypto`                | `^3.0.0`   | SHA-256 over profile fields → `profileHash` (3D regen gate).  |

### Routing & i18n

| Package                | Version     | Purpose                                                  |
| ---------------------- | ----------- | -------------------------------------------------------- |
| `go_router`            | `^17.2.2`   | Declarative routing, auth-driven `redirect:`.            |
| `intl`                 | `^0.20.2`   | Locale formatting helpers; backs ARB-driven `gen-l10n`.  |
| `flutter_localizations` | (sdk)      | Material localization delegates.                         |

### Local persistence

| Package                  | Version    | Purpose                                                                                   |
| ------------------------ | ---------- | ----------------------------------------------------------------------------------------- |
| `flutter_secure_storage` | `^8.1.0`   | Keychain / encrypted-prefs: `deviceId`, `cachedUid`. Pinned to v8 (v9 conflicts on Win32). |
| `shared_preferences`     | `^2.3.3`   | `profileComplete`, `lastBranchId`, `themeAccent`.                                          |

> No local DB for app content. Reference + user data lives in Firestore; the SDK's offline cache replaces what would otherwise need a hand-rolled Drift mirror.

### UI / media

| Package                   | Version       | Purpose                                                  |
| ------------------------- | ------------- | -------------------------------------------------------- |
| `cached_network_image`    | `^3.4.1`      | Caches accessory PNGs + user gallery thumbnails.         |
| `image_picker`            | `^1.1.2`      | Camera + photo-library picker for the Gallery tab.       |
| `photo_view`              | `^0.14.0`     | Pinch-to-zoom + swipe gallery in the photo viewer.       |
| `share_plus`              | `^13.1.0`     | Native share sheet for gallery photos.                   |
| `google_fonts`            | `^6.2.1`      | DM Sans + JetBrains Mono (per Claude Design handoff).    |
| `flutter_svg`             | `^2.0.10+1`   | SAF crest vector on Welcome / dashboard app bar.         |
| `flutter_launcher_icons`  | `^0.14.3`     | Generates Android mipmap + iOS AppIcon set (dev dep).    |

### Camera / AR / 3D / pose detection

| Package                       | Version       | Purpose                                                              |
| ----------------------------- | ------------- | -------------------------------------------------------------------- |
| `model_viewer_plus`           | `^1.9.3`      | 3D viewport in `GhostScreen` (drag-rotate, pinch-zoom, WebXR AR).    |
| `camera`                      | `^0.11.0+2`   | Live camera feed for the (placeholder) AR scanner.                   |
| `google_mlkit_pose_detection` | `^0.14.0`     | Pose-detection plumbing for posture scoring (UI placeholder today).  |
| `permission_handler`          | `^11.3.1`     | Camera + photo-library permission prompts.                           |

### Linting & tests

| Package               | Version     | Purpose                                                  |
| --------------------- | ----------- | -------------------------------------------------------- |
| `flutter_lints`       | `^6.0.0`    | Backs `analysis_options.yaml`.                            |
| `flutter_test`        | (sdk)       | Widget + unit tests.                                     |
| `fake_cloud_firestore` | `^4.0.0`   | In-memory Firestore mock for repository tests.           |

### Operator tooling (dev deps, not shipped to the app)

| Package                | Version     | Purpose                                                                      |
| ---------------------- | ----------- | ---------------------------------------------------------------------------- |
| `firebase_admin_sdk`   | `^0.5.1`    | Pure-Dart admin SDK used by [tool/seed_firestore.dart](tool/seed_firestore.dart). |
| `google_cloud_firestore` | `^0.5.1`  | Admin Firestore client.                                                      |
| `google_cloud_storage` | `^0.6.0`    | Admin Storage client (Dart upload path; Python uploaders preferred).         |

---

## Architecture

### 1. Layered, feature-first

Every feature in [`lib/features/`](lib/features/) follows a Clean-Architecture-style split:

```
features/<feature>/
├── domain/         # pure Dart entities, enums, abstract repository interfaces
├── data/           # concrete repository implementations, DTOs, services
└── presentation/   # Riverpod providers, notifiers, widgets, screens
```

`domain/` is the dependency root: it has no Flutter or Firebase imports, only pure Dart. This makes it easy to test and keeps the data + presentation layers swappable.

### 2. Bootstrap sequence (Welcome-screen-owned)

[`main.dart`](lib/main.dart) is intentionally tiny — it only calls `WidgetsFlutterBinding.ensureInitialized()` and launches the `ProviderScope`. All async startup work lives behind a single `@Riverpod(keepAlive: true) Future<BootstrapOutcome>` provider in [app_bootstrap_provider.dart](lib/features/onboarding/presentation/providers/app_bootstrap_provider.dart), which is driven by [WelcomeScreen](lib/features/onboarding/presentation/screens/welcome_screen.dart):

```
WelcomeScreen (paints first frame instantly — no white screen)
  └─ watches appBootstrapProvider
       1. Firebase.initializeApp()                           (idempotent)
       2. DeviceIdentityService.resolve()                    (keychain-cached UUIDv4)
       3. Read cachedUid + profileComplete from local prefs  (synchronous seed)
       4. Live auth round-trip (8s timeout):
            a. claimDeviceIdentity({deviceId, platform})     (Cloud Function)
            b. signInWithCustomToken(claim.customToken)      (Firebase Auth)
            c. Upsert users/{uid} hardware id
            d. Refresh local cache
            e. authSessionProvider.notifier.set(liveSession)
       5. Returns BootstrapOutcome.{returningUser | newUser}

WelcomeScreen also runs a 1.5s minimum-display timer + an 8s safety timeout.
  - returningUser  → context.go('/dashboard')
  - newUser/error  → reveal CTA, tap goes to '/config'
```

The UI never blocks on the network: cached sessions keep the app usable offline, and Firestore writes queue in the SDK's local cache.

### 3. State management — Riverpod 3

- All shared state lives behind `@Riverpod(keepAlive: true)` providers.
- [UniformProfileNotifier](lib/features/profile/presentation/providers/uniform_provider.dart) is the **single source of truth** for the user's selections (branch, rank, gender, dress code, sikh flag, full name, vocation, medal-row count, badges, accessory checks). Every setter schedules a **500 ms debounced** write to `users/{uid}/profile/current`. Callers needing a guaranteed flush (e.g. the Config wizard) `await persist()`.
- `coordinateMapProvider` is a **pure derivation** of `(uniformProfile, branchConfig, medalVerticalShiftRule) → CoordinateMap`. Anything 3D-related goes through this — never reads `UniformProfile` directly.
- Generated `*.g.dart` and `*.freezed.dart` files are committed but never hand-edited.

### 4. Routing — go_router

Constants live in [routes.dart](lib/core/routing/routes.dart). The router ([app_router.dart](lib/core/routing/app_router.dart)) has an auth-driven `redirect:`:

- If `session == null` (cold start, never signed in): only `/` and `/config` are reachable.
- If `session.profileComplete == false`: anything other than `/` or `/config` bounces to `/config`.
- The router does **not** auto-redirect returning users from `/` to `/dashboard` — `WelcomeScreen` owns that decision.

| Route                  | Screen                                | Notes                                                                  |
| ---------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| `/`                    | `WelcomeScreen`                       | Initial location; owns bootstrap; auto-routes returning users.         |
| `/config`              | `ConfigScreen`                        | 4-step wizard; awaits `persist()` + `markProfileComplete` Cloud Func.  |
| `/dashboard`           | `DashboardScreen`                     | IndexedStack of 4 tabs (Home / Wardrobe / Gallery / Profile).          |
| `/checklist`           | `ChecklistScreen`                     | Legacy accessory list; current consumer is the Wardrobe tab.           |
| `/dress-accessories`   | (per-dress accessory drill-down)      | Companion route for dress-specific accessory inspection.               |
| `/ghost-model`         | `GhostScreen`                         | 3D viewport + 6-hotspot pin overlay.                                   |
| `/wearing`             | `WearingGuideScreen`                  | 9-step dressing flow.                                                  |
| `/ar`                  | `ARScannerScreen`                     | Phase-1 placeholder UI.                                                |
| `/generating?dress=…`  | `GeneratingScreen`                    | Animated ring loader; auto-routes to `/ghost-model` on complete.       |
| `/rebuilding`          | `RebuildingScreen`                    | 5-row dress progress; auto-routes to `/dashboard`.                     |
| `/gallery/viewer`      | `PhotoViewerScreen`                   | Full-screen pinch-zoom gallery; expects `state.extra` record.          |

### 5. Theming

Each branch (Army / Navy / RSAF / DIS) ships a fixed `BranchTheme` ([branch_themes.dart](lib/core/theme/branch_themes.dart)) registered as a `ThemeExtension`. The active theme is resolved by `activeBranchThemesProvider`, which branches on `themeAccentProvider`:

- `FollowBranch()` (default) — theme follows the user's selected service.
- `SafCrest()` — overrides with the navy/gold SAF crest theme. The user's profile branch is unaffected (Firestore data, AR models, accessory IDs all keep using `currentBranchProvider`).

The Settings sheet exposes 5 accent tiles (4 services + SAF Crest); the choice persists via `LocalStorageService.writeThemeAccent`. Dark/light is toggled via `themeModeProvider` (defaults to dark).

Typography: DM Sans for all UI, JetBrains Mono via `AppTextStyles.mono(...)` for technical labels (eyebrows, status chips, cm dimensions). The SAF crest itself is rendered via [`SafCrestLogo`](lib/core/design/widgets/saf_crest_logo.dart) backed by `assets/branding/saf_crest.svg`.

### 6. Localization

ARBs at [`lib/core/l10n/arb/app_en.arb`](lib/core/l10n/arb/app_en.arb) and `app_zh.arb`. [`l10n.yaml`](l10n.yaml) drives generation into [`lib/core/l10n/generated/`](lib/core/l10n/generated/). App title is i18n-driven via `MaterialApp.router`'s `onGenerateTitle`.

### 7. Error handling

Use [`Result<T>`](lib/core/error/result.dart) (sealed `Ok<T> | Err<T>`) and the sealed [`Failure`](lib/core/error/failure.dart) hierarchy at repository / service boundaries. Widgets and notifiers `switch` on `Result` rather than catching raw exceptions in the UI layer. Every I/O method is wrapped in `try/catch` per the project's [working policies](CLAUDE.md#13-logging-discipline).

### 8. Local persistence

[`LocalStorageService`](lib/core/persistence/local_storage_service.dart) holds only what's needed to render the first frame synchronously:

| Key                   | Backed by               | Purpose                                                                 |
| --------------------- | ----------------------- | ----------------------------------------------------------------------- |
| `saf.deviceId`        | `flutter_secure_storage` | Hardware-derived UUID (iOS `identifierForVendor`; Android UUIDv5 of `ANDROID_ID`). |
| `saf.cachedUid`       | `flutter_secure_storage` | Last Firebase uid; lets the router relax guards before the live round-trip lands. |
| `saf.profileComplete` | `shared_preferences`    | Mirrors `device_registrations/{deviceId}.profileComplete`.              |
| `saf.lastBranchId`    | `shared_preferences`    | Theme-bootstrap hint.                                                   |
| `saf.themeAccent`     | `shared_preferences`    | `"follow"` (default) or `"saf_crest"`.                                  |

Everything else (the `UniformProfile`, gallery photos, reference content) lives in Firestore.

---

## Design Patterns

| Pattern                          | Where it lives                                                                                  |
| -------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Clean Architecture**           | `domain/` / `data/` / `presentation/` split per feature.                                        |
| **Repository pattern**           | Abstract repo interfaces in `domain/repositories/`; concrete impls in `data/`.                  |
| **Result / Failure**             | Sealed types in [`lib/core/error/`](lib/core/error/). No raw exceptions reach the UI.           |
| **Provider-as-derivation**       | E.g. `coordinateMapProvider` is a pure function of `(profile, config, rule)` → output.          |
| **Optimistic UI**                | 3D model regen: client sets `generationStartedAt`; the Cloud Function is the authoritative writer of `modelUrl`. |
| **Code generation**              | Freezed (immutable models) + `riverpod_generator` (providers) + `json_serializable` (DTOs).     |
| **Offline-first via SDK cache**  | Firestore SDK's built-in cache; no hand-rolled local mirror.                                    |
| **Debounced auto-sync**          | `UniformProfileNotifier` writes to Firestore 500 ms after the last user edit.                   |
| **Hardware-bound identity**      | UUID v5 of `ANDROID_ID` (Android) + `identifierForVendor` (iOS) means uninstall+reinstall recovers the same uid via `claimDeviceIdentity`. |

---

## Integrations

### Firebase

Project id `saf-uniforms`, region `asia-southeast1`. The four backend products:

#### Auth — custom-token sign-in

The previous client-side `signInAnonymously()` flow was retired because anonymous-auth UIDs are wiped on every uninstall on both iOS and Android. The current flow uses an Admin-SDK lookup of `device_registrations/{deviceId}` to mint a custom token, so the same uid is recovered after uninstall + reinstall.

#### Firestore collections

| Collection                                | Purpose                                                                          |
| ----------------------------------------- | -------------------------------------------------------------------------------- |
| `users/{uid}`                             | `{hardwareId, platform, lastSeenAt, createdAt, previousHardwareIds[]}`.          |
| `users/{uid}/profile/current`             | The user's `UniformProfile` + `generatedDresses` map.                            |
| `users/{uid}/gallery/{photoId}`           | Per-photo metadata (`url`, `thumbnailUrl`, `uploadedAt`, `dressCode`).            |
| `device_registrations/{deviceId}`         | **Admin-only.** Written by `claimDeviceIdentity` / `markProfileComplete`.        |
| `branch_configs/{branchId}`               | Authoritative branch config (Army/Navy/RSAF/DIS).                                 |
| `global_logic_rules/{ruleId}`             | Cross-branch rules (currently `medal_vertical_shift`).                            |
| `dress_requirements/{dressId}`            | Per-dress mandatory + optional rule definitions; supports `branch_overrides`.    |
| `accessory_library/{accessoryId}`         | Per-accessory display metadata, rules, render logic.                              |

Security rules ([firestore.rules](firestore.rules)): authenticated reads on the four reference collections (writes blocked from clients — admin portal uses a service account); owner-scoped reads/writes on `users/{uid}`; `device_registrations` blocked entirely from client SDKs.

#### Cloud Storage

Single bucket: `saf-uniforms.firebasestorage.app`. Three top-level prefixes (rules in [storage.rules](storage.rules)):

| Prefix                                                | Purpose                                                                                |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `accessories/{accessoryId}/{image,placement}.png`     | Mirrors `accessory_library` ids. Auth-required reads; writes blocked.                  |
| `models/**`                                           | 3D asset library: `bodies/`, `uniforms/`, `accessories/`, plus `placeholder.glb`.      |
| `user_models/{uid}/{dressCode}.glb`                   | Per-user composed GLBs; written exclusively by `composeUniformModel`.                  |

Every uploaded object carries a `firebaseStorageDownloadTokens` metadata entry so the app can use a stable `https://firebasestorage.googleapis.com/...?alt=media&token=...` URL that bypasses the auth header. Cache headers (`public, max-age=31536000, immutable`) keep CDN edges warm.

#### Cloud Functions ([`functions/`](functions/) — TypeScript, Node 20, region `asia-southeast1`)

- **`claimDeviceIdentity({deviceId, platform})`** — Looks up `device_registrations/{deviceId}`. If found, returns the existing `{uid, profileComplete}`. Otherwise creates a fresh Firebase user via `admin.auth().createUser({})` and writes the mapping. Always returns a `customToken` for client `signInWithCustomToken`. Rejects the Nil UUID server-side via Zod `.refine()`.
- **`markProfileComplete({deviceId})`** — Flips `device_registrations/{deviceId}.profileComplete = true` after the Configuration wizard completes. Verifies caller's uid matches the registration to prevent guessing attacks.
- **`composeUniformModel({dressCode, profileHash})`** — Composes the user's per-dress GLB. Validates auth, recomputes `profileHash` server-side (replay protection), short-circuits if cached entry already matches, resolves the accessory list via [`functions/src/dress_accessory_resolver.ts`](functions/src/dress_accessory_resolver.ts), downloads body / uniform / accessory GLBs from Storage (falling back to `models/placeholder.glb`), validates them through `@gltf-transform/core`, uploads the composed result to `user_models/{uid}/{dressCode}.glb`, and writes `users/{uid}/profile/current.generatedDresses[<dressDocId>]`. Runtime: 1 GiB memory, 120s timeout.

Deploy: `firebase deploy --only functions,firestore:rules,storage:rules`.

### ML Kit & 3D viewport

`google_mlkit_pose_detection` is wired into the dependency graph but the AR Scanner screen is still a placeholder; pose scoring lights up in a future phase. `model_viewer_plus` powers the 3D viewport in [GhostScreen](lib/features/ar_engine/presentation/screens/ghost_screen.dart) — drag-rotate, pinch-zoom, free WebXR AR mode on supported devices.

---

## Features

The app's nine feature modules under [`lib/features/`](lib/features/), in roughly the order a user encounters them.

### Onboarding (Welcome)

[`lib/features/onboarding/`](lib/features/onboarding/)

What the user sees: the SAF crest with the tagline "Precision in every detail.", a thin progress strip while bootstrap runs, and either an automatic transition to the dashboard (returning users) or a "Get Started" CTA (new users).

- Screen: [`welcome_screen.dart`](lib/features/onboarding/presentation/screens/welcome_screen.dart)
- Provider: [`app_bootstrap_provider.dart`](lib/features/onboarding/presentation/providers/app_bootstrap_provider.dart) — owns Firebase init, device id resolution, cached-session seed, and the live `claimDeviceIdentity` + `signInWithCustomToken` round-trip with an 8 s timeout.
- Side effects: writes to `users/{uid}` (upsert), reads/writes the local-prefs cache.

### Auth (device-bound identity)

[`lib/features/auth/`](lib/features/auth/)

Identity is hardware-derived and survives uninstall + reinstall. iOS uses `identifierForVendor`; Android uses UUIDv5 of `Settings.Secure.ANDROID_ID`. The derived value is cached in the keychain for fast reads, but the hardware value is re-derived on every launch and reconciled — the cache is a hint, not authoritative. A hard `StateError` guard prevents the Nil UUID from ever leaking into the system.

- Domain: [`device_identity.dart`](lib/features/auth/domain/device_identity.dart), [`auth_repository.dart`](lib/features/auth/domain/auth_repository.dart)
- Data: [`device_identity_service.dart`](lib/features/auth/data/device_identity_service.dart), [`device_registry_service.dart`](lib/features/auth/data/device_registry_service.dart), [`auth_repository_impl.dart`](lib/features/auth/data/auth_repository_impl.dart)
- Backend touchpoints: `claimDeviceIdentity` Cloud Function, `device_registrations/{deviceId}` (admin-only), `users/{uid}` upsert.

### Profile (Configuration wizard + central state)

[`lib/features/profile/`](lib/features/profile/)

The Configuration wizard collects branch, rank, gender, dress code, full name, vocation, medal-row count, and badge selections across four steps. On the final step it `await`s `UniformProfileNotifier.persist()`, calls `markProfileComplete`, and routes to `/dashboard`.

- Notifier: [`uniform_provider.dart`](lib/features/profile/presentation/providers/uniform_provider.dart) — single source of truth; setters debounce 500 ms before writing to `users/{uid}/profile/current`. Owns the marksmanship-tier mutex (`marksman ↔ sniper ↔ fitness`) and per-dress check mutators (`toggleDressAccessory`, `setDressAccessoryChecked`, `clearDressAccessoryChecks`).
- Repositories: [`profile_repository_impl.dart`](lib/features/profile/data/profile_repository_impl.dart), [`branch_config_repository.dart`](lib/features/profile/data/branch_config_repository.dart), [`global_rules_repository.dart`](lib/features/profile/data/global_rules_repository.dart).
- Domain entities: `BranchId`, `DressCode`, `Gender`, `Rank` (full SAF rank ladder), `BranchConfig`, `Accessory`, `UniformProfile`, `MedalVerticalShiftRule` — all Freezed + json_serializable.

### Dashboard

[`lib/features/dashboard/`](lib/features/dashboard/)

`DashboardScreen` is an `IndexedStack` of four tabs with a bottom nav bar and a top app bar:

- **Home tab** — Setup card, hero No.3 dress, dynamic dress grid (Firestore-driven via `dressRequirementsAllProvider`), quick actions.
- **Wardrobe tab** — Dress filter dropdown, `VERIFIED X / Y` progress card, accessory checklist with `MANDATORY` / `OPTIONAL` chips. Live consumer of the dress + accessory data layer.
- **Gallery tab** — see § Gallery feature below.
- **Profile tab** — `SectionCards` for service / identity / rank / medals / badges. Settings sheet is a modal that exposes the theme-mode toggle + the 5-tile accent picker.

Two satellite screens drive transitions:

- [`generating_screen.dart`](lib/features/dashboard/presentation/screens/generating_screen.dart) — animated ring loader, takes a `dress` query param, auto-routes to `/ghost-model`.
- [`rebuilding_screen.dart`](lib/features/dashboard/presentation/screens/rebuilding_screen.dart) — 5-row dress progress list with a ring chart, auto-routes to `/dashboard`.

### Checklist (accessory verification)

[`lib/features/checklist/`](lib/features/checklist/)

The data layer that powers the Wardrobe tab and the legacy `/checklist` route. [`DressAccessoryResolver`](lib/features/checklist/domain/services/dress_accessory_resolver.dart) walks the No.3 structured override keys (`headdress`, `cap_badge`, `cap_embellishment`, `rank_insignia_sleeve.specialist | enlistee`, `epaulettes`, `lanyard`, `arms_badge`, `vocation_badge`) to pick the accessories that apply to the active `(branch, rank, gender, isSikh)`. `resolveSplit(...)` returns `({mandatory, optional})`.

Providers ([dress_accessories_provider.dart](lib/features/checklist/presentation/providers/dress_accessories_provider.dart)):

- `dressAccessoriesProvider` — bridge between dress requirements + accessory library + user profile.
- `dressAccessoriesByIdProvider(dressId)` — parameterised version for any dress doc id.
- `allDressesAccessoriesCombinedProvider` — deduplicated list across every dress, drives the Wardrobe "All Accessories" filter.
- `accessoryDressIndexProvider` — inverts the resolver so a single tick fans out to every dress that lists the accessory.
- `wardrobeProgressProvider(WardrobeFilter)` — the verified-count derivation behind `VERIFIED X / Y`.

Backend touchpoints: `dress_requirements/{dressId}`, `accessory_library/{accessoryId}`.

### Gallery (user uniform photos)

[`lib/features/gallery/`](lib/features/gallery/)

A full personal gallery: 3-column grid, upload from camera or library with a dress-code tag, shimmer skeleton, dress-code filter bar. Tapping a tile opens a full-screen `PhotoViewGallery` ([`photo_viewer_screen.dart`](lib/features/gallery/presentation/screens/photo_viewer_screen.dart)) with pinch-to-zoom, swipe between photos, share via `share_plus`, and delete.

- Domain: [`gallery_photo.dart`](lib/features/gallery/domain/entities/gallery_photo.dart), [`gallery_repository.dart`](lib/features/gallery/domain/repositories/gallery_repository.dart).
- Data: [`gallery_repository_impl.dart`](lib/features/gallery/data/gallery_repository_impl.dart) — Storage path `user_photos/{uid}/{photoId}.jpg`; Firestore doc at `users/{uid}/gallery/{photoId}`.
- Providers: `galleryRepositoryProvider`, `galleryPhotosProvider` (real-time stream ordered by `uploadedAt desc`), `GalleryUploadNotifier`, `GalleryDeleteNotifier`.

### Wearing Guide

[`lib/features/wearing_guide/`](lib/features/wearing_guide/)

A 9-step dressing flow: silhouette + step text + voice-narration stub (TTS lands later) + completion view. Single screen at [`wearing_guide_screen.dart`](lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart).

### AR Scanner

[`lib/features/ar_scanner/`](lib/features/ar_scanner/)

Phase-1 placeholder UI at [`ar_scanner_screen.dart`](lib/features/ar_scanner/presentation/screens/ar_scanner_screen.dart). Camera, ML Kit pose detection, and permission-handling deps are wired but the live feed + scoring lights up in a follow-up phase.

### AR Engine (3D ghost model)

[`lib/features/ar_engine/`](lib/features/ar_engine/)

The 3D viewport. [`GhostScreen`](lib/features/ar_engine/presentation/screens/ghost_screen.dart) wraps `model_viewer_plus`: drag-rotate, pinch-zoom, free WebXR AR. Front/Back camera-orbit toggle (`0deg` / `180deg`), regenerating badge, generate / generating / failed state cards, and the existing 6-hotspot pin overlay (front + ready state only).

The regeneration gate is profile-hash-driven:

- [`profile_hash.dart`](lib/features/ar_engine/data/profile_hash.dart) computes `sha256` over the profile fields that affect the model. The TS port at [`functions/src/profile_hash.ts`](functions/src/profile_hash.ts) is byte-for-byte identical so the server can reject replay attempts.
- `generatedDressProvider(DressCode)` exposes the current `GeneratedDress` entry on the profile (or `null`).
- `modelStatusProvider(DressCode)` folds it against a fresh hash to return `needsGeneration | generating | ready | stale | failed`.
- [`ModelGenerationController`](lib/features/ar_engine/presentation/providers/model_generation_controller.dart) wraps the imperative `composeUniformModel` callable. `ensureFresh(DressCode)` is the idempotent entry point used from `GhostScreen.initState`.

Backend touchpoints: `composeUniformModel` Cloud Function, `models/**` Storage prefix, `user_models/{uid}/{dressCode}.glb` write, `users/{uid}/profile/current.generatedDresses[*]` reconciled via the existing Firestore stream.

---

## Project Structure

```
SAF-Uniforms/
├── ChangeRequest/         # Plan files (mandatory before non-trivial changes — see CLAUDE.md §1.1)
├── android/               # Android platform project
├── ios/                   # iOS platform project
├── assets/
│   ├── accessories/       # Per-id No.3 accessory PNGs (image.png + placement.png)
│   ├── 3d/                # Local mirror of gs://…/models/** (placeholder bodies + real assets)
│   ├── data/              # FROZEN seed snapshot (branch_configs.v1.json, etc.)
│   ├── branding/          # SAF crest SVG + 1024×1024 master PNG (launcher icon source)
│   └── images/            # Misc UI imagery
├── docs/
│   └── 3d-body-authoring.md  # MakeHuman + Blender + MPFB2 recipe for production bodies
├── functions/             # Firebase Cloud Functions (TypeScript, Node 20)
│   └── src/
│       ├── claimDeviceIdentity.ts
│       ├── markProfileComplete.ts
│       ├── composeUniformModel.ts
│       ├── dress_accessory_resolver.ts
│       └── profile_hash.ts
├── lib/                   # Dart source (see below)
├── test/                  # Mirrors lib/ structure
├── tool/                  # Operator-only scripts (NOT in app build graph)
│   ├── seed_firestore.dart            # Pure-Dart Admin SDK seeder
│   ├── upload_accessory_images.py     # Python: assets/accessories/** → Storage
│   ├── extract_pdf_accessories.py     # Crops accessory PNGs from the doctrine PDF
│   ├── generate_placeholder_bodies.py # Algorithmic stand-in humanoid GLBs
│   └── upload_models.py               # Python: assets/3d/** → Storage
├── firebase.json          # Firebase CLI config (rules + functions pointer)
├── firestore.rules        # Firestore security rules
├── storage.rules          # Cloud Storage security rules
├── l10n.yaml              # ARB → Dart code generation config
├── pubspec.yaml
├── analysis_options.yaml
├── README.md              # This file
└── CLAUDE.md              # Internal working policies + canonical architecture record
```

### Inside [`lib/`](lib/)

```
lib/
├── main.dart                # Entry point — only ensureInitialized() + runApp(...)
├── app.dart                 # Root MaterialApp.router
├── firebase_options.dart    # Generated by FlutterFire CLI
│
├── core/
│   ├── design/              # Claude-Design tokens: colors, text styles, spacing, shared widgets
│   ├── error/               # Sealed Failure + Result<T>
│   ├── l10n/                # ARB inputs + generated localizations
│   ├── persistence/         # LocalStorageService (keychain + shared_preferences)
│   ├── routing/             # Route constants + GoRouter provider
│   ├── theme/               # BranchTheme extension + dark/light + accent override
│   └── widgets/             # ErrorView, LoadingView
│
└── features/
    ├── ar_engine/           # 3D ghost model + composeUniformModel client
    ├── ar_scanner/          # Camera + ML Kit pose detection (placeholder UI)
    ├── auth/                # Device-bound identity + custom-token sign-in
    ├── checklist/           # DressAccessoryResolver + per-dress accessory providers
    ├── dashboard/           # 4-tab IndexedStack + Generating / Rebuilding screens
    ├── gallery/             # User photo upload, full-screen viewer, share, delete
    ├── onboarding/          # Welcome screen + appBootstrapProvider
    ├── profile/             # UniformProfileNotifier + Configuration wizard data
    └── wearing_guide/       # 9-step dressing flow
```

---

## Getting Started

### Prerequisites

- Flutter `>=3.41.0` and Dart `^3.11.1` ([install guide](https://docs.flutter.dev/get-started/install))
- An iOS or Android device / simulator
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm i -g firebase-tools`)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) (`dart pub global activate flutterfire_cli`)
- Python 3.10+ (only required for the operator scripts in [`tool/`](tool/))
- A service-account JSON for the `saf-uniforms` Firebase project (Firebase Console → Project settings → Service accounts → Generate new private key). Keep it outside the repo or under `secrets/` (gitignored).

### First-time setup (full demo bring-up)

```bash
# 1. Flutter side
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutterfire configure --project=saf-uniforms   # writes lib/firebase_options.dart
flutter analyze && flutter test

# 2. Reference data → Firestore (operator action; needs service-account JSON)
dart run tool/seed_firestore.dart <svc-account>.json

# 3. Accessory imagery → Firebase Storage
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_accessory_images.py --bucket saf-uniforms.firebasestorage.app

# 4. 3D placeholder bodies → Firebase Storage (unblocks GhostScreen)
python3 -m venv .venv-tools
.venv-tools/bin/pip install trimesh numpy
.venv-tools/bin/python tool/generate_placeholder_bodies.py
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app

# 5. Cloud Functions + security rules
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions,firestore:rules,storage:rules

# 6. Run the app
flutter run
```

The placeholder bodies in step 4 are intentionally rough humanoids ([`tool/generate_placeholder_bodies.py`](tool/generate_placeholder_bodies.py)) so the GhostScreen demo works without 3D-artist work. Replace them with real MakeHuman bodies per [`docs/3d-body-authoring.md`](docs/3d-body-authoring.md) when ready — same filenames, re-run step 4, no app changes.

### Running on a specific device

```bash
flutter devices              # list connected devices
flutter run -d <deviceId>    # run on the named device
```

---

## Common Commands

| Command                                                          | Effect                                                          |
| ---------------------------------------------------------------- | --------------------------------------------------------------- |
| `flutter pub get`                                                | Install / update dependencies.                                  |
| `dart run build_runner build --delete-conflicting-outputs`       | Regenerate Riverpod / Freezed / json_serializable code.         |
| `dart run build_runner watch --delete-conflicting-outputs`       | Continuous codegen during development.                          |
| `flutter gen-l10n`                                               | Regenerate localizations from ARBs.                             |
| `flutter analyze`                                                | Static analysis (must be clean before merging).                 |
| `flutter test`                                                   | Run the unit + widget test suite.                               |
| `flutter run`                                                    | Launch on the default connected device.                         |
| `dart run flutter_launcher_icons`                                | Regenerate launcher icons from `assets/branding/saf_crest_1024.png`. |
| `firebase deploy --only functions,firestore:rules,storage:rules` | Deploy backend.                                                 |

---

## Project Conventions

- **Imports** — relative imports inside the same feature; absolute `package:saf_uniforms/...` only from `test/`.
- **File / directory names** — `snake_case.dart`.
- **Class names** — `UpperCamelCase`. Enum values are `lowerCamelCase` with a stable `wireName` for serialization (see `BranchId`, `DressCode`).
- **Codegen output** (`*.g.dart`, `*.freezed.dart`) is committed but **never** hand-edited — regenerate via `build_runner`.
- **No `print` statements** — use `dart:developer`'s `log()` with a stable `name:` per file/feature.
- **Tests** live under [`test/`](test/) and mirror `lib/`'s path structure. Use `ProviderContainer` directly for unit tests of notifiers (see [test/features/profile/uniform_provider_test.dart](test/features/profile/uniform_provider_test.dart)).
- **Private providers / classes** are prefixed with `_`.

---

## Contributor Workflow

This project follows a **plan-first workflow** — before any non-trivial change (feature, refactor, schema migration, dependency upgrade, multi-file bug fix), drop a plan file under [`ChangeRequest/`](ChangeRequest/) (see [`ChangeRequest/README.md`](ChangeRequest/README.md) for the template). Trivial work (typo fixes, formatting, lock-file regen) can skip the plan.

The full mandatory policies — plan-first workflow, logging discipline (every method emits `info` / `debug` / `error`), defensive `try / catch` at I/O boundaries, post-plan verification (`flutter analyze` + `build_runner` + `flutter test` + smoke run on Android & iOS) — live in [CLAUDE.md §1](CLAUDE.md#1-working-policies-mandatory). Read it once before opening a PR.

When a plan touches folder layout, dependencies, the Riverpod provider graph, the routing table, theming, localization, Firestore collections, or any feature's public API, [CLAUDE.md](CLAUDE.md) must be updated in the same change set so the document never drifts.

---

## Known Gaps / Roadmap

These are pointers for whoever picks up the next plan, not policies:

- **3D placeholder bodies.** `assets/3d/bodies/{male,female,female_maternity}_apose.glb` ship as algorithmically-generated stand-ins (~50–60 KB each, visibly humanoid, A-pose, named sub-meshes — but explicitly not doctrine-accurate). Real MakeHuman + Blender bodies drop in via [`docs/3d-body-authoring.md`](docs/3d-body-authoring.md).
- **Phase-2 3D composition.** `composeUniformModel` currently emits the validated body GLB only. Multi-asset merge (uniform + accessory re-parenting under named socket bones, name-tag baking via `sharp`, Draco + KTX2 compression) lights up as artist deliveries land.
- **No.1 / 2 / 4 / 5 dress accessories.** The `accessory_library` is doctrine-aligned for **No. 3** only. Other dress codes still reference legacy generic placeholders (filtered out by `DressAccessoryResolver` until their PDFs land).
- **AR Scanner.** Camera + ML Kit pose deps are wired; the screen is still a Phase-1 placeholder. Real camera feed + posture scoring is a follow-up.
- **Wearing-guide voice narration** is currently a no-op stub. TTS lands separately.
- **Coordinate-map calculator.** Vertical-shift math for medals is wired; the richer No.3 placement math (collar offsets, ladies-belt alignment, name-tag protocol) lives in `dress_requirements` docs but is not yet consumed by `coordinateMapProvider`.
- **Logging coverage** is sparse today; bring it up to [CLAUDE.md §1.3](CLAUDE.md#13-logging-discipline) as you touch each method.
- **Legacy `/checklist` route** is no longer reachable from any user path; will be retired or converted to dynamic data in a follow-up plan.

---

## License

License: **TBD** — internal SAF reference app. No `LICENSE` file is committed yet; treat all source as proprietary until that changes.
