# Army No.3 Male — Accessory Placement Fix

- **Date:** 2026-05-13
- **Author:** Claude (with Datta)
- **Status:** executed (awaiting device smoke test for `verified`)

## Execution log (2026-05-13)

- Phase 0 — `male_apose.glb` inspection: ✓ all 15 sockets present (head_top, cap_band_front, left/right_collar_tip, left/right_chest_pocket, left/right_shoulder_seam, left/right_sleeve_upper, belt_center, left/right_ankle, left/right_foot_top) + `name_tag` mesh + `hair` node. The 482 KB size is correct for a Tripo-injected body without textures (placeholder body was 13.7 MB with procedural geometry + a 1024×256 PNG).
- Phase 0 — raw artist sources: only `army_cap_badge_sltc_me6_below_source.glb` and `male_apose_tripo_source.glb` exist in `assets/3d_raw/`. The other 6 artist GLBs were already injected; raws weren't preserved. Strategy adjusted: re-inject only the GLBs with confirmed orientation problems, using the existing injected GLB as input (preserves textures because `inject_accessory.py` re-runs through trimesh produce a same-size output).
- Phase 1 — re-injections (only 2 needed per bbox inspection):
  - `army_enlistee_insignia`: `--no-auto-orient --rotate-y 90 --target-size 0.08` → flat face now on ±X (outward from arm); 11.3 MB preserved.
  - `army_lanyard_sa_ma`: `--no-auto-orient --rotate-z 90 --target-size 0.30` → Y is now the long axis (drape direction); 11.9 MB preserved.
  - Other artist GLBs (beret, cap_badge, arms_badge, belt, shoes, name_tag) inspected and confirmed correctly oriented; no re-injection.
- Phase 2 — `accessory_library.v1.json` updated:
  - `army_beret`: `offset_y_cm 1.3 → -3.0`.
  - `army_cap_badge_sltc_me6_below`: `offset_y_cm 1.3 → 0.0`, added `offset_z_cm: 2.0`.
  - `army_enlistee_insignia`: `anchor "shoulder_seam" → "sleeve_upper"`; removed unimplemented `y_multiplier`.
  - `army_lanyard_sa_ma`: added `offset_y_cm: -15.0`, `offset_z_cm: 3.0`.
  - `nylon_belt`: added `offset_z_cm: -5.0`.
  - `leather_shoes_low_cut`: anchor `foot_top → left_foot_top`, removed `mirror_left_right`, added `offset_x_cm: 10.0` + `offset_y_cm: 4.0` (the GLB packs both shoes in one mesh).
- Phase 3 — upload + seed + deploy:
  - `tool/upload_models.py` → 2 new objects (enlistee_insignia + lanyard), 66 sha256-matched skipped. Other artist GLBs were already in Storage from a prior run.
  - `dart run tool/seed_firestore.dart` → 82 docs pushed to `accessory_library`.
  - `cd functions && npm run build && firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated. Bundle v4 + 2 GiB memory now live.
- Phase 4 — static verification:
  - `npm test` in `functions/` → 18/18 pass.
  - `flutter analyze` → "No issues found! (ran in 5.3s)".

Outstanding: device smoke test on Samsung (Front + Side GhostScreen vs reference image). User to run `flutter run` and report; iterate per-accessory if any remain visibly mis-placed.

## 1. Goal

Make the composed Army No.3 male GLB visually match the doctrine reference image: beret centred on head with cap badge front-and-centre, rank chevrons on both upper sleeves, lanyard draping from the right shoulder, name-tag baked on right chest, black belt wrapping the waist, low-cut black shoes covering both feet — no floating accessories, no gray-cube fallbacks, no bare-skin feet.

Today's GhostScreen render shows: beret floating high & tilted, lanyard floating mid-air, chevrons off-shoulder, belt rendering as a tiny black box, gray cubes near the feet (fallback placeholder), and visible bare-feet skin.

## 2. Scope

In scope (Army / No.3 / male):
- 8 artist-authored accessory GLBs: `army_beret`, `army_cap_badge_sltc_me6_below`, `army_enlistee_insignia`, `army_arms_badge`, `army_lanyard_sa_ma`, `nylon_belt`, `leather_shoes_low_cut`, `name_tag_standard`.
- Their `render_logic` blocks in `assets/data/accessory_library.v1.json`.
- The pending uncommitted CF changes (`MODEL_BUNDLE_VERSION = 4`, `memory: 2GiB`, name_tag resolver tweak) — build + deploy.
- Firebase Storage upload via `tool/upload_models.py`.
- Firestore reseed via `tool/seed_firestore.dart`.

Out of scope (follow-up plans):
- Navy / RSAF / DIS branches — they reuse `nylon_belt`, `black_socks`, `leather_shoes_low_cut`, `name_tag_standard`, so they benefit indirectly, but their branch-specific accessories (cap badges, sleeve insignia, lanyards) still need their own pass.
- No.1 / No.2 / No.4 / No.5 dresses (legacy placeholders pending doctrine).
- Female / female-maternity bodies.
- Drape simulation for lanyard `allowance_min_cm` / `allowance_max_cm` (merger reads cm offsets only).
- `y_multiplier` field in render_logic (unimplemented; dropping where present).

## 3. Affected areas

- [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json) — 6 entries retuned (beret, cap_badge, enlistee_insignia, lanyard, belt, shoes).
- [assets/3d/accessories/*.glb](../assets/3d/accessories/) — 7 GLBs re-injected via `tool/inject_accessory.py`.
- [assets/3d/bodies/male_apose.glb](../assets/3d/bodies/male_apose.glb) — verified for socket integrity; regenerated if needed.
- [functions/src/composeUniformModel.ts](../functions/src/composeUniformModel.ts) — already-uncommitted memory bump; rebuild + deploy.
- [functions/src/profile_hash.ts](../functions/src/profile_hash.ts) — already-uncommitted v3 → v4 bundle version bump; deploy.
- `gs://saf-uniforms.firebasestorage.app/models/accessories/*` — re-uploaded.
- `accessory_library` Firestore collection — re-seeded.
- [CLAUDE.md](../CLAUDE.md) §5.5 (bundle version 3 → 4), §8 (No.3 male placement notes).

## 4. Step-by-step plan

### Phase 0 — Pre-flight (read-only)
0.1 Inspect `assets/3d/bodies/male_apose.glb` for the 15 sockets + `name_tag_mat` material + `hair` node; regenerate via `.venv-tools/bin/python tool/generate_placeholder_bodies.py` if any are missing.
0.2 Confirm `assets/3d_raw/<accessory>.glb` sources are present (the inject script needs raw artist exports as input).

### Phase 1 — Re-inject artist GLBs
For each accessory, run `tool/inject_accessory.py` with the rotation + scale combination derived from doctrine + ChangeRequest history:
1.1 `leather_shoes_low_cut` — `--target-size 0.25 --no-auto-orient` (shoe length is the long axis, ~25 cm).
1.2 `nylon_belt` — `--target-size 0.30 --rotate-y 90 --no-auto-orient` (wraps Y-axis, X-major ~30 cm).
1.3 `army_beret` — `--target-size 0.20 --no-auto-orient` (dome up, rim down).
1.4 `army_cap_badge_sltc_me6_below` — `--target-size 0.045` (auto-orient OK; flat face +Z).
1.5 `army_enlistee_insignia` — `--target-size 0.06 --rotate-y 90` (flat face must point sideways for left+right mirror).
1.6 `army_lanyard_sa_ma` — `--target-size 0.30 --no-auto-orient` (cord drape along −Y).
1.7 `army_arms_badge` — `--target-size 0.06` (auto-orient OK).
1.8 `name_tag_standard` — skip (bake-only).

### Phase 2 — Tune `accessory_library.v1.json` offsets
2.1 `army_beret`: `{anchor: head_top, offset_y_cm: -3.0}` (was `+1.3`).
2.2 `army_cap_badge_sltc_me6_below`: `{anchor: cap_band_front, offset_y_cm: 0.0, offset_z_cm: 0.5}` (was `+1.3` Y).
2.3 `army_enlistee_insignia`: `{anchor: sleeve_upper, mirror_left_right: true}` (was `shoulder_seam` with unused `y_multiplier: 0.5`).
2.4 `army_lanyard_sa_ma`: `{side: right, offset_y_cm: -2.0, offset_z_cm: 5.0}` (was no offsets).
2.5 `nylon_belt`: keep `{anchor: belt_center, offset_y_cm: 0.0}` (orientation handled at GLB level).
2.6 `leather_shoes_low_cut`: `{anchor: foot_top, offset_y_cm: -3.0, mirror_left_right: true}` (was no Y-drop, shoe was floating above instep).

### Phase 3 — Upload / seed / build / deploy
3.1 `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app` (idempotent SHA-256 skip; new sha values for the 8 modified GLBs).
3.2 `dart run tool/seed_firestore.dart <svc>.json` (pushes updated accessory_library entries to Firestore).
3.3 `cd functions && npm install && npm run build && cd .. && firebase deploy --only functions:composeUniformModel` (v4 bundle bump flushes every cached `user_models/{uid}/{dressCode}.glb`).

### Phase 4 — Verification
4.1 `cd functions && npm test` (server merger helpers still pass).
4.2 `flutter analyze` (no Dart code changed; should stay clean).
4.3 `flutter run` on the Samsung dev device → Configure Army / REC / male / non-Sikh / No.3 → GhostScreen → compare Front + Side views to the reference image (the 1st screenshot from the user). Iterate Phase 1 + 2 for any single accessory still misplaced.

## 5. Risks & rollback

- **Rotation guesses wrong:** Phase 1 commands derive rotation/scale from doctrine + ChangeRequest log, but Tripo's actual output frame may differ. Mitigation: `gltf-transform inspect` each output bbox before upload; visual iteration is fast (single-accessory re-inject + upload).
- **`male_apose.glb` lost sockets** (13.7 MB → 482 KB shrink): if Phase 0.1 fails, regenerate from procedural template via `tool/generate_placeholder_bodies.py` and re-upload — placeholder body satisfies the merger contract.
- **v4 cache-bust regenerates every active user's GLB on first open:** expected behaviour of the bundle version field; CF memory now 2 GiB to absorb.
- **Rollback:** `git restore assets/3d/accessories/*.glb assets/3d/bodies/male_apose.glb assets/data/accessory_library.v1.json functions/src/profile_hash.ts functions/src/composeUniformModel.ts`; redeploy CF. Storage idempotency by sha256 will resurrect older content on re-upload of the restored files.

## 6. Verification

Per CLAUDE.md §1.5:
1. `flutter analyze` — clean.
2. `cd functions && npm test` — all Node 20 tests pass.
3. `flutter test` — Dart unit tests pass (none changed; sanity).
4. `flutter run` on Android: Army / REC / male / non-Sikh / No.3 → GhostScreen renders with all accessories on body, no gray cubes, no bare-feet skin, beret on head with cap badge centred, both sleeves carry a chevron, lanyard drapes from right shoulder, belt wraps waist, shoes cover both feet. Front + Side toggle both verified.
5. Update plan `Status:` to `executed`, then `verified`.

## 7. CLAUDE.md updates required

- §5.5 "Backend — Firebase" — bump `MODEL_BUNDLE_VERSION` mention from 3 → 4; note CF memory increase to 2 GiB.
- §8 "Known gaps / TODOs" — record that Army No.3 male placement is now doctrine-aligned; flag remaining branches (Navy, RSAF, DIS) as the next plan; note that lanyard `allowance_min_cm` / `allowance_max_cm` and `y_multiplier` remain unimplemented (no longer relied upon for Army No.3 male).
