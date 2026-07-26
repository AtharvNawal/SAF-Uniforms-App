# SAF Uniforms — Project Guide

Singapore Armed Forces uniform reference app, built with Flutter. This file is
the source of truth for project architecture and the working agreement that
Claude (and any contributor) must follow on this codebase.

---

## 1. Working Policies (MANDATORY)

These policies override default behaviour. Follow them exactly.

### 1.1 Plan-first workflow
Before executing any non-trivial change (feature, refactor, schema change,
dependency upgrade, bug-fix that touches multiple files), you **MUST**:

1. Create a plan file inside the [`ChangeRequest/`](ChangeRequest/) folder at
   the project root.
2. File name: `YYYY-MM-DD_<short-kebab-title>.md` (see
   [ChangeRequest/README.md](ChangeRequest/README.md) for the template).
3. The plan must cover: Goal, Scope, Affected areas, Step-by-step plan,
   Risks & rollback, Verification, and which sections of `CLAUDE.md` will
   need to be refreshed.
4. Only **after** the plan file is saved should execution begin.

Trivial work (typo fix, comment, dependency lock-file regen, formatting) can
skip the plan, but anything that changes runtime behaviour or architecture
needs a plan file.

### 1.2 Keep CLAUDE.md in sync after every plan
Whenever a plan from `ChangeRequest/` is executed and it changes any of:

- Folder layout / module boundaries
- Dependencies in `pubspec.yaml`
- Drift schema or migrations
- Firestore collections / documents
- Riverpod provider graph or bootstrap sequence
- Routing table (`Routes` / `appRouterProvider`)
- Theming or `BranchTheme` extension
- Localization (ARB files / supported locales)
- Public API of a feature (`domain/` exports)

…you **MUST** update the relevant section of this `CLAUDE.md` in the same
change set so the document never drifts from reality. Mark the plan file's
status as `executed` and then `verified` once policy 1.5 is satisfied.

### 1.3 Logging discipline
Every method (especially in `data/`, repositories, services, notifiers,
bootstrap, and route guards) must emit logs at the appropriate level:

| Level   | When to use                                                        |
| ------- | ------------------------------------------------------------------ |
| `info`  | Lifecycle events, successful high-level operations, state changes. |
| `debug` | Inputs, intermediate values, branch-taken decisions.               |
| `error` | Caught exceptions inside `catch` blocks (with stack trace).        |

Use `dart:developer`'s `log()` (already available — no extra dep) and pass a
stable `name:` per file/feature, e.g.
`log('signed in uid=${user.uid}', name: 'auth.repo', level: 800);`

> Today the codebase has very few logs. Anyone touching a method should add
> the missing `info`/`debug`/`error` calls as part of the change.

### 1.4 Defensive try / catch
Every method that does I/O, async work, JSON decoding, Firestore /
Drift / `rootBundle` / `Platform` access, or anything that can throw, **must**
be wrapped in a `try / catch`:

```dart
Future<Foo> doThing() async {
  log('doThing: start', name: 'feature.area');
  try {
    final result = await _someAsyncCall();
    log('doThing: ok', name: 'feature.area');
    return result;
  } catch (e, st) {
    log('doThing: failed', name: 'feature.area', error: e, stackTrace: st,
        level: 1000);
    rethrow; // or return Err(...) using core/error/result.dart
  }
}
```

Prefer returning `Result<T>` (see [lib/core/error/result.dart](lib/core/error/result.dart))
or a typed `Failure` (see [lib/core/error/failure.dart](lib/core/error/failure.dart))
instead of letting raw exceptions escape repository / service boundaries.
Pure functions and trivially-typed getters do not need a `try / catch`.

### 1.5 Verify the app after every plan
After a plan is executed, you **MUST** verify the app before marking the
plan `verified`:

1. `flutter analyze` — must be clean.
2. `flutter pub run build_runner build --delete-conflicting-outputs` — if any
   `@freezed` / `@riverpod` / `drift` / `json_serializable` annotations were
   touched.
3. `flutter test` — all existing tests pass; add tests for new logic.
4. `flutter run` (Android **and** iOS where reasonable) — at minimum, smoke
   test the affected screen / flow.
5. Update the plan file's `Status:` line to `verified` and note what was run.

---

## 2. Project at a glance

- **Name:** `saf_uniforms`
- **Description:** "SAF Uniforms — Singapore Armed Forces uniform reference."
- **Type:** Flutter mobile app (Android + iOS).
- **Dart SDK:** `^3.11.1`, **Flutter:** `>=3.41.0`.
- **Version:** `1.0.0+1`.

### Demo bring-up (one-time, end-to-end)

If you're standing up the project from scratch — including the 3D-avatar
demo for the product owner — run these once:

```bash
# 1. Flutter side
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test

# 2. Reference data → Firestore (operator action; needs service-account JSON)
dart run tool/seed_firestore.dart <svc-account>.json

# 3. Accessory imagery → Firebase Storage
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_accessory_images.py --bucket saf-uniforms.firebasestorage.app

# 4. 3D placeholder bodies → Firebase Storage (this unblocks GhostScreen)
python3 -m venv .venv-tools
.venv-tools/bin/pip install trimesh numpy
.venv-tools/bin/python tool/generate_placeholder_bodies.py
GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
  python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app

# 5. Cloud Functions + Storage rules
cd functions && npm install && npm run build && cd ..
firebase deploy --only functions,firestore:rules,storage:rules

# 6. Run the app
flutter run
```

Step 4's GLBs are intentionally rough placeholders (see
[`tool/generate_placeholder_bodies.py`](tool/generate_placeholder_bodies.py))
so the GhostScreen demo works today without 3D-artist work. Replace
them with real MakeHuman bodies per
[`docs/3d-body-authoring.md`](docs/3d-body-authoring.md) when ready —
same filenames, re-run step 4, no app changes.

### Top-level layout

```
SAF-Uniforms/
├── ChangeRequest/         # Plan files (policy 1.1)
├── android/               # Android platform project
├── ios/                   # iOS platform project
├── assets/
│   ├── accessories/       # Per-id No.3 accessory PNGs (image.png + placement.png). README.md is the per-id source-picture checklist for the SAF No.3 Dress PDF. Uploaded to Firebase Storage by `tool/seed_firestore.dart --upload-images`.
│   ├── 3d/                # 3D asset library — local mirror of `gs://…/models/**`. `bodies/{male,female,female_maternity}_apose.glb` are placeholder humanoids generated by `tool/generate_placeholder_bodies.py`; `placeholder.glb` is a small grey cube the CF falls back to when an asset is missing. Real artist deliveries (uniforms, accessories) drop into the same tree under `uniforms/` and `accessories/`. Pushed to Storage by `tool/upload_models.py`. The recipe for replacing the placeholders with real MakeHuman + Blender bodies is in [docs/3d-body-authoring.md](docs/3d-body-authoring.md).
│   ├── data/              # FROZEN seed snapshot for tool/seed_firestore_main.dart
│   │   ├── branch_configs.v1.json
│   │   ├── accessory_library.v1.json
│   │   ├── dress_requirements.v1.json
│   │   └── README.md
│   └── images/
├── docs/                  # Operator + contributor docs
│   └── 3d-body-authoring.md  # MakeHuman + Blender + MPFB2 recipe for producing real body GLBs (the placeholders generated by tool/generate_placeholder_bodies.py are stand-ins until this is run for production)
├── lib/                   # Dart source (see § 4)
├── test/                  # Mirrors lib/ structure
├── tool/                  # Operator-only entry points (not in app build graph)
│   ├── seed_firestore.dart            # Pure-Dart Firebase Admin SDK seeder; bypasses Firestore rules. Run via `dart run tool/seed_firestore.dart <service-account.json>` to push the four reference collections. The `--upload-images` flag exists but is unreliable — use `tool/upload_accessory_images.py` for image uploads (see §5.5).
│   ├── upload_accessory_images.py     # Python uploader for `assets/accessories/<id>/{image,placement}.png` → Firebase Storage. Replaces the broken Dart upload path. Idempotent via per-object SHA-256 metadata. Run with `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_accessory_images.py --bucket saf-uniforms.firebasestorage.app`.
│   ├── extract_pdf_accessories.py     # One-shot Python tool: crops per-accessory PNGs out of the rendered SAF No.3 Dress PDF and writes them to `assets/accessories/<id>/{image,placement}.png`. Re-run when the doctrine PDF changes; details in `assets/accessories/README.md`.
│   ├── generate_placeholder_bodies.py # Python (trimesh + Pillow) generator for stand-in humanoid GLBs. Outputs `assets/3d/bodies/{male,female,female_maternity}_apose.glb` + `assets/3d/placeholder.glb`. Composes primitives (head sphere, torso box, arms, legs, beret, name-tag patch, medal ribbons) per variant, plus a textured `name_tag` mesh with a `name_tag_mat` material (1024×256 white base-color texture — Phase-2 bake target) and 11 named socket markers (`head_top`, `cap_band_front`, `left/right_collar_tip`, `left/right_chest_pocket`, `left/right_shoulder_seam`, `left/right_sleeve_upper`, `belt_center`) that the merger looks up by name. Visibly humanoid but explicitly NOT production. Run via `python3 -m venv .venv-tools && .venv-tools/bin/pip install trimesh numpy Pillow && .venv-tools/bin/python tool/generate_placeholder_bodies.py`. Replace with real MakeHuman exports per `docs/3d-body-authoring.md` when ready.
│   ├── generate_placeholder_accessories.py # Python (trimesh) generator for procedural accessory GLBs. Reads `assets/data/accessory_library.v1.json`, dispatches each non-legacy entry to a per-category builder (beret = truncated cone, sikh turban = ovoid, cap badge = flat oval gold, sleeve insignia = chevron stripes, epaulette = slab, lanyard = cord + loop, etc.), writes `assets/3d/accessories/{id}.glb` centred on origin. The merger applies the per-anchor offset translation when re-parenting under a body socket. Each placeholder is visibly distinct + branch-coloured but obviously not production. Output: 55 GLBs covering headdress / cap badges / cap embellishments / sleeve insignia / epaulettes / lanyards / arms badges / vocation badges. Skips out-of-scope categories (footwear, gorgettes, medal_ribbons, etc.). Run via `.venv-tools/bin/python tool/generate_placeholder_accessories.py`.
│   ├── inject_accessory.py            # Python tool that takes a raw artist-authored accessory GLB (Tripo / Meshy / Luma export, arbitrary scale + orientation) and emits a contract-compliant accessory GLB ready to drop under `assets/3d/accessories/{id}.glb`. Loads via `trimesh.load(force="mesh")` to bake node transforms, auto-orients so the bbox's thinnest extent aligns with Z (so the accessory's flat face points +Z, matching the merger's body-front sockets), scales uniformly to a target size (default 5 cm widest dim — appropriate for cap badges; bump to 0.07-0.20 m for sleeve insignia / headdress), and recentres at origin so the merger's per-accessory `render_logic.offset_*_cm` translation lands as designed. CLI: `--in <raw.glb> --out <accessory.glb> [--target-size METRES] [--rotate-{x,y,z} DEG] [--no-auto-orient]`. The `--rotate-y 180` flag is the one-flag fix when the auto-oriented badge ends up facing the camera-back rather than camera-front. Raw artist sources are preserved at `assets/3d_raw/` (gitignored).
│   ├── inject_sockets.py              # Python tool to make a raw Tripo / Meshy / Luma body GLB satisfy the Phase-2 merger contract. Loads via `trimesh.load(force="mesh")` (bakes node transforms), normalises to target height (default 1.75m) with feet at y=0 and centred on x/z, then injects 14 named scene-graph nodes via `transform=` parameter on `add_geometry` so the SOCKET NODE TRANSFORMS carry the world position (NOT vertex coordinates — the merger's `socket.addChild(accRoot)` inherits world transform). Front-side socket Z-offsets are anatomic constants (chest=0.10m, head_front=0.08m, name_tag=0.105m), NOT bbox fractions, because Tripo bodies' A-pose depth (~0.64m) would otherwise put chest features ~25cm in front of the shirt surface. Supports `--up-axis {y,z,-z}` for non-glTF-standard exports and `--target-height` to override the 1.75m default (use 1.65 for female / maternity).
│   └── upload_models.py               # Python uploader for `assets/3d/**/*.glb` → Firebase Storage `models/**`. Mirrors `upload_accessory_images.py`'s pattern (urllib + openssl signing, idempotent SHA-256, persistent download tokens). Run via `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app`. Supports `--dry-run` and `--only <glob>` for targeted uploads.
├── functions/             # Firebase Cloud Functions (TypeScript, Node 20). Three HTTPS callables: `claimDeviceIdentity` and `markProfileComplete` back the device-bound identity flow; `composeUniformModel` runs the Phase-2 multi-asset 3D merger (uniform + accessories + name-tag bake + Draco/WebP compression) via the helpers in `src/glb_compose.ts`. Deployed via `firebase deploy --only functions`. Tests: `npm test` (Node 20 built-in `node:test` runner over `lib/*.test.js`).
├── admin-portal/          # Angular 20 SSR admin portal (standalone components, routing, SCSS). Lives entirely in its own folder with its own `package.json` / `tsconfig.json` / `node_modules/`. Wired via AngularFire 20 to the same `saf-uniforms` Firestore + Storage + Auth + Functions (region `asia-southeast1`) as the Flutter mobile app. SSR routes are all `RenderMode.Client` — the SSR server just ships the shell; live Firebase reads happen client-side. Deployed to **Firebase App Hosting** (Cloud Run-backed) via `apphosting.yaml` + GitHub auto-deploy. **Phase 1 foundation (current state):** Claude Design CSS ported verbatim to `src/styles/_tokens.scss` + `_design.scss` (light/dark via `[data-theme="..."]`); **ngx-translate** i18n (English only today via `public/i18n/en.json`; structurally ready for more); **ThemeService** (`'dark' | 'light' | 'system'`, persists to `localStorage`); **ToastService**; **AuthService + auth guard** over AngularFire Auth; **`<app-icon>` component** with all 41 SVGs; **15 UI primitives** (Button / Chip / Card / Field / Input / Select / Toggle / PillToggle / Modal / Avatar / BranchDot / Eyebrow / MonoTag / EmptyState / PageStub); **responsive shell** (sidebar 240 px on desktop, slide-over below 1023 px, bottom mobile nav + "More" overflow modal); **MockDataService** mirroring the JSX `data.jsx` shapes for all 11 reference collections (swap to AngularFire-backed implementations in a follow-up plan with no caller changes). **All 10 routes fully designed against the Claude Design handoff** (no stubs remain): `/login` (centred crest card + sign-in form), `/dashboard` (5-card stat grid + activity list + quick actions + coverage matrix), `/dress` (filterable card grid), `/dress/add` (3-step PDF wizard with animated AI scan overlay → review pane → finalise pane), `/dress/:id` (review pane + change history accordion), `/accessories` (table + 4-tab detail drawer), `/models` (4-tab router: bodies / uniforms matrix / accessories table / placeholder), `/branches` (4-card per-branch config editor with collapsible sections), `/logic` (rule cards + JSON viewer + Add Rule modal), `/users` (read-only table + drawer), `/admins` (table + Add Admin modal), `/settings` (theme picker + locale + danger-zone shells). Every page consumes data via `MockDataService` (Observable-based; swap to AngularFire-backed implementations in a follow-up "Real Firestore wiring" plan with no caller changes). New shared primitives added beyond the foundation: `<app-icon-btn>`, `<app-drawer>`, `<app-cfg-section>`, `<app-json-viewer>`, `<app-pdf-dropzone>`. Scaffolded by `ChangeRequest/2026-05-17_angular-admin-portal-scaffold.md`; foundation by `ChangeRequest/2026-05-17_admin-portal-foundation.md`; per-screen ChangeRequests at `ChangeRequest/2026-05-17_admin-portal-{dashboard,users,admins,branches,logic,accessories,models,dress}.md` (all status: executed). Topographic background overlay (`.topo-overlay`) removed from runtime — CSS class still present in `_design.scss` for future use.
├── firebase.json          # Firebase CLI config (firestore.rules + storage.rules + functions pointer; `apphosting` block added by `firebase init apphosting` for the admin portal)
├── firestore.rules        # Firestore security rules
├── storage.rules          # Cloud Storage security rules — auth-required reads for accessories/{id}/{image,placement}.png; owner read/write for user_photos/{uid}/
├── l10n.yaml              # ARB → Dart code generation config
├── pubspec.yaml
├── analysis_options.yaml
└── CLAUDE.md              # This file
```

---

## 3. Tech stack

| Concern               | Package(s)                                                      |
| --------------------- | --------------------------------------------------------------- |
| State management      | `flutter_riverpod ^3.3.1`, `riverpod_annotation ^4.0.2`         |
| Codegen (state)       | `riverpod_generator ^4.0.3`, `build_runner ^2.5.5`              |
| Backend               | `firebase_core ^4.7.0`, `firebase_auth ^6.4.0`, `cloud_firestore ^6.3.0`, `cloud_functions ^6.0.0`, `firebase_storage ^13.0.4` |
| Device identity       | `device_info_plus ^13.1.0`, `uuid ^4.5.0`                       |
| Image loading         | `cached_network_image ^3.4.1` (No.3 accessory photos + placement diagrams; Gallery user photos from Firebase Storage) |
| Gallery               | `image_picker ^1.1.2` (camera + library), `photo_view ^0.14.0` (pinch-to-zoom viewer + swipe gallery), `share_plus ^13.1.0` (share sheet) |
| Local persistence     | `flutter_secure_storage ^8.1.0` (keychain / encrypted prefs), `shared_preferences ^2.3.3` |
| Modeling / JSON       | `freezed ^3.2.5` (+ `freezed_annotation ^3.1.0`), `json_serializable ^6.10.0` (+ `json_annotation ^4.11.0`) |
| Routing               | `go_router ^17.2.2`                                             |
| Localization          | `flutter_localizations`, `intl ^0.20.2` (+ `l10n.yaml`)         |
| Linting               | `flutter_lints ^6.0.0` (see `analysis_options.yaml`)            |
| Tests                 | `flutter_test`, `fake_cloud_firestore ^4.0.0`                   |
| Operator tooling      | `firebase_admin_sdk ^0.5.1`, `google_cloud_firestore`, `google_cloud_storage`, `crypto` (dev deps; pure-Dart admin SDK used only by `tool/seed_firestore.dart` — Firestore + Storage upload + SHA-256 hashing for idempotent reruns) |
| Camera / AR / pose    | `camera ^0.11.0+2`, `model_viewer_plus ^1.9.3` (now wired into `GhostScreen` to render the per-user composed GLB), `google_mlkit_pose_detection ^0.14.0`, `permission_handler ^11.3.1` |
| Hashing               | `crypto ^3.0.0` (sha256 over profile fields → 16-hex `profileHash` cache key for the 3D-avatar regeneration gate; also used by the seed-tool's image idempotency check) |
| Typography            | `google_fonts ^6.2.1` (DM Sans + JetBrains Mono per Claude Design handoff) |
| Vector branding       | `flutter_svg ^2.0.10+1` (SAF crest in Welcome screen + dashboard app bar)   |
| Launcher icons        | `flutter_launcher_icons ^0.14.3` (dev only; regenerates Android mipmap + iOS AppIcon set from `assets/branding/saf_crest_1024.png`) |

> No local DB for app content. Reference content is read directly from
> Firestore real-time snapshots; the Firestore SDK's offline cache
> handles offline reads. The only local persistence is a tiny
> `LocalStorageService` that holds the per-device UUID (`deviceId`),
> last-known Firebase `uid`, and `profileComplete` flag — used to
> render the Welcome / Dashboard branch synchronously before the
> background `claimDeviceIdentity` Cloud Function call resolves.

### Codegen commands

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n   # ARB → lib/core/l10n/generated/*
```

---

## 4. Source tree (`lib/`)

```
lib/
├── main.dart                # Entry point — only `ensureInitialized()` + `runApp(ProviderScope(...))`. All async startup work lives in `appBootstrapProvider`, driven by `WelcomeScreen`.
├── app.dart                 # Root MaterialApp.router
├── firebase_options.dart    # Generated by FlutterFire CLI
│
├── core/
│   ├── persistence/
│   │   └── local_storage_service.dart   # flutter_secure_storage (deviceId, cachedUid) + shared_preferences (profileComplete, lastBranchId)
│   ├── design/                          # Shared design-system layer (Claude Design tokens)
│   │   ├── app_colors.dart              # Color tokens + ServicePalette
│   │   ├── app_text_styles.dart         # DM Sans + JetBrains Mono helpers
│   │   ├── app_spacing.dart             # gap / radius / common heights
│   │   └── widgets/
│   │       ├── topo_background.dart     # Topo-map painted bg + radial accent
│   │       ├── ios_status_bar.dart      # Visual iPhone status bar
│   │       ├── app_chip.dart            # Mono uppercase chip (accent variant)
│   │       ├── app_buttons.dart         # PrimaryButton, GhostButton, IconChipButton
│   │       ├── app_card.dart            # AppCard + SectionCard (eyebrow + title)
│   │       ├── app_field.dart           # AppTextField, AppDropdown, FieldLabel
│   │       ├── pill_toggle.dart         # 2-or-3 segmented toggle
│   │       ├── badge_pill.dart          # Toggleable rounded pill
│   │       ├── check_card.dart          # Accessory checklist row
│   │       ├── spotlight_card.dart      # Accent radial-gradient card
│   │       ├── app_bottom_sheet.dart    # showAppBottomSheet + SheetHeader
│   │       └── dress_mini_preview.dart  # Per-dress SVG-style figure painter
│   ├── error/
│   │   ├── failure.dart     # Sealed Failure + Network/Auth/Storage/Unknown
│   │   └── result.dart      # Sealed Result<T> = Ok<T> | Err<T>
│   ├── l10n/
│   │   ├── arb/{app_en.arb, app_zh.arb}     # Full UI strings (en + zh)
│   │   ├── generated/                       # Output of `flutter gen-l10n`
│   │   └── l10n_extensions.dart             # context.l10n + BranchId/DressCode/Gender labels
│   ├── routing/
│   │   ├── routes.dart      # 9 route constants (welcome, dashboard, config, ghost-model, wearing, ar, generating, rebuilding, /checklist)
│   │   └── app_router.dart  # GoRouter provider — registers all routes
│   ├── theme/
│   │   ├── app_theme.dart            # AppTheme.light/dark applies DM Sans + tokens
│   │   ├── branch_themes.dart        # Army/Navy/RSAF/DIS palettes (now with `bright`)
│   │   ├── branch_theme_extension.dart  # ThemeExtension<BranchTheme> + context.branchTheme
│   │   └── theme_mode_provider.dart  # NotifierProvider<ThemeMode> — toggleable from Settings sheet
│   └── widgets/
│       ├── error_view.dart
│       └── loading_view.dart
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── device_identity_service.dart  # Resolves the per-device UUIDv4 (generates + persists to keychain on first launch)
    │   │   ├── device_registry_service.dart  # Wraps the `claimDeviceIdentity` + `markProfileComplete` Cloud Function callables
    │   │   └── auth_repository_impl.dart     # signInWithCustomToken + users/{uid} upsert
    │   ├── domain/
    │   │   ├── device_identity.dart          # `DeviceIdentity` (deviceId, platform) + `ClaimResult`
    │   │   └── auth_repository.dart          # Abstract AuthRepository + AuthSession (uid, deviceId, profileComplete)
    │   └── presentation/
    │       └── providers/
    │           ├── auth_providers.dart       # @Riverpod keepAlive — auth, registry, identity, local storage, FirebaseFunctions
    │           └── auth_providers.g.dart
    │
    ├── profile/
    │   ├── data/
    │   │   ├── branch_config_repository.dart # Pure Firestore stream of branch_configs/{branchId}
    │   │   ├── global_rules_repository.dart  # Pure Firestore stream of global_logic_rules/{ruleId}
    │   │   ├── profile_repository_impl.dart  # users/{uid}/profile/current
    │   │   └── dtos/
    │   │       ├── branch_config_firestore.dart # BranchConfig.fromFirestore(docId, data)
    │   │       └── uniform_profile_dto.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── branch_id.dart            # enum: army/navy/rsaf/dis
    │   │   │   ├── dress_code.dart           # enum: No1..No5
    │   │   │   ├── gender.dart
    │   │   │   ├── rank.dart                 # Full SAF rank ladder
    │   │   │   ├── branch_config.dart        # @freezed + json_serializable
    │   │   │   ├── medal_vertical_shift_rule.dart  # @freezed cross-branch rule
    │   │   │   ├── accessory.dart            # @freezed; shape of accessory_library entries
    │   │   │   └── uniform_profile.dart      # @freezed user-selected state
    │   │   └── repositories/
    │   │       └── profile_repository.dart
    │   └── presentation/
    │       └── providers/
    │           ├── uniform_provider.dart     # UniformProfileNotifier (@Riverpod)
    │           ├── branch_config_provider.dart
    │           └── global_rules_provider.dart    # GlobalRulesRepository + rule streams
    │
    ├── onboarding/
    │   └── presentation/
    │       ├── providers/
    │       │   ├── app_bootstrap_provider.dart      # @Riverpod(keepAlive) Future<BootstrapOutcome> — owns Firebase init, deviceId resolve, cached-session seed, and the `claimDeviceIdentity` + `signInWithCustomToken` round-trip (8s timeout). Driven by WelcomeScreen.
    │       │   └── app_bootstrap_provider.g.dart
    │       └── screens/
    │           └── welcome_screen.dart               # Crest + "Precision in every detail." Watches `appBootstrapProvider` + a 1.5s min-display timer. CTA slot shows a thin progress strip while loading; on `BootstrapOutcome.returningUser` auto-routes to `/dashboard`; on `newUser` reveals the "Get Started" CTA → `/config`.
    │
    ├── dashboard/
    │   └── presentation/
    │       ├── screens/
    │       │   ├── dashboard_screen.dart             # IndexedStack of 4 tabs + bottom nav + app bar
    │       │   ├── generating_screen.dart            # Animated ring loader, dress query param
    │       │   └── rebuilding_screen.dart            # 5-row dress progress list with ring chart
    │       ├── tabs/
    │       │   ├── home_tab.dart                     # Setup card, hero No.3, dynamic dress grid (Firestore-driven), quick actions
    │       │   ├── wardrobe_tab.dart                 # Dress filter dropdown + VERIFIED progress card + accessory checklist (mandatory/optional chips)
    │       │   ├── gallery_tab.dart                  # Full gallery: 3-col grid, upload w/ dress-code tag, filter bar, shimmer skeleton
    │       │   └── profile_tab.dart                  # SectionCards: service / identity / rank / medals / badges
    │       └── widgets/
    │           └── settings_sheet.dart               # Modal: theme mode + accent picker
    │
    ├── checklist/
    │   ├── data/
    │   │   ├── dress_requirements_repository.dart    # Pure Firestore stream of dress_requirements/{dressId}
    │   │   └── dtos/
    │   │       └── dress_requirement_firestore.dart  # DressRequirement.fromFirestore(docId, data)
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── dress_requirement.dart            # @freezed; mergedFor(BranchId) applies branch_overrides
    │   │   └── services/
    │   │       └── dress_accessory_resolver.dart     # Resolves (DressRequirement, UniformProfile) → List<Accessory>; resolveSplit() returns (mandatory, optional)
    │   └── presentation/
    │       ├── models/
    │       │   └── accessory_item.dart               # View-model for legacy /checklist screen
    │       ├── providers/
    │       │   ├── dress_requirements_provider.dart  # @Riverpod keepAlive — Firestore-direct
    │       │   └── dress_accessories_provider.dart   # dressAccessoriesProvider, dressAccessoriesByIdProvider(dressId), allDressesAccessoriesCombinedProvider, accessoryDressIndexProvider, wardrobeProgressProvider(filter)
    │       ├── screens/
    │       │   └── checklist_screen.dart             # Progress card + check-card list + sticky CTA
    │       └── widgets/
    │           └── accessory_detail_sheet.dart       # Bottom sheet: rule + placement diagram + verify CTA
    │
    ├── gallery/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── gallery_photo.dart                # @freezed; id, url, thumbnailUrl, uploadedAt, dressCode
    │   │   └── repositories/
    │   │       └── gallery_repository.dart           # watchPhotos, uploadPhoto, deletePhoto, updateMetadata
    │   ├── data/
    │   │   └── gallery_repository_impl.dart          # FirebaseStorage + Firestore; path user_photos/{uid}/{photoId}.jpg
    │   └── presentation/
    │       ├── providers/
    │       │   ├── gallery_providers.dart            # galleryRepositoryProvider, galleryPhotosProvider, GalleryUploadNotifier, GalleryDeleteNotifier
    │       │   └── gallery_providers.g.dart
    │       └── screens/
    │           └── photo_viewer_screen.dart          # PhotoViewGallery full-screen: pinch-to-zoom, swipe, share, delete
    │
    ├── wearing_guide/
    │   └── presentation/screens/
    │       └── wearing_guide_screen.dart             # 9 steps + silhouette + voice stub + completion view
    │
    ├── ar_scanner/
    │   └── presentation/screens/
    │       └── ar_scanner_screen.dart                # Phase 1 scanning placeholder + Phase 2 scorecard
    │
    └── ar_engine/
        ├── data/
        │   ├── accessory_library_repository.dart    # Pure Firestore stream of accessory_library/{accessoryId}
        │   ├── model_generation_repository.dart     # Wraps the `composeUniformModel` Cloud Function callable; returns `{modelUrl, profileHash, schemaVersion}` for the optimistic UI path
        │   ├── profile_hash.dart                    # Pure fn `computeProfileHash(profile, dressCode)` — sha256 of the profile fields that affect what the 3D model looks like; matches the server-side TypeScript implementation byte-for-byte. Houses `kModelBundleVersion` (bump to force regen for everyone)
        │   └── dtos/
        │       └── accessory_firestore.dart         # Accessory.fromFirestore(docId, data)
        ├── domain/
        │   └── coordinate_map.dart           # @freezed Anchor3D + CoordinateMap
        └── presentation/
            ├── providers/
            │   ├── accessory_library_provider.dart       # @Riverpod keepAlive
            │   ├── accessory_library_provider.g.dart
            │   ├── coordinate_map_provider.dart           # Pure derivation (profile, config, verticalShiftRule) → CoordinateMap
            │   ├── generated_dress_provider.dart          # `modelGenerationRepositoryProvider`, `generatedDressProvider(DressCode)` → current `GeneratedDress` from profile, `modelStatusProvider(DressCode)` → `ModelStatus` enum (needsGeneration / generating / ready / stale / failed) folding profile hash against the cached entry
            │   └── model_generation_controller.dart       # `ModelGenerationController.generate(DressCode)` triggers `composeUniformModel` and writes optimistic `markGenerationStarted` flag; `ensureFresh(DressCode)` is the idempotent entry-point used from `GhostScreen.initState`
            └── screens/
                └── ghost_screen.dart                      # `model_viewer_plus`-backed 3D viewport (drag-rotate, pinch-zoom, free WebXR AR), front/back camera-orbit toggle, regenerating badge, generate / generating / failed state cards, and the existing 6-hotspot pin overlay (front + ready state only)
```

> The `*.g.dart` and `*.freezed.dart` files are codegen output — never edit by
> hand; regenerate via `build_runner`.

---

## 5. Architecture

### 5.1 Layered, feature-first
Each feature follows a Clean-style split:

- `domain/` — pure Dart entities, enums, abstract repository interfaces,
  pure-function domain services. No Flutter, no Firebase imports.
- `data/` — concrete repository implementations, DTOs, services. Talks to
  Firestore / platform plugins.
- `presentation/` — Riverpod providers, notifiers, widgets, screens.

### 5.2 State management — Riverpod 3
- All shared state lives behind `@Riverpod(keepAlive: true)` providers.
- Codegen producers (`*.g.dart`) must be regenerated whenever annotations
  change.
- `UniformProfileNotifier`
  ([uniform_provider.dart](lib/features/profile/presentation/providers/uniform_provider.dart))
  owns the user's current selection (branch, rank, gender, dress code, sikh
  flag, full name, vocation, medal-row count, selected badge ids, selected
  accessory ids, and the per-dress accessory check map
  `dressAccessoryChecks: Map<dressId, Set<accessoryId>>` populated from the
  Wardrobe tab). It is the single source of truth that downstream providers
  (theme, coordinate map) react to. Every setter schedules a **500 ms
  debounced** `repo.upsert(state)` write to `users/{uid}/profile/current`,
  so live edits sync to Firestore without an explicit Save button. Callers
  needing a guaranteed write (Config Done) `await persist()` to flush the
  debounce immediately. On launch, `hydratedProfileProvider` (a stream from
  `profileRepository.watch()`) rehydrates state via
  `notifier.hydrate(profile)` once auth lands. The notifier also owns the
  marksmanship-tier badge mutex (`marksman ↔ sniper ↔ fitness`) inside
  `toggleBadge`, plus per-dress check mutators (`toggleDressAccessory`,
  `setDressAccessoryChecked`, `clearDressAccessoryChecks`) used by the
  Wardrobe tab.
- `currentBranchProvider` is a thin selector exposed for the theme + AR layer.
- `coordinateMapProvider` is a **pure derivation** of
  `(uniformProfile, branchConfig, medalVerticalShiftRule)` → `CoordinateMap`.
  Anything 3D-related must go through this provider, never read
  `UniformProfile` directly. The Vertical-Shift rule is consumed via
  `medalVerticalShiftRuleProvider` (cross-branch, sourced from
  `global_logic_rules/medal_vertical_shift`).
- `accessoryLibraryProvider` (`Stream<List<Accessory>>`) and
  `accessoryByIdProvider(String)` expose the live `accessory_library`
  Firestore collection (no Drift cache — the Firestore SDK handles offline
  persistence). Backed by `AccessoryLibraryRepository`.
- `dressRequirementByIdProvider(String)` and
  `dressRequirementForBranchProvider(String, BranchId)` expose the live
  `dress_requirements` Firestore collection. The latter applies any
  matching `branch_overrides` over the base entry via
  `DressRequirement.mergedFor(BranchId)`.
- `dressRequirementsAllProvider` (`Stream<List<DressRequirement>>`)
  streams every doc in `dress_requirements` and drives the dynamic
  Dashboard Home grid (one tile per non-`No3` doc — `No3` is filtered
  because the hero card still renders it explicitly until the
  generated-model lane lands).
- `dressAccessoriesProvider` (`AsyncValue<List<Accessory>>`) is the bridge
  between dress requirements + accessory library + user profile. It walks
  the No.3 structured override keys (`headdress`, `cap_badge`,
  `cap_embellishment`, `rank_insignia_sleeve.specialist|enlistee`,
  `epaulettes`, `name_tag`, `lanyard`, `arms_badge`, `vocation_badge`) via
  `DressAccessoryResolver` to pick the accessories that apply to the
  active `(branch, rank, gender, isSikh)`. Legacy-placeholder accessories
  (`render_logic.legacy_placeholder == true`) are filtered out, so No.1/2/4/5
  return empty until their doctrine PDFs land.
- `DressAccessoryResolver` exposes `resolveSplit(...)` returning
  `({mandatory, optional})` where headdress / cap_badge / cap_embellishment
  / rank_insignia_sleeve / epaulettes / name_tag / belt / socks / footwear
  are mandatory and lanyard / arms_badge / vocation_badge are optional.
  `name_tag` resolves to `name_tag_standard` for Army/Navy/RSAF/DIS (all
  branches use `name_tag_standard`; DIS additionally has `name_tag_protocol`
  as an unconsumed optional key for protocol appointments). The 3D pipeline
  handles name_tag via texture bake (`bakeNameTag` in `composeUniformModel`)
  rather than mesh attachment — the resolver surfaces it in the Wardrobe
  checklist only. `resolve(...)` is a backwards-compatible flatten of the
  same split. Consumed by the Wardrobe tab to render per-row
  `MANDATORY` / `OPTIONAL` chips.
- `dressAccessoriesByIdProvider(String dressId)`
  (`AsyncValue<AccessorySplit>`) is the parameterised version that returns
  the split for any dress doc id (so the Wardrobe tab can show a checklist
  for a dress other than the user's currently-configured one).
- `allDressesAccessoriesCombinedProvider`
  (`AsyncValue<List<Accessory>>`) deduplicates accessories across every
  dress in `dress_requirements`, in the order each dress's resolver
  output is encountered. Drives the Wardrobe "All Accessories" filter.
- `accessoryDressIndexProvider`
  (`AsyncValue<Map<accessoryId, Set<dressId>>>`) inverts the resolver so
  the Wardrobe "All Accessories" toggle can fan a tick out across every
  dress that lists the accessory.
- `wardrobeProgressProvider(WardrobeFilter)`
  (`({checked, total})`) is the verified-count derivation used by the
  Wardrobe `VERIFIED  X / Y` card. `WardrobeFilter` is a sealed
  `AllAccessoriesFilter` | `SingleDressFilter(dressId)`.
- `generatedDressProvider(DressCode)` exposes the current
  `GeneratedDress` entry on the profile (or `null` if nothing has
  been composed yet). `modelStatusProvider(DressCode)` folds it
  against a freshly-computed `profileHash` to return one of
  `needsGeneration`, `generating`, `ready`, `stale`, `failed`.
  `ModelGenerationController` (singleton via
  `modelGenerationControllerProvider`) wraps the imperative
  `composeUniformModel` callable and writes optimistic
  `markGenerationStarted` / `markGenerationFailed` flags to
  `UniformProfileNotifier` so `GhostScreen` reacts immediately
  without waiting on the round-trip. The Cloud Function is the
  authoritative writer of `modelUrl` + `profileHash` —
  client-side state is reconciled via the existing
  `hydratedProfileProvider` Firestore stream.

### 5.3 Bootstrap sequence — Welcome-owned, non-blocking
[`main.dart`](lib/main.dart) is intentionally tiny:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SafUniformApp()));
}
```

No async work, no Firebase init, no provider container plumbing — the
first frame paints immediately so there is **no white-screen flash**
on cold start. Every async startup step lives behind a single
`@Riverpod(keepAlive: true) Future<BootstrapOutcome> appBootstrap(Ref ref)`
in
[`app_bootstrap_provider.dart`](lib/features/onboarding/presentation/providers/app_bootstrap_provider.dart),
driven by
[`WelcomeScreen`](lib/features/onboarding/presentation/screens/welcome_screen.dart).

`appBootstrapProvider` runs once and steps through:

1. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
   (idempotent — skipped if `Firebase.apps.isNotEmpty`).
2. `DeviceIdentityService.resolve()` reads (or generates + persists) a
   stable UUIDv4 in [`flutter_secure_storage`](lib/core/persistence/local_storage_service.dart).
3. `LocalStorageService.readCachedUid()` + `readProfileComplete()`. If
   the uid is present, build an `AuthSession` and call
   `authSessionProvider.notifier.set(session)` so the router's
   deep-link guards relax immediately.
4. **Live auth round-trip**, bounded by an **8 s timeout**:
   1. `claimDeviceIdentity({deviceId, platform})` Cloud Function call.
   2. `signInWithCustomToken(claim.customToken)` — reauthenticates as
      the same uid that was registered for this device, even after an
      uninstall + reinstall.
   3. Upserts `users/{uid}` with the stable hardware id.
   4. Writes back the freshest `cachedUid` + `profileComplete` to
      local storage.
   5. `authSessionProvider.notifier.set(liveSession)`.
5. Returns `BootstrapOutcome.returningUser` if a session (cached or
   live) has `profileComplete == true`, else `BootstrapOutcome.newUser`.

`WelcomeScreen` watches `appBootstrapProvider` together with a
**1.5 s minimum-display timer** and a **separate 8 s safety timeout**.
While the pipeline runs, the CTA slot shows a thin
`LinearProgressIndicator` tinted with the active branch's `bright`
accent. Once both the timer has elapsed and bootstrap has either
completed or hit the safety timeout, Welcome decides:

- `returningUser` → `context.go(Routes.dashboard)` via a post-frame
  callback (`_didNavigate` flag prevents double-pushes).
- `newUser` (or `AsyncError`, or safety-timeout fallback) → CTA
  appears; tap goes to `Routes.config`.

**Why Welcome owns the redirect (not the router):** the router's
`redirect` no longer auto-bounces returning users from `/` to
`/dashboard`. If it did, Welcome would flash and disappear before
the brand moment is visible. Welcome enforces the minimum-display
window and only navigates after it elapses.

**The UI never blocks on the network.** If the Cloud Function is
unreachable, the cached session keeps the app usable and Firestore
writes queue in the SDK's offline cache. If a brand-new user has no
cached session and the network is down, the 8 s safety timeout in
Welcome reveals the CTA so they can still enter Config.

All reference content (`branch_configs`, `dress_requirements`,
`accessory_library`, `global_logic_rules`) is read on-demand by
per-feature repositories as Firestore real-time streams — no startup
priming, no manual sync wiring.

### 5.4 Local persistence
[`LocalStorageService`](lib/core/persistence/local_storage_service.dart)
holds a small fixed set of values needed to render the first frame
synchronously:

| Key                  | Backed by               | Purpose                                                     |
| -------------------- | ----------------------- | ----------------------------------------------------------- |
| `saf.deviceId`       | `flutter_secure_storage` | Hardware-derived UUID: `identifierForVendor` on iOS; UUID v5 of `Settings.Secure.ANDROID_ID` on Android. Re-derived on every launch and reconciled against the cache — cache is a fast-path hint, not authoritative. If the cached value differs from the hardware-derived one (Nil UUID poisoning, stale random v4 from older builds, signing-key change, etc.) `DeviceIdentityService.resolve()` overwrites the cache with the hardware value. Random v4 fallback only when hardware is unavailable (simulators, plugin failure). A hard `StateError` guard ensures the service never returns the Nil UUID `00000000-0000-0000-0000-000000000000`. |
| `saf.cachedUid`      | `flutter_secure_storage` | Last Firebase uid; lets the router show the Dashboard before the background auth round-trip completes. |
| `saf.profileComplete`| `shared_preferences`    | Mirrors `device_registrations/{deviceId}.profileComplete`; drives the Welcome → Config vs. Dashboard branch. |
| `saf.lastBranchId`   | `shared_preferences`    | Optional theme-bootstrap hint (not yet wired into `BranchTheme`). |
| `saf.themeAccent`    | `shared_preferences`    | `"follow"` (default) or `"saf_crest"` — drives `themeAccentProvider`. |

All actual app content (reference collections + the `UniformProfile`
itself) lives in Firestore. The Firestore SDK's offline cache handles
content persistence — a hand-rolled Drift mirror would duplicate that
work. The previous Drift schema (`branch_configs`, `accessories`,
`dress_requirements`, `rules` tables and the `AppDatabase` class) was
removed in `ChangeRequest/2026-05-02_firestore-first-migration.md`.

On Android, `flutter_secure_storage`'s encrypted SharedPreferences are
restored across reinstalls only if Android Auto Backup is enabled
(`AndroidManifest.xml: android:allowBackup="true"` +
[`backup_rules.xml`](android/app/src/main/res/xml/backup_rules.xml)
whitelist). On iOS the keychain entries persist by default.

### 5.5 Backend — Firebase
- **Project id:** `saf-uniforms`. `flutterfire configure
  --project=saf-uniforms` writes `lib/firebase_options.dart`,
  `android/app/google-services.json`, and
  `ios/Runner/GoogleService-Info.plist`. The Angular admin portal is a
  separate Firebase **Web app** registered manually in the Firebase
  Console (Project settings → Your apps → Add app → Web); its config
  lives in `admin-portal/src/environments/environment{,.prod}.ts` and is
  consumed by the AngularFire `provideFirebaseApp(initializeApp(...))`
  call in `admin-portal/src/app/app.config.ts`.
- **Deploy targets:** three independent deploys against the same
  `saf-uniforms` project:
  - `firebase deploy --only functions` → Node 20 Cloud Functions
    (region `asia-southeast1`).
  - `firebase deploy --only firestore:rules,storage:rules` → security
    rules.
  - **Firebase App Hosting** → the Angular admin portal. Configured by
    `firebase init apphosting` (writes the `apphosting` block in
    `firebase.json` and a `.firebaserc`), tuned via
    `admin-portal/apphosting.yaml`, and triggered automatically by
    GitHub pushes to the linked live branch.
- **Auth:** **Custom-token sign-in** issued by the
  `claimDeviceIdentity` Cloud Function. The previous client-side
  `signInAnonymously()` flow was retired because anonymous-auth UIDs
  are wiped on every uninstall on both iOS and Android — the only way
  to re-authenticate as the same uid after a reinstall is for a
  server-side Admin SDK call to look up `device_registrations/{deviceId}`
  and mint a custom token for the matching uid.
- **Cloud Functions:** [`functions/`](functions/) (TypeScript, Node 20).
  - `claimDeviceIdentity({deviceId, platform})` — looks up
    `device_registrations/{deviceId}`; if found returns the existing
    `{uid, profileComplete}`, otherwise creates a fresh Firebase user
    via `admin.auth().createUser({})` and writes the mapping. Always
    returns a `customToken` the client passes to
    `signInWithCustomToken`. Region: `asia-southeast1`. Both this
    callable and `markProfileComplete` reject the Nil UUID
    `00000000-0000-0000-0000-000000000000` server-side via Zod
    `.refine()` — defence in depth against client-side cache
    corruption that would otherwise orphan the real registration
    behind a bogus `device_registrations/00000000-…` entry.
  - `markProfileComplete({deviceId})` — flips
    `device_registrations/{deviceId}.profileComplete = true` after the
    Configuration wizard completes. Verifies the caller's uid matches
    the registration to prevent guessing-attacks. Same Nil-UUID
    rejection as `claimDeviceIdentity`.
  - `composeUniformModel({dressCode, profileHash})` — composes the
    user's per-dress GLB. Validates auth, loads
    `users/{uid}/profile/current`, recomputes the canonical
    `profileHash` server-side (must match the client's hash; replay
    protection), short-circuits if the cached entry already matches,
    resolves the accessory list using
    [`functions/src/dress_accessory_resolver.ts`](functions/src/dress_accessory_resolver.ts)
    (a TypeScript port of the Dart `DressAccessoryResolver`),
    downloads the body / uniform / accessory GLBs from
    `gs://saf-uniforms.firebasestorage.app/models/**` (falling back
    to `models/placeholder.glb` when an asset hasn't been uploaded
    yet), runs the **Phase-2 multi-asset merger** in
    [`functions/src/glb_compose.ts`](functions/src/glb_compose.ts)
    (uniform merge → hair detach when a headdress is present →
    per-accessory re-parent under named socket bones with cm offsets
    converted to metres → name-tag bake via `sharp` onto the
    `name_tag_mat` material's base-color texture → Draco mesh
    compression + WebP texture compression), uploads the composed
    result to `user_models/{uid}/{dressCode}.glb`, and writes
    `users/{uid}/profile/current.generatedDresses[<dressDocId>]`
    with `{modelUrl, profileHash, schemaVersion, builtAt}`.
    `generationStartedAt` / `error` are cleared on success and set
    on failure. Each merger step is wrapped in `try / catch` so a
    single bad artist delivery (missing socket, malformed GLB, sharp
    failure) degrades gracefully — the affected accessory is logged
    and skipped while the rest of the composition still ships.
    The accessory list resolver reads everything from per-branch
    `requirement.branch_overrides[branchId]`: headdress / cap_badge /
    cap_embellishment / rank_insignia_sleeve / epaulettes / name_tag
    (mandatory), belt / socks / footwear (mandatory; same values across
    branches today but duplicated per branch so the Wardrobe UI's
    mandatory-vs-optional split has one consistent source), and
    lanyard / arms_badge / vocation_badge (optional). `name_tag` resolves
    to `name_tag_standard` for all four branches; `composeUniformModel`
    filters accessories with `category === "name_tag"` from the mesh
    attachment loop and instead bakes the surname text onto the body's
    `name_tag_mat` material via `bakeNameTag()`. Belt / socks /
    footwear values can be: a bare id; a list of ids (alternatives —
    all rendered as mandatory in Wardrobe, e.g. men's footwear has
    `["leather_shoes_low_cut", "patent_shoes_low_cut"]`); or a
    `{men, ladies}` selector keyed by profile gender (female +
    maternity → ladies) where each side itself can be a bare id or
    a list. Three accessory-attach helpers
    live in `composeUniformModel.ts`:
    `resolveAccessoryAnchor` maps `render_logic.anchor` (most cases)
    or `render_logic.side: "left"|"right"` (lanyards) to a body socket
    name; the merger reads `render_logic.mirror_left_right === true`
    and passes it to `attachAccessory({mirror: true})` so generic
    paired-alias names (`shoulder_seam`, `collar_point`, `ankle`,
    `foot_top`, etc.) attach a copy of the accessory under both
    `left_*` and `right_*` body sockets, with the right-side copy
    carrying a `[-1, 1, 1]` scale to flip symmetric meshes. Accessories with `category === "name_tag"`
    are filtered from the accessory loop because the bake step renders
    the surname onto the body's pre-existing `name_tag_mat` material;
    attaching a separate name-tag GLB on top would z-fight.
    `compressForWeb`'s final step is `consolidateBuffersToOne(doc)` —
    `mergeDocuments` accumulates one `Buffer` per merged source (body
    + N accessories = N+1 buffers), but `NodeIO.writeBinary` enforces
    "GLB must have 0–1 buffers". The helper reassigns every
    accessor's buffer to the first one and disposes the rest.
    Runtime: `2 GiB` memory, 120s timeout, region
    `asia-southeast1`. The bundle version (`MODEL_BUNDLE_VERSION = 15`)
    flushes every existing per-user cached GLB on first GhostScreen
    open after deploy. Profile-hash logic is shared with the client
    via the parallel implementation in
    [`functions/src/profile_hash.ts`](functions/src/profile_hash.ts).
    **Operator note (added pass 5):** bumping `MODEL_BUNDLE_VERSION` requires
    a matching bump in `kModelBundleVersion`
    ([lib/features/ar_engine/data/profile_hash.dart](lib/features/ar_engine/data/profile_hash.dart))
    AND a `flutter run` (rebuild + reinstall) on every active device. The
    Dart constant is compile-time, so editing the source file does NOT
    update an already-installed app. Without the rebuild, every existing
    install sends a hash computed with the OLD bundle version, the
    server's hash uses the NEW value, hashes diverge, and the function
    throws `HttpsError("failed-precondition", "Stale request…")` to the
    client. The CF logs this rejection as
    `composeUniformModel: rejected (hash mismatch — client likely stale; rebuild Flutter app …)`
    with both hashes + the server bundle version visible — search
    `firebase functions:log --only composeUniformModel` for that string
    if a user reports a compose error after a bundle bump.
  - Deploy: `firebase deploy --only functions,firestore:rules,storage:rules`.
- **Security rules:** [`firestore.rules`](firestore.rules) — auth-required
  reads on the four reference collections (writes blocked from clients;
  the future web admin portal will write via a service account that
  bypasses rules); owner-scoped reads + writes on `users/{uid}` and any
  nested docs; **`device_registrations/{deviceId}` blocked entirely from
  client SDK access** (only the Cloud Functions' Admin SDK touches it).
- **Cloud Storage:** [`storage.rules`](storage.rules) — single bucket
  `saf-uniforms.firebasestorage.app` (the modern Firebase Storage
  naming; the older `<projectId>.appspot.com` is **not** the active
  bucket on this project). Three top-level prefixes:
  - `accessories/{accessoryId}/{image,placement}.png` — mirrors the
    `accessory_library` collection ids. Reads are auth-required, writes
    blocked (Admin SDK only via the seed script).
  - `models/**` — the 3D asset library that
    `composeUniformModel` reads from. Layout
    `models/bodies/{male|female|female_maternity}_apose.glb`,
    `models/uniforms/{branch}_{no1..no5}_{male|female|female_maternity}.glb`,
    `models/accessories/{accessoryId}.glb` (mirrors the `accessory_library`
    Firestore doc IDs), plus `models/placeholder.glb` as the
    fallback for any object that hasn't been authored yet. Reads are
    auth-required, writes blocked (operator script via Admin SDK).
  - `user_models/{uid}/{dressCode}.glb` — per-user composed GLBs
    written exclusively by `composeUniformModel`. Reads are scoped to
    the owning uid (matches Firestore profile rules), writes blocked
    (Admin SDK only). Each upload carries metadata
    `{firebaseStorageDownloadTokens, profileHash, schemaVersion,
    bundleVersion}` so the client URL is a stable
    `https://firebasestorage.googleapis.com/...?alt=media&token=...`
    download URL that bypasses the auth header. Each uploaded object carries
  `cacheControl: public, max-age=31536000, immutable` so the CDN keeps
  edge copies indefinitely, plus custom metadata
  `sha256=<hex>` for the seed script's idempotency check and
  `firebaseStorageDownloadTokens=<uuid>` to mint the
  `https://firebasestorage.googleapis.com/...` download URL the app
  uses. The token-bearing URL works without an auth header (that's how
  Firebase Storage download tokens are designed); the
  auth-required rule still applies to any *non-tokened* access. Deploy:
  `firebase deploy --only storage`.
- **Firestore collections in use** (all read directly via real-time
  Firestore snapshots — no Drift mirror):
  - `users/{uid}` — `{hardwareId, platform, lastSeenAt, createdAt, previousHardwareIds[]}`.
    `hardwareId` is now the keychain-persisted **UUIDv4**, not
    `Build.ID` / `identifierForVendor` — see §5.3 step 3.
  - `users/{uid}/profile/current` — the user's `UniformProfile`. Written
    via `ProfileRepositoryImpl.upsert` from the **debounced auto-sync**
    inside `UniformProfileNotifier` (every setter, 500 ms after the
    last change) and by the Configuration wizard's awaited `persist()`.
    The `generatedDresses` map carries one entry per dress code the
    user has rendered: `{builtAt, modelUrl, profileHash,
    schemaVersion, generationStartedAt?, error?}`. The `modelUrl`
    points to `gs://…/user_models/{uid}/{dressCode}.glb` and is
    written by the `composeUniformModel` Cloud Function — the
    client only sets `generationStartedAt` (optimistic in-flight
    flag) and `error` (last failure for the UI to surface).
  - `users/{uid}/gallery/{photoId}` — per-photo metadata: `url` (String),
    `thumbnailUrl` (String), `uploadedAt` (Timestamp), `dressCode` (String,
    e.g. `"No3"` or empty). Written by `GalleryRepositoryImpl.uploadPhoto`;
    deleted by `deletePhoto`. Read by `watchPhotos()` as a Firestore
    real-time stream ordered by `uploadedAt` descending.
  - `device_registrations/{deviceId}` — admin-only, written exclusively
    by the `claimDeviceIdentity` and `markProfileComplete` Cloud
    Functions. Shape:
    `{uid, platform, profileComplete, createdAt, lastSeenAt}`. The
    client never reads or writes this directly.
  - `branch_configs/{branchId}` — authoritative branch config. Read by
    `BranchConfigRepository`.
  - `global_logic_rules/{ruleId}` — cross-branch rules. Currently:
    `medal_vertical_shift` (`{ params: { minRows, verticalShiftCmPerExtraRow } }`),
    consumed by `coordinateMapProvider` to push chest badges down when
    medal rows ≥ `minRows`. Read by `GlobalRulesRepository`.
  - `dress_requirements/{dressId}` — per-dress mandatory/optional rule
    definitions (headdress, identification, rank insignia, base
    accessories, optional vocation/skills/awards) plus an optional
    `branch_overrides` map keyed by `branchId` for per-branch
    divergence. All five dress codes (`no_1`..`no_5`) are read by
    `DressRequirementsRepository`.
  - `accessory_library/{accessoryId}` — per-accessory display metadata
    (`display_name`, `image_url`, `placement_diagram`) plus `rules` and
    `render_logic` blobs. Read by `AccessoryLibraryRepository`. The
    `image_url` and `placement_diagram` fields hold
    `https://firebasestorage.googleapis.com/...` URLs (auth-required)
    pointing to the per-id PNGs uploaded by `tool/seed_firestore.dart
    --upload-images` from `assets/accessories/<id>/{image,placement}.png`.
    Empty strings on entries whose images have not been sourced yet
    (legacy No.1/2/4/5 placeholders, plus any new doctrine-aligned entry
    awaiting an upload) — the app degrades gracefully to the category
    icon fallback. v3 holds
    82 entries grouped by `category` (e.g. `headdress_beret`,
    `headdress_sikh_turban`, `headdress_ladies_hat`, `cap_badge`,
    `cap_embellishment`, `epaulette`, `gorgette`,
    `sleeve_rank_specialist`, `sleeve_rank_enlistee`, `arms_badge`,
    `vocation_badge`, `name_tag`, `lanyard`, `belt`, `footwear`, `socks`,
    `medal_ribbons`, `saf_badge`, `foreign_badge`, `skill_tab`,
    `skill_badge`). For **No. 3 dress** entries are PDF-aligned per-branch
    + per-rank-tier (e.g. `army_sikh_turban_col_me7_above`,
    `navy_cap_embellishment_bg_me8_above`,
    `rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee`).
    For No. 1, 2, 4, 5 dress, the original generic entries
    (`beret_standard`, `turban_sikh`, `ladies_service_hat_a` /
    `_b`, `name_tag`, `epaulettes`, `gorgettes_ladies_only`,
    `rank_insignia_sleeve`, `arms_badge_vocation`, `lanyard_ma_sa`)
    remain as **legacy placeholders** (`render_logic.legacy_placeholder: true`),
    flagged "pending doctrine review" — `DressAccessoryResolver` filters
    them out so callers see only doctrine-aligned entries.
- **Operator-only seed script:** [`tool/seed_firestore.dart`](tool/seed_firestore.dart)
  is a pure-Dart Firebase Admin SDK script (no Flutter, no device, not in
  the app build graph). Reads `assets/data/*.v1.json` from disk and writes
  the four reference collections via `firebase_admin_sdk`. Admin-SDK auth
  bypasses Firestore security rules entirely, so the strict
  `firestore.rules` stay live during seed. Idempotent
  (`SetOptions.merge()`). Operator workflow:
  1. Firebase Console → `saf-uniforms` → Project settings → Service
     accounts → Generate new private key. Save the JSON outside the repo
     (or under `secrets/` — gitignored).
  2. `dart run tool/seed_firestore.dart <path/to/service-account.json>`.
  3. Confirm the printed counts (`branch_configs: ok (4 docs)`, etc.) and
     eyeball one doc per collection in the Console.

  **`--upload-images` flag (opt-in, but currently unreliable)**: in
  theory walks `assets/accessories/<id>/{image,placement}.png` and
  uploads each pair to
  `gs://<bucket>/accessories/<id>/<file>` via the Admin SDK's Cloud
  Storage client, then patches resolved URLs back into
  `assets/data/accessory_library.v1.json` before the Firestore batch
  fires. **In practice, Dart's shared HttpClient inside
  `google_cloud_storage` corrupts mid-stream after a handful of
  uploads** with `HttpException: Unexpected response (unsolicited
  response without request)`, and that exception escapes try/catch via
  an async stream callback. Use the Python uploader below instead;
  this Dart flag is left in place for small batches but should be
  considered legacy.

  **Real upload pipeline:** [`tool/upload_accessory_images.py`](tool/upload_accessory_images.py).
  Pure-Python urllib + openssl signing; uses the same SHA-256 idempotency
  contract and the same `firebaseStorageDownloadTokens` metadata the
  app expects. Operator workflow:
  ```bash
  GOOGLE_APPLICATION_CREDENTIALS=<svc-account>.json \
    python3 tool/upload_accessory_images.py \
      --bucket saf-uniforms.firebasestorage.app

  # Then push the patched JSON to Firestore (no flag required):
  dart run tool/seed_firestore.dart <svc-account>.json
  ```

  Per-id source-picture cheat sheet for the SAF No.3 Dress PDF is in
  [`assets/accessories/README.md`](assets/accessories/README.md).
  Diagrams that apply across multiple accessories
  (e.g. the male nametag positioning Picture C-6) are **duplicated**
  per-id rather than referenced via a shared folder, so each accessory
  subdir is self-contained.

  Once the web admin portal lands, both this script and the bundled JSON
  can be retired.

### 5.6 Routing — go_router
Constants in [`Routes`](lib/core/routing/routes.dart). Provider:
[`appRouterProvider`](lib/core/routing/app_router.dart). The router has
a `redirect:` driven by `authSessionProvider` (re-evaluated via
`refreshListenable` whenever the session mutates):

- `session == null` (cold start, never signed in): only `/` and
  `/config` are reachable; everything else bounces to `/`.
- `session.profileComplete == false` and the user navigates anywhere
  other than `/` or `/config`: bounce to `/config` so the wizard
  can't be skipped via deep link.

The router intentionally does **not** auto-redirect returning users
from `/` to `/dashboard` — `WelcomeScreen` owns that decision and
only navigates after its 1.5 s minimum-display window elapses (see
§ 5.3). Bouncing here would make Welcome flash and disappear before
users see it.

Current routes:

- `/` — `WelcomeScreen` (initial location). Owns the bootstrap
  pipeline (§ 5.3). For returning users with `profileComplete=true`
  it auto-routes to `/dashboard` after the min-display window; for
  new users it reveals a CTA that goes to `/config`.
- `/dashboard` — `DashboardScreen` with internal IndexedStack of 4 tabs
  (Home, Wardrobe, Gallery, Profile). Tabs are local UI state (not routes).
- `/config` — 4-step `ConfigScreen` wizard. On the final step it
  awaits `UniformProfileNotifier.persist()`, calls the
  `markProfileComplete` Cloud Function, writes
  `profileComplete=true` to local storage, and sets
  `authSession.copyWith(profileComplete: true)` before
  `context.go('/dashboard')`.
- `/checklist` — `ChecklistScreen` (accessory verification).
- `/ghost-model` — `GhostScreen` (Front/Back ghost figure + 6 hotspots).
- `/wearing` — `WearingGuideScreen` (9 dressing steps + completion view).
- `/ar` — `ARScannerScreen` (Phase 1 scanning placeholder + Phase 2 scorecard).
- `/generating?dress=No3` — `GeneratingScreen` (animated ring loader; auto-routes to `/ghost-model` on complete).
- `/rebuilding` — `RebuildingScreen` (5-row dress progress ring + auto-route to `/dashboard`).
- `/gallery/viewer` — `PhotoViewerScreen`. Expects `state.extra` as a Dart named-field record `({List<GalleryPhoto> photos, int initialIndex})`. Full-screen `PhotoViewGallery` with pinch-to-zoom, swipe between photos, share, and delete.

`Routes.home` and `Routes.profile` are kept as backwards-compatible
aliases (`home → welcome`, `profile → dashboard`).

### 5.7 Theming — per-branch + dark/light + DM Sans
Each branch (Army / Navy / RSAF / DIS) has a fixed `BranchTheme`
(see [branch_themes.dart](lib/core/theme/branch_themes.dart)) registered
as a `ThemeExtension`. The active theme is **resolved** by
`activeBranchThemesProvider`
([active_branch_theme_provider.dart](lib/core/theme/active_branch_theme_provider.dart))
which returns a `(light, dark)` `BranchTheme` record consumed by
[`SafUniformApp`](lib/app.dart). The resolver branches on
`themeAccentProvider`:

- `SafCrest()` (default) — returns the navy/gold SAF crest theme
  (`safCrestBranchTheme` / `safCrestBranchThemeDark` from
  [saf_crest_theme.dart](lib/core/theme/saf_crest_theme.dart)). The
  user's profile branch is unaffected — Firestore data, AR ghost
  models, and accessory IDs all keep using `currentBranchProvider`.
  Fresh installs (and any user who has never opened the Settings sheet
  to pick a service tile) land here.
- `FollowBranch()` — both variants are
  `branchThemeFor(currentBranch)`, so the visual theme follows the
  user's selected service. Opted into by tapping any of the four
  service tiles in the Settings sheet.

The Settings sheet's accent picker exposes 5 tiles: 4 branch tiles
(Army / Navy / RSAF / DIS — tapping sets `setBranch(b)` AND resets
`themeAccentProvider` to `FollowBranch`) and a SAF Crest tile (sets
`themeAccentProvider` to `SafCrest()` only). The choice is persisted
via `LocalStorageService.writeThemeAccent` (key `saf.themeAccent`,
values `"follow"` / `"saf_crest"`). On launch, the notifier's
`_userOverride` flag prevents an in-flight hydrate from clobbering an
explicit user tap (race fix).

The active brightness comes from `themeModeProvider`
(`NotifierProvider<ThemeMode>`, defaults to dark matching the Claude
Design).

Reading the branch palette inside any widget:

```dart
final ext = context.branchTheme;            // BranchTheme extension
final accent = ext.bright;                  // matches design's --accent-bright
```

`BranchTheme` exposes `branch`, `primary`, `accent`, `bright`,
`surfaceTint`, `ghostModelBg`, `rankInsigniaTint`. The `bright` field
maps to the design's `--accent-bright` CSS variable and is the colour
used for chips, active states, gradients, and highlights. Service
palette + tag values live in `ServicePalette`
([app_colors.dart](lib/core/design/app_colors.dart)). The `branch`
field on `BranchTheme` is consulted only by the theme system itself
(for `lerp`); the SAF Crest theme uses `BranchId.army` as a no-op
placeholder there.

Typography: `AppTheme` applies the DM Sans `TextTheme` via `google_fonts`
to every screen; `AppTextStyles.mono(...)` returns JetBrains Mono for
technical labels (eyebrows, status chips, cm dimensions).

Branding: the SAF crest renders via
[`SafCrestLogo`](lib/core/design/widgets/saf_crest_logo.dart) (one
widget, `withGlow: true` on the Welcome screen, `withGlow: false` in
the Dashboard app bar). The asset itself lives at
`assets/branding/saf_crest.svg` and is rendered through
`flutter_svg`, so it stays sharp at every density. The same crest
also serves as the launcher icon — `flutter_launcher_icons`
rasterizes `assets/branding/saf_crest_1024.png` into Android mipmap
PNGs and the iOS AppIcon set whenever
`dart run flutter_launcher_icons` is invoked.

### 5.8 Localization
- ARBs: `lib/core/l10n/arb/app_en.arb`, `app_zh.arb`.
- `l10n.yaml` drives generation into `lib/core/l10n/generated/`.
- `MaterialApp.router` wires `AppLocalizations.localizationsDelegates` and
  `supportedLocales`. App title is i18n-driven via `onGenerateTitle`.

### 5.9 Error handling pattern
Use [`Result<T>`](lib/core/error/result.dart) and the sealed
[`Failure`](lib/core/error/failure.dart) hierarchy at repository / service
boundaries. Widgets / notifiers should `switch` on `Result` rather than
catching raw exceptions in the UI layer.

---

## 6. Conventions

- **Imports:** relative imports inside the same feature; absolute
  `package:saf_uniforms/...` only from `test/`.
- **Naming:**
  - Files / dirs: `snake_case.dart`.
  - Classes: `UpperCamelCase`. Enum values: `lowerCamelCase`, with a stable
    `wireName` for serialization (see `BranchId`, `DressCode`).
  - Private providers/classes prefixed with `_`.
- **Codegen files** (`*.g.dart`, `*.freezed.dart`) are committed but never
  hand-edited.
- **Tests** live under `test/` and mirror `lib/`'s path. Use
  `ProviderContainer` directly for unit tests of notifiers (see
  [test/features/profile/uniform_provider_test.dart](test/features/profile/uniform_provider_test.dart)).
- **No print statements** — use `dart:developer`'s `log()` per § 1.3.

---

## 7. Common workflows

```bash
# Install / update deps
flutter pub get

# Regenerate Riverpod / Freezed / json_serializable / Drift
flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate localizations
flutter gen-l10n

# Static analysis
flutter analyze

# Run tests
flutter test

# Run on device / simulator
flutter run
```

---

## 8. Known gaps / TODOs (informational)

These are not policies, just pointers for whoever picks up the next plan:

- The 3D viewport in
  [`GhostScreen`](lib/features/ar_engine/presentation/screens/ghost_screen.dart)
  renders a per-user composed GLB via `model_viewer_plus` (drag-rotate,
  pinch-zoom, free WebXR AR mode). The Front/Back toggle drives the
  ModelViewer's camera orbit between `0deg` and `180deg`. The 6-hotspot
  pin overlay is preserved on the front + ready state. The composition
  pipeline is **Phase-2 multi-asset** — the `composeUniformModel` Cloud
  Function, via the helpers in
  [`functions/src/glb_compose.ts`](functions/src/glb_compose.ts), merges
  the body GLB with the matching uniform GLB, re-parents each accessory
  under its declared socket bone (`render_logic.anchor` —
  `head_top` / `left_chest_pocket` / `belt_center` / …) with cm offsets
  applied, detaches the `hair` sub-mesh when a headdress is mounted,
  bakes the user's surname onto the `name_tag_mat` material's
  base-color texture via `sharp`, then runs Draco mesh compression +
  WebP texture compression. Each step is wrapped in try/catch so a
  single bad asset (missing socket, malformed GLB, sharp failure)
  degrades gracefully rather than failing the whole composition.
  **Demo readiness:** the
  `assets/3d/bodies/{male,female,female_maternity}_apose.glb` files
  ship as algorithmically-generated placeholders produced by
  [`tool/generate_placeholder_bodies.py`](tool/generate_placeholder_bodies.py)
  — they already satisfy the Phase-2 contract (11 named socket markers
  + `name_tag` mesh + `name_tag_mat` material with a 1024×256 white
  base-color texture), so the merger runs end-to-end against placeholders
  while real artist authoring is in progress. Real artist GLBs land
  as drop-in replacements per
  [`docs/3d-body-authoring.md`](docs/3d-body-authoring.md) — same
  filenames, no code changes. **Tripo3D** (or similar generative-3D)
  exports are normalised + injected with the 11 contract sockets +
  name-tag material via [`tool/inject_sockets.py`](tool/inject_sockets.py)
  (chest-side socket Z-offsets are anatomic constants, not bbox
  fractions — Tripo's A-pose body depth ~0.64 m would otherwise put
  chest features ~25 cm in front of the shirt surface). The current
  live `gs://…/models/bodies/male_apose.glb` is a Tripo-generated
  body run through inject_sockets; female + maternity remain on the
  procedural placeholders. Uniform GLBs
  (`models/uniforms/{branch}_{no1..no5}_{gender}.glb`) are still
  **unpopulated** pending artist deliveries; the merger logs
  `uniform GLB missing; body-only composition` and proceeds. Accessory
  GLBs (`models/accessories/{accessoryId}.glb`) are populated for **55
  No.3 categories** by [`tool/generate_placeholder_accessories.py`](tool/generate_placeholder_accessories.py)
  (procedural geometric stand-ins — berets, sikh turbans, ladies hats,
  cap badges, cap embellishments, sleeve insignia stripes, epaulettes,
  lanyards, arms badges, vocation badges). The full uniform namespace
  is 4 branches × 5 dress codes × 3 genders = 60 slots; Phase-2 ships
  the merger for all 60, but the initial artist deliverable target is
  the 12 No.3 uniform files. Each future dress code is an asset-only
  follow-up — no merger or Cloud-Function changes are needed when
  No.1/2/4/5 land.
- Universal base accessories (belt, socks, footwear) live inside each
  branch's `branch_overrides[branchId]` entry — same values across
  branches today, but the duplication keeps the resolver's source of
  truth in one place (the Wardrobe UI groups them alongside every
  other mandatory accessory). The body now exposes 15 sockets (was
  11): the original 11 plus `left/right_ankle` (for socks) and
  `left/right_foot_top` (for shoes). The merger's `PAIRED_SOCKETS`
  map resolves the generic library anchors `ankle` and `foot_top` to
  the canonical left/right pair (mirror semantics). Placeholder
  geometry for belt (torus), socks (cylinder), and shoes (sole +
  upper + optional heel) lives in `tool/generate_placeholder_accessories.py`.
  The artist `leather_shoes_low_cut.glb` ships a **single shoe**
  centred at origin; its `render_logic` uses the generic `foot_top`
  anchor with `mirror_left_right: true` so the merger attaches a
  mirrored copy under both `left_foot_top` and `right_foot_top`
  (right copy carries `scale=[-1,1,1]`). Earlier (2026-05-13) the
  file was assumed to pack both shoes in one mesh; the 2026-05-17
  device test proved otherwise — see
  [ChangeRequest/2026-05-17_army-no3-placement-fix-pass2.md](ChangeRequest/2026-05-17_army-no3-placement-fix-pass2.md).
  Note also that on the Tripo-derived `male_apose.glb` the head's
  hair is part of the head mesh (no separate `hair` node), so
  `detachNodeByName(body, "hair")` is a no-op; the current
  mitigation is a larger beret (`--target-size 0.26` on injection)
  that covers the residual hair geometry.
- **Army No.3 male body / uniform alignment** (2026-05-17 pass 3,
  `ChangeRequest/2026-05-17_army-no3-body-uniform-alignment.md`): the
  live `assets/3d/bodies/male_apose.glb` through 2026-05-17 morning was
  a corrupted flat-strip placeholder (62 k verts collapsed onto z=0,
  plus the 18 socket markers floating at proper anatomic positions).
  Whatever generated that file is gone — re-running the current
  `tool/inject_sockets.py --target-height 1.78` against
  `assets/3d_raw/male_apose_tripo_source.glb` produces a properly 3-D
  body (~37 cm × 178 cm × 64 cm). Separately, the Tripo-derived uniform
  GLBs ship at the source's native scale (~0.98 m); they MUST be
  normalised to 1.78 m and re-centred on x/z (feet at y=0) before the
  merger's socket positions line up — done for `army_no3_male.glb` via
  a one-off `trimesh` scale-and-translate (backed up to
  `assets/3d_raw/army_no3_male_source.glb`). A formal
  `tool/inject_uniform.py` should be authored when more uniforms land —
  tracked in the un-executed
  `ChangeRequest/2026-05-17_inject-uniform-tool.md` follow-up plan.
  **Pass 4 (2026-05-17,
  `ChangeRequest/2026-05-17_army-no3-uniform-y-flip.md`):** the
  Tripo-derived uniform was additionally modelled back-to-camera —
  body faces +Z but `army_no3_male.glb` faced −Z, so every accessory
  anchored at a front-facing socket (`cap_band_front`, chest pockets,
  `name_tag` at +0.105 m, `belt_center` +Z offset, lanyard shoulder
  +Z arc) was placed on the back of the rendered shirt. Fixed by a
  one-off 180° Y rotation + recentre on x/z applied to the uniform
  GLB in place. The proper repeatable normaliser is the
  `tool/inject_uniform.py` follow-up plan above. `MODEL_BUNDLE_VERSION`
  bumped 7 → 8 (both `functions/src/profile_hash.ts` and
  `lib/features/ar_engine/data/profile_hash.dart`) to invalidate every
  cached per-user GLB.
  **Pass 5 (2026-05-17,
  `ChangeRequest/2026-05-17_army-no3-pass5-hierarchy-fix.md`):** the
  pass-4 device test revealed the model rendered in profile on
  initial GhostScreen load (mouth pointing camera-right at
  `cameraOrbit: '0deg 90deg 4m'`). Per-geometry world-bbox analysis
  found that both the body's "body" mesh and the uniform's mesh
  have X-span < Z-span — i.e., Z is the shoulder/arm-span axis and
  X is the front-back axis, so both meshes face along ±X (the body
  specifically at +X per user observation). But
  `inject_sockets.py` placed every front-side socket at +Z thinking
  the body faces +Z. Net result: sockets land on the body's SIDE
  in render-space, not its front. The earlier "force=mesh" nose
  test reported nose at +Z because the 1cm-wide socket marker
  cubes at +Z dominated the head slice's +Z extreme; the actual
  body-mesh face axis is ±X. Fixed by rotating the body's "body"
  mesh by −90°Y (face: +X → +Z) and applying a 90° net rotation
  to the uniform (face: +Z), both baked into vertex coords;
  sockets and head/hair marker cubes untouched. Also added
  `consolidateScenesToOne` to `glb_compose.ts`'s `compressForWeb`
  cleanup pass — `mergeDocuments` was leaving secondary scenes on
  the merged Document (one per merged source = body + uniform + N
  accessories), and renderers that only render the default scene
  were missing the uniform / accessory geometry. `MODEL_BUNDLE_VERSION`
  bumped 8 → 9 to invalidate every cached per-user GLB.
  **Pass 6 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass6-placement-tuning.md`):** the
  pass-5 device test (model now face-forward) revealed four remaining
  placement issues. (1) Only ONE rank chevron rendered — `mirror_left_right`
  applied `setScale([-1, 1, 1])` to the right-side wrapper, inverting
  triangle winding; with the default material's back-face culling the
  mirrored copy was invisible. Pass 6 **removed the negative scale**;
  both copies now attach with identity scale. Symmetric placeholder
  meshes (chevrons) read correctly on both sides; asymmetric ones
  (single-sided shoes) appear the same on both feet — acceptable until
  L/R pairs are authored. (2) Chevron landed on the chest pocket
  area, not the upper arm — `left/right_sleeve_upper` sockets moved
  from `(±0.183, 1.388, +0.10)` to `(±0.30, 1.30, 0.0)`. (3) Body's
  bare-skin feet showed through the shoe mesh — sliced the body's
  monolithic Tripo mesh at `y=0.10m`, with vertices below moved into
  a new `feet` sub-node. New `FEET_NODE` constant in `glb_compose.ts`
  and a feet-detach block in `composeUniformModel.ts` (parallel to
  the existing hair-detach when a headdress mounts) drops the feet
  whenever a `category === "footwear"` accessory is included.
  (4) Sparkly star/asterisk near the wearer's right cheek was
  `army_arms_badge` (anchored at `right_collar_tip` with `offset_y_cm: +1.5`
  putting it at chin height) — offset changed to `-3.0` so the badge
  drops onto the shirt's collar tip. Additionally, **stripped marker
  mesh references** from every socket node except `body`, `feet`,
  `name_tag` (the 8-vert marker cubes that `inject_sockets.py` added
  for socket-position visualisation were rendering as visible dark
  bumps on the shoulders/collar). And **`nylon_belt.offset_z_cm`**
  -2.0 → -3.0 to pull the belt flush against the trouser surface.
  `MODEL_BUNDLE_VERSION` bumped 9 → 10.
  **Pass 7 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass7-accessory-details.md`):**
  nine per-accessory detail fixes on top of pass-6.
  (1) `leather_shoes_low_cut.glb` shipped as a pair — sliced at x=0
  so only one shoe remains; the merger's mirror_left_right (identity
  scale per pass-6) attaches one copy under each foot_top socket.
  (2) `army_beret.glb` rendered green (Tripo texture tint) —
  overrode the material's `baseColorFactor` to (0.05, 0.05, 0.05, 1.0)
  and dropped the texture so it reads matte black; same treatment
  applied to `nylon_belt.glb`.
  (3) `army_lanyard_sa_ma.glb` was hanging upside-down — rotated
  180° around X (top↔bottom flip).
  (4) `nylon_belt.glb` rotated 180° around Y so the buckle moves
  from -Z to +Z (front-facing).
  (5) `black_socks.glb` was a 42-vert placeholder cube — replaced
  with a proper cylinder (radius 0.05m, height 0.10m, flat black).
  (6) Body `name_tag` socket moved from y=1.228 → y=1.345 (above the
  chest pocket at y=1.282).
  (7) `army_arms_badge.render_logic.offset_z_cm`: 0 → -3.0 (pull
  the badge back toward the body's surface).
  (8) `army_cap_badge_sltc_me6_below.render_logic.offset_z_cm`:
  +1.5 → +3.0 (push the badge forward through the beret dome so it's
  visible on the front face).
  `MODEL_BUNDLE_VERSION` bumped 10 → 11.
  **Pass 8 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass8-doctrine-alignment.md`):**
  user shared the SAF Army No.3 doctrine reference image and called
  out three corrections.
  (1) Name plate was on the opposite (wearer's left) chest pocket.
  Confirmed empirically that this body GLB's socket naming
  convention has world +X = wearer's LEFT side (camera-right side
  of screen). Flipped body `name_tag` socket X from +0.0599 to
  −0.0599 so the name plate lands on the wearer's right chest
  pocket per doctrine.
  (2) Beret-still-green complaint is a cache / not-yet-rebuilt
  issue (the `army_beret.glb` material was already overridden to
  flat black in pass-7 — verified via direct GLB inspection). Bundle
  bump force-flushes both the per-user composed GLB cache and
  forces the device's compile-time `kModelBundleVersion` to update
  on next `flutter run`.
  (3) Lanyard wasn't attaching at the shoulder — after pass-7's
  180°X flip, the loop sits 8 cm above the shoulder seam with
  `offset_y_cm: −22`. Tuned to `−30` so the loop now lands at
  world y = 1.477 + 0.30 − 0.30 = 1.477 = shoulder height ✓.
  `MODEL_BUNDLE_VERSION` bumped 11 → 12.
  **Pass 9 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass9-hair-detach-belt-scale.md`):**
  user reported "two berets — green and black" after the pass-8
  rebuild. The green dome was actually the body's scalp region:
  the Tripo material's texture tints the head's hair area
  green-khaki, and the black beret only partially covered it.
  Pass-6 had already split the body into `body` + `feet` and pass-7
  stripped the marker mesh refs (including from the `hair` node),
  so `composeUniformModel`'s hair-detach-on-headdress logic found
  the `hair` node but it had no geometry to drop — the actual hair
  vertices lived in the `body` mesh. Re-sliced `body` at y=1.65
  (above brow / eyebrow line): vertices at or above that cut
  moved into a real `hair` sub-mesh. Now `detachNodeByName(body,
  "hair")` actually removes the scalp geometry when a beret mounts,
  and only the black beret is visible on the head.
  Also scaled `nylon_belt.glb` 1.6×1.5×1.0 → 48 cm × 10.5 cm ×
  7 cm so the belt appears more prominent on the waist.
  `MODEL_BUNDLE_VERSION` bumped 12 → 13.
  **Pass 10 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass10-beret-belt-final.md`):**
  user reported the green dome above the beret was STILL visible
  after pass-9, despite the body's main mesh being cleanly cut at
  y=1.659 and hair-detach firing. Root cause: Tripo's
  `normalTexture` + `metallicRoughnessTexture` were still embedded
  in `army_beret.glb` (pass-7 had only stripped `baseColorTexture`),
  and PBR shading on those bump-map channels was producing a green
  tint where lighting hit the rim. Fixed by stripping ALL textures
  + ALL images from the beret GLB and resetting materials to a
  plain `baseColorFactor=[0.02, 0.02, 0.02, 1.0]`,
  `metallicFactor=0`, `roughnessFactor=0.9`. No PBR data left that
  can introduce a tint. Also scaled the beret 1.3× → 32 cm × 21 cm
  × 34 cm + bumped `offset_y_cm` -4 → -7 so the rim covers the
  brow / temple. Replaced `nylon_belt.glb` with the user-provided
  wrap-around belt (`/Users/meet/Documents/accessories/nylon_belt.glb`,
  24 × 22 × 98 cm), stripped textures, recoloured matte black; tuned
  `offset_y_cm: 0 → -11` and `offset_z_cm: -3 → -16` to centre the
  wrap-around on the waist. `MODEL_BUNDLE_VERSION` bumped 13 → 14.
  **Pass 11 (2026-05-18,
  `ChangeRequest/2026-05-18_army-no3-pass11-beret-from-scratch.md`):**
  the Tripo `army_beret.glb` kept bleeding a green tint even after
  pass-10's "strip all textures + flat-black material" treatment.
  Decided to discard the Tripo source entirely and **rebuild the
  beret from scratch** using trimesh primitives (hemisphere dome +
  brim ring, 22×16×22 cm). The new GLB has vertex colors
  `(12,12,12,255)` on every vertex AND an explicit `beret_black`
  PBR material — triple-layered guarantee of flat-black rendering.
  Also tuned `offset_y_cm: -7 → -16` so the brim sits at brow level.
  **Removed the body's `hair` sub-mesh entirely** (pass-9 had sliced
  it out as a detachable sub-node but the green source kept
  re-appearing); the body's max_y is now 1.659 (forehead/temple),
  with no green-tinted scalp geometry anywhere. Tuned
  `nylon_belt.offset_y_cm: -11 → -3` (the belt was below the shirt
  hem and occluded). Moved body `name_tag` socket from
  `(-0.060, 1.345)` to `(-0.075, 1.36)` per user request to nudge
  the plate inboard + lift slightly. `MODEL_BUNDLE_VERSION` bumped
  14 → 15.
- **Army No.3 male** doctrine-aligned placement, current values after
  2026-05-17 pass 2
  (`ChangeRequest/2026-05-17_army-no3-placement-fix-pass2.md`,
  supersedes `2026-05-13_army-no3-placement-fix.md`):
  - `army_beret` anchors at `head_top` with `offset_y_cm: -4.0`; the
    GLB was re-injected via `--target-size 0.26` so the rim is wide
    enough to cover the residual hair geometry on the Tripo body
    (~24 cm rim diameter).
  - `army_cap_badge_sltc_me6_below` anchors at `cap_band_front` with
    `offset_y_cm: -1.0` and `offset_z_cm: 1.5` (sits on the band of
    the bigger beret).
  - `army_enlistee_insignia` anchors at `sleeve_upper` with
    `mirror_left_right: true`; the artist GLB carries the prior
    `--rotate-y 90` so the chevron's flat face points ±X (outward
    from arm).
  - `army_lanyard_sa_ma` re-injected with `--rotate-y 180` (on top of
    the prior `--rotate-z 90`) so the loop curves toward the right
    pocket button instead of leftward across the chest. `render_logic`
    uses `side: right` (resolves to `right_shoulder_seam`) with
    `offset_y_cm: -22` (was -12 — see pass 4 below; the loop's forward
    Z-arc was intersecting the camera sightline at face height under the
    smaller drop) and `offset_z_cm: 4`.
  - `nylon_belt` anchored at `belt_center` with `offset_z_cm: -2`
    (was -5 — pulled too deep into the torso; the GLB's Z half-extent
    is only 3.7 cm).
  - `leather_shoes_low_cut` ships as a **single shoe**, anchored at
    the generic `foot_top` with `mirror_left_right: true` and
    `offset_y_cm: 3` (sole rests on ground); the merger attaches a
    mirrored copy under both `left_foot_top` and `right_foot_top`.
  - Remaining branches (Navy, RSAF, DIS) and dresses (No.1/2/4/5) still
    use the unrefined defaults from the pre-2026-05-13 schema; a
    follow-up plan will retune them per-branch.
- Still out of scope for the No.3 placeholder population: medal
  ribbons / SAF badges / foreign badges (no `anchor` field on those
  library entries — they need stack-layout logic that depends on
  `medalRowCount`), gorgettes (officer / cadet only; per-rank-tier
  placement), and collar rank pins (officer only; needs a new
  collar-mid socket). These render cleanly via the existing
  graceful-degradation path (logged + skipped) and ship later.
- Full coordinate-map math (medal positions, rank insignia, sikh turban
  projection) currently lives inline in `calculateCoordinateMap`; expected
  to graduate to a dedicated `CoordinateMapCalculator`. Vertical Shift for
  chest badges is already wired via `MedalVerticalShiftRule`.
- `accessory_library` and `dress_requirements` are read directly from
  Firestore by `AccessoryLibraryRepository` and
  `DressRequirementsRepository`. **No. 3 dress** is aligned with the
  official PDF specification (per-branch + per-rank-tier headdress / cap
  badges / cap embellishments / sleeve insignia / lanyards / epaulettes
  / arms or vocation badges for Army, Navy, RSAF, DIS — see
  [ChangeRequest/2026-05-02_no3-dress-asset-alignment.md](ChangeRequest/2026-05-02_no3-dress-asset-alignment.md)).
  No. 1, 2, 4, 5 still reference legacy generic placeholder accessories
  (`beret_standard`, `turban_sikh`, `ladies_service_hat_a` / `_b`,
  `name_tag`, `epaulettes`, `gorgettes_ladies_only`,
  `rank_insignia_sleeve`, `arms_badge_vocation`, `lanyard_ma_sa`)
  pending their own doctrine PDFs.
- Accessory imagery (`image_url` + `placement_diagram` on
  `accessory_library` docs) is sourced from the **SAF No.3 Dress** PDF
  and uploaded to Firebase Storage by
  `tool/seed_firestore.dart --upload-images` reading from
  `assets/accessories/<id>/{image,placement}.png` (see
  [ChangeRequest/2026-05-04_no3-accessory-images.md](ChangeRequest/2026-05-04_no3-accessory-images.md)).
  The committed PNGs are a first pass extracted programmatically from
  the doctrine PDF via
  [`tool/extract_pdf_accessories.py`](tool/extract_pdf_accessories.py)
  — quality matches the source PDF (low-to-medium DPI raster). Higher-res
  or vector replacements should drop into the same paths when available.
  Until an operator runs `tool/seed_firestore.dart --upload-images`,
  the `accessory_library` docs ship empty URL strings and the app falls
  back to the category icon in `CheckCard` / `AccessoryDetailSheet`.
  Legacy No.1 / 2 / 4 / 5 entries will stay empty until their doctrine
  PDFs land.
- `DressRequirement.mergedFor(BranchId)` only swaps top-level
  `mandatory_rules` / `optional_logic` lists when a branch override
  supplies them. The richer No.3 structured keys
  (`branch_overrides[branchId].headdress`, `cap_badge`,
  `cap_embellishment`, `rank_insignia_sleeve.specialist` / `.enlistee`,
  `epaulettes`, `name_tag`, `lanyard`, `arms_badge`, `vocation_badge`) are now
  consumed by `DressAccessoryResolver` /
  `dressAccessoriesProvider`. The remaining structured keys
  (`collar_offset_cm`, `collar_offset_cm_with_arms_badge`,
  `arms_badge_extra_offset_from_tip_cm`, `ladies_belt_alignment`,
  `lanyard_left_side_for`, `name_tag_protocol`, `no_arms_badge`) are
  stored verbatim and not yet consumed — they will feed
  `coordinateMapProvider` once 3D placement math graduates to a
  dedicated calculator.
- The Wardrobe tab is the live consumer of the dress + accessory data
  layer: it reads `dressRequirementsAllProvider`,
  `dressAccessoriesByIdProvider`, `allDressesAccessoriesCombinedProvider`,
  and `wardrobeProgressProvider`, and persists per-dress checks via
  `UniformProfileNotifier.toggleDressAccessory` /
  `setDressAccessoryChecked`. The standalone `/checklist` route still
  uses the static `AccessoryItem.all(l)` view-models from l10n; that
  legacy screen is no longer reachable from any user path and will be
  retired or converted to dynamic data in a follow-up plan.
- `flutterfire configure --project=saf-uniforms` must be run before the
  app can boot — `lib/firebase_options.dart` ships as a placeholder
  that throws `UnimplementedError`. Separately,
  `dart run tool/seed_firestore.dart <service-account.json>` is a
  one-off operator action to push `assets/data/*.v1.json` into the
  cloud project (admin SDK; bypasses rules), and
  `firebase deploy --only functions,firestore:rules` must be run once
  before the device-bound identity flow will work.
- **Android reinstall recovery** is now hardware-bound via
  `Settings.Secure.ANDROID_ID` (converted to UUID v5). This survives
  uninstall + reinstall regardless of Auto Backup. iOS uses
  `identifierForVendor` for the same guarantee. Both platforms still
  cache the derived UUID in `flutter_secure_storage` for fast reads
  on subsequent launches. See
  [ChangeRequest/2026-05-04_stable-device-id.md](ChangeRequest/2026-05-04_stable-device-id.md).
- The Profile tab and Config wizard now persist `fullName`, `vocation`,
  `medalRowCount`, and `selectedBadgeIds` through the notifier (see
  [ChangeRequest/2026-05-02_persist-name-medals-badges.md](ChangeRequest/2026-05-02_persist-name-medals-badges.md)).
- Camera + pose detection deps are present (`camera`,
  `google_mlkit_pose_detection`, `permission_handler`) but the new
  `ARScannerScreen` is a placeholder UI — no real camera feed or pose
  detection yet.
- The Wearing Guide voice narration is a no-op stub
  ([`WearingGuideScreen`](lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart));
  TTS will land separately.
- Logging is sparse; bring it up to policy 1.3 as you touch each method.
