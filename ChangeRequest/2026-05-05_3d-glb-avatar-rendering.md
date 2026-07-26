# 3D GLB avatar rendering — `model_viewer_plus` + server-side composition

- **Date:** 2026-05-05
- **Author:** Claude (Datta-driven session)
- **Status:** executed
- **Verification:** `flutter analyze` clean, `flutter test` 64/64 pass,
  `cd functions && npm run build` clean. End-to-end app run + Cloud
  Functions deploy + Storage-rules deploy still pending — operator
  responsibility (policy 1.5 verified once that is done).

## 1. Goal
Replace the flat `_GhostFigurePainter` silhouette with a true 3D personalised
avatar that:
- Renders a human-like 3D figure (male / female / maternity) wearing the
  correct SAF dress for the user's profile.
- Places every accessory on the right anchor (collar, chest, sleeve, head,
  belt, foot).
- Lets the user spin / tilt / pinch-zoom in `GhostScreen`.
- Is **per-user** — driven by branch, rank, gender, dress code, isSikh,
  accessories, name tag.
- Is **stored** in Firebase Storage with a URL + content-hash on the
  Firestore profile, so it is generated once and only regenerated when the
  profile actually changes.
- Has near-zero ongoing cost (hash-gated; no per-render AI fees).

The visual target is the SAF doctrine PDF (DIS No.3 men / women /
maternity reference illustrations).

## 2. Scope

### In scope (this plan)
- New `composeUniformModel` Cloud Function (TypeScript, Node 20) that
  loads the user's profile, picks body + uniform + accessory GLBs from
  Firebase Storage, merges them with `@gltf-transform/core`, paints the
  user's name onto a name-tag texture, optimises with Draco + KTX2, and
  uploads the composed GLB to `user_models/{uid}/{dressCode}.glb`.
- TypeScript port of `DressAccessoryResolver` so the CF resolves the
  same accessory list as the Flutter client.
- Extension of `GeneratedDress` entity with `modelUrl`, `profileHash`,
  `schemaVersion`, `generationStartedAt`, `error` fields, plus DTO
  serialisation.
- New Flutter side: `profile_hash.dart` (pure fn matching server hash),
  `ModelGenerationRepository`, `generatedDressProvider`,
  `modelGenerationControllerProvider`.
- `UniformProfileNotifier` debounce-followup: after a profile change is
  persisted, fire-and-forget a hash check + regen call for the current
  dress code.
- `GhostScreen` swap: `_GhostFigurePainter` → `ModelViewer`, with
  loading / error / generation states.
- `storage.rules` update: read-only `models/**` library, owner-scoped
  `user_models/{uid}/**`.
- New `functions/` deps: `@gltf-transform/core`, `@gltf-transform/extensions`,
  `@gltf-transform/functions`, `meshoptimizer`, `draco3dgltf`, `sharp`.

### Out of scope (future plans)
- Authoring the actual 3D assets (body GLBs in MakeHuman, uniform /
  accessory commissions). The CF ships with placeholder GLB box geometry
  fall-backs so the pipeline is end-to-end testable before art lands.
- Photo-based avatar (Phase 2 — Ready Player Me face replacement only).
- Other dress codes (No.1, No.2, No.4, No.5) — Phase 2 once No.3 ships.
- Real-time animation, AR overlay on detected pose. `model_viewer_plus`'s
  free WebXR AR mode is enabled but pose-detection AR is its own plan.
- Hotspot pin re-alignment to true 3D coordinates — Phase 2 polish.

## 3. Affected areas

### Flutter
- `lib/features/profile/domain/entities/generated_dress.dart` — extend.
- `lib/features/profile/data/dtos/uniform_profile_dto.dart` — serialise new fields.
- `lib/features/profile/presentation/providers/uniform_provider.dart` — debounce-followup.
- `lib/features/ar_engine/data/profile_hash.dart` — NEW.
- `lib/features/ar_engine/data/model_generation_repository.dart` — NEW.
- `lib/features/ar_engine/presentation/providers/generated_dress_provider.dart` — NEW.
- `lib/features/ar_engine/presentation/providers/model_generation_controller.dart` — NEW.
- `lib/features/ar_engine/presentation/screens/ghost_screen.dart` — swap painter for `ModelViewer`.
- `lib/features/ar_engine/presentation/widgets/ghost_model_view.dart` — DELETE (legacy).
- `pubspec.yaml` — `model_viewer_plus` already present; no new deps.

### Backend
- `functions/package.json` — add gltf-transform, draco, sharp, meshoptimizer.
- `functions/src/composeUniformModel.ts` — NEW.
- `functions/src/dress_accessory_resolver.ts` — NEW (TS port).
- `functions/src/index.ts` — re-export `composeUniformModel`.

### Firebase
- `storage.rules` — add `/models/**` + `/user_models/{uid}/**` blocks.

### Storage
- `gs://saf-uniforms.firebasestorage.app/models/{bodies|uniforms|accessories|textures}/*` — NEW asset library bucket layout (population by operator script in a follow-up plan).
- `gs://saf-uniforms.firebasestorage.app/user_models/{uid}/{dressCode}.glb` — NEW per-user composed output, written exclusively by the CF.

### Firestore
- `users/{uid}/profile/current.generatedDresses[<dressCode>]` — extended shape (new optional fields).

## 4. Step-by-step plan
1. Extend `GeneratedDress` entity with new fields + regenerate freezed.
2. Update `UniformProfileDto` to serialise new fields.
3. Add `profile_hash.dart` (sha256 first 16 hex chars; sorted JSON).
4. Add `model_generation_repository.dart` (wraps `composeUniformModel` callable).
5. Add `generated_dress_provider.dart` (AsyncValue per `DressCode`, watches Firestore).
6. Add `model_generation_controller.dart` (triggers regen, in-flight state).
7. Wire `UniformProfileNotifier`: after debounced upsert, fire-and-forget regen if hash changed.
8. Replace `_GhostFigurePainter` in `ghost_screen.dart` with `ModelViewer` + loading/error/generate states. Keep hotspot pin overlay as-is for v1.
9. Delete `ghost_model_view.dart` (legacy placeholder).
10. Update `storage.rules` and deploy (operator step).
11. Add Cloud Function deps in `functions/package.json`.
12. Port `DressAccessoryResolver` → `dress_accessory_resolver.ts`.
13. Implement `composeUniformModel` CF (validate, hash check, load asset GLBs from Storage, merge via gltf-transform, bake name tag with sharp, Draco+KTX2 compress, upload, write Firestore).
14. Re-export from `functions/src/index.ts`.
15. Run `flutter analyze`, `dart run build_runner build --delete-conflicting-outputs`, `cd functions && npm run build`.
16. Update relevant CLAUDE.md sections (policy 1.2).

## 5. Risks & rollback
- **Composed GLB > 8 MB target / 10 MB hard ceiling.** Mitigation: Draco mesh compression + KTX2 textures in CF; CF fails-loudly above ceiling so we catch it during QA.
- **Asset library not yet populated.** Mitigation: CF detects missing GLB, uploads a small `box_placeholder.glb` so the pipeline is still end-to-end testable; logs a warning; UI shows a generic 3D box. Real assets land via the operator upload script in a follow-up plan.
- **`model_viewer_plus` performance on low-end Android.** WebView-based renderer; revisit native renderer (`flutter_3d_controller`) if frame-rate is unacceptable.
- **Cloud Function cold start latency.** First generation takes ~5–10s including 3D mesh ops. UI shows a generation progress state; subsequent loads hit the cached `modelUrl`.
- **Rollback:** revert this plan's commit; clients silently fall back to `_GhostFigurePainter` because `dress.modelUrl` will be `null` and the `GhostScreen` already shows a `_GeneratePromptView` in that case. No destructive Firestore writes — new fields are all optional.

## 6. Verification
1. `flutter analyze` clean.
2. `dart run build_runner build --delete-conflicting-outputs` — `GeneratedDress` codegen passes.
3. `cd functions && npm run build` — TS compiles.
4. `firebase deploy --only functions,storage:rules` (operator).
5. End-to-end smoke test (after operator uploads at least placeholder GLBs to `models/`):
   - New user → Welcome → Config → Dashboard → Ghost screen.
   - Verify `composeUniformModel` is called once (CF logs).
   - Verify `users/{uid}/profile/current.generatedDresses['No3']` has `modelUrl` and `profileHash`.
   - Verify `ModelViewer` renders the figure with rotate + zoom.
   - Change rank in Profile tab → return to Ghost screen → verify regeneration fires (new `builtAt`, fresh GLB).
   - Toggle Sikh flag → verify the turban replaces beret.
6. Update plan status → `executed` then `verified`.

## 7. CLAUDE.md updates required
- §3 Tech stack — confirm `model_viewer_plus` is now wired (move from "shipped but not used" to "active").
- §4 Source tree — add new files under `lib/features/ar_engine/`.
- §5.1 Architecture — note `composeUniformModel` Cloud Function and the per-user composition pipeline.
- §5.2 State management — add `generatedDressProvider` and `modelGenerationControllerProvider`.
- §5.5 Backend — add `composeUniformModel` to the Cloud Functions list, add `models/**` and `user_models/{uid}/**` to Storage layout.
- §8 Known gaps — remove the "model_viewer_plus shipped but not yet wired" line; add a new gap for the asset library being populated.
