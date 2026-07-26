# Army No.3 Male — Pass 11: beret from scratch + remove hair

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress (awaiting device verify)
- **Supersedes:** none (follows pass-10)

## 1. Goal

User reports after pass-10:
1. **Green tint still visible on head** despite pass-10 stripping ALL
   textures from the Tripo beret and forcing flat-black material.
2. **Belt invisible** with the pass-10 offsets (-11, -16).
3. **Name plate** needs to move a bit up and toward the wearer's-right.
4. **Beret still too small** to cover the head.

## 2. Root cause

The Tripo `army_beret.glb` appears to persistently render with a
green tint no matter what we do to its material. There's likely
something in the Tripo source — vertex colors, COLOR_0 attribute,
or a renderer quirk reading the residual TEXCOORD_0 even with no
textures — that PBR shading interprets as green. Decided to
**rebuild the beret from scratch** using trimesh primitives so the
provenance is fully under our control.

The belt was placed at world (0, 0.922, 0) — that's BELOW the
trouser waistband; the shirt probably occluded it.

## 3. Scope

In-scope, single change set:

1. **Replace `army_beret.glb`** with a hand-built dome:
   - Hemisphere dome scaled to 22cm wide × 13.2cm tall × 22cm deep
   - Brim ring (annulus) at the rim, 20-23cm outer diameter, 3cm height
   - Slight forward tilt (~8°) to mimic doctrine wear
   - Vertex colors all set to (12, 12, 12, 255)
   - Explicit `beret_black` PBR material: baseColorFactor [0.02, 0.02,
     0.02, 1.0], metallicFactor 0, roughnessFactor 0.9, doubleSided
   - Triple-layered guarantee: vertex colors + black material + no
     textures
2. **`army_beret.render_logic.offset_y_cm`**: −7 → −16 so the brim
   sits at world y=1.65 (brow level), covering the full top of head.
3. **Remove the body's `hair` sub-mesh entirely** from
   `assets/3d/bodies/male_apose.glb`. The body's max_y is now 1.659
   (forehead/temple). No green-tinted scalp can render anywhere.
4. **`nylon_belt.render_logic.offset_y_cm`**: −11 → −3 to lift the
   belt back to the waist level (was below the shirt hem and
   occluded).
5. **Body `name_tag` socket**: world translation
   `(-0.0599, 1.345, 0.165)` → `(-0.075, 1.36, 0.165)` (slightly more
   inboard on wearer's right, lifted 1.5cm higher).
6. **Bundle bump** `MODEL_BUNDLE_VERSION` 14 → 15.

## 4. Affected files

| File | Change |
| --- | --- |
| `assets/3d/accessories/army_beret.glb` | Replaced with hand-built dome + brim, vertex colors black, explicit black PBR material. |
| `assets/3d/bodies/male_apose.glb` | Removed `hair` sub-mesh; moved `name_tag` socket to (−0.075, 1.36, 0.165). |
| `assets/data/accessory_library.v1.json` | `army_beret.offset_y_cm`: −7 → −16. `nylon_belt.offset_y_cm`: −11 → −3. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 15` + v15 docblock. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 15` + matching docblock. |
| `CLAUDE.md` | §5.5 + §8 updates. |

## 5. Verification

1. `cd functions && npm run build && npm test` ✅ 22/22 pass.
2. `flutter analyze` ✅ clean.
3. Device — Army / REC / male / non-Sikh / No.3:
   - Beret renders pure flat black (no green anywhere) with the
     brim at brow level.
   - Belt visible across the front of the waist.
   - Name plate moved up + right.
   - No green dome anywhere on the head.

## 6. Risks & rollback

- The hand-built beret is plain — no badge backing detail, no
  fabric texture, just a smooth dome. Once we have a proper artist
  beret, swap it in.
- The cap badge (`army_cap_badge_sltc_me6_below`) still anchors at
  `cap_band_front` socket which is independent of the beret mesh.
  It should sit on the brim regardless of beret shape.
- Rollback: revert bundle bump + the four file changes; redeploy.
