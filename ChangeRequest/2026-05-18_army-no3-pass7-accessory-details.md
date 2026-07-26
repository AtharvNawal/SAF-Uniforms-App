# Army No.3 Male — Pass 7: nine per-accessory detail fixes

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress
- **Supersedes:** none (follows pass-6
  `2026-05-18_army-no3-pass6-placement-tuning.md`)

## 1. Goal

Pass-6 brought the major structural fixes (mirror, sleeve socket
move, feet detach, marker-mesh strip, arms_badge / belt offsets).
The device test reveals nine remaining detail issues, all user-
reported from the front + side screenshots:

1. **Beret is green, should be black.** The current
   `army_beret.glb` is a Tripo-generated artist model whose texture
   reads as green. The user expects the black SAF doctrine beret.
2. **Name tag is below the chest pocket — should be above.**
   `name_tag` socket sits at `y=1.228` (below `chest_pocket` at
   `y=1.282`). Move the `name_tag` socket up.
3. **Belt looks cut / wrong side.** Inspect the belt mesh
   orientation and offset.
4. **Arms badge should sit further back** along the body's depth
   axis. Increase the negative Z offset.
5. **Cap badge not visible on the beret.** Either the badge is
   inside the beret mesh or it's behind the brim. Tune
   `cap_band_front` offsets.
6. **Shoes pair GLB ships as a pair** (both shoes in one mesh).
   The merger duplicates the pair at both `foot_top` sockets → 4
   shoes visible. Slice the pair offline at `x=0`, keep one
   shoe, save. The existing `mirror_left_right` (identity scale
   per pass-6) attaches that single shoe to both feet.
7. **Socks position is inside the legs.** The current
   `black_socks.glb` is a 42-vert placeholder cube — replace with
   a simple sock cylinder sized to wrap the lower leg.
8. **Lanyard is upside-down on the shoulder.** Rotate the lanyard
   mesh 180° (around X or Z) so its current top becomes the bottom,
   then re-tune the shoulder offset.
9. **Beret size doesn't fit the head.** Tune the beret target
   size and re-inject so the rim sits at brow level without
   hair poking through.

## 2. Scope

In-scope (single change set):

1. Slice `assets/3d/accessories/leather_shoes_low_cut.glb` at
   `x=0` (the pair's midline). Keep the wearer's-left shoe
   (`x < 0` half), recentre on origin. Re-export at the same path.
2. Override `army_beret.glb` material `baseColorFactor` to
   `(0.10, 0.10, 0.10, 1.0)` (near-black) so the green texture
   tint reads black under PBR shading.
3. Re-inject `army_beret.glb` at slightly larger `--target-size`
   if the rim doesn't cover the head, or smaller if it overshoots.
   Iterate via bbox audit + offset_y tune.
4. Replace `assets/3d/accessories/black_socks.glb` with a simple
   sock cylinder (radius ~0.05m, height ~0.10m) for each ankle,
   black material.
5. Rotate `assets/3d/accessories/army_lanyard_sa_ma.glb` 180°
   around X (flip top↔bottom).
6. Adjust `assets/3d/bodies/male_apose.glb`:
   - `name_tag` socket: y `1.228` → `1.345` (above the chest
     pocket which is at `y=1.282`, with the pocket's vertical
     extent factored in).
7. Adjust `assets/data/accessory_library.v1.json`:
   - `army_arms_badge.render_logic.offset_z_cm`: 0 → `-2` so the
     badge sits further back along Z (closer to the body's surface
     rather than protruding forward).
   - `army_cap_badge_sltc_me6_below.render_logic.offset_z_cm`:
     `+1.5` → `+3.0` (push the badge further forward so it's
     visible on the beret's front face, not inside the dome).
8. Inspect belt mesh — if the belt only covers the front
   (~30cm wide vs body waist circumference ~80cm), the user's
   complaint of "cut version" is by design of the placeholder.
   Re-orient if the buckle is on the back (Z asymmetry test).
9. Bump `MODEL_BUNDLE_VERSION` 10 → 11 in
   `functions/src/profile_hash.ts` +
   `lib/features/ar_engine/data/profile_hash.dart`.
10. Re-upload changed GLBs, patch Firestore for
    `army_arms_badge` + `army_cap_badge_sltc_me6_below`, redeploy
    `composeUniformModel`.

Out of scope:
- User-provided real artist deliveries for any of the accessories
  (this pass works with the placeholders + tunes them).
- Other branches / dresses.

## 3. Affected files

| File | Change |
| --- | --- |
| `assets/3d/accessories/leather_shoes_low_cut.glb` | Sliced at x=0, single shoe. |
| `assets/3d/accessories/army_beret.glb` | baseColor overridden to black; possibly re-sized. |
| `assets/3d/accessories/army_lanyard_sa_ma.glb` | Rotated 180° around X. |
| `assets/3d/accessories/black_socks.glb` | Replaced with cylinder pair. |
| `assets/3d/accessories/nylon_belt.glb` | Inspected; possibly re-oriented. |
| `assets/3d/bodies/male_apose.glb` | `name_tag` socket Y moved up. |
| `assets/data/accessory_library.v1.json` | arms_badge offset_z + cap_badge offset_z + possibly beret offset_y. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 11`. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 11`. |

## 4. Step-by-step plan

1. Inspect belt orientation (which side is the buckle on).
2. Slice shoes pair → single shoe.
3. Rotate lanyard 180° around X.
4. Override beret material color to black.
5. Replace socks placeholder with a cylinder pair.
6. Move `name_tag` socket up in body GLB.
7. Update accessory_library.v1.json offsets.
8. Bump bundle version.
9. `cd functions && npm run build && npm test` ; `flutter analyze`.
10. Re-upload changed GLBs.
11. Patch Firestore via the Python admin client.
12. `firebase deploy --only functions:composeUniformModel`.
13. User: `flutter run`.

## 5. Risks & rollback

- Beret color override via `baseColorFactor` multiplies the
  texture color. Black times texture-green ≈ very dark green,
  not pure black. If the user needs pure black, the texture itself
  must be replaced with a black PNG. Mitigation: iterate to a flat
  black texture if the multiplied color isn't dark enough.
- Slicing the shoes pair at `x=0` assumes the pair is symmetric
  about origin. If the pair was authored off-centre, the kept
  half may not include a complete shoe. Mitigation: visual check
  before re-upload.
- Lanyard 180° rotation may put the cord in front of the chest
  instead of behind. Tune by ±90° if needed.
- Rollback: every change gated by bundle 11. Revert the bump and
  the four code/asset files; redeploy.

## 6. Verification

1. `cd functions && npm run build && npm test` — green.
2. `flutter analyze` — clean.
3. Device — Army / REC / male / non-Sikh / No.3:
   - Beret black, sized to head, badge visible on front.
   - Name tag ABOVE the chest pocket.
   - Belt visible and oriented buckle-front.
   - Arms badge on collar, not floating near face.
   - One shoe per foot (no quad-shoes).
   - Socks visible on lower legs.
   - Lanyard drapes correctly from shoulder.

## 7. CLAUDE.md updates required

- §5.5 bundle 10 → 11.
- §8 pass-7 entry under the Army No.3 alignment bullet.
