# Army No.3 Male — Uniform −Z Facing Y-Flip (Pass 4)

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** in-progress
- **Supersedes:** none (additive on top of [2026-05-17_army-no3-body-uniform-alignment.md](2026-05-17_army-no3-body-uniform-alignment.md) pass 3 — body / uniform alignment fix)
- **Follow-up:** [2026-05-17_inject-uniform-tool.md](2026-05-17_inject-uniform-tool.md) (proposed, un-executed — proper `tool/inject_uniform.py` normaliser)

## 1. Goal

Make accessories on the composed Army / No.3 / male GLB land on the
**front** of the visible uniform shirt instead of the back.

Pass 3 (body / uniform alignment) made the body and uniform the same
height and the same XYZ origin, so they overlap correctly in
world-space. But a separate orientation bug remains: the body mesh
faces **+Z** (face / nose / toes / chest curvature all on the +Z side —
matches the socket contract, where every `*_front` / front-side socket
sits on the +Z half-space), while the uniform mesh faces **−Z** (the
Tripo export was modelled back-to-camera and the one-off
scale-and-translate in pass 3 did not include a rotation). Every
accessory anchored at a front-facing socket (`cap_band_front`,
`left/right_chest_pocket`, `belt_center`'s +Z offset, `name_tag`'s
+10.5 cm Z, `left/right_shoulder_seam` for the lanyard with +Z arc)
is placed on the *back* of the rendered shirt.

Definitive verification (head-slice nose protrusion test, chest
asymmetry test, foot/toe direction test, all run via `trimesh` on the
project venv):

| File | Nose extreme | Chest spread | Toe direction | Verdict |
| --- | --- | --- | --- | --- |
| `assets/3d/bodies/male_apose.glb` | +Z (max +0.1053 vs −0.0904) | balanced | +Z (0.2433 vs 0.2362) | **+Z forward** |
| `assets/3d/uniforms/army_no3_male.glb` | −Z (max −0.0947 vs +0.0877) | back deeper (0.1793 vs 0.1643) | −Z (0.2388 vs 0.2340) | **−Z forward** |

Hard 180° flip around Y, not a subtle drift.

## 2. Scope

In scope:
- `assets/3d/uniforms/army_no3_male.glb` — apply 180° Y rotation in
  place, recentre on x/z, feet at y=0.
- Re-upload to `gs://saf-uniforms.firebasestorage.app/models/uniforms/army_no3_male.glb` (operator step).
- `MODEL_BUNDLE_VERSION` bump in both
  [functions/src/profile_hash.ts](../functions/src/profile_hash.ts) and
  [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart):
  `7 → 8`.
- Cloud Function redeploy + Flutter rebuild (operator steps).
- CLAUDE.md §8 refresh — note pass 4 corrected the −Z facing.

Out of scope:
- Authoring `tool/inject_uniform.py` (tracked separately in the
  follow-up plan).
- Re-orienting future uniforms (Navy / RSAF / DIS, No.1 / 2 / 4 / 5) —
  none uploaded yet.
- The `mergeUniform` Cloud Function helper. Confirmed read-only that
  it applies no rotation; the contract that all uniform GLBs face +Z
  stays on the asset side, not the merger.

## 3. Affected files

- [assets/3d/uniforms/army_no3_male.glb](../assets/3d/uniforms/army_no3_male.glb) — rotated in place.
- [functions/src/profile_hash.ts](../functions/src/profile_hash.ts) — `MODEL_BUNDLE_VERSION = 8` + v8 docblock note.
- [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart) — `kModelBundleVersion = 8` + matching docblock note.
- [CLAUDE.md](../CLAUDE.md) §8 — append pass-4 note to the Army No.3 alignment bullet.

## 4. Step-by-step plan

1. **Y-flip the GLB** via the project venv:
   ```bash
   .venv-tools/bin/python - <<'PY'
   import trimesh, numpy as np
   p = "assets/3d/uniforms/army_no3_male.glb"
   s = trimesh.load(p, force="scene")
   s.apply_transform(trimesh.transformations.rotation_matrix(np.pi, [0,1,0]))
   b = s.bounds
   cx = (b[0,0] + b[1,0]) / 2.0
   cz = (b[0,2] + b[1,2]) / 2.0
   y0 = b[0,1]
   s.apply_transform(trimesh.transformations.translation_matrix([-cx, -y0, -cz]))
   s.export(p)
   print("ok", s.bounds)
   PY
   ```
2. **Sanity-check**: re-run the head-slice nose-protrusion test on the
   rewritten file; nose extreme must now be on **+Z**.
3. **Bump `MODEL_BUNDLE_VERSION`** in `functions/src/profile_hash.ts`
   and `kModelBundleVersion` in
   `lib/features/ar_engine/data/profile_hash.dart`, both 7 → 8, with
   matching docblock notes.
4. **Static verification** (Claude-side):
   - `cd functions && npm run build` — TypeScript clean.
   - `cd functions && npm test` — existing 18 tests pass.
   - `flutter analyze` — clean.
   - `flutter test` — 73 tests pass.
5. **Operator hand-off** (commands Datta runs):
   - `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app --only "uniforms/army_no3_male.glb"`
   - `firebase deploy --only functions:composeUniformModel`
   - `flutter run` on device (Dart constant is compile-time — without a
     rebuild the installed app keeps hash bundle 7 and CF rejects with
     `failed-precondition`).
6. **Device verification** — open GhostScreen on Army / No.3 / male
   profile. Bundle v8 forces a fresh compose. Expected: beret on
   front of head (rim covers eyebrows); cap badge on band-front; name
   tag on right chest; lanyard arc on front-right; sleeve chevrons on
   outer-upper arms; belt across waist front; both feet shod.
7. **Mark `Status: verified`** with executed command summary.

## 5. Risks & rollback

- **Risk:** the Y-flip overshoots — accessories now land correctly but
  the shirt itself appears mirrored (left chest pocket on wearer's
  right, branch embroidery reversed). The male No.3 shirt is mostly
  symmetric so this is low risk, but the pocket geometry and the
  trouser fly are the tells. **Mitigation:** preview the rewritten GLB
  in a model viewer before upload.
- **Risk:** only one of the two `profile_hash` files bumped. Server-
  side hash mismatch then rejects every compose request with
  `failed-precondition`. **Mitigation:** CLAUDE.md §5.5 already calls
  this out; both files are listed in §3 above.
- **Risk:** users see a stale cached GLB. **Mitigation:** the bundle
  bump invalidates every cached `user_models/{uid}/No3.glb`.
- **Rollback:** the previous uniform GLB is recoverable from git
  (`git show HEAD:assets/3d/uniforms/army_no3_male.glb > /tmp/army_no3_male.prev.glb`,
  then move it back into place). Revert both `MODEL_BUNDLE_VERSION`
  bumps, re-deploy the CF, re-upload the prev GLB.

## 6. Verification

Per CLAUDE.md §1.5:
1. `cd functions && npm run build && npm test` — green.
2. `flutter analyze` — clean.
3. `flutter test` — 73 pass.
4. `flutter run` on device → Ghost screen Army / No.3 / male:
   accessories on **front** of shirt.

## 7. CLAUDE.md updates required

§8 Known gaps — append a pass-4 entry to the Army No.3 alignment
bullet noting the uniform was Y-flipped in place to correct its −Z
facing, and pointing to the un-executed
`2026-05-17_inject-uniform-tool.md` follow-up plan for the proper
normaliser.

§5.5 — `MODEL_BUNDLE_VERSION` mention 7 → 8.
