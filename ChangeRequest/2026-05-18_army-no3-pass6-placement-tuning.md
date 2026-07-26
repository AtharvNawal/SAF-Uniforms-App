# Army No.3 Male — Pass 6: per-accessory placement tuning

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress (awaiting device verify)
- **Supersedes:** none (builds on pass-5
  `2026-05-17_army-no3-pass5-hierarchy-fix.md`)

## 1. Goal

Pass-5 fixed the face-axis rotation — the model now faces camera on
initial GhostScreen load. The pass-5 device screenshot showed four
remaining accessory placement issues, all user-confirmed:

1. **Only ONE chevron visible** — the rank chevron
   (`army_enlistee_insignia`, `mirror_left_right: true`) rendered on
   one side only.
2. **Chevron landed on chest, not upper arm** — even when both
   copies render, `sleeve_upper` sockets sit at
   `(±0.183, 1.388, +0.10)` = inner-shoulder front-of-chest, not on
   the outer upper arm.
3. **Bare feet visible under shoes** — the body's monolithic Tripo
   mesh has the bare-skin feet baked in; nothing detaches them when
   shoes mount.
4. **Sparkly star near the wearer's right cheek** — user confirmed
   this is `army_arms_badge` (anchored at `right_collar_tip` with
   `offset_y_cm: +1.5`, landing at chin-height instead of on the
   shirt collar).

Plus two related sub-issues exposed by the same diagnostic:
- Small dark bumps on the shoulders / collar from the 8-vert socket
  marker cubes that `inject_sockets.py` bakes into the body GLB
  (used to be invisible but became more obvious after pass-5).
- Belt sits slightly forward of the trouser surface (`offset_z_cm: -2`
  isn't enough pull-back given the trouser mesh's depth).

## 2. Scope

In-scope:

1. **Remove the `setScale([-1, 1, 1])`** in
   [functions/src/glb_compose.ts](../functions/src/glb_compose.ts)
   `attachAccessory()`. Both copies attach with identity scale.
   The negative scale was inverting triangle winding on the right
   copy → back-face culling made it invisible.

2. **Move `left/right_sleeve_upper` sockets** in
   [assets/3d/bodies/male_apose.glb](../assets/3d/bodies/male_apose.glb):
   `(±0.183, 1.388, +0.10)` → `(±0.30, 1.30, 0.0)` so rank chevrons
   land on the outer upper arm.

3. **Slice the body mesh at `y=0.10m`**: vertices below the ankle
   move into a new `feet` sub-node, vertices above stay in `body`.
   New `FEET_NODE = "feet"` constant in `glb_compose.ts`. New
   feet-detach block in `composeUniformModel.ts` (mirrors the
   existing hair-detach), triggered when any
   `category === "footwear"` accessory is in the include list.

4. **Strip marker mesh refs** from every socket node in the body
   GLB except `body`, `feet`, `name_tag`. Sockets keep their
   transform; the mesh reference is null'd so the 8-vert marker
   cubes don't render.

5. **`army_arms_badge.render_logic.offset_y_cm`**: +1.5 → −3.0.

6. **`nylon_belt.render_logic.offset_z_cm`**: -2.0 → -3.0.

7. **Bundle bump** `MODEL_BUNDLE_VERSION = 10` in
   [functions/src/profile_hash.ts](../functions/src/profile_hash.ts)
   and [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart),
   with v10 docblocks documenting every change.

8. Unit tests:
   - Updated `attachAccessory: mirror=true ...` test to assert
     identity scale on both sides (was `[-1, 1, 1]` on the right).
   - New `detachNodeByName: removes FEET_NODE` test (parallel to
     the existing HAIR_NODE detach test).

Out of scope:
- Proper artist L/R shoe pair (placeholder is acceptable).
- Per-accessory render_logic fine-tuning beyond what's listed above.
- Other branches (Navy, RSAF, DIS) or other dresses
  (No.1/2/4/5) — none uploaded yet.
- `tool/inject_uniform.py` (still tracked in the un-executed
  `2026-05-17_inject-uniform-tool.md` plan).

## 3. Affected files

| File | Change |
| --- | --- |
| `functions/src/glb_compose.ts` | Removed `setScale([-1, 1, 1])`; added `FEET_NODE` constant + updated AttachOptions.mirror docblock. |
| `functions/src/composeUniformModel.ts` | Added feet-detach block (parallel to hair-detach). |
| `functions/src/glb_compose.test.ts` | Updated mirror test; added feet-detach test. 22/22 pass. |
| `assets/3d/bodies/male_apose.glb` | Sliced body mesh at y=0.10 → `body` + `feet`; moved sleeve_upper sockets; stripped 17 marker mesh refs. |
| `assets/data/accessory_library.v1.json` | `army_arms_badge.offset_y_cm`: +1.5 → −3.0; `nylon_belt.offset_z_cm`: -2.0 → -3.0. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 10` + v10 docblock. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 10` + matching docblock. |
| `CLAUDE.md` | §5.5 bundle 9 → 10; §8 pass-6 entry. |

## 4. Step-by-step plan (executed)

1. Inspected `nylon_belt.glb` bbox: 30cm × 7cm × 7cm — not
   oversized, just z-offset needs tuning.
2. One-off Python: split `body` mesh at y=0.10m into `body` + `feet`
   sub-nodes; moved sleeve_upper sockets; preserved every other
   socket node with original transform.
3. Post-process: stripped `mesh` refs from every socket node except
   `body`/`feet`/`name_tag` via direct GLB JSON edit. Verified new
   sleeve_upper positions in the rewritten GLB.
4. Removed `setScale([-1, 1, 1])` block in `attachAccessory`;
   simplified the `resolved` array shape (no more `mirrorX` field).
   Updated AttachOptions.mirror docblock to describe the
   identity-scale semantics.
5. Added `FEET_NODE = "feet"` export.
6. Added feet-detach block in `composeUniformModel.ts` immediately
   after the hair-detach block, triggered by
   `includeAccessories.some(a => a.record.category === "footwear")`.
7. Updated `glb_compose.test.ts`: mirror test now asserts identity
   scale on both sides; new feet-detach test asserts `detachNodeByName(doc, FEET_NODE)` returns true.
8. Updated `accessory_library.v1.json`: `army_arms_badge.offset_y_cm`
   +1.5 → −3.0; `nylon_belt.offset_z_cm` -2.0 → -3.0.
9. Bumped both `MODEL_BUNDLE_VERSION` and `kModelBundleVersion` 9 → 10
   with v10 docblocks.
10. `cd functions && npm run build && npm test` → 22/22 pass.
11. `flutter analyze` → "No issues found!".
12. Updated CLAUDE.md §5.5 + §8.
13. (Operator) re-upload body GLB, re-seed Firestore (for accessory
    library changes), re-deploy CF.

## 5. Risks & rollback

- **Risk:** removing the X-flip mirror leaves placeholder shoes
  visually identical on both feet. **Mitigation:** acceptable for
  the demo; proper fix is artist-authored L/R pair or proper
  mesh-mirror (flip vertices + invert winding). Tracked as future
  follow-up.
- **Risk:** body slice at `y=0.10m` clips ankles awkwardly.
  **Mitigation:** the slice plane is tunable; if the device test
  reveals weird gaps at the ankle, raise to y=0.08m or lower to
  y=0.12m and re-export.
- **Risk:** sleeve_upper at x=±0.30 lands *outside* the upper-arm
  geometry (A-pose arms drop at an angle). **Mitigation:** tune
  by ±2cm based on device output.
- **Risk:** dropping `army_arms_badge` by 3cm places it below the
  shirt collar. **Mitigation:** iterate by ±1cm.
- **Risk:** belt z-offset overshoot pulls the buckle into the
  trouser fly. **Mitigation:** revert to -2cm if needed.
- **Risk:** marker-mesh strip accidentally drops the body mesh.
  **Mitigation:** script explicitly excludes body / feet / name_tag.
  Verified post-write that body + feet meshes exist with correct
  vertex counts.
- **Rollback:** every change is gated by bundle 10. Revert the
  bump + the code/JSON/GLB changes; redeploy to fall back to
  pass-5 behaviour.

## 6. Verification

Per CLAUDE.md §1.5:

1. `cd functions && npm run build` ✅ clean TypeScript build.
2. `cd functions && npm test` ✅ **22/22 pass** (updated mirror
   test + new feet-detach test).
3. `flutter analyze` ✅ "No issues found!".
4. **Device** — Army / REC / male / non-Sikh / No.3:
   - Both chevrons visible on the outer upper arms.
   - Shoes on both feet; no bare-skin toes showing.
   - Belt flush against trouser surface.
   - `army_arms_badge` on the shirt's right collar tip (not on
     cheek).
   - No dark cubes visible on shoulders / collar.
   - All accessories on correct anatomic spots per doctrine.

## 7. CLAUDE.md updates

- §5.5 bundle 9 → 10.
- §8 pass-6 entry appended under the Army No.3 alignment bullet.
