# Army No.3 Male — Pass 5: face-axis rotation + scene consolidation

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** in-progress
- **Supersedes:** none (builds on pass-4 `2026-05-17_army-no3-uniform-y-flip.md`)

## 1. Goal

Two root causes diagnosed empirically:

### Root cause A — body & uniform meshes face the X axis

After pass-4 Y-flipped the uniform GLB, the device test showed the
model in profile on initial GhostScreen load (mouth pointing
camera-right at `cameraOrbit: '0deg 90deg 4m'`). Investigation with
`trimesh` + per-geometry world-bbox inspection showed:

- The body's main "body" mesh (60,659 verts) has bbox
  `x=±0.166, z=±0.324`. Z is the **wider** axis, meaning Z is the
  shoulder/arm-span axis (not front-back). The body's face is along
  ±X (specifically +X — user observation).
- The uniform's mesh has bbox `x=±0.159, z=±0.321`. Same pattern: Z
  is shoulder, X is front-back.
- The 18 socket markers (`cap_band_front`, `left/right_chest_pocket`,
  `left/right_sleeve_upper`, `belt_center`, `name_tag`, etc.) sit at
  `z > 0` — placed by `inject_sockets.py` assuming the body faces
  +Z, which is **wrong**. The sockets land on the body's SIDE, not
  its front.
- Pass-4's earlier nose-protrusion test (which reported nose at +Z)
  was misled by the socket-marker cubes themselves — their +Z
  positions dominated the head-slice's +Z extreme, not the body
  mesh's actual nose.

After pass-4 the uniform was 180° around Y. Net effect: body face +X,
uniform face -X → user-rotated to face-forward shows accessories on
the visible chest (because sockets at +Z = camera-right under user's
+Z-camera view) but the chevron / belt / etc. end up at the wrong
anatomic positions.

### Root cause B — `mergeDocuments` creates secondary scenes

Empirical simulation of the compose pipeline showed the merged GLB
contains 8 scenes (body, uniform, plus 6 from per-accessory merges).
`@gltf-transform/functions` `mergeDocuments` docs explicitly state
"Scenes and Buffers are not combined." Only the default scene (the
body's) is guaranteed to render. The remaining geometry lives in
secondary scenes which model-viewer may or may not render — even
when it does, the secondary geometry doesn't necessarily compose
with the body's coordinate frame the way the merger assumed.

## 2. Scope

In-scope:

1. Rotate the body's "body" mesh by **−90° around Y** (mapping face
   from +X to +Z), baked into vertex coords. Sockets and head/hair
   marker cubes are untouched (they're at the correct +Z positions
   the merger expects).
2. Rotate the uniform mesh so its face moves from −X (post-pass-4)
   to +Z, baked into vertex coords. Net rotation from raw Tripo
   source: 90° around Y.
3. Add `consolidateScenesToOne(doc)` helper to
   [functions/src/glb_compose.ts](../functions/src/glb_compose.ts).
   Call it from `compressForWeb`'s final cleanup pass alongside
   `consolidateBuffersToOne`. Result: every exported per-user GLB
   has exactly one scene with all geometry under the body's root.
4. Unit tests in
   [functions/src/glb_compose.test.ts](../functions/src/glb_compose.test.ts):
   - `consolidateScenesToOne` collapses N scenes into the first.
   - `consolidateScenesToOne` is a no-op for ≤1-scene documents.
   - Full pipeline (`mergeUniform` + 2× `attachAccessory` +
     `compressForWeb`) yields exactly 1 scene.
5. Bump `MODEL_BUNDLE_VERSION` 8 → 9 in
   [functions/src/profile_hash.ts](../functions/src/profile_hash.ts)
   and [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart).
6. Re-upload `models/bodies/male_apose.glb` and
   `models/uniforms/army_no3_male.glb`.
7. Re-deploy `composeUniformModel`.
8. Update [CLAUDE.md](../CLAUDE.md) §5.5 (bundle 8 → 9) and §8
   (pass-5 entry).

Out of scope:
- `attachAccessory` hierarchy fix (the second Explore agent flagged
  that mirror_left_right's `-1` X-scale lands on the accessory's
  `world` wrapper instead of the mesh node). The wrapper-vs-mesh
  scale is acceptable for the current accessories — chevrons are
  symmetric, shoes already ship as a single mirror-able mesh. Defer
  to a follow-up plan if the device test on Army No.3 male shows
  the mirror is genuinely broken (e.g. one of two paired accessories
  invisible). Cf. todo §3 in the follow-up.
- Re-orienting Navy / RSAF / DIS or No.1/2/4/5 uniforms (none
  uploaded yet).
- Authoring `tool/inject_uniform.py` (still tracked in
  `2026-05-17_inject-uniform-tool.md`).

## 3. Affected files

| File | Change |
| --- | --- |
| `assets/3d/bodies/male_apose.glb` | Rotated body mesh −90°Y (sockets untouched). |
| `assets/3d/uniforms/army_no3_male.glb` | Rotated 90° net (180° pass-4 baked, +180° flip), face now +Z. |
| `functions/src/glb_compose.ts` | Added `consolidateScenesToOne`, called from `compressForWeb`. |
| `functions/src/glb_compose.test.ts` | 3 new tests for scene consolidation. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 9`. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 9`. |
| `CLAUDE.md` | §5.5 + §8 updates. |

## 4. Step-by-step plan (executed)

1. Dumped body GLB node hierarchy + decomposed every node matrix.
   Confirmed all rotations are identity; only the body's main mesh
   needs rotating.
2. Verified body bbox shows X-span (33cm) < Z-span (65cm). Z is
   actually shoulder width. Body's face axis is X.
3. Verified uniform bbox shows same pattern. Face axis is X.
4. Loaded body GLB, applied −90°Y to only the "body" geometry's
   vertex data, saved. Confirmed post-rotation X-span (65cm) > Z-span
   (33cm).
5. Loaded uniform GLB with `force="mesh"` (baking the pass-4 180°
   rotation into vertex coords), applied −90°Y, recentred on x/z,
   feet at y=0, saved. Then applied another 180°Y (to get face
   from −Z to +Z) and re-saved.
6. Confirmed both meshes now have chest-band Z asymmetry showing
   `+Z > -Z` (chest forward at +Z).
7. Added `consolidateScenesToOne(doc)` to `glb_compose.ts`. Wired
   into `compressForWeb`'s final cleanup pass before
   `consolidateBuffersToOne`.
8. Added 3 unit tests asserting scene consolidation behaviour.
9. Bumped bundle version 8 → 9 in both `profile_hash.ts` and
   `profile_hash.dart`, with v9 docblocks documenting both root
   causes.
10. `cd functions && npm run build && npm test` — green, 21/21.
11. `flutter analyze` — clean.
12. (Operator) re-upload + redeploy + `flutter run`.

## 5. Risks & rollback

- **Risk:** body's face actually at −X (not +X as inferred from
  user observation). My −90°Y rotation maps +X → +Z; if face was at
  −X, it now points to −Z (away from camera). **Mitigation:** if
  device test shows back of head facing camera, apply another 180°Y
  rotation to body mesh and re-upload.
- **Risk:** accessory render_logic offsets are tuned against the old
  socket-on-side configuration. Some accessories may now visibly
  intersect the chest geometry. **Mitigation:** tune individual
  `offset_z_cm` values in `accessory_library.v1.json` per accessory;
  this is a fast iteration.
- **Risk:** `consolidateScenesToOne`'s `addChild` across scenes
  corrupts internal references. **Mitigation:** unit test verifies
  the final doc has exactly one scene with all expected roots; if
  it regressed, the test would fail before deploy.
- **Rollback:** every change is gated by bundle version 9. Revert
  the bundle bump, revert `glb_compose.ts` + test additions, and
  re-upload the pre-rotation GLBs via
  `git show HEAD~1:assets/3d/.../...glb`. Re-deploy.

## 6. Verification

Per CLAUDE.md §1.5:

1. `cd functions && npm run build` ✅ clean.
2. `cd functions && npm test` ✅ **21/21 pass** (3 new
   `consolidateScenesToOne` tests).
3. `flutter analyze` ✅ "No issues found!".
4. `flutter test` — unrelated `objective_c` native-build hook issue
   persists (pre-existing). No regression in our code.
5. Device — on Army / Sgt / male / non-Sikh / No.3, GhostScreen
   initial load shows model **face-forward** (not profile). Beret
   on head, cap badge on band-front, name tag on right chest,
   lanyard arc on front-right, sleeve chevrons on outer-upper
   arms, belt at waist, both feet shod.

## 7. CLAUDE.md updates required

- §5.5 — `MODEL_BUNDLE_VERSION` mention 8 → 9.
- §8 — append pass-5 note under the Army No.3 alignment bullet
  describing the face-axis rotation + scene-consolidation fix.
