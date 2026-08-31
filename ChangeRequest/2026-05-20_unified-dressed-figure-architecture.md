# Unified Dressed-Figure Architecture

- **Date:** 2026-05-20
- **Author:** Claude (with Datta)
- **Status:** in-progress

## Goal

Switch the 3D composition pipeline from a **separate body + uniform merge** approach to a
**unified dressed-figure** approach where a single Tripo3D-generated GLB represents the
complete uniformed soldier (shirt + trousers + body). Accessories are attached on top via
the existing socket system.

## Problem

13 passes of placement fixes have been fighting a fundamental structural issue:

- The body GLB and uniform GLB are generated independently by Tripo3D with no guaranteed
  coordinate-frame alignment.
- Sockets are injected into the naked body **before** the uniform is merged, so they
  reference the naked body's bbox — not the actual pocket/collar/shoulder positions on the
  shirt.
- Every Tripo generation produces a slightly different orientation (±X vs ±Z facing, 
  different torso depth, different up axis), requiring manual per-mesh correction passes.

Root causes discovered across passes 1–13:
- Face direction mismatch (body +X, uniform +Z → accessories on wrong side)
- Scale mismatch (uniform at native Tripo scale vs 1.78m body)
- `metallicRoughnessTexture` stray reference crashing belt load (pass 12)
- isSikh profile flag silently routing to turban instead of beret (pass 12)
- Sleeve chevron facing backward due to independent rotation on separate GLB (pass 13)

## Scope

### Code changes
- `functions/src/composeUniformModel.ts` — body-path resolution: check for
  `models/uniforms/{branch}_{dressCode}_{gender}.glb` first; when found, use it as the
  body document directly and skip `mergeUniform`.
- `functions/src/profile_hash.ts` — bump `MODEL_BUNDLE_VERSION` 21 → 22.
- `lib/features/ar_engine/data/profile_hash.dart` — bump `kModelBundleVersion` 21 → 22.
- `tool/inject_sockets.py` — add `--socket-overrides` flag for operator fine-tuning
  without editing source.

### Operator / asset actions (after code ships)
1. Generate `army_no3_male` unified dressed figure from Tripo3D Studio (see prompts below).
2. Run `inject_sockets.py --in <tripo_raw.glb> --out assets/3d/uniforms/army_no3_male.glb
   --target-height 1.78`.
3. Verify sockets in https://gltf-viewer.donmccurdy.com/.
4. Upload: `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app
   --only "models/uniforms/army_no3_male.glb"`.
5. `firebase deploy --only functions` + `flutter run` (compile-time constant bump).

## Tripo3D Prompts

### Text-to-3D
```
Full-body male soldier in A-pose (arms raised 30 degrees from the sides, palms facing the body, feet shoulder-width apart), Singapore Armed Forces No. 3 dress uniform. Light cream-olive short-sleeve formal military shirt: two large squared chest patch pockets with button flap covers, pointed spread collar with no tie, smooth pressed fabric, epaulette loop tabs sewn flat on both shoulders. Dark forest-green formal straight-cut trousers with sharp front creases. Shirt tucked in at waist. Short cropped black hair, neutral Asian male face, no expression. The model must NOT include: hat, beret, headgear of any kind, rank chevrons on sleeves, lanyard, collar pins, collar badges, chest medals, or any badges. Black leather low-cut Oxford shoes. Black leather belt with rectangular metal buckle centred at front. Realistic military proportions, 1.75 metres tall. Clean quad-dominant topology suitable for rigging. Non-overlapping UV layout. Neutral lighting, white background.
```

### Image-to-3D (recommended — upload the doctrine reference image)
```
Convert this Singapore Army No. 3 dress uniform illustration into a realistic 3D male character model. A-pose stance: arms raised to 30 degrees from body sides, palms facing inward, feet slightly apart. IMPORTANT EXCLUSIONS — do NOT include these items on the 3D mesh (they will be attached as separate 3D accessories later): beret or any headgear, cap badge, rank chevrons on sleeves, lanyard, collar badge or arm badge, name plate, epaulette rank slides. INCLUDE: the pale cream/olive short-sleeve shirt with two chest pocket flaps, dark olive formal trousers, black leather Oxford shoes, black leather belt with gold buckle, flat epaulette shoulder loop tabs. Style: realistic military, clean topology, 1.75m height, neutral facial expression.
```

## Affected areas

- `functions/src/composeUniformModel.ts`
- `functions/src/profile_hash.ts`
- `lib/features/ar_engine/data/profile_hash.dart`
- `tool/inject_sockets.py`
- New asset path: `models/uniforms/army_no3_male.glb` in Firebase Storage

## Architecture comparison

| Issue | Separate body + uniform | Unified dressed figure |
|-------|------------------------|----------------------|
| Alignment | Two independent Tripo meshes — caused 13 fix passes | One mesh, cannot misalign |
| Face direction | Independent orientations to fix per-mesh | One facing direction to verify |
| Socket accuracy | Sockets into naked body, not actual shirt pockets | Sockets injected onto real pocket geometry |
| Pipeline | mergeUniform step required | mergeUniform skipped |
| Backward compat | — | Falls back to old path for branches without unified GLB |

## Backward compatibility

The change is fully additive: the CF checks for the unified path first and falls back to the
existing `bodies/{gender}_apose.glb` + `uniforms/{branch}_{dress}_{gender}.glb` path when no
unified figure is present. Navy, RSAF, DIS, and all non-No.3 dress codes continue as before
until their own unified figures are authored.

## Risks & rollback

- **Risk:** `inject_sockets.py` bbox-proportional sockets may still miss actual pocket
  positions on the Tripo figure. **Mitigation:** the new `--socket-overrides` flag lets the
  operator specify exact XYZ without code changes.
- **Risk:** Tripo3D may bake in accessories (beret, chevrons) that we want as separate GLBs.
  **Mitigation:** use the image-to-3D prompt with explicit EXCLUSIONS list; re-generate if
  accessories appear in the output.
- **Rollback:** remove `army_no3_male.glb` from `models/uniforms/` in Storage → CF falls back
  to old path automatically (no code change needed).

## Verification

1. `cd functions && npm run build && npm test` — ✅ 2026-07-30: `tsc` builds clean, all 22
   `node --test` cases pass.
2. `firebase deploy --only functions` — not run (requires operator credentials / explicit
   deploy approval).
3. `flutter analyze` — ✅ 2026-07-30: was reporting 244 issues, all inside the gitignored
   `ios/build/ios/SourcePackages/**` Swift-Package-Manager dependency cache (a local build
   artifact, not project source — see fix below). Added an `analyzer: exclude:` block to
   `analysis_options.yaml` for `build/**`, `ios/build/**`, `android/build/**`; analyze now
   reports "No issues found!".
4. `flutter test` — ✅ 2026-07-30: all 73 tests pass.
5. `flutter run` on a real device — not run in this session (no attached device/simulator).
6. Open GhostScreen → Army No.3 male, trigger fresh compose, confirm placement — not run
   (depends on step 5).
7. Status left as `in-progress`: steps 1/3/4 verified clean; steps 2/5/6 (deploy + on-device
   visual confirmation) still need an operator with deploy credentials and a device/simulator.
