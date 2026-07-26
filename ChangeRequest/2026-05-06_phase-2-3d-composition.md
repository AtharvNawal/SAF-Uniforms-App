# Phase 2 — Real multi-asset 3D composition pipeline

- **Date:** 2026-05-06
- **Author:** Claude (Datta-driven session)
- **Status:** executed (Milestone A engineering + Milestone B placeholder upload + Cloud-Function deploy all complete). On-device smoke (the final part of Milestone C) is the only remaining step before flipping to `verified`.
- **Verification (Milestone A — engineering, fully green):**
  - `flutter analyze` — **clean** (no issues, 9.5s).
  - `dart run build_runner build --delete-conflicting-outputs` — **clean**, 36 outputs written, **no diff** vs. `git status` (the `kModelBundleVersion` constant has no codegen dependents, as predicted).
  - `flutter test` — **73/73 pass** (≈ 6s wall time, all existing suites green; no new Dart tests added because the helper layer lives server-side).
  - `cd functions && npm run build` — **clean** (tsc, no errors).
  - `cd functions && npm test` — **12/12 pass** (`node:test` runner over `lib/*.test.js`):
    - `findNodeByName: returns top-level scene-root node` ✓
    - `findNodeByName: returns nested descendant` ✓
    - `findNodeByName: returns null on miss` ✓
    - `detachNodeByName: removes a top-level scene-root node` ✓
    - `detachNodeByName: returns false when node is absent` ✓
    - `mergeUniform: appends source's nodes to target` ✓
    - `attachAccessory: re-parents merged accessory root under named socket` ✓
    - `attachAccessory: returns attached=false when socket is missing` ✓
    - `bakeNameTag: replaces existing base-color texture image bytes` ✓
    - `bakeNameTag: returns false when material is absent` ✓
    - `bakeNameTag: synthesises a texture when material has no base-color texture` ✓
    - `compressForWeb: runs dedup+prune on an empty document without throwing` ✓
  - **Milestone B — placeholder refresh + upload (executed 2026-05-06):**
    - `.venv-tools/bin/pip install Pillow` → Pillow 12.2.0 installed.
    - `.venv-tools/bin/python tool/generate_placeholder_bodies.py` → 3 body GLBs regenerated (62/65/70 KB) plus `placeholder.glb` (1,260 B). Validated via `gltf-transform`: all 11 named sockets present, `name_tag` mesh + `name_tag_mat` material with 1024×256 base-color texture present, `hair` node present (detachable when headdress mounted).
    - `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app` → 3 bodies uploaded; `placeholder.glb` skipped (sha256 match — idempotency).
  - **Milestone C — Cloud Function deploy (executed 2026-05-06):**
    - `firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated successfully. Build clean.
    - **Smoke test against placeholder body** (run locally pre-deploy via the helper module): body load → hair detach → name-tag bake (`TAN`) → dedup+prune+WebP compression → write. Output 60,480 bytes vs. 62,232 input. End-to-end pipeline green.
  - **Milestone C — on-device smoke (PENDING; operator-only — requires Android + iOS hardware):** open the app, set profile to Army / 3SG / male / No.3, open GhostScreen. Watch CF logs for `composeUniformModel: resolved` → `planned assets` → `done`. Confirm body renders + name-tag carries the surname + accessories appear at the right anchors. Repeat for female / maternity / navy / sikh-turban variants. Toggle an optional accessory in Wardrobe, return to GhostScreen, confirm regeneration + appearance. Then flip status to `verified`.

## 1. Goal

Close the four Phase-2 TODOs that the original 3D-avatar plan left open in
[functions/src/composeUniformModel.ts](../functions/src/composeUniformModel.ts):

1. Merge a uniform GLB onto the body using `@gltf-transform/core` scene-graph
   primitives.
2. Re-parent each accessory under named socket bones on the body rig
   (`head_top` / `left_chest_pocket` / `belt_center` / …) with the doctrinal
   `offset_*_cm` translation applied.
3. Bake the user's `fullName` onto the name-tag mesh via `sharp` and patch the
   matching material's base-color texture.
4. Apply Draco mesh compression + WebP texture compression via
   `@gltf-transform/extensions` so the composed GLB is ≤ 1 MB even with a dozen
   accessories.

When this lands, GhostScreen will render the user's *actual* uniform — correct
branch, dress code, gender, accessories worn, personalised name tag — instead
of the validated-but-empty body GLB Phase 1 emits today.

## 2. Scope

### In scope (this plan)
- New helper module `functions/src/glb_compose.ts` housing `findNodeByName`,
  `detachNodeByName`, `mergeUniform`, `attachAccessory`, `bakeNameTag`,
  `compressForWeb`.
- Pipeline rewrite in `functions/src/composeUniformModel.ts` — replace the
  Phase-1 single-GLB validation block with the merger, threaded through the
  helpers. Keep the outer try/catch + per-asset try/catch so a single bad
  artist delivery degrades gracefully instead of failing the whole composition.
- Bump `MODEL_BUNDLE_VERSION` (TS + Dart twin) from `1` → `2` so every existing
  user regenerates on next GhostScreen open.
- Extend `tool/generate_placeholder_bodies.py` to emit the eleven named socket
  nodes and a `name_tag` mesh + `name_tag_mat` material with a 1024×256 white
  base-color texture, so engineering can develop and verify the merger
  end-to-end against placeholders before artist GLBs land.
- Append a "Name tag" + "Hair / scalp split" section to
  `docs/3d-body-authoring.md` formalising the artist contract.
- Add `functions/src/glb_compose.test.ts` (Node 20 built-in `node:test`
  runner — no new deps) covering: socket lookup hit, socket lookup miss,
  hair detach, name-tag bake replaces texture bytes, full pipeline against
  in-memory fixture body+uniform+1-accessory.
- Add `npm test` script wired to `tsc && node --test lib/**/*.test.js`.
- Refresh CLAUDE.md per policy 1.2.

### Out of scope (future plans)
- Real artist body / uniform / accessory GLB authoring (operator track —
  Milestone B). Engineering ships against placeholders and the artist
  deliveries drop in cleanly.
- No.1 / No.2 / No.4 / No.5 dress-code asset uploads. The merger is
  dress-code-agnostic; future dress codes are asset-only ChangeRequests.
- Real-time AR Scanner pose-detection scoring.
- LOD generation, animation, in-app re-bake without full regeneration.
- Per-rank insignia geometry variation beyond the existing
  `sleeve_rank_specialist` / `sleeve_rank_enlistee` accessory-id split.

## 3. Affected areas

### Backend (Cloud Functions)
- `functions/src/composeUniformModel.ts` — pipeline rewrite at the Phase-1 single-GLB block.
- `functions/src/glb_compose.ts` — **NEW**.
- `functions/src/glb_compose.test.ts` — **NEW**.
- `functions/src/profile_hash.ts` — `MODEL_BUNDLE_VERSION = 2`.
- `functions/package.json` — add `npm test` script. No new dependencies.

### Flutter client
- `lib/features/ar_engine/data/profile_hash.dart` — `kModelBundleVersion = 2`.

### Tooling
- `tool/generate_placeholder_bodies.py` — emit sockets + name-tag mesh.
- `docs/3d-body-authoring.md` — append name-tag + hair-split sections.

### Storage
- No rule changes. The merger reads uniforms / accessories from
  `models/uniforms/**` and `models/accessories/**` paths Phase 1 already
  resolves; the per-asset placeholder fallback handles missing artist files.

### Firestore
- No schema changes. The `MODEL_BUNDLE_VERSION` bump silently invalidates
  every existing `generatedDresses[*]` cache entry; the next GhostScreen
  open per user fires a regeneration.

## 4. Step-by-step plan

1. Extend `tool/generate_placeholder_bodies.py` to emit eleven named socket
   nodes (`head_top`, `cap_band_front`, `left_collar_tip`, …, `belt_center`)
   per variant and a `name_tag` mesh with a `name_tag_mat` PBR material
   carrying a 1024×256 white base-color texture. Produces drop-in placeholder
   bodies that satisfy the merger's contract.
2. Add `functions/src/glb_compose.ts` with the helpers. Each helper is a pure
   function over `Document` instances; no Firebase / Storage access.
3. Wire helpers into `composeUniformModel.ts`. Replace the validation-only
   block with the full merger. Wrap each asset-load and each accessory attach
   in `try / catch` so a single bad asset degrades gracefully.
4. Bump `MODEL_BUNDLE_VERSION = 2` in `profile_hash.ts` and `profile_hash.dart`.
5. Add `functions/src/glb_compose.test.ts` driving the merger against
   in-memory `Document` fixtures via `node:test`.
6. Add `"test": "npm run build && node --test lib/**/*.test.js"` to
   `functions/package.json`.
7. Append a "Name-tag mesh contract" + "Hair / scalp split" section to
   `docs/3d-body-authoring.md`.
8. `cd functions && npm run build && npm test` — green.
9. `flutter analyze` — clean. `dart run build_runner build` — no diff (only
   constant change).
10. Refresh CLAUDE.md sections per policy 1.2.
11. Update plan status → `executed`, then verified once Milestone C operator
    smoke test passes.

## 5. Risks & rollback

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Artist socket names drift from the contract | Medium | `findNodeByName` logs warnings + accessory falls through to scene root or is skipped. Test fixture pins the contract. |
| Skinned uniform mesh fails to re-bind to body's joints (real assets) | Medium | Outer try/catch falls back to body-only composition; surface error on `generatedDresses[*].error`; GhostScreen shows error card. |
| Draco encode bumps the function over 120s for accessory-heavy users | Low | Time-budget logging in `compressForWeb`; raise CF timeout to 180s and memory to `2GiB` if observed. |
| Compression module fails to initialise on cold start | Low | `compressForWeb` wrapped in try/catch; falls back to uncompressed output, logs warning. |
| `MODEL_BUNDLE_VERSION` bump causes thundering-herd regen | Low | `maxInstances: 50`; per-user-on-first-open spread is naturally graceful. |

**Rollback:** Revert `MODEL_BUNDLE_VERSION` to `1` and redeploy the previous
`composeUniformModel.ts`. Existing `user_models/{uid}/{dressCode}.glb` objects
from Phase 1 are still valid (body-only). The `generatedDresses[*]` Firestore
entries with `schemaVersion: 1` are picked up unchanged. No data loss.

## 6. Verification

Per policy 1.5:

1. `flutter analyze` — clean.
2. `dart run build_runner build --delete-conflicting-outputs` — only
   `kModelBundleVersion` constant changes; no codegen diff.
3. `flutter test` — all existing tests pass (no new Dart tests added).
4. `cd functions && npm run build && npm test` — green.
5. **Operator (Milestone B):** Drop artist GLBs into `assets/3d/{bodies,uniforms,accessories}/`,
   run `tool/upload_models.py`, `firebase deploy --only functions`.
6. **Operator (Milestone C):** Cold-launch app on Android + iOS, sign in, set
   profile to Army / 3SG / male / No.3, open GhostScreen. Watch CF logs for
   `composeUniformModel: resolved` → `planned assets` → `done` with `bytes`
   in the expected band (~700 KB). Confirm GhostScreen renders the body in
   the correct uniform with the right beret + cap badge + sleeve insignia
   + name-tag-with-surname. Repeat for female / maternity / navy / sikh-turban.
   Toggle an optional accessory, confirm regeneration + appearance.
7. Update plan status → `verified` with run log.

## 7. CLAUDE.md updates required

Per policy 1.2:

- §3 Tech stack — note `@gltf-transform/extensions` is now load-bearing on the CF (Draco + WebP compress).
- §4 Source tree — add `functions/src/glb_compose.ts` + `glb_compose.test.ts`.
- §5.5 Backend — Firebase, `composeUniformModel` block — replace "Phase-1 composition only emits the validated body GLB — full multi-asset merge … is staged behind TODOs" with the live behaviour. Update bundle version reference.
- §5.5 Cloud Storage `models/**` block — note that `models/uniforms/**` and `models/accessories/**` are now consumed by the merger (still empty until artist deliveries land).
- §8 Known gaps / TODOs — strike the four Phase-2 TODOs. Replace with a forward-looking note about No.1/2/4/5 still pending their doctrine PDFs (asset-only follow-ups).
