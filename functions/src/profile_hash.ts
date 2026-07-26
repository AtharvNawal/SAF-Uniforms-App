/**
 * Server-side mirror of `lib/features/ar_engine/data/profile_hash.dart`.
 *
 * The Cloud Function recomputes the same hash as the client to detect
 * stale composeUniformModel requests (replay protection) and to make
 * the regeneration cache key deterministic.
 *
 * IMPORTANT: any change to the input shape here MUST be mirrored in
 * the Dart implementation, otherwise the client and server will
 * disagree about whether a model is up-to-date and we'll thrash.
 */

import { createHash } from "crypto";

/**
 * Bumps when the composition logic itself changes — see the matching
 * `kModelBundleVersion` in profile_hash.dart.
 *
 * v2: Phase-2 multi-asset composition (uniform merge + accessory
 * re-parenting under named sockets + name-tag bake + Draco/WebP
 * compression).
 *
 * v3: Phase-2 accessory population — chest-side socket offset bug fix in
 * inject_sockets.py, anchor reconciliation in accessory_library.v1.json,
 * mirror_left_right + side support in the merger, name-tag filter on the
 * resolver loop. Bumping invalidates every existing per-user cached GLB
 * so the next GhostScreen open recomposes against the new pipeline.
 *
 * v5: Army No.3 placement pass 2 — bigger beret to cover hair, single-shoe
 * GLB with mirror_left_right for both feet, lanyard re-rotated to flip
 * loop direction, belt z-offset reduced from -5 to -2 to keep the front
 * face on the trouser surface. Cap-badge and beret offsets retuned to
 * match the bigger beret bbox.
 *
 * v6: Army No.3 body / uniform alignment fix — male_apose.glb was a
 * corrupted flat-strip mock (62k verts at z=0) and the uniform GLB was
 * at 0.98m Tripo native scale while body sockets assumed 1.78m, so
 * accessories at upper-body sockets floated ~80cm above the rendered
 * uniform's head. Body regenerated from Tripo source via existing
 * inject_sockets.py; uniform scaled up to 1.78m to match.
 *
 * v7: Army lanyard offset_y_cm -12 -> -22 so the cord drapes down the
 * right chest instead of arcing across the face. The lanyard mesh's
 * forward Z-curve (loop reaches z=+0.28 at upper-chest height) was
 * intersecting the camera's sightline at face level under the -12cm
 * drop; the bigger -22cm drop puts the entire arc below shoulder level.
 *
 * v8: Army No.3 male uniform Y-flip — army_no3_male.glb was modelled
 * back-to-camera (faced -Z) while the body faces +Z. Every accessory
 * anchored at a front-facing socket landed on the back of the visible
 * shirt. Fixed by applying a one-off 180° Y rotation + recentre on x/z
 * to the uniform GLB in place (ChangeRequest 2026-05-17_army-no3-uniform-y-flip).
 * The proper repeatable normaliser (tool/inject_uniform.py) is the
 * follow-up plan 2026-05-17_inject-uniform-tool.
 *
 * v20: Pass-17 — REVERTED v19. Mandatory items (belt, socks, footwear)
 *      stay mandatory in the composed GLB regardless of the user's
 *      wardrobe check state. Reason: the AR/VR overlay needs all
 *      mandatory items present to overlay against real wearing for
 *      verification; unchecking a mandatory item in the wardrobe is a
 *      "did I wear this?" verification flag, not a "render it or not"
 *      flag. Only OPTIONAL items respect the check set (back to v18
 *      behaviour).
 *
 * v19: Pass-16 — (reverted in v20) respect user wardrobe unchecks for
 *      mandatory items.
 *
 * v18: Pass-15 belt tightened (outer radius 19→16.5cm, strap 3.5→2.5cm).
 * v17: Pass-14 belt strap thinned + bigger buckle.
 *
 * v16: Pass-13 Army No.3 male — wrap-around belt rebuilt from
 *      scratch. User's nylon_belt.glb was a flat 98 cm × 22 cm slab,
 *      not a true wrap-around — appeared as a giant horizontal plank
 *      in side view. Replaced with a trimesh torus (major_radius
 *      0.18 m, minor_radius 0.018 m, Y-flattened by 2× for strap
 *      width) + a gold flat-box buckle at +Z. Vertex colors black
 *      strap / gold buckle. Material respects vertex colors
 *      (baseColorFactor=[1,1,1,1]).
 *
 * v15: Pass-11 Army No.3 male — built-from-scratch beret + remove
 *      body hair entirely + name_tag/belt re-tune (ChangeRequest
 *      2026-05-18_army-no3-pass11-beret-from-scratch):
 *      - Discarded the Tripo `army_beret.glb` — even after stripping
 *        textures + flat-black material in pass-10, the user still
 *        reported a green tint. Built a NEW beret mesh from scratch
 *        in trimesh: hemisphere dome (22×16×22 cm) + brim ring,
 *        vertex colors all (12,12,12,255) AND a plain black PBR
 *        material assigned. Triple-layered guarantee of flat-black
 *        rendering.
 *      - `army_beret.render_logic.offset_y_cm`: -7 → -16 so the brim
 *        sits at brow level (world y=1.65), covering the full head.
 *      - Removed the body's `hair` sub-mesh entirely from the GLB
 *        (was the green-tinted scalp from pass-9). Now the body's
 *        max y = 1.659 (forehead/temple). Any leftover green-tint
 *        bleed-through from the previous hair sub-mesh is gone.
 *      - `nylon_belt.render_logic.offset_y_cm`: -11 → -3 (belt was
 *        too low, invisible).
 *      - Body `name_tag` socket moved: x -0.060 → -0.075, y 1.345 →
 *        1.36 (slightly more inboard / wearer's-right + lifted 1.5cm
 *        higher).
 *
 * v14: Pass-10 Army No.3 male — beret coverage + user-provided belt
 * (ChangeRequest 2026-05-18_army-no3-pass10-beret-belt-final):
 *   - User reported "green dome" still visible above the beret + black
 *     beret too small to cover the head. Diagnosed: PBR shading on the
 *     beret's residual `normalTexture` + `metallicRoughnessTexture`
 *     (still embedded though baseColorTexture was removed) was bleeding
 *     a green tint into the rim where lighting hit the bump map.
 *     Stripped ALL textures + ALL images from `army_beret.glb`, reset
 *     materials to a single plain
 *     `baseColorFactor=[0.02, 0.02, 0.02, 1.0]`, `metallicFactor=0`,
 *     `roughnessFactor=0.9` (matte non-metallic). No texture sampling
 *     can introduce a tint now.
 *   - Scaled beret 1.3× uniformly → 32 cm × 21 cm × 34 cm (was
 *     24×16×26) so the rim covers more of the head.
 *   - `army_beret.render_logic.offset_y_cm`: -4 → -7 (pull the beret
 *     down 3 cm so the rim covers the brow / temple area).
 *   - Replaced `nylon_belt.glb` with the user-provided wrap-around
 *     belt at `/Users/meet/Documents/accessories/nylon_belt.glb`
 *     (bbox 24 cm × 22 cm × 98 cm — actually wraps around the
 *     waist instead of just covering the front). Stripped its
 *     textures + recoloured matte black.
 *   - `nylon_belt.render_logic.offset_y_cm`: 0 → -11 and
 *     `offset_z_cm`: -3 → -16 to centre the wrap-around belt on
 *     the body's waist (the user's belt's local origin is at the
 *     bottom of the strap with the wrap extending ±49 cm in Z).
 *
 * v13: Pass-9 Army No.3 male — hair detach + belt scale
 * (ChangeRequest 2026-05-18_army-no3-pass9-hair-detach-belt-scale):
 *   - The body's main `body` mesh was rendering the scalp/hair region
 *     in the Tripo texture's green-khaki tint where the beret didn't
 *     fully cover. The `hair` node existed (since pass-6) but had no
 *     real mesh — the actual hair vertices were inside the `body` mesh,
 *     so the existing hair-detach-on-headdress logic dropped nothing.
 *     Re-sliced `body` at y=1.65: vertices at or above (scalp area)
 *     moved into a real `hair` sub-mesh. Now `detachNodeByName(body,
 *     "hair")` in composeUniformModel actually removes the scalp
 *     geometry when a beret mounts.
 *   - Scaled `nylon_belt.glb` 1.6×1.5×1.0 → 48 cm × 10.5 cm × 7 cm
 *     so the belt appears wider on the waist and taller (more visible
 *     buckle band).
 *
 * v12: Pass-8 Army No.3 male — doctrine-alignment corrections
 * (ChangeRequest 2026-05-18_army-no3-pass8-doctrine-alignment):
 *   - Flipped body `name_tag` socket X from +0.0599 to -0.0599 so
 *     the name plate lands on the wearer's RIGHT chest pocket
 *     (camera-left side) per SAF doctrine. The body's socket
 *     naming convention has been confirmed inverted: world +X is
 *     the wearer's LEFT side (camera-right), world -X is the
 *     wearer's RIGHT side (camera-left).
 *   - `army_lanyard_sa_ma.render_logic.offset_y_cm`: -22 → -30
 *     so the lanyard's loop (top of bbox after pass-7's 180°X
 *     flip) sits AT the shoulder seam instead of floating 8cm
 *     above it. With offset_y_cm=-30, world y of loop becomes
 *     1.477+0.30-0.30 = 1.477 (shoulder height) ✓.
 *
 * v11: Pass-7 Army No.3 male — nine per-accessory detail fixes
 * (ChangeRequest 2026-05-18_army-no3-pass7-accessory-details):
 *   - Sliced `leather_shoes_low_cut.glb` at x=0 → single shoe; the
 *     existing mirror_left_right (identity scale per pass-6)
 *     attaches one copy under each foot_top socket.
 *   - Overrode `army_beret.glb` material baseColorFactor to
 *     (0.05, 0.05, 0.05, 1.0) and dropped the green Tripo texture
 *     so the beret renders matte black.
 *   - Rotated `army_lanyard_sa_ma.glb` 180° around X (flipped
 *     top↔bottom so the cord hangs the right way up).
 *   - Rotated `nylon_belt.glb` 180° around Y (move buckle from
 *     -Z to +Z) and overrode material to flat black.
 *   - Replaced 42-vert `black_socks.glb` placeholder with a
 *     proper sock cylinder (radius 0.05m, height 0.10m, flat
 *     black) so socks read as socks not as box markers.
 *   - Moved body `name_tag` socket from y=1.228 → y=1.345 (above
 *     the chest pocket at y=1.282).
 *   - `army_arms_badge.render_logic.offset_z_cm`: 0 → -3.0 (pull
 *     the badge back toward the body's surface instead of
 *     protruding forward).
 *   - `army_cap_badge_sltc_me6_below.render_logic.offset_z_cm`:
 *     +1.5 → +3.0 (push badge forward through the beret dome so
 *     it's visible on the beret's front face).
 *
 * v10: Pass-6 Army No.3 male — per-accessory placement tuning
 * (ChangeRequest 2026-05-18_army-no3-pass6-placement-tuning):
 *   1. Removed `setScale([-1, 1, 1])` from `attachAccessory`'s mirror
 *      path. The X-flip inverted triangle winding on the right copy;
 *      combined with the default material's back-face culling, the
 *      mirrored mesh rendered invisible. Both copies now attach with
 *      identity scale. Symmetric meshes (chevrons) read correctly on
 *      both sides; asymmetric ones (single-sided placeholder shoes)
 *      render the same shape on both feet — acceptable until L/R
 *      pairs are authored.
 *   2. Moved body sockets `left/right_sleeve_upper` from front-of-
 *      chest (±0.183, 1.388, +0.10) to outer upper arm (±0.30, 1.30,
 *      0.00) so rank chevrons land on the sleeve, not the chest.
 *   3. Sliced the body's monolithic mesh at y=0.10m: the bare feet
 *      now live in a dedicated `feet` sub-node. `composeUniformModel`
 *      detaches `feet` whenever a footwear accessory is in the
 *      include list (parallel to the existing hair-detach when a
 *      headdress mounts).
 *   4. Stripped marker mesh references from all socket nodes except
 *      `body`, `feet`, `name_tag`. The 8-vert marker cubes were
 *      visible as small dark bumps on the shoulders/collar.
 *   5. `army_arms_badge.render_logic.offset_y_cm`: +1.5 → -3.0 to
 *      drop the badge from chin-height onto the shirt's right
 *      collar tip.
 *   6. `nylon_belt.render_logic.offset_z_cm`: -2.0 → -3.0 so the
 *      belt sits flush on the trouser surface instead of protruding
 *      forward.
 *
 * v9: Pass-5 Army No.3 male — TWO ROOT CAUSES (ChangeRequest
 * 2026-05-17_army-no3-pass5-hierarchy-fix):
 *   1. The body AND uniform meshes were both authored facing ±X (face
 *      direction along the X axis), but the sockets injected by
 *      inject_sockets.py sat at +Z assuming the meshes face +Z. So
 *      sockets were on the SIDE of the visible body/uniform, not the
 *      front. The pass-4 Y-flip (which assumed body and uniform faced
 *      opposite Z axes) just rotated the uniform along the wrong axis,
 *      leaving it 90° off from the body. Diagnosed by user-report
 *      ("initial GhostScreen load shows model in profile, mouth toward
 *      camera-right") plus chest-span analysis showing X span > Z span.
 *      Fixed by rotating only the body's "body" mesh -90° around Y
 *      (face: +X → +Z), and applying a 90° net rotation to the uniform
 *      (180° pass-4 + (-90°) + 180° to align with body), with all
 *      transforms baked into vertex coords (sockets untouched).
 *   2. mergeDocuments leaves N source scenes on the target Document
 *      (body + uniform + accessories = N+1 scenes). model-viewer renders
 *      only the default scene, so secondary-scene geometry was either
 *      invisible or rendered through an unguaranteed code path. Fixed
 *      by `consolidateScenesToOne` in compressForWeb, called alongside
 *      consolidateBuffersToOne before the final write.
 */
export const MODEL_BUNDLE_VERSION = 22;

/**
 * Subset of `UniformProfile` fields that affect what the model looks
 * like. Anything outside this set must NOT be folded into the hash.
 */
export interface HashInputs {
  branch: string; // BranchId.wireName
  rank: string; // Rank.code
  gender: string; // Gender.wireName
  dressCode: string; // DressCode.wireName
  isSikh: boolean;
  fullName: string;
  vocation: string;
  medalRowCount: number;
  selectedBadgeIds: string[];
  selectedAccessoryIds: string[];
  /** Per-active-dress check ids (sorted). */
  dressChecks: string[];
}

/**
 * Returns the first 16 hex chars of `sha256(canonicalJson)`. The
 * canonicalisation step (recursive key-sort) ensures Dart and Node
 * produce byte-identical input.
 */
export function computeProfileHash(inputs: HashInputs): string {
  const payload = {
    bundleVersion: MODEL_BUNDLE_VERSION,
    branch: inputs.branch,
    rank: inputs.rank,
    gender: inputs.gender,
    dressCode: inputs.dressCode,
    isSikh: inputs.isSikh,
    fullName: inputs.fullName,
    vocation: inputs.vocation,
    medalRowCount: inputs.medalRowCount,
    selectedBadgeIds: [...inputs.selectedBadgeIds].sort(),
    selectedAccessoryIds: [...inputs.selectedAccessoryIds].sort(),
    dressChecks: [...inputs.dressChecks].sort(),
  };
  const json = JSON.stringify(sortKeysDeep(payload));
  return createHash("sha256").update(json).digest("hex").slice(0, 16);
}

function sortKeysDeep(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeysDeep);
  if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const k of Object.keys(obj).sort()) {
      out[k] = sortKeysDeep(obj[k]);
    }
    return out;
  }
  return value;
}
