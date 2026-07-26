# Army No.3 Male — Pass 10: beret coverage + user-provided belt

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress (awaiting device verify)
- **Supersedes:** none (follows pass-9)

## 1. Goal

After pass-9 the user still reports:
- Green dome visible above the black beret.
- Beret too small to cover the head.
- The auto-scaled belt now overflows the waist; user provided a
  proper wrap-around belt at
  `/Users/meet/Documents/accessories/nylon_belt.glb`.

Diagnosis:
- The hair-detach IS firing (CF log confirms) and the body's
  `body` mesh is cleanly cut at y=1.659 (verified). What's
  rendering "green" is the **beret itself** — Tripo's
  `normalTexture` + `metallicRoughnessTexture` are still embedded
  in the GLB and PBR shading uses their data, which produces a
  green tint where light hits the bump map even though
  `baseColorTexture` was removed in pass-7.
- The pass-9 belt scale 1.6×1.5 was too aggressive against the
  body's narrow X bbox; user's wrap-around file is a proper
  doctrine belt.

## 2. Scope (executed)

1. **Strip ALL textures + images** from `army_beret.glb`. Reset
   the single material to a plain
   `baseColorFactor=[0.02, 0.02, 0.02, 1.0]`,
   `metallicFactor=0.0`, `roughnessFactor=0.9`. No
   `normalTexture` / `occlusionTexture` / `emissiveTexture`.
   Zero PBR data that could leak a tint.
2. **Scale beret 1.3×** uniformly → 32 cm × 21 cm × 34 cm
   (was 24 × 16 × 26).
3. **`army_beret.render_logic.offset_y_cm`**: −4 → −7 to drop
   the rim 3 cm lower onto the brow/temple.
4. **Swap `nylon_belt.glb`** with the user's wrap-around belt
   (24 cm wide × 22 cm tall × 98 cm long — the long axis wraps
   the waist). Strip textures, force matte black material.
5. **`nylon_belt.render_logic`**:
   - `offset_y_cm`: 0 → −11 (belt's local origin is at the bottom
     of the strap; centre it on the waist).
   - `offset_z_cm`: −3 → −16 (centre the wrap on the body so
     the front-back loop straddles z=0).
6. **Bundle bump** 13 → 14 in both
   `functions/src/profile_hash.ts` +
   `lib/features/ar_engine/data/profile_hash.dart`.

## 3. Affected files

| File | Change |
| --- | --- |
| `assets/3d/accessories/army_beret.glb` | All textures stripped; material reset to plain matte black; mesh scaled 1.3× uniformly. |
| `assets/3d/accessories/nylon_belt.glb` | Replaced with user's wrap-around file; textures stripped; material recoloured matte black. |
| `assets/data/accessory_library.v1.json` | `army_beret.offset_y_cm`: −4 → −7. `nylon_belt.offset_y_cm`: 0 → −11, `offset_z_cm`: −3 → −16. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 14`. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 14`. |
| `CLAUDE.md` | §5.5 + §8 updates. |

## 4. Verification

1. `cd functions && npm run build && npm test` ✅ **22/22 pass**.
2. `flutter analyze` ✅ clean.
3. Device — Army / REC / male / non-Sikh / No.3:
   - Beret renders pure matte black (no green tint), wider rim
     covers more of the head (no scalp showing on the sides).
   - Belt wraps around the waist properly, sits flush, no
     overflow beyond the body's bbox.

## 5. Risks & rollback

- The user's belt's Y extent is 22 cm — that's much taller than a
  real belt. The offset_y_cm=−11 centres the strap on the waist;
  if the user wants only the bottom 5 cm visible (typical belt),
  they may need to reshape the mesh or further tune offsets.
- Beret offset_y_cm=−7 might push the brim into the eyebrows. If
  so, dial back to −5 or −6.
- Rollback: revert bundle bump + the four file changes; redeploy.
