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
│   ├── upload_accessory_images.py     # Python uploader for `assets/accessories/<id>/{image,placement}.png` → Firebase Storage. Replaces the broken Dart upload path. Idempotent via per-object SHA-256 metadata. Also uploads `<variant>_{image,placement}.png` files (same Storage folder, flat names — fits the existing rule) and records them in the entry's `dress_images[<variant>]`. Run with `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_accessory_images.py --bucket saf-uniforms.firebasestorage.app`.
│   ├── extract_pdf_accessories.py     # One-shot Python tool: crops per-accessory PNGs out of the rendered SAF No.3 Dress PDF and writes them to `assets/accessories/<id>/{image,placement}.png`. Re-run when the doctrine PDF changes; details in `assets/accessories/README.md`.
│   ├── extract_pdf_accessories_no4.py # No.4 sibling of the above: renders exact clip rectangles (PDF points) out of the SAF No.4 Dress PDF with PyMuPDF (`.venv-tools/bin/pip install pymupdf`; no `pdftoppm` needed) and writes `assets/accessories/<id>/{image,placement}.png` for the No.4-only ids. Shared No.3 items keep their No.3 pair; their No.4 pictures (per service where the PDF has them — name tape, Singapore tag, chest / sleeve / foreign badge layouts, berets, turbans) go to `<id>/<variant>_{image,placement}.png`, variant `no4` or `no4_<branch>` (`MANIFEST_NO4_VARIANTS`; also feet / head / neckline crops of the full-uniform figures as placement for boots, socks, RSAF jockey cap, DIS inner T-shirt). Run via `.venv-tools/bin/python tool/extract_pdf_accessories_no4.py <SAF_No_4_Dress.pdf>`.
│   ├── extract_glb_reference.py       # Offline GLB reference-manifest CLI. Runs `python3 tool/extract_glb_reference.py --directory assets/3d/bodies --out /tmp/saf-glb-manifest.json` and records hierarchy, world transforms, mesh bounds/counts, material/texture presence, skin/animation metadata, and the 15 known anchors. Anchor nodes are explicitly marked even when an exporter gives them tiny helper geometry; they are not treated as doctrine-approved accessory meshes.
│   ├── generate_placeholder_bodies.py # Python (trimesh + Pillow) generator for stand-in humanoid GLBs. Outputs `assets/3d/bodies/{male,female,female_maternity}_apose.glb` + `assets/3d/placeholder.glb`. Composes primitives (head sphere, torso box, arms, legs, beret, name-tag patch, medal ribbons) per variant, plus a textured `name_tag` mesh with a `name_tag_mat` material (1024×256 white base-color texture — Phase-2 bake target) and 11 named socket markers (`head_top`, `cap_band_front`, `left/right_collar_tip`, `left/right_chest_pocket`, `left/right_shoulder_seam`, `left/right_sleeve_upper`, `belt_center`) that the merger looks up by name. Visibly humanoid but explicitly NOT production. Run via `python3 -m venv .venv-tools && .venv-tools/bin/pip install trimesh numpy Pillow && .venv-tools/bin/python tool/generate_placeholder_bodies.py`. Replace with real MakeHuman exports per `docs/3d-body-authoring.md` when ready.
│   ├── generate_placeholder_accessories.py # Python (trimesh) generator for procedural accessory GLBs. Reads `assets/data/accessory_library.v1.json`, dispatches each non-legacy entry to a per-category builder (beret = truncated cone, sikh turban = ovoid, cap badge = flat oval gold, sleeve insignia = chevron stripes, epaulette = slab, lanyard = cord + loop, etc.), writes `assets/3d/accessories/{id}.glb` centred on origin. The merger applies the per-anchor offset translation when re-parenting under a body socket. Each placeholder is visibly distinct + branch-coloured but obviously not production. Output: 55 GLBs covering headdress / cap badges / cap embellishments / sleeve insignia / epaulettes / lanyards / arms badges / vocation badges. Also builds belt / socks / footwear (No.4 boots get a shaft via `render_logic.style: boot_high|boot_mid`), `rank_epaulette_chest` and `sleeve_patch`. Skips out-of-scope categories (gorgettes, medal_ribbons, etc.). Run via `.venv-tools/bin/python tool/generate_placeholder_accessories.py --only-missing` — **always pass `--only-missing`**: without it the script overwrites every GLB, including the hand-tuned / artist files (`army_beret`, `nylon_belt`, `leather_shoes_low_cut`, …).
│   ├── inject_accessory.py            # Python tool that takes a raw artist-authored accessory GLB (Tripo / Meshy / Luma export, arbitrary scale + orientation) and emits a contract-compliant accessory GLB ready to drop under `assets/3d/accessories/{id}.glb`. Loads via `trimesh.load(force="mesh")` to bake node transforms, auto-orients so the bbox's thinnest extent aligns with Z (so the accessory's flat face points +Z, matching the merger's body-front sockets), scales uniformly to a target size (default 5 cm widest dim — appropriate for cap badges; bump to 0.07-0.20 m for sleeve insignia / headdress), and recentres at origin so the merger's per-accessory `render_logic.offset_*_cm` translation lands as designed. CLI: `--in <raw.glb> --out <accessory.glb> [--target-size METRES] [--rotate-{x,y,z} DEG] [--no-auto-orient]`. The `--rotate-y 180` flag is the one-flag fix when the auto-oriented badge ends up facing the camera-back rather than camera-front. Raw artist sources are preserved at `assets/3d_raw/` (gitignored).
│   ├── prepare_unified_figure.mjs     # Node (gltf-transform from `functions/node_modules`) prep for artist-delivered *dressed figures* (body + uniform + modelled accessories in one GLB) bound for the unified `models/bodies/{branch}_{dress}_{gender}.glb` path. Keeps the scene graph intact, unlike `inject_sockets.py`, which flattens. It does four things:
│   │                                  #   - adds the 15 sockets + `name_tag`, measured from the figure's own parts;
│   │                                  #   - solves the sockets a replacement accessory may use (`head_top`, `cap_band_front`, `belt_center`) so the replacement lands on the built-in part;
│   │                                  #   - groups multi-node parts (rank tab + insignia);
│   │                                  #   - blanks, V-flips and renames the name tape to `name_tag_mat` so the surname bakes upright, and writes `extras.saf_baked_slots`.
│   │                                  #   Per-figure config: `assets/3d/figures/<figure>.json`. Run `node tool/prepare_unified_figure.mjs --config assets/3d/figures/rsaf_no4.json --in assets/3d_raw/rsaf_no4_male_source.glb --out assets/3d/bodies/rsaf_no4_male.glb`.
│   ├── inject_sockets.py              # Python tool to make a raw Tripo / Meshy / Luma body GLB satisfy the Phase-2 merger contract. Loads via `trimesh.load(force="mesh")` (bakes node transforms), normalises to target height (default 1.75m) with feet at y=0 and centred on x/z, then injects 14 named scene-graph nodes via `transform=` parameter on `add_geometry` so the SOCKET NODE TRANSFORMS carry the world position (NOT vertex coordinates — the merger's `socket.addChild(accRoot)` inherits world transform). Front-side socket Z-offsets are anatomic constants (chest=0.10m, head_front=0.08m, name_tag=0.105m), NOT bbox fractions, because Tripo bodies' A-pose depth (~0.64m) would otherwise put chest features ~25cm in front of the shirt surface. Supports `--up-axis {y,z,-z}` for non-glTF-standard exports and `--target-height` to override the 1.75m default (use 1.65 for female / maternity).
│   └── upload_models.py               # Python uploader for `assets/3d/**/*.glb` → Firebase Storage `models/**`. Mirrors `upload_accessory_images.py`'s pattern (urllib + openssl signing, idempotent SHA-256, persistent download tokens). Run via `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app`. Supports `--dry-run` and `--only <glob>` for targeted uploads.
├── functions/             # Firebase Cloud Functions (TypeScript, Node 20). Three HTTPS callables: `claimDeviceIdentity` and `markProfileComplete` back the device-bound identity flow; `composeUniformModel` runs the Phase-2 multi-asset 3D merger (uniform + accessories + name-tag bake + Draco/WebP compression) via the helpers in `src/glb_compose.ts`. Deployed via `firebase deploy --only functions`. Tests: `npm test` (Node 20 built-in `node:test` runner over `lib/*.test.js`).
├── admin-portal/          # Angular 20 SSR admin portal (standalone components, routing, SCSS). Lives entirely in its own folder with its own `package.json` / `tsconfig.json` / `node_modules/`. Wired via AngularFire 20 to the same `saf-uniforms` Firestore + Storage + Auth + Functions (region `asia-southeast1`) as the Flutter mobile app. SSR routes are all `RenderMode.Client` — the SSR server just ships the shell; live Firebase reads happen client-side. Deployed to **Firebase App Hosting** (Cloud Run-backed) via `apphosting.yaml` + GitHub auto-deploy. **Phase 1 foundation (current state):** Claude Design CSS ported verbatim to `src/styles/_tokens.scss` + `_design.scss` (light/dark via `[data-theme="..."]`); **ngx-translate** i18n (English only today via `public/i18n/en.json`; structurally ready for more); **ThemeService** (`'dark' | 'light' | 'system'`, persists to `localStorage`); **ToastService**; **AuthService + auth guard** over AngularFire Auth; **`<app-icon>` component** with all 41 SVGs; **15 UI primitives** (Button / Chip / Card / Field / Input / Select / Toggle / PillToggle / Modal / Avatar / BranchDot / Eyebrow / MonoTag / EmptyState / PageStub); **responsive shell** (sidebar 240 px on desktop, slide-over below 1023 px, bottom mobile nav + "More" overflow modal); **MockDataService** mirroring the JSX `data.jsx` shapes for all 11 reference collections (swap to AngularFire-backed implementations in a follow-up plan with no caller changes). **All 10 routes fully designed against the Claude Design handoff** (no stubs remain): `/login` (centred crest card + sign-in form), `/dashboard` (5-card stat grid + activity list + quick actions + coverage matrix), `/dress` (filterable card grid), `/dress/add` (3-step PDF wizard with animated AI scan overlay → review pane → finalise pane), `/dress/:id` (review pane + change history accordion), `/accessories` (table + 4-tab detail drawer), `/models` (4-tab router: bodies / uniforms matrix / accessories table / placeholder), `/branches` (4-card per-branch config editor with collapsible sections), `/logic` (rule cards + JSON viewer + Add Rule modal), `/users` (read-only table + drawer), `/admins` (table + Add Admin modal), `/settings` (theme picker + locale + danger-zone shells). Every page consumes data via `MockDataService` (Observable-based; swap to AngularFire-backed implementations in a follow-up "Real Firestore wiring" plan with no caller changes). New shared primitives added beyond the foundation: `<app-icon-btn>`, `<app-drawer>`, `<app-cfg-section>`, `<app-json-viewer>`, `<app-pdf-dropzone>`. Scaffolded by `ChangeRequest/2026-05-17_angular-admin-portal-scaffold.md`; foundation by `ChangeRequest/2026-05-17_admin-portal-foundation.md`; per-screen ChangeRequests at `ChangeRequest/2026-05-17_admin-portal-{dashboard,users,admins,branches,logic,accessories,models,dress}.md` (all status: executed). Topographic background overlay (`.topo-overlay`) removed from runtime — CSS class still present in `_design.scss` for future use.
├── cv-service/             # Python — Phase-2 AI uniform-compliance CV pipeline (sibling to `functions/`, own dependency stack, not part of any JS/Dart build; not wired into production — `checkUniformCompliance.ts` is unchanged). Runnable `POST /inspect` and `POST /check_uniform` FastAPI endpoints (`api/main.py`) chaining real geometry — human detection (`pose/detect_person.py`, YOLOv8n), pose estimation (`pose/estimate_pose.py`, MediaPipe), PnP camera-pose recovery (`calibration/pnp_solve.py`, projects the canonical body anchors from `utils/extract_anchors.py` into each specific photo, with a `reliable` guard against poses that don't resemble a relaxed standing A-pose), and the doctrine rule engine (`rules/rule_engine.py` + `rules/army_no3_male.json`, transcribed from the SAF No.3 Dress PDF) — with a real trained YOLOv8n-seg model (`segmentation/segment_uniform.py`, 9 classes, mask mAP50 0.742 — **synthetic renders only, zero real photos, unvalidated real-world accuracy**, see §5.10) for garment segmentation, a vision-language stand-in (`detectors/vision_crop_inspector.py`) for the not-yet-trained accessory detector, and a scored JSON + annotated-image report (`reporting/report.py`). `pose/anchor_mapping.py` is a second, general-purpose BlazePose→anchor mapping (all 16 `anchors.male.json` keys, additive alongside `pnp_solve.py`'s own narrower 7-anchor correspondence — see §5.10) with measured synthetic accuracy (143.55px mean error, 92% coverage) and an explicit 0-real-photos gap. `labeling/` + `data/` are real-photo ground-truth **infrastructure only** — a versioned label schema, a local FastAPI+canvas tool for a human to click the 15 anchors and outline accessories on a photo, and a gitignored intake folder — populated so far with 0 real photos and 3 clearly-flagged synthetic stand-ins (see §5.10). `geometry/solve_camera_pose.py` + `geometry/project_rules.py` are a second, additive PnP-solve + rule-projection path consuming Milestone B's fuller pose estimate (up to 15 anchor correspondences vs. `pnp_solve.py`'s own 7) — measured lateral position accuracy is good (~6cm mean) but recovered camera **depth is unreliable** (~62cm mean error, up to ~1m) from a single near-frontal view, a real single-view-PnP limitation, not a bug (see §5.10). `evaluation/compare_segmentation_real_vs_synthetic.py` is real-vs-synthetic mAP50 comparison tooling for the trained segmentation model — built and mechanically verified, but reports "0 real photos, nothing to compare" today rather than a table, since none exist (see §5.10). `rules/rule_engine.py`'s `evaluate_verdicts()` + `segmentation/mask_geometry.py` are a geometric pass/fail/missing/unverifiable verdict engine (Army No.3 Male) chaining Milestones B+C+the trained segmenter for the first time end-to-end — measured footwear precision/recall 1.0/1.0 (n=2, thin) against Milestone A's stand-ins, every other accessory class 0 ground-truth-positive signal, 5 of 18 doctrine rules structurally undetectable (no matching segmentation class) and always reported `unverifiable`, never guessed at (see §5.10). `/inspect` now also returns an additive `geometric_verdicts` field (a second, independent B→C→segmenter→verdict pass, kept deliberately separate from the endpoint's original vision-crop path — see §5.10) surfaced in the Flutter dev scorecard. `evaluation/run_real_photo_sanity_check.py` is a lightweight, label-free batch runner — the cheapest pre-check of whether detection/pose/camera-solve hold up on real photos at all, before investing in labeling or training (see §5.10); not yet run for real, 0 real photos exist. `POST /check_uniform` (`api/response_schema.py` + `api/validation.py`, see §5.10) is a second, additive endpoint reshaping the same geometric pipeline into a stable `{success, overall_status, overall_score, image_quality, person, accessories[], summary}` contract with a `SLIGHTLY_MISALIGNED` status band, a Stage-0 image-quality gate, and zero Anthropic dependency; `config.py` centralizes every confidence/tolerance constant across the service (env-var overridable) that used to be scattered per-file. 138 tests (`.venv-tools/bin/pytest cv-service/tests/`), all runnable without external credentials via a dependency-injected fake Anthropic client. `training/` holds the synthetic-dataset generators (bbox + segmentation-mask, both `pyrender`-based) and the segmentation training script. See `cv-service/README.md` for exactly what's real CV vs. synthetic-only-trained vs. a vision-language placeholder, and what's still un-built (a real accessory detector, real-photo validation of anything, Flutter/Cloud-Function wiring, Cloud Run deploy). Uses the same `.venv-tools` Python venv as `tool/*.py`. Built across `ChangeRequest/2026-08-05_cv-service-anchor-extraction-scaffold.md`, `2026-08-05_cv-service-mvp-inspect-endpoint.md`, `2026-08-05_cv-service-remaining-milestones.md`, `2026-08-05_cv-service-m2-synthetic-segmentation-model.md`, `2026-08-11_cv-service-real-photo-ground-truth-tooling.md`, `2026-08-11_cv-service-pose-anchor-mapping.md`, `2026-08-11_cv-service-geometry-camera-pose-rule-projection.md`, `2026-08-11_cv-service-segmentation-real-vs-synthetic-comparison-tooling.md`, `2026-08-11_cv-service-verdict-engine-army-no3-male.md`, `2026-08-11_flutter-geometric-verdict-ui-wiring.md`, `2026-08-11_real-photo-phase1-sanity-check-tooling.md`, and `2026-08-28_cv-service-check-uniform-api-contract.md`. **Accuracy program (2026-09-28, see §5.10 last subsection):** several numbers above are superseded — the "~62cm depth error, single-view limitation" and "143.55px anchor error" were largely a left/right-mirrored anchor bug, now fixed (camera depth 1-4 cm, anchors 5.7 px on the same stand-ins); `/check_uniform` gained live-guided burst capture, EXIF focal length, gravity/height priors, weighted PnP, mask-refined anchors, calibrated uncertainty, two-stage + zero-shot detection, colour / badge-variant / name-tag-OCR checks, per-item instructions, and a synthetic violation benchmark that measures all of it.
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
| Backend               | `firebase_core ^4.14.0`, `firebase_auth ^6.6.1`, `cloud_firestore ^6.9.0`, `cloud_functions ^6.4.0`, `firebase_storage ^13.5.0` (floors raised 2026-08-30 — `cloud_firestore` < 6.9 fails to compile on iOS; keep the family in lockstep) |
| Device identity       | `device_info_plus ^13.1.0`, `uuid ^4.5.0`                       |
| Image loading         | `cached_network_image ^3.4.1` (No.3 accessory photos + placement diagrams; Gallery user photos from Firebase Storage) |
| Gallery               | `image_picker ^1.1.2` (camera + library), `photo_view ^0.14.0` (pinch-to-zoom viewer + swipe gallery), `share_plus ^13.1.0` (share sheet) |
| Local persistence     | `flutter_secure_storage ^8.1.0` (keychain / encrypted prefs), `shared_preferences ^2.3.3` |
| Modeling / JSON       | `freezed ^3.2.5` (+ `freezed_annotation ^3.1.0`), `json_serializable ^6.10.0` (+ `json_annotation ^4.11.0`) |
| Routing               | `go_router ^17.2.2`                                             |
| Localization          | `flutter_localizations`, `intl ^0.20.2` (+ `l10n.yaml`)         |
| Linting               | `flutter_lints ^6.0.0` (see `analysis_options.yaml`)            |
| Tests                 | `flutter_test`, `fake_cloud_firestore ^4.2.0`                   |
| Operator tooling      | `firebase_admin_sdk ^0.5.1`, `google_cloud_firestore`, `google_cloud_storage`, `crypto` (dev deps; pure-Dart admin SDK used only by `tool/seed_firestore.dart` — Firestore + Storage upload + SHA-256 hashing for idempotent reruns) |
| Camera / AR / pose    | `camera ^0.11.0+2` (live preview + image stream for capture guidance), `model_viewer_plus ^1.9.3` (now wired into `GhostScreen` to render the per-user composed GLB), `google_mlkit_pose_detection ^0.14.0` (live capture guidance + post-capture gate), `permission_handler ^11.3.1` |
| Device motion         | `sensors_plus ^7.1.0` (accelerometer → phone pitch/roll for the AR Scanner's "hold the phone level" guidance and the `gravity_x/y/z` camera-tilt prior sent to `cv-service`) |
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
    │   │   ├── profile_repository_impl.dart  # users/{uid}/profile/current (incl. optional `heightCm`, sent to the AR Scanner's check)
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
    │   │       ├── dress_accessory_resolver.dart     # Resolves (DressRequirement, UniformProfile) → List<Accessory>; resolveSplit() returns (mandatory, optional)
    │   │       └── accessory_presentation.dart       # Pure: `accessoryImagesFor(a, dress, branch)` (per-slot fallback `dress_images[no4_<branch>]` → `[no4]` → base) and `accessoryDoctrineText(a, gender, dress, branch)` (`no4_<branch>_placement` / `no4_placement` → gendered rule → placement / applicability…). Used by the Wardrobe detail sheet and the Wearing Guide.
    │   └── presentation/
    │       ├── models/
    │       │   └── accessory_item.dart               # View-model for legacy /checklist screen
    │       ├── providers/
    │       │   ├── dress_requirements_provider.dart  # @Riverpod keepAlive — Firestore-direct
    │       │   └── dress_accessories_provider.dart   # dressAccessoriesProvider, dressAccessoriesByIdProvider(dressId), allDressesAccessoriesCombinedProvider, accessoryDressIndexProvider, wardrobeProgressProvider(filter)
    │       ├── screens/
    │       │   └── checklist_screen.dart             # Progress card + check-card list + sticky CTA
    │       └── widgets/
    │           ├── accessory_remote_image.dart       # `AccessoryRemoteImage`: Storage image card with caption chip + icon placeholder/fallback; shared by the detail sheet and the Wearing Guide
    │           └── accessory_detail_sheet.dart       # Bottom sheet: rule + placement diagram + verify CTA. Takes the dress being viewed (+ branch, gender) and shows that dress's pictures and doctrine text — No.4 items shared with No.3 show the No.4 PDF pictures, not the khaki No.3 ones (`ChangeRequest/2026-10-19_no4-wardrobe-imagery.md`). The cross-dress "All Accessories" list passes no dress → base pictures.
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
    │   ├── domain/
    │   │   └── wearing_steps.dart                    # Pure `buildWearingSteps(dressCode, split, profile)`: base garments + the active dress's resolved accessories (mandatory, plus optional only if ticked in the Wardrobe for that dress), in dressing order; medal-ribbons step is No.3-only (`medalRowCount > 0`); SAF-badge steps from `selectedBadgeIds` (No.3: one step; No.4: chest + left-sleeve steps with per-branch PDF placements). `pickDoctrineTip` takes each step's tip from the accessory's `rules` text (gendered key first).
    │   └── presentation/screens/
    │       └── wearing_guide_screen.dart             # Steps follow `profile.dressCode` via `dressAccessoriesByIdProvider` (No.4 shows only No.4 items — `ChangeRequest/2026-10-19_wearing-guide-follows-dress.md`) + per-step ACCESSORY / PLACEMENT pictures for the dress being worn (same `accessoryImagesFor` as the Wardrobe; medal / badge steps use the `medal_ribbons` / `saf_badges_chest` / `skill_badges_sleeve` library entries — `ChangeRequest/2026-10-19_wearing-guide-images.md`), zone silhouette when a step has no picture, voice stub, completion view
    │
    ├── ar_scanner/
    │   ├── domain/
    │   │   └── entities/
    │   │       ├── compliance_result.dart            # @freezed ComplianceResult/ComplianceItem + ComplianceStatus enum (correct/missing/incorrect/uncertain); mirrors the `report_compliance` tool schema forced on the `checkUniformCompliance` Cloud Function. **Phase-1 Node/Anthropic path is disabled** (`uniform_compliance_provider.dart` commented out in full; `checkUniformCompliance` is on trial billing). Model + `compliance_result_test.dart` kept for when it's re-enabled.
    │   │       ├── cv_inspection_result.dart         # @freezed CvInspectionResult + CvVerdict (5-state: present/missing/misaligned/wrongType/lowConfidence) + CvSubscores/CvIssue/CvUncertainItem/CvCameraDiagnostics — mirrors `cv-service`'s `/inspect` JSON shape (Phase 2, long-press dev path). Deliberately NOT unified with `compliance_result.dart` — the backends return different-shaped reports.
    │   │       └── uniform_check_result.dart         # @freezed UniformCheckResult + UniformCheckAccessory + UniformCheckStatus (5-state: correct/slightlyMisaligned/incorrect/missing/uncertain) + UniformCheckPoint/Box/Summary — mirrors `cv-service`'s Anthropic-free `POST /check_uniform` contract (`api/response_schema.py`). `overallStatus` is `PASS`/`FAIL`/`INCOMPLETE` (`passed` / `incomplete` getters). Per item: `instruction` (cm + wearer's left/right), `required`, `checkable`, `detectionSource`, `frameAgreement`; per result: coverage counts, `debugImageBase64`, burst frame counts, `focalSource`. `couldNotCheck` (checkable but unjudgeable — a retake may help) vs `checkByEye` (no detector yet) split the old single "uncertain" list. This is the **default capture path** now (replaced the fabricated "100% match" stand-in). Third report shape, deliberately separate from the other two. Added `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.
    │   │   (+ `domain/supported_uniforms.dart` — pure: `kCheckableUniformTypes` (mirror of `cv-service/uniforms.py` `UNIFORMS`; update both together), `kScannableDresses` (No.3, No.4), `uniformTypeFor(branch, dress, gender)`, `isCheckableUniform`. The scanner checks the profile's active dress, which is set by tapping a No.1–No.5 card on the Dashboard Home tab (`DashboardScreen.onOpenDress` → `setDressCode`) or by building a dress (`GeneratingScreen`). When that combination isn't checkable, capture is disabled and a "can't be checked yet" card lists the supported uniforms with a "Choose uniform on Dashboard" link — `ChangeRequest/2026-10-09_ar-scanner-dress-picker.md`.)
    │   ├── data/
    │   │   ├── uniform_compliance_repository.dart    # Wraps the `checkUniformCompliance` HTTPS callable; base64-encodes the captured photo client-side. Currently unused (Phase-1 path disabled — see above).
    │   │   ├── cv_service_inspection_repository.dart # HTTP multipart client for `cv-service`'s `POST /inspect` (`kCvServiceBaseUrl`, defaults to `localhost:8001` — no deployed instance yet)
    │   │   ├── uniform_check_repository.dart         # HTTP multipart client for `cv-service`'s `POST /check_uniform` (one frame) / `POST /check_uniform_burst` (several frames, D17) (reuses `kCvServiceBaseUrl`). Sends the optional accuracy inputs `wearer_name` (profile full name → name-tag OCR), `height_cm`, `gravity_x/y/z`, and `include_debug_image=true`; the focal length travels in the JPEG's EXIF. Decodes responses as UTF-8 explicitly (the service sends no charset; `Response.body` fell back to Latin-1 and garbled "—"/"°"). Throws `UniformCheckException(message, {statusCode, errorCode})` — `statusCode == null` = service unreachable; `errorCode` is the service's typed code, read from the body's `status` key (it was read from `error` and always lost before 2026-09-28) (`NO_PERSON_DETECTED`, `POSE_UNRELIABLE`, `SCALE_UNAVAILABLE`, `UNSUPPORTED_UNIFORM`, `SEGMENTER_UNAVAILABLE`, image-quality codes).
    │   │   ├── capture_quality_gate.dart              # On-device pose-quality check via `google_mlkit_pose_detection` — rejects a captured photo (no person / torso not visible / camera tilted) before it's uploaded. Now the post-capture backstop behind the live guide below.
    │   │   ├── live_pose_guide.dart                   # D15 live capture guidance: `CaptureGuidance.assess` (pure, unit-tested) turns ML Kit landmarks + phone tilt into the first failing `CaptureHint` (no person / not full body / too far / too close / off-centre / facing away / sideways / arms raised / phone tilted / hold still / ready); `LivePoseGuide` runs it on the throttled camera image stream (NV21 / BGRA8888) and only reports `ready` after 3 consecutive good frames. Replaced a fixed 1.8 s timer that unlocked capture regardless of framing.
    │   │   ├── cv_service_health.dart                 # `normaliseCvServiceUrl` + `CvServiceHealth.check` (`GET /health`, 5 s timeout, never throws — reports the exact error) + `kCvServiceUsbUrl` (`http://127.0.0.1:8001`, for `adb reverse`).
    │   │   └── device_tilt.dart                       # D16: accelerometer (sensors_plus, low-pass) → world-up in the back camera's OpenCV frame (`gravityUpCamera`, sent as `gravity_x/y/z`) + pitch/roll for guidance.
    │   └── presentation/
    │       ├── providers/
    │       │   ├── uniform_compliance_provider.dart  # **Commented out in full** — `UniformComplianceController` (Phase-1 Node/Anthropic path) is disabled. Kept so it can be uncommented later.
    │       │   ├── uniform_compliance_provider.g.dart
    │       │   ├── cv_service_inspection_provider.dart # `CvServiceInspectionController` — drives `cv-service`'s `/inspect` (long-press dev path). Separate controller.
    │       │   ├── cv_service_inspection_provider.g.dart
    │       │   ├── cv_service_url_provider.dart       # `cvServiceUrlProvider` (keepAlive `Notifier<String>`): compiled `kCvServiceBaseUrl`, replaced by the persisted `saf.cvServiceUrl` override once loaded; `set(input)` normalises + persists, `reset()` clears. Both cv-service repository providers `watch` it.
    │       │   ├── uniform_check_provider.dart        # `uniformCheckRepositoryProvider` + `UniformCheckController` (`@riverpod` AsyncNotifier<UniformCheckResult?>, not keepAlive) — `check(photoBytes, uniformType, rankTier, gender, isSikh, medalRowCount, bodyType)` drives `POST /check_uniform`, `reset()` clears for a re-scan. Ephemeral, nothing persisted. This is what the **default capture button** now calls.
    │       │   └── uniform_check_provider.g.dart
    │       ├── widgets/
    │       │   └── cv_server_settings.dart            # `CvServerSettings`: address field, Save, "USB cable" preset, Default, "Test connection" — in the Settings sheet and behind the "Server settings" button on the scanner's "Connection problem" screen (which also shows the URL called + the real error).
    │       └── screens/
    │           └── ar_scanner_screen.dart             # Live `CameraPreview` + **live pose guidance** (`LivePoseGuide` on the image stream, `DeviceTilt`; the status banner shows the current `CaptureHint`; capture unlocks only when the protocol holds, or after 4 s if guidance can't run on the device) → **default tap** takes a 3-frame burst → capture-quality gate on frame 1 → `POST /check_uniform_burst` (`UniformCheckController.check(photos: …, wearerName, heightCm, gravityUpCamera)`; `uniform_type` sent as `"${branch}_${dress}_${gender}"` e.g. `army_no3_male` — a non-army/non-No3 profile gets the service's `UNSUPPORTED_UNIFORM` 422 surfaced verbatim) → `_RealScorecard` (overall PASS/FAIL/INCOMPLETE + score ring, expected-vs-detected overlay image, and one evidence-rich card for every accessory grouped into correct, issue, could-not-check, and check-by-eye sections; each card reports presence, placement, confidence/visibility where available, measured offset, instruction, frame agreement, detector source, and doctrine reference) → analyzing / failed states. **Needs a reachable `cv-service`** (`kCvServiceBaseUrl`, default `http://localhost:8001`; override per device with `--dart-define=CV_SERVICE_BASE_URL=...`) — no deployment exists yet, so an unreachable service lands on `_FailedPhase` with an explicit "analysis service unreachable" message (NOT a fake pass). The prior fabricated "100% perfect match" stand-in (`_buildResult`) is deleted. See `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md` and `ChangeRequest/2026-11-08-accurate-result-page-verdicts.md` (code-level verification only until a real photo/device run). Long-press the capture button still routes through the older `/inspect` dev path (`_captureCvService` → `_CvScorecard`, labelled "PHASE 2 · DEV", with a "GEOMETRIC VERDICTS" section from `/inspect`'s `geometric_verdicts` field). Phase-1 `checkUniformCompliance` (Node/Anthropic) is disabled — imports commented out. **Not exercised against any real photo** (0 exist in this project).
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
  debounce immediately — `persist()` returns `Future<bool>` (`true` =
  write actually landed), unlike the fire-and-forget debounced path,
  because `ConfigScreen`'s completion step must not mark onboarding
  complete and navigate away when the write silently failed (see
  §5.6's "Config profile-save failure fix" note and
  `ChangeRequest/2026-08-11_config-profile-save-failure-fix.md`). On
  launch, `hydratedProfileProvider` (a stream from
  `profileRepository.watch()`) rehydrates state via
  `notifier.hydrate(profile)` once auth lands. `hydrate` ignores a
  snapshot while a local edit's debounced write is still pending — it
  used to apply it and cancel the write, so a No.4 dress pick could snap
  back to No.3 unsaved (`ChangeRequest/2026-10-19_wearing-guide-follows-dress.md`). The notifier also owns the
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
  (`render_logic.legacy_placeholder == true`) are filtered out, so No.1/2/5
  return empty until their doctrine PDFs land. No.3 and No.4 are
  doctrine-aligned.
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
  same split. Override shapes added for No.4 (2026-10-02,
  `ChangeRequest/2026-10-02_no4-dress-doctrine-alignment.md`), mirrored
  in the TS port:
  - `headdress` may be gender-neutral, `{unisex, sikh,
    sikh_col_me7_above}`. This also fixed DIS No.3, whose `{unisex,
    sikh}` headdress had never resolved.
  - `headdress.alternatives` / `sikh_alternatives` are optional.
  - `rank_epaulette: {standard, cadet_trainee}` is mandatory for every
    rank. `Rank.oct` gets `cadet_trainee`.
  - `additional_mandatory` / `additional_optional` are plain id lists.
  - Unknown override keys (e.g. No.4's `chest_badges`,
    `sleeve_badges`, `foreign_badge_rules` cm metadata) are ignored. Consumed by the Wardrobe tab to render per-row
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
- `UniformComplianceController` (`@riverpod` `AsyncNotifier<ComplianceResult?>`,
  not `keepAlive` — a fresh `ARScannerScreen` visit starts at `null` again)
  wraps the `checkUniformCompliance` callable via
  `uniformComplianceRepositoryProvider`. `check(dressCode, photoBytes)`
  base64-encodes the captured JPEG and awaits the Cloud Function's
  AI-vision verdict; `reset()` clears state for a re-scan. Unlike
  `ModelGenerationController`, nothing here is written back to
  `UniformProfile` or Firestore — the result is ephemeral by design (see
  `ChangeRequest/2026-07-30_ai-uniform-compliance-check.md`).

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
| `saf.cvServiceUrl`   | `shared_preferences`    | User-set AR Scanner analysis-server (`cv-service`) address, overriding the compiled `kCvServiceBaseUrl`; edited in Settings → Analysis server or from the scanner's "Connection problem" screen (`cvServiceUrlProvider`). `http://127.0.0.1:8001` = USB via `adb reverse` (`deploy/connect-phone-usb.sh`). See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`. |
| `saf.lastRoute`      | `shared_preferences`    | Last matched `GoRouter` location, written on every navigation but restricted to `Routes.restorable` (see §5.6). Lets `WelcomeScreen` return a returning user to the screen they were on after a cold start — including an Android-triggered process-death respawn (e.g. the OS camera app backgrounding this app for a photo capture) — instead of always `/dashboard`. See `ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md`. |

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
  - **`cv-service` on Cloud Run** (2026-10-02,
    `ChangeRequest/2026-10-02_cv-service-cloud-run-deploy.md`):
    - Deployed to `https://cv-service-612500938654.asia-southeast1.run.app`
      by `deploy/deploy-cv-service-cloudrun.sh`, which uses Cloud Build,
      `deploy/cloudbuild.cv-service.yaml` and `.gcloudignore`.
    - Runtime: 4 vCPU / 8 GiB, concurrency 1, 0–2 instances.
    - `CV_SERVICE_REQUIRE_AUTH=1`, so `api/auth.py` requires a Firebase ID
      token on the analysis endpoints. The app's two clients attach one via
      an `IdTokenProvider`.
    - Public at the Cloud Run level since 2026-10-05, granted by an
      Owner (Editors can't), like the Firebase functions. Live
      smoke-tested: no-token and forged-token scans get 401, real-token
      scan and burst get 200.
    - Release APKs point at it with
      `--dart-define=CV_SERVICE_BASE_URL=<that URL>`.
    - **RSAF No.4 men + ladies** supported since 2026-10-07, revision
      `cv-service-00003` (`ChangeRequest/2026-10-05_cv-service-rsaf-no4.md`).
    - `cv-service/uniforms.py` maps each `uniform_type` to its:
      - rules (`rules/rsaf_no4_*.json`, built by
        `utils/build_rsaf_no4_rules.py`);
      - anchors (`rules/anchors.rsaf_no4_*.json`, from
        `utils/extract_figure_anchors.py`);
      - pose offsets;
      - stature;
      - segmentation model (Army → v2, RSAF → `segmentation_v3`, which adds
        `rank_tab` / `sleeve_patch`).
    - RSAF benchmark: `training/generate_violation_benchmark_rsaf.py` and
      `evaluation/run_violation_benchmark.py --bench
      violation_benchmark_rsaf`. Result: 3.2% false alarms, 39% violation
      recall, most correct items "too close to call".
    - The sleeve unit patch is check-by-eye.
  - Locally, `cv-service` runs
    via `deploy/run-cv-service-local.sh` (or `cv-service/Dockerfile`),
    and the Flutter app reaches it over the LAN, or over the USB cable via
    `deploy/connect-phone-usb.sh` (`adb reverse tcp:8001 tcp:8001` + the
    app's "USB cable" preset). The address is compiled in
    (`kCvServiceBaseUrl`) but can be changed on the phone — Settings →
    Analysis server, with a "Test connection" `GET /health` probe — no
    rebuild needed.
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
    `asia-southeast1`.

    **Baked slots** (2026-10-02,
    `ChangeRequest/2026-10-02_rsaf-no4-unified-figures.md`): a unified
    dressed figure can declare the accessories it already models in its
    root `extras.saf_baked_slots`, as `{slot: {node, accessory | null,
    optional?}}`. Before attaching, compose applies
    `planBakedDetaches` / `planBakedSkips` from `glb_compose.ts`:
    - It skips accessories the figure already shows.
    - A *mandatory* accessory that differs from the built-in one detaches
      that node and attaches normally: Sikh turban for beret, COL/BG cap
      badge, cadet rank tab. A detached parent takes its children with it.
    - Optional alternatives never strip a built-in part.
    - `accessory: null` slots are just covered (socks in boots, belt under
      an untucked shirt).
    - `optional: true` parts (the RSAF chest wing badge) are removed
      unless the profile ticked one.

    Figures without the key behave exactly as before. `bakeNameTag` picks
    white or dark text from the tape's luminance. `createComposeIO`
    registers `KHR_texture_transform`; it used to drop it silently,
    which coarsened artist fabric tiling.

    The bundle version (`MODEL_BUNDLE_VERSION = 15`)
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
  - `checkUniformCompliance({dressCode, photoBase64, mimeType})` —
    AI-vision uniform inspection. Validates auth, loads
    `users/{uid}/profile/current`, resolves the same expected-accessory
    list `composeUniformModel` uses (mandatory + user-ticked optional,
    via the shared `resolveAccessorySplit` port in
    `dress_accessory_resolver.ts`), best-effort fetches each
    accessory's `accessory_library/{id}.image_url` from Storage as a
    reference image (missing/failed fetches degrade to a text-only
    description for that item — never fail the whole check), then
    calls the Anthropic API (`claude-sonnet-5`) with the user's photo +
    reference images, **forcing tool-use** (`tool_choice` pinned to a
    `report_compliance` tool) so the response shape is guaranteed
    rather than parsed out of prose. The tool-call `input` is
    zod-validated server-side before being returned — `overallScore`
    (0-100), `summary`, and `items[]` each with `accessoryId`,
    `displayName`, `status` (`correct` / `missing` / `incorrect` /
    `uncertain`), and `note`. Nothing is persisted — fully ephemeral
    per request. The Anthropic API key lives in Secret Manager
    (`defineSecret("ANTHROPIC_API_KEY")`, injected via the function's
    `secrets:` option) — never logged, never sent to the client.
    Region `asia-southeast1`, 60s timeout, 512MiB memory. See
    `ChangeRequest/2026-07-30_ai-uniform-compliance-check.md`.
  - Deploy: `firebase deploy --only functions,firestore:rules,storage:rules`.
    `checkUniformCompliance` additionally requires the secret to exist
    first: `firebase functions:secrets:set ANTHROPIC_API_KEY`.
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
    `accessory_library` collection ids. Dress-specific variants sit
    alongside as `<variant>_{image,placement}.png` (e.g.
    `no4_rsaf_placement.png`). Reads are auth-required, writes
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
    (`display_name`, `image_url`, `placement_diagram`, optional
    `dress_images: {"no4" | "no4_<branch>": {image_url, placement_diagram}}`)
    plus `rules` (incl. optional `no4_placement` / `no4_<branch>_placement`
    text from the No.4 PDF) and `render_logic` blobs. Read by `AccessoryLibraryRepository`. The
    `image_url` and `placement_diagram` fields hold
    `https://firebasestorage.googleapis.com/...` URLs (auth-required)
    pointing to the per-id PNGs uploaded by `tool/seed_firestore.dart
    --upload-images` from `assets/accessories/<id>/{image,placement}.png`.
    Empty strings on entries whose images have not been sourced yet
    (legacy No.1/2/5 placeholders, plus any new doctrine-aligned entry
    awaiting an upload) — the app degrades gracefully to the category
    icon fallback. v3 holds
    113 entries (82 + 31 No.4 entries added 2026-10-02) grouped by `category` (e.g. `headdress_beret`,
    `headdress_sikh_turban`, `headdress_ladies_hat`, `cap_badge`,
    `cap_embellishment`, `epaulette`, `gorgette`,
    `sleeve_rank_specialist`, `sleeve_rank_enlistee`, `arms_badge`,
    `vocation_badge`, `name_tag`, `lanyard`, `belt`, `footwear`, `socks`,
    `medal_ribbons`, `saf_badge`, `foreign_badge`, `skill_tab`,
    `skill_badge`). For **No. 3 dress** entries are PDF-aligned per-branch
    + per-rank-tier (e.g. `army_sikh_turban_col_me7_above`,
    `navy_cap_embellishment_bg_me8_above`,
    `rsaf_ladies_hat_specialist_me1_me2_cadet_me_trainee`).
    For **No. 4 dress** (2026-10-02, SAF No.4 Dress PDF):
    - The Army/Navy/RSAF/DIS berets (now unisex, since ladies wear them
      in No.4), Sikh turbans and cap badges are reused from No.3.
    - New: alternative headdress (jockey caps, jungle hats, Navy Kevlar
      helmet, RSAF ball cap, `sikh_field_turban_green`). These have no
      `anchor`, so they appear in the Wardrobe only and are never
      rendered.
    - New: per-branch chest rank tabs (`<branch>_no4_rank_epaulette[_cadet_trainee]`,
      category `rank_epaulette_chest`, anchored `belt_center` +20 cm).
    - New: `singapore_tag`, inner T-shirts (Navy/RSAF/DIS),
      `army_no4_belt` / `no4_belt_black`, `combat_boots`,
      `safety_boots[_mid_cut]`, `safety_shoes_low_cut`, `green_socks`,
      `rsaf_vocation_badge`, `rsaf_unit_patch`, `dis_service_patch`,
      `dis_formation_patch`.
    For No. 1, 2, 5 dress, the original generic entries
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

**Last-route restoration (2026-08-11,
`ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md`):** every
navigation to a route in `Routes.restorable` is persisted to
`LocalStorageService` (key `saf.lastRoute`) via a listener on
`appRouterProvider`'s `GoRouterDelegate`. `Routes.restorable` is an
explicit allowlist (`/dashboard`, `/config`, `/ghost-model`, `/wearing`,
`/ar`, `/checklist`, `/dress-accessories`) — deliberately excludes `/`
(the default landing spot anyway), `/generating`/`/rebuilding`
(transient, animation-driven screens that auto-navigate onward on their
own), and `/gallery/viewer` (requires a typed `state.extra` record that
can't be reconstructed from a persisted URL string). `WelcomeScreen`
reads this back (`Routes.resolveRestoreTarget`, which re-validates
against the *current* allowlist rather than trusting a possibly-stale
persisted value) instead of always going to `/dashboard` for a returning
user. This fixes a bug where `image_picker`'s OS-camera hand-off (used
by the AR Scanner's capture button) could get the Flutter process killed
by Android under memory pressure while backgrounded, so the user
returned to Dashboard Home instead of wherever they actually were — this
app has no other state-restoration mechanism (no `RestorationMixin`, no
`WidgetsBindingObserver`), so every process-death respawn is otherwise
indistinguishable from a fresh cold start. Deliberately a lightweight
fix: only the *route* is restored, not fine-grained in-progress widget
state within that screen (e.g. an exact Config wizard step resets to
step 1) — full `RestorationMixin` adoption was considered and declined
as out of scope for this fix.

Current routes:

- `/` — `WelcomeScreen` (initial location). Owns the bootstrap
  pipeline (§ 5.3). For returning users with `profileComplete=true`
  it auto-routes to the last-restored route (see above, falls back to
  `/dashboard`) after the min-display window; for new users it reveals
  a CTA that goes to `/config`.
- `/dashboard` — `DashboardScreen` with internal IndexedStack of 4 tabs
  (Home, Wardrobe, Gallery, Profile). Tabs are local UI state (not routes).
- `/config` — 4-step `ConfigScreen` wizard. On the final step it
  awaits `UniformProfileNotifier.persist()` — **checking its `bool`
  result** (with one automatic retry on failure) before proceeding; if
  the write still fails, onboarding is NOT marked complete and the user
  stays on Config with a visible error, rather than the pre-fix
  behavior of silently navigating to Dashboard against a profile that
  was never actually saved (see
  `ChangeRequest/2026-08-11_config-profile-save-failure-fix.md` — this
  is what was producing a confusing "Finish your profile first" error
  later, during an unrelated compliance check). Only once the write is
  confirmed does it call the `markProfileComplete` Cloud Function,
  write `profileComplete=true` to local storage, and set
  `authSession.copyWith(profileComplete: true)` before
  `context.go('/dashboard')`.
- `/checklist` — `ChecklistScreen` (accessory verification).
- `/ghost-model` — `GhostScreen` (Front/Back ghost figure + 6 hotspots).
- `/wearing` — `WearingGuideScreen` (9 dressing steps + completion view).
- `/ar` — `ARScannerScreen` (align/capture UI → real AI-vision compliance check via `checkUniformCompliance` → Phase 2 scorecard with live results).
- `/generating?dress=No3` — `GeneratingScreen` (animated ring loader; auto-routes to `/ghost-model` on complete). Also sets the profile's active `dressCode` to the dress being built, because `/ghost-model` and `/ar` both read `profile.dressCode` (before 2026-10-09 building No.4 left it at No.3, so the scanner sent e.g. `rsaf_no3_female` → `UNSUPPORTED_UNIFORM`; `ChangeRequest/2026-10-09_ar-scanner-follows-built-dress.md`).
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

### 5.10 cv-service — AI uniform-compliance CV pipeline
[`cv-service/`](cv-service/) is a separate Python service (own
`requirements.txt`, own `.venv-tools` venv shared with `tool/*.py`,
own FastAPI app) that will eventually replace the single-shot
Claude-vision call in `checkUniformCompliance.ts` with a full
computer-vision pipeline. **Not wired into production yet** —
`checkUniformCompliance.ts` is unchanged; `cv-service` runs standalone
via `POST /inspect` on `localhost:8001` until a future plan flips the
Cloud Function over (see the "Not built yet" list below).

The core design principle: the reference body GLB is a **measuring
instrument, never a comparison image**. `assets/3d/bodies/*.glb`
carries 15 named scene-graph sockets — built for
`composeUniformModel`'s accessory re-parenting, but geometrically
identical to the doctrine's own placement anchors ("collar edge",
"pocket top edge", "shoulder seam"). `cv-service/utils/extract_anchors.py`
reads those socket world-positions once, offline, via `trimesh`, and
freezes them into `cv-service/rules/anchors.<variant>.json`. Every
inspection request measures a photo against that static file — nothing
re-parses a GLB per request, nothing ever diffs pixels against a
rendered reference image. `cv-service/rules/army_no3_male.json` is the
Army No.3 Male doctrine transcribed from the SAF No.3 Dress PDF into
one JSON rule per accessory (anchor + cm offset + tolerance +
`doctrine_ref` pointing at the exact picture/page).

**Uniform identity is now a mandatory gate before accessory verification**
(2026-11-08, `ChangeRequest/2026-11-08-uniform-identity-gate.md`).
`detectors/uniform_identity.py` consumes the existing segmentation result after
person detection and requires coherent torso, lower-body, footwear, and
uniform-structure evidence before pose projection and accessory verdicts run.
Weak garment evidence returns `UNABLE_TO_VERIFY`; no garment evidence returns
`INVALID_ATTIRE`; neither response has a compliance score or accessory
verdicts. A successful response includes `uniform_identification` with the
gate status, evidence confidence, and `inspection_allowed`. This is a
conservative safety gate, not a validated SAF classifier: the current
segmentation models are synthetic-trained and the gate must be calibrated
against labelled real photographs before accuracy claims or automatic
approval.

`cv-service/utils/extract_glb_manifest.py` provides the broader offline
reference inventory used before detector integration. It records the scene
hierarchy, world transforms, mesh bounds and counts, material/texture
presence, and glTF skin/animation counts for one GLB or a directory of GLBs.
Each known socket is listed separately under `anchors` and is marked with
`has_geometry`; this matters because some exporters encode marker cubes while
others encode transform-only sockets. An anchor is a placement reference, not
proof that an accessory mesh or doctrine-approved item is present. The
manifest is an offline inventory only; request-time compliance still uses the
frozen anchor/rule files and detector evidence.

**Rule selection is profile-aware** (2026-11-08,
`ChangeRequest/2026-11-08-official-rule-engine.md`). `rules/rule_loader.py`
validates every doctrine JSON's metadata and per-rule source reference;
`rules/rule_selector.py` validates the requested service, dress, gender,
rank tier, personnel category and Sikh flag before selecting the exact
configuration. `/check_uniform` and `/check_uniform_burst` accept
`personnel_category` and include the selected `inspection_profile` in a
successful response. The currently provisioned, validated request-time
configurations remain Army No.3 Male and RSAF No.4 Male/Female. Navy, DIS,
other dresses and diagram-only rules must not be represented by copied Army
rules or invented tolerances; they remain unavailable until their source
rules, matching anchors and detector evidence are added and tested.

**What's real, measured geometry today** (built
2026-08-05, `ChangeRequest/2026-08-05_cv-service-mvp-inspect-endpoint.md`):
`pose/detect_person.py` (YOLOv8n, pretrained), `pose/estimate_pose.py`
(MediaPipe Tasks PoseLandmarker, pretrained, 33 keypoints),
`calibration/pnp_solve.py` (OpenCV `solvePnP` recovering the camera's
position relative to the body from a fixed anchor↔landmark
correspondence set, then projecting any doctrine anchor+offset into
that specific photo's pixel space), and `rules/rule_engine.py`
(resolves every applicable rule — filtered by a small profile-condition
evaluator for rank tier / gender / Sikh / medal row count — into a
pixel-space crop region, including a fix that blends "half of sleeve
length from the shoulder seam"-style rules toward the detected elbow
landmark in 2D rather than sitting statically at the shoulder anchor).
`CameraSolution.reliable` is a real guard rail, not decoration: a photo
whose pose doesn't resemble a relaxed standing A-pose (validated
against an actual yoga-pose test photo during development) makes
`solvePnP` converge to a mathematically valid but physically
nonsensical camera, with reprojection error in the thousands of pixels
instead of the tens — `reliable=False` catches that and the endpoint
returns 422 asking for a recapture, rather than silently running tight
cm-tolerance checks against garbage geometry.

**What is explicitly NOT a trained detector:**
`detectors/vision_crop_inspector.py` stands in for the architecture
memo's Stage 4/5 (trained accessory detection + segmentation), which
needs labeled training data that doesn't exist yet. It sends each
*already geometrically located* crop to Claude and asks "what do you
see here" — a real accuracy improvement over Phase-1's whole-photo
call (the model only judges a small, targeted region instead of
searching the whole frame), but still a vision-language judgment, not
a measurement. `reporting/report.py` (Stage 7) aggregates verdicts
into the JSON report shape (`overall_score`, per-region `subscores`,
`issues`, `uncertain`) plus a green/yellow/red annotated image; two
subscore buckets (`lower_body`, `appearance`) have no rules yet and
report `null` rather than a faked passing score. Scoring weights are
an explicit placeholder pending calibration against real inspections.

Run the service: `cd cv-service && ../.venv-tools/bin/uvicorn
api.main:app --reload --port 8001` (needs `ANTHROPIC_API_KEY` in the
environment for the vision-crop step — same secret already provisioned
for `checkUniformCompliance`; stages 1-3/6 run without it). Run tests:
`.venv-tools/bin/pytest cv-service/tests/` — 23 tests, all runnable
with zero external credentials (the Anthropic call is
dependency-injected and faked deterministically in every test). The
one real photo used for the full-pipeline tests is an offscreen render
of the actual reference body GLB
(`cv-service/tests/fixtures/rendered_army_no3_male_front.jpg`,
regenerate via `generate_fixture.py` if the body changes) since no
real soldier photo exists yet. Regenerate `anchors.male.json` whenever
`male_apose.glb` changes — see `cv-service/README.md`.

**Milestone status (2026-08-05,
`ChangeRequest/2026-08-05_cv-service-remaining-milestones.md`):** M4
(rule engine) and M5 (3D reference alignment) are done. M1 (pose
estimation) is done on both halves now — server-side
(`pose/estimate_pose.py`) and client-side
([`CaptureQualityGate`](lib/features/ar_scanner/data/capture_quality_gate.dart),
which runs `google_mlkit_pose_detection` — previously a declared but
unused dependency, see the historical note below — against the
captured photo immediately after the shutter fires and rejects it with
a specific reason before it's ever uploaded; it gates post-capture
rather than mid-preview against the live feed (see the in-app camera
note in §8), same intent as the architecture memo's §0/§10). M6 (inspection API) has a `cv-service/Dockerfile`
now, **unverified by an actual `docker build`** — no Docker in the
environment that authored it. M7 (Flutter integration) has real,
tested wiring: [`cv_inspection_result.dart`](lib/features/ar_scanner/domain/entities/cv_inspection_result.dart)
mirrors `cv-service`'s report shape (5-state verdict, subscores,
annotated image) as a model strictly separate from the Phase-1
`ComplianceResult`; [`CvServiceInspectionRepository`](lib/features/ar_scanner/data/cv_service_inspection_repository.dart)
calls `cv-service`'s `POST /inspect` over HTTP; `ar_scanner_screen.dart`
reaches it via a long-press on the capture button (not the default tap
— the shipped Phase-1 flow is untouched) and renders a `_CvScorecard`
labelled "PHASE 2 · DEV". None of this has been exercised against a
live `cv-service` instance on a device — `flutter analyze` and
`flutter test` (77/77) pass, but that's static verification, not a
device smoke test.

M3 (accessory detection) remains genuinely un-completable without
labeled real-photo training data — restated because it's still true.
`detectors/vision_crop_inspector.py` remains its stand-in.
[`cv-service/training/generate_synthetic_dataset.py`](cv-service/training/generate_synthetic_dataset.py)
is a real, verified bounding-box dataset generator for it (renders the
reference body + doctrine-anchored accessories from randomized cameras
via `pyrender` — Blender isn't installed in this environment, so this
substitutes for the memo §16 Blender script with the same job, and
derives bounding boxes by projecting actual mesh vertices through the
exact render camera rather than guessing them) — genuine progress on
M3's data prerequisite, explicitly not M3 itself.

**M2 (segmentation) is different: a real model was actually trained**
(2026-08-05/06,
`ChangeRequest/2026-08-05_cv-service-m2-synthetic-segmentation-model.md`) —
prompted by a user claim that the seeded Firestore data ("complete
database... all data is there") already unblocked M2. Checked first:
it doesn't — the 82 `accessory_library` entries + `branch_configs` /
`dress_requirements` are reference/config metadata and 67 single-item
accessory photos, not photos of a person wearing the uniform with
pixel-level region labels. What the same 3D-asset completeness *does*
support: `pyrender`'s `RenderFlags.SEG` flat-color render mode produces
pixel-perfect, occlusion-correct segmentation masks straight from the
geometry (no approximation), and this machine has `torch` + Apple
Silicon MPS acceleration available — so
[`cv-service/training/generate_segmentation_dataset.py`](cv-service/training/generate_segmentation_dataset.py)
+
[`cv-service/training/train_segmentation.py`](cv-service/training/train_segmentation.py)
actually generated 180 labeled renders and trained a YOLOv8n-seg model
(40 epochs, ~12 minutes on `mps`) wrapped by
[`cv-service/segmentation/segment_uniform.py`](cv-service/segmentation/segment_uniform.py)
and wired into `/inspect`'s `segmentation` field (best-effort — degrades
to `null` if the model isn't present, never breaks the rest of the
report). 9 classes, bounded by what the one continuous body mesh's
geometry actually supports (`shirt`/`trousers` via a horizontal
plane-cut at waist/neck height — the same y-slicing technique already
used in this repo's own merger pipeline, not a novel hack — plus
`headwear`/`cap_badge`/`epaulette`/`sleeve_rank`/`arms_badge`/`belt`/
`footwear` from actual separate accessory meshes; no separate
`collar`/`pocket`/`sleeve` classes are derivable without hand-authored
mesh sub-regions). Final validation on a held-out **synthetic** split
(30 renders, same body, different random cameras — never a real
photo): overall mask mAP50 **0.742** — shirt/trousers/headwear/footwear
~0.995 each (large unambiguous regions, near-solved in the synthetic
domain), cap_badge 0.904, but small accessories much weaker
(belt 0.556, arms_badge 0.524, epaulette 0.496, sleeve_rank 0.222).
Confirmed the trained model runs correctly against the existing test
fixture, including a visible reproduction of a documented, real
limitation: hands hanging near hip height get misclassified as
`trousers` (the plane-cut can't distinguish torso from arm at the same
world height). **The load-bearing caveat, restated because it's the
whole point: zero real photographs were used anywhere in this training
run.** Real-world accuracy is completely unvalidated — this is a real
trained model and a real mechanism proof, not a production-ready
segmenter.

**Real-photo ground-truth labeling — infrastructure only, 0 real photos
(2026-08-11,
`ChangeRequest/2026-08-11_cv-service-real-photo-ground-truth-tooling.md`):**
every accuracy number above is synthetic-only, and this milestone exists
to build the pipe that eventually fixes that — not to fix it yet.
`cv-service/data/real_photos/` (gitignored — will hold photos of real
servicemembers) is the intake folder, convention
`<subject_id>/<subject_id>__<angle>__<lighting>.jpg`, documented in its
own `README.md`. `cv-service/data/schemas/ground_truth.v1.schema.json` is
a versioned JSON Schema for one label file (all 15 `SOCKET_NAMES` anchor
clicks, each either a pixel position or an explicit not-visible flag,
plus zero or more polygon instances over the 9 segmentation `CLASSES`) —
generated by `cv-service/labeling/schema.py` **from** those two existing
lists rather than hand-duplicated, so a schema regen is the only thing
standing between it and drifting out of sync with the rest of the
pipeline; `cv-service/tests/test_ground_truth_schema.py` fails loudly if
someone changes either list and forgets to regenerate. `cv-service/labeling/server.py`
is a local FastAPI app + a single self-contained HTML/canvas page
(`labeling/templates/label.html`, no external JS/CDN) that walks a
non-engineer through one photo at a time and writes a validated label to
`cv-service/data/labels/` (also gitignored) on save. Since zero real
photos exist anywhere in this project, the plan's "personally label 3
photos" verification step used 3 **synthetic stand-ins** instead
(`cv-service/labeling/render_standins.py` renders the bare reference body
GLB from 3 camera angles/distances via the same `pyrender` technique as
the existing test fixture, one deliberately cropped close enough to push
the ankles/feet out of frame and exercise the not-visible path;
`cv-service/labeling/label_standins.py` then drives the real running
server's `/save` endpoint — via FastAPI's `TestClient`, same technique
`tests/test_api.py` already uses — with anchor coordinates computed by
projecting the exact same 3D socket positions through the exact same
render camera, not mouse clicks, since an agent has none and no real
photo exists to click on anyway). Every one of those 3 label files sets
the schema-required `is_synthetic_stand_in: true` field, so nothing
downstream can mistake a stand-in for real validation data. **Restating
the number one more time because it's the point of this whole
subsection: 0 real photographs exist in this repository.** Sourcing an
actual consenting subject + camera + doctrine uniform is explicitly out
of scope for this milestone and remains the single biggest open item
blocking every accuracy claim in this section.

**Pose→anchor mapping — general coverage, additive, synthetic-only
accuracy so far (2026-08-11,
`ChangeRequest/2026-08-11_cv-service-pose-anchor-mapping.md`):** no new
pose model — this reuses Stage 2's existing pretrained MediaPipe
PoseLandmarker as-is. What's new is `cv-service/pose/anchor_mapping.py`'s
`estimate_anchor_pose(image_path) -> dict`, which maps BlazePose's output
onto **all 16** `anchors.male.json` keys (the 15 sockets + derived
`chest_center`), not just the 7 `calibration/pnp_solve.py` already
covers for its own narrower PnP-correspondence purpose (both
`CORRESPONDENCES` lists now coexist deliberately — see each module's
docstring — rather than being unified, since PnP only ever needed a
reliable subset). 7 anchors (both shoulder seams, both ankles, both
foot-tops, `belt_center` via hip midpoint) are direct or averaged
BlazePose detections; the other 8 (`head_top`, `cap_band_front`, both
collar tips, both chest pockets, both sleeve-uppers) have no BlazePose
equivalent at all and are geometric heuristics — interpolated between two
real landmarks (collar tip, chest pocket, sleeve-upper) or extrapolated
beyond them (`head_top`, `cap_band_front`, since BlazePose has no
skull-top point) — each carrying an explicit confidence penalty
(`INTERPOLATION_CONFIDENCE_PENALTY = 0.6`,
`EXTRAPOLATION_CONFIDENCE_PENALTY = 0.35`) so a caller can tell a
detection from a guess; a `confidence: 0.0` / null-coordinate result
means the required landmark(s) weren't visible enough (same 0.5
visibility threshold `pnp_solve.py` already uses), never a
silently-wrong point. `chest_center` is derived as the midpoint of the
two chest-pocket estimates — same method `utils/extract_anchors.py` uses
for the 3D version. Additive only: `estimate_pose.py`'s `LANDMARK_NAMES`
gained a few more BlazePose index names (ears, eyes) that the head-region
heuristics need, but its return shape, and every existing caller
(`pnp_solve.py`, `rule_engine.py`, `api/main.py`), are untouched —
confirmed by the full pre-existing test suite passing unmodified.
`cv-service/pose/evaluate_pose_accuracy.py` measures accuracy against
labeled ground truth, **synthetic and real reported as two separate
numbers, never blended** (per this milestone's own requirement, since
synthetic accuracy reads better and would mask real-world performance):
against Milestone A's 3 synthetic stand-ins, mean error **143.55px**,
median **131.05px**, coverage **92%** (of 16 anchors × 3 photos) on
800×1200px renders — a real, moderate-to-poor number worth reading
plainly rather than as a pass, plausibly inflated by both the heuristic
anchors' inherent error and MediaPipe (trained on real photos) running
against a visibly synthetic placeholder body. **The real-photo row reads
0 photos, not a number** — same gap as the labeling milestone above, not
yet closed. Per this milestone's own instruction, the (already-shipped)
PnP camera-pose stage is explicitly flagged as not re-verified against
real-photo pose accuracy until that gap closes.

**Geometry — camera-pose solve + rule projection from the fuller pose
estimate (2026-08-11,
`ChangeRequest/2026-08-11_cv-service-geometry-camera-pose-rule-projection.md`):**
`cv-service/geometry/solve_camera_pose.py` takes Milestone B's anchor-keyed
2D pose dict directly (a different input contract than `pnp_solve.py`'s
own `solve_camera_pose(pose: PoseResult, ...)`, which is untouched) and
gathers up to 15 correspondences instead of `pnp_solve.py`'s fixed 7,
excluding the derived `chest_center` (adds no new geometric information —
it's just the midpoint of two anchors already in the set). Reuses
`pnp_solve.py`'s `CameraSolution` type and `project_point()` rather than
reimplementing projection math. Confidence filtering defaults to `>= 0.3`
(a straight 0.5 visibility-style cutoff would exclude nearly every
heuristic anchor Milestone B produces, even at high underlying
visibility) and `>= 6` correspondences (solvePnP's mathematical minimum
is 4; 6 gives a stability margin). Degenerate cases are flagged, not
silently returned: too few correspondences, `solvePnP` non-convergence,
or reprojection error above the same shoulder-width-scaled dynamic
threshold `pnp_solve.py` already uses all produce an explicit
`solved=False` or `reliable=False`, never a silent bad camera.
`cv-service/geometry/project_rules.py` doesn't reimplement rule
resolution either — it calls `rule_engine.resolve_rules()` and adds the
one field that wasn't already surfaced: per-rule `angle_deg`/
`tolerance_deg`, read straight from each rule's doctrine JSON (e.g. cap
badges: `tolerance_deg=10`; presence-only rules like `army_beret`
correctly get `None`, not an invented default).

Measured against Milestone A's 3 known-camera synthetic stand-ins (exact
render camera, not approximate): reprojection error 25.6–36.5px (mean
32.1px on 800×1200px renders) looks reasonable in isolation — the actual
finding is what happens when translation error is broken into
components rather than reported as one number. Lateral (in-image-plane)
error is good: 2.7–7.9cm, mean 6.1cm. **Depth error (distance along the
camera's viewing axis) is large and unstable: 7.6–101.6cm, mean 61.9cm —
up to roughly a metre.** This is a real, expected single-view-PnP
limitation (near-frontal body landmarks give almost no parallax to
constrain depth specifically), verified empirically (solved rotation is
near-identity, solved lateral translation matches the known camera
closely, isolating the error to depth) rather than assumed. Practical
read: the geometry is sound for what `project_rules.py` actually needs
— 2D crop-region placement, which depends on reprojection accuracy and
lateral position, both fine here — but not yet trustworthy for anything
that depends on recovered depth alone from a single photo. Same
real-photo gap as every other subsection: **0 real photos**, so this
entire table is synthetic-only.
**Superseded 2026-09-28:** the depth error was the mirrored-anchor bug
described in the accuracy-program subsection below, not a single-view
limitation, and the evaluator graded the mirrored solution against the
wrong rotation convention.

**Segmentation real-vs-synthetic comparison tooling — built, verified
mechanically, reports 0 real photos today (2026-08-11,
`ChangeRequest/2026-08-11_cv-service-segmentation-real-vs-synthetic-comparison-tooling.md`):**
the task this plan answers was originally scoped as "run the trained
segmenter against Milestone A's real photos" — re-checked before writing
the plan, and Milestone A has none (all 3 of its labeled photos are
synthetic stand-ins). Rather than substitute synthetic data and call it
"real-world," this plan built the comparison **tooling** only, ready to
produce a real result the moment real photos exist.
`evaluation/segmentation_label_conversion.py` converts Milestone A's
ground-truth label JSON into the exact YOLO-seg dataset format
`training/generate_segmentation_dataset.py` already produces (same
normalized-polygon-per-line format, same `CLASS_ID` ordering) —
`is_synthetic_stand_in: true` labels excluded by default
(`require_real=True`), so `model.val()` runs through the **identical**
Ultralytics code path for both sides of the comparison, making "real
mAP50" and "synthetic mAP50" genuinely comparable rather than two
differently-computed numbers. `evaluation/compare_segmentation_real_vs_synthetic.py`
re-runs synthetic validation live against `cv-service/synthetic_data/seg_v1/`
(confirmed to reproduce the exact previously-documented per-class numbers
— 0.995/0.995/0.995/0.904/0.496/0.222/0.524/0.556/0.995 — proving both
runs exercise the same code path), builds the real side from any
non-synthetic labels, and — finding none — reports **"Real photos found:
0 (skipped 3 synthetic stand-ins)"** rather than a fabricated table.
`flag_regressions()` (threshold: 0.15 absolute mAP50 drop, justified
against the weakest synthetic classes already sitting at 0.5–0.6 — see
the plan) and a `Diagnosis` structure (fixed vocabularies for root-cause
category and proposed fix) exist and are tested, but every field stays
unpopulated by construction — there are no real regressions yet to
diagnose. Mechanically verified via a clearly-labeled **smoke test only**
(`require_real=False` against Milestone A's 3 stand-ins, explicitly not
reported as a finding): confirms the converter + `model.val()` pipeline
runs end-to-end, and — as predicted, since those renders composite no
accessory GLBs — only `shirt`/`trousers`/`footwear` had any ground-truth
instances to measure at all.

**Verdict engine — geometric pass/fail/missing/unverifiable, Army No.3
Male (2026-08-11,
`ChangeRequest/2026-08-11_cv-service-verdict-engine-army-no3-male.md`):**
given Milestone C's projected zones and the trained segmenter's detected
regions, `rules/rule_engine.py`'s `evaluate_verdicts()` produces one of
four statuses per accessory, never forcing pass/fail where the detector
can't back it up. Tolerances are **not invented** — doctrine's own
`tolerance_cm`/`tolerance_deg` fields (already in `army_no3_male.json`)
are the source of truth: detected-mask centroid vs. the projected
doctrine point, compared via `tolerance_cm` converted to px through
`cm_per_px`; rules with no cm figure (berets, turbans, epaulettes,
footwear, socks) get a generous region-overlap check instead of a tight
one doctrine doesn't justify. `segmentation/mask_geometry.py` adds mask
orientation estimation (`cv2.minAreaRect`, mod-180°) for `angle_deg`/
`tolerance_deg` rules, refusing to guess (`None`) when a mask's aspect
ratio is too close to square (<1.3) to have a reliable long axis.
`unverifiable` is returned, with a stated reason, for: no segmentation
class exists for a doctrine category (5 of 18 rules — `name_tag`,
`medal_ribbons`, `saf_badges_chest`, `skill_tabs_sleeve`,
`skill_badges_sleeve` — plus `socks`, always reported even when the rule
is optional, so a report can't look like every category was checked when
several structurally never were); the projected region falls outside the
photo (occlusion / extreme camera angle, distinct from a confident
`missing`); the camera solve itself was unreliable (wires up Milestone
C's own `CameraSolution.reliable` — one unreliable camera solve makes
every verdict for that photo `unverifiable`, not silently-wrong `pass`es
built on a bad camera); or an ambiguous orientation reading. 9 segmentation
classes cover only some doctrine categories, several shared by multiple
rank-tier/variant rules (3 cap-badge rules → 1 `cap_badge` class, etc.)
— this engine can confirm presence + position, never *which* variant,
by design, not by oversight. First milestone this session to chain
**B → C → the trained segmenter → a verdict** end-to-end: measured
against Milestone A's 3 stand-ins, `footwear` precision/recall = 1.0/1.0
(n=2 — thin, not a strong claim), every other accessory class has zero
ground-truth-positive examples in that data (no accessory GLBs
composited into the stand-ins) so precision/recall are correctly `N/A`
(undefined at zero positives), not padded to a fake number — and
`standin02`'s cropped-out feet correctly produced `unverifiable`, not a
false `missing`, confirming the occlusion handling on a real pipeline
run. Same real-photo gap as everywhere else in this section: **0**.

**Wired into `/inspect` + the Flutter dev scorecard — code-complete,
not human-verified (2026-08-11,
`ChangeRequest/2026-08-11_flutter-geometric-verdict-ui-wiring.md`):**
three explicit decisions, stated up front rather than left implicit.
(1) **Runtime shape unchanged** — `cv-service` still has no Cloud Run
deployment, so there is nothing for a Cloud Function to proxy to yet;
the app keeps talking to `/inspect` directly over HTTP
(`CvServiceInspectionRepository`, dev-only, `kCvServiceBaseUrl`), same as
before. Building actual deployment + a Cloud Function proxy is a
separate infra project, not a byproduct of wiring a UI. (2) **Runs
alongside Phase 1, does not replace it** — `checkUniformCompliance.ts`
and the default capture flow are untouched; the new verdicts only
appear behind the existing long-press "PHASE 2 · DEV" path, because
nothing about this session's geometric verdict engine has been
validated against a real photo yet (see above). (3) **`/inspect` runs
the geometry stack twice** — the endpoint's original vision-crop path
keeps using its existing `pose/estimate_pose` + `calibration/pnp_solve`
computation untouched; `report["geometric_verdicts"]` is computed by a
second, independent pass through `pose/anchor_mapping` →
`geometry/solve_camera_pose` → `rule_engine.resolve_rules` →
`rule_engine.evaluate_verdicts`, reusing the already-computed
segmentation result. Accepted redundancy, not an oversight — avoids any
risk to the already-tested vision-crop path; a natural unification point
once the new path has more validation. Always present as a (possibly
empty) list, never omitted, degrading silently to `[]` on any internal
failure (best-effort, consistent with how the segmentation field already
degrades). Dart side: `GeometricVerdictStatus` (`pass`/`fail`/`missing`/
`unverifiable`) is a **deliberately separate enum** from the existing
`CvVerdict` (5-state, vision-crop-specific) — same "documented, not
unified" posture as every other new judgment mechanism this session —
rendered as a new "GEOMETRIC VERDICTS" section in `_CvScorecard`, one row
per accessory with its doctrine reference, color/icon-coded (pass=green,
fail/missing=red, unverifiable=grey/help-icon, reusing the vision-crop
section's existing palette). `flutter analyze` clean, `flutter test`
82/82 passed (5 new), `.venv-tools/bin/pytest cv-service/tests/` 97/97
passed (confirmed via an actual FastAPI `TestClient` round-trip, not
just a unit call). **What did NOT happen: the task's own required
5-real-photo, human-reviewed end-to-end verification.** Zero real photos
exist, so this plan is marked `executed`, deliberately not `verified` —
stated as the honest status in the plan file itself, not silently
upgraded once the code-side work was done.

**Real-photo Phase 1 sanity-check runner — tooling only, unrun (2026-08-11,
`ChangeRequest/2026-08-11_real-photo-phase1-sanity-check-tooling.md`):**
before investing in labeling or training on real data, the cheapest
possible test of whether the geometric approach is sound at all: point
`evaluation/run_real_photo_sanity_check.py` at a folder of real photos
and see whether person-detection, pose, camera-solve, and segmentation
hold up or degrade — no labels, no new model, narrower and cheaper than
`evaluate_verdict_precision_recall.py` (which needs Milestone A-format
labels to score precision/recall). Verified mechanically via
`--include-standins` against the 3 synthetic stand-ins (explicitly not
a real-world finding) and against a `no3_acc/` folder found in
`cv-service/data/real_photos/` — individual accessory reference
pictures (belt, nametag, rank insignia, etc.), not photos of a person,
which the tool correctly reports as 0% person-detected rather than
silently miscounting them as usable real-photo data. **Not run for its
actual purpose** — needs the operator to supply 15-20 real photos
first; still 0 in this repo.

**`POST /check_uniform` — stable API contract + central config
(2026-08-28,
`ChangeRequest/2026-08-28_cv-service-check-uniform-api-contract.md`):**
a second, additive FastAPI endpoint alongside `/inspect`, built in
response to a detailed external backend spec — investigation found
~80% of that spec already existed under this section's prior milestones,
so this plan built the genuine gaps only: a stable response contract and
robustness, not a rewrite. Same underlying pipeline as `/inspect`'s
`geometric_verdicts` (anchor-mapping pose → PnP camera solve → rule
resolution → trained segmentation → `rules/rule_engine.py`'s
`evaluate_verdicts`), but as the endpoint's *primary* path — every
failure is a hard, typed error (`NO_PERSON_DETECTED`,
`MULTIPLE_PEOPLE_DETECTED`, `POSE_UNRELIABLE`, `SCALE_UNAVAILABLE`, five
image-quality codes from the new `api/validation.py` Stage-0 gate,
`UNSUPPORTED_UNIFORM`, `SEGMENTER_UNAVAILABLE`) rather than a
best-effort secondary pass. **Zero Anthropic dependency.** Response
shape: `{success, overall_status, overall_score, image_quality, person,
accessories[], summary}` (`api/response_schema.py`, a pure mapping
function), each accessory carrying `present`/`position_correct`/
`confidence`/`status`/`visibility`/`bounding_box`/`expected_position`/
`detected_position`/`error`/`doctrine_ref`/`message`. `status` gained a
new `SLIGHTLY_MISALIGNED` band (between `tolerance_px` and
`tolerance_px × 1.5`) so a near-boundary measurement isn't forced into a
binary pass/fail — `VerdictResult` gained additive optional fields
(`confidence`, `bounding_box_px`, `expected_position_px`,
`detected_position_px`, `error_px`, `visibility`) that
`_evaluate_one_crop` already computed internally but previously
discarded; every pre-existing caller (`/inspect`'s `geometric_verdicts`,
all prior tests) is unaffected since the fields default to `None`/
`"uncertain"`. `include_debug_image=true` returns a debug overlay
(`reporting/report.py`'s new `render_debug_image_b64`) — expected/
detected markers + an error-vector arrow per accessory, distinct from
`/inspect`'s existing crop-box annotation.

New `cv-service/config.py` centralizes every confidence/tolerance
constant that was previously scattered as local per-file magic numbers
(and in one case genuinely duplicated — the segmentation-confidence
`0.4` in both `rules/rule_engine.py` and
`segmentation/segment_uniform.py`), each overridable via a
`CV_SERVICE_<NAME>` environment variable. Behavior-preserving: every
default matches what the code already used, confirmed by the full
pre-existing pytest suite (106 tests) passing unmodified after the
refactor. Total suite after this plan: 138 tests, all passing,
including a real end-to-end HTTP test of `/check_uniform` against the
existing rendered fixture photo.

Deliberately out of scope for this plan (see the plan file's "explicitly
out of scope" section): renaming `cv-service`'s folders to any
`vision/`/`glb/`/`compliance/`-style layout, a real trained accessory
bounding-box detector, per-accessory GLB geometry extraction, and
wiring `/check_uniform` into the Flutter app or Cloud Run — each is a
candidate follow-up plan, not built here. Same real-photo caveat as
every other cv-service milestone: this plan changes the API contract
and robustness, not the underlying detection/segmentation accuracy —
still synthetic-only, **0 real photos**.

**Flutter wiring of `/check_uniform` (2026-08-30,
`ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`):** the
AR Scanner's **default** capture button now calls `POST /check_uniform`
(`UniformCheckRepository` / `UniformCheckController` /
`UniformCheckResult` on the Flutter side — a third report shape,
deliberately not unified with `/inspect`'s `CvInspectionResult` or the
Phase-1 `ComplianceResult`) and renders `_RealScorecard` from the real
geometry verdicts. This replaced a fabricated "100% perfect match"
stand-in that always passed. **Still no Cloud Run deployment** —
`kCvServiceBaseUrl` defaults to `http://localhost:8001`, overridable per
device with `--dart-define=CV_SERVICE_BASE_URL=...`; an unreachable
service produces an explicit "analysis service unreachable" failure
screen, never a fake pass. Code-only: `flutter analyze` clean,
`flutter test` green (9 new tests), **not device-verified** — needs the
operator to run `uvicorn` and point the app at it. Cloud Run deploy +
a Cloud Function proxy remain the open follow-up.

**Coverage gate + search-area-gated matching (2026-09-28,
`ChangeRequest/2026-09-28_cv-service-coverage-gate-and-matching.md`):**
two logic fixes to `/check_uniform`, independent of model accuracy.
(1) `overall_status` is now `PASS` / `FAIL` / **`INCOMPLETE`** — PASS
requires at least `MIN_VERIFIED_COVERAGE` (config, default 0.8) of the
*detector-backed* required items to have a definite verdict; below that
the result is `INCOMPLETE`, or `FAIL` if a required item was already
found `fail`/`missing`. Previously unverifiable items were silently
dropped from the score, so 1 verified pass out of 7 read as 100 → PASS.
Required items with no segmentation class (name tag, socks) are excluded
from the gate's denominator — otherwise PASS would be impossible for
every profile — and reported in a new additive `coverage` object
(`verified_required`, `checkable_required`, `fraction`,
`not_checkable_required`). (2) `evaluate_verdicts` only accepts a
detection whose mask centroid lies inside the rule's crop (search) box,
and assigns detections to a rule's crops one-to-one (greedy by
distance) — a stray or other-side detection can no longer turn an empty
expected region into a misplaced `fail` (it's now `missing`, with the
out-of-area detection noted in the reason), and one detection can no
longer satisfy both sides of a paired item. `/inspect`'s
`geometric_verdicts` inherits (2). Flutter's `_RealScorecard` shows
`INCOMPLETE` (warn colour + retake hint) via
`UniformCheckResult.incomplete`.

**Accuracy program — everything short of real photos (2026-09-28,
`ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`).** The
`/check_uniform` flow now lives in `api/pipeline.py` (`solve_geometry` +
`run_check`, shared by the endpoint, `POST /check_uniform_burst` and the
benchmark). Stages, in order:
1. Stage-0 gate; **blur measured on the person crop** (`check_sharpness`) —
   whole-image Laplacian variance falsely rejected 40% of benchmark photos
   against plain walls.
2. Segmentation with manual **flip TTA** (Ultralytics' `augment=True` is a
   no-op for seg models). Loader prefers `segmentation_v2` only once
   `models/segmentation_v2/training_complete.json` exists (Ultralytics
   rewrites `best.pt` every epoch — the service used to pick up a
   half-trained model); `CV_SERVICE_SEGMENTATION_MODEL` pins one;
   `tests/conftest.py` pins the regression tests to v1.
3. Pose: `pose_landmarker_heavy` on the padded/upscaled person crop;
   **fitted landmark→socket offsets** (`pose/anchor_offsets.male.json`,
   fitted by `pose/calibrate_anchor_offsets.py` on 60 dressed renders in a
   body-aligned frame) — anchor error on the 3 stand-ins 55.6 → 5.7 px.
4. **Mask-refined anchors** (`geometry/mask_anchor_refinement.py`):
   head_top from headwear, belt_center from the shirt/trousers waistline
   (never from the belt it later judges), ankles from footwear.
5. Camera: **anatomical anchor names** (`utils/extract_anchors.py
   _to_anatomical_sides` — the GLB's socket names are left/right-swapped,
   which made every earlier solve a mirrored, body-behind-the-camera fit),
   **behind-camera guard**, frontal-seeded iterative + SQPnP, **EXIF focal
   length** (`api/intrinsics.py`; guessed focal = 57-115 cm depth error,
   true focal = 0-4 cm), anchors scaled to **`height_cm`**, and a final
   **weighted** least-squares refinement (1/σ per anchor from the fitted
   residuals) with an optional **gravity prior** (`gravity_x/y/z`).
6. Rules: derived **`cap_badge_tier`** (cap-badge conditions used to test a
   `rank_tier` value the app never sends — no enlistee/specialist had their
   cap badge checked); tolerance from the **local px/cm** at each rule's 3D
   point; per-rule geometric uncertainty.
7. **Two-stage** re-segmentation of small items' search boxes (one batched
   call) and **zero-shot** YOLO-World + SAM 2 for empty headwear / belt /
   footwear boxes only (measured: true large items score 0.61-0.91, a bare
   head scored 0.18 as "beret", small items < 0.2 → accept ≥ 0.45). **A zero-shot region can't certify an item** (2026-10-09, `ChangeRequest/2026-10-09_cv-service-zero-shot-false-beret.md`): the verdict is `unverifiable`, `failure_kind: "unconfirmed"` — YOLO-World scored the hair of a bare head 0.72 as "beret", so a missing beret used to pass.
8. Verdicts measure the doctrine **reference edge** (`reference_point`,
   e.g. the name tag's bottom edge) and decide with **calibrated
   uncertainty**: pass only if distance + u ≤ tolerance, out-of-tolerance
   only if distance − u > tolerance, else `unverifiable` (`failure_kind:
   boundary`) with the measured offset in the instruction.
   `UNCERTAINTY_REPROJECTION_WEIGHT`/`_MASK_FRACTION` (1.35 / 0.09) are
   fitted by `evaluation/calibrate_uncertainty.py` to cover 90% of real
   measurement error.
9. **Colour** (shoes/socks black relative to the shirt; only where doctrine
   states a colour — the Army beret is dark green / formation-dependent),
   **badge variant** (DINOv2 vs `assets/accessories/<id>/image.png`, fails
   only on a clear margin), **name-tag OCR** (EasyOCR vs any word of the
   profile full name, sent as `wearer_name`).
10. Response adds per-item `instruction` (cm + wearer's left/right),
    `required`, `checkable`, `detection_source`, `tolerance`-aware text,
    `summary.slightly_misaligned`, and a `camera` block (focal + source,
    reprojection, gravity disagreement, height scale).

`POST /check_uniform_burst` runs 1-5 frames and keeps each item's strict
majority status (`api/burst.py`; no majority → `UNCERTAIN`,
`frame_agreement` per item). `segmentation_v2`: 12 classes (adds
`name_tag`, `socks`, `hand` — fixes "hands labelled trousers"), 1 150
domain-randomised renders (`training/generate_segmentation_dataset_v2.py`:
procedural backgrounds, lighting, camera roll/offset, body proportions,
accessory variants and random absences, blur/noise/JPEG), yolov8s-seg at
768 px.

**Measured on the synthetic violation benchmark**
(`training/generate_violation_benchmark.py` — 60 scenes, 540 item
verdicts with exact ground truth: doctrine-exact placements plus injected
displacements of 0.5/1.25/2× tolerance, removals, wrong-pocket name tag,
wrong cap-badge variant, grey socks; scored by
`evaluation/run_violation_benchmark.py`, results in `cv-service/logs/`,
gitignored):

| Variant | Exact | Violation recall | False alarms | Abstain |
| --- | --- | --- | --- | --- |
| baseline (program stages off, bug fixes kept) | 10.2% | 56.6% | 52.6% | 39.4% |
| program, v1 segmenter | 15.9% | 45.3% | 32.9% | 52.8% |
| **program, v2 segmenter (default)** | **36.1%** | **60.4%** | **5.5%** | 58.1% |

(v2: 93% of correctly placed items detected vs 32% for v1; mask mAP50
0.879 on its domain-randomised synthetic val split. Per item, v2 abstains
on the tight-tolerance badges — cap badge 87%, insignia 90%, arms badge
97% — and still falsely flags epaulettes 15.5% / belt 17.9% of the time,
so no truly compliant benchmark scene reached PASS: 9 FAIL, 6
INCOMPLETE. 13/60 scenes are rejected as genuinely blurred.)

**The central, honest finding:** even with the geometry fixed, the
pipeline's measurement error on correctly placed items is a median
0.78 cm with v2 (1.3 cm with v1) — the same order as doctrine's 0.8-1.5 cm
tolerances. With uncertainty
calibrated so correct items aren't flagged, ±1 cm items cannot be
*certified* from one full-body photo at ~2.5 m and come back "too close to
call" (with the measured offset). Missing items, wrong variants/colours
and clearly misplaced items are still caught. The next accuracy step is a
second, closer upper-body photo (pixel error roughly constant → cm error
halves), plus real labelled photos. Everything here is synthetic-only —
**0 real photos**.

App side: live pose guidance (`live_pose_guide.dart`) replaced a fixed
1.8 s "aligned" timer; `DeviceTilt` supplies gravity; default capture is a
3-frame burst; `heightCm` on the profile; scorecard shows instructions,
the overlay image, "could not check" vs "check by eye". Fixed in passing:
typed error codes were read from the wrong key (always lost), and
responses were decoded as Latin-1 (garbled "—"/"°"). `flutter test` runs on
this machine without accepting the Xcode licence via an `xcrun` shim to the
Command Line Tools SDK (see the plan's verification notes).

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
  **No. 4 dress** is aligned with the SAF No.4 Dress PDF
  (`ChangeRequest/2026-10-02_no4-dress-doctrine-alignment.md`):
  - All ranks wear one chest-centre rank tab; there are no sleeve
    chevrons, collar pins or shoulder epaulettes.
  - Berets for men and ladies; boots instead of shoes; per-branch belt,
    socks and inner shirt.
  - **Combat boots are compulsory for every service; safety boots
    (Navy mid-cut / low-cut shoes, RSAF / DIS safety boots) are optional**
    — a product decision that overrides the PDF's per-service default
    (`ChangeRequest/2026-10-19_no4-combat-boots-required.md`). The RSAF
    figures' built-in boots are declared `combat_boots` in
    `assets/3d/figures/rsaf_no4.json` so compose keeps them.
  - The PDF's cm placement rules (chest/sleeve badges, RSAF 10/20/5 mm,
    DIS patches) are stored as metadata in `branch_overrides`.
  - **RSAF No.4** (2026-10-02,
    `ChangeRequest/2026-10-02_rsaf-no4-unified-figures.md`): it uses the
    artist dressed figures `models/bodies/rsaf_no4_{male,female}.glb`,
    prepared by `tool/prepare_unified_figure.mjs` from
    `assets/3d_raw/rsaf_no4_*_source.glb`. They're uploaded and
    `composeUniformModel` is deployed.
    - The operator's misnamed `models/uniforms/rasf_no4_*.glb` uploads
      are unused and can be deleted.
    - The Sikh turban swapped in is the light-blue procedural placeholder.
    - The built-in rank tab shows one insignia for all non-cadet ranks.
  - The other branches' No.4 models are still the generic body +
    accessories until their figures are delivered.
  - cv-service has no No.4 rules, so `/check_uniform` returns
    `UNSUPPORTED_UNIFORM` for No.4. That is a separate follow-up.
  - **The device keeps showing the old No.4 stub until the operator runs
    `upload_accessory_images.py`, `seed_firestore.dart` and
    `upload_models.py --only 'accessories/*'`.**

  **No.3 completed for every service / gender / Sikh / rank (2026-10-19,
  `ChangeRequest/2026-10-19_no3-no4-full-coverage.md`).** The Dart
  resolver now:
  - treats maternity as ladies (as the TS port does);
  - picks ladies' hats by tier — BG, officer/WO, else the
    `specialist…` key; a lady OCT gets the specialist hat;
  - gives the Navy white turban (`sikh_3wo_me3_above`) to 3WO and above;
  - resolves No.3 `epaulettes {standard, cadet_trainee | me_trainee}` for
    men only, and the new `ladies_rank {collar_pins, gorgette_officer_cadet,
    gorgette_me_trainee}` for ladies (officers / WOs → collar pins, OCT →
    gorgette);
  - gives the cap embellishment (service-hat peak) to ladies only, with
    the MAJ–SLTC / SWO–CWO tier;
  - picks BG cap badges for DIS (`bg_me8_radm_above`) and RSAF (beret vs
    service hat).

  No.3 `additional_optional` lists medal ribbons and the SAF / sleeve /
  foreign badge groups. `test/features/checklist/no3_no4_coverage_test.dart`
  checks every combination for a complete dress with a picture on every
  item. **The TS port (`functions/src/dress_accessory_resolver.ts`) was
  not updated**, so the 3D compose still omits No.3 epaulettes / collar
  pins / gorgettes, gives men the Navy/RSAF embellishment, and misses the
  BG DIS/RSAF badges. Aligning it attaches new GLBs and needs a Functions
  deploy — a separate plan.

  No. 1, 2, 5 still reference legacy generic placeholder accessories
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
  Legacy No.1 / 2 / 5 entries will stay empty until their doctrine
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
- **AR Scanner default capture = real geometry now (2026-08-30,
  [ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md](ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md)):**
  the default tap sends the captured photo to `cv-service`'s
  Anthropic-free `POST /check_uniform` (`UniformCheckController`) and
  renders `_RealScorecard` from the pixel-space verdicts (pose → PnP
  camera solve → trained segmentation → doctrine tolerance check). This
  replaced a fabricated "100% perfect match" stand-in
  (`_capture` → `_buildResult`) that always passed regardless of what
  the photo showed. **`cv-service` has no deployment** — set
  `--dart-define=CV_SERVICE_BASE_URL=http://<host>:8001` and run
  `uvicorn`; an unreachable service shows an explicit failure screen,
  never a fake pass. Code-only, not device-verified. The Phase-1
  `checkUniformCompliance` Cloud Function (Node/Anthropic, trial
  billing) is **disabled** — `uniform_compliance_provider.dart` and its
  import are commented out; the model + test are kept for re-enabling.
  `google_mlkit_pose_detection` is still used by the capture-quality
  gate (below); live continuous per-frame pose detection / AR overlay
  against the camera feed remains out of scope — capture-then-analyze.
- **In-app live camera (2026-08-11,
  [ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md](ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md)):**
  `ARScannerScreen` now owns a `CameraController` and renders a live
  `CameraPreview` for its capture flow (both the default Phase-1 tap
  and the Phase-2 long-press dev path share the same preview),
  replacing the prior `image_picker`-launches-the-OS-camera-app
  hand-off. The `camera` dependency is no longer unused. A
  `WidgetsBindingObserver` (this app's first) disposes/reinitializes
  the controller around app backgrounding, per the `camera` package's
  own documented pattern. `gallery_tab.dart`'s separate photo-upload
  flow is untouched and still uses `image_picker`. This plan also fixed
  a bug where every compliance-check failure showed the same hardcoded
  "check your connection" message regardless of cause (unauthenticated,
  missing profile, bad photo, genuine connectivity, etc. all looked
  identical to the user) — `describeCaptureError()`
  (`lib/features/ar_scanner/presentation/utils/capture_error_message.dart`)
  now maps the actual thrown `FirebaseFunctionsException`/
  `CvServiceInspectionException`/`UniformCheckException` to an accurate
  message (the last added 2026-08-30 — unreachable `cv-service` vs. its
  typed error codes).
- The Wearing Guide was a fixed list of 9 No.3 steps until 2026-10-19; it
  now builds its steps from the active dress (see `wearing_steps.dart`).
  Accessory names and tips come from Firestore and are English-only.
  No.1/2/5 show the base garments plus belt/socks/footwear and a
  "pending doctrine review" note.
- The Wearing Guide voice narration is a no-op stub
  ([`WearingGuideScreen`](lib/features/wearing_guide/presentation/screens/wearing_guide_screen.dart));
  TTS will land separately.
- **iOS build (2026-08-30,
  [ChangeRequest/2026-08-30_ios-build-enablement.md](ChangeRequest/2026-08-30_ios-build-enablement.md)):**
  iOS had never built in this repo — `ios/Podfile` line 3 was a stray
  shell command. Fixed, plus: deployment target 13.0 → 15.5 (MLKit),
  `Info.plist` gained `NSAllowsLocalNetworking` + `NSLocalNetworkUsageDescription`
  (dev concession so the app can reach the LAN `cv-service` over http —
  remove before any App Store submission), and the FlutterFire family
  was bumped (`cloud_firestore` 6.3.0 → 6.9.0 etc.; < 6.9 won't compile
  against the current firebase-ios-sdk). `flutter build ios --release
  --no-codesign` now produces `Runner.app`; `flutter build apk` still
  green. **Not run on a physical iPhone** — that needs the operator's
  Apple ID team set in Xcode (`open ios/Runner.xcworkspace`) then
  `flutter run --release` to a connected device; a free Apple ID works
  but the install expires after 7 days. MLKit pods lack arm64 for
  Apple-Silicon **simulators** (iOS 26+) — devices are fine.
- Logging is sparse; bring it up to policy 1.3 as you touch each method.
