# RSAF No. 4 — wire the delivered dressed figures into the 3D pipeline

- **Date:** 2026-10-02
- **Author:** Claude (Opus 5.5) for Atharv Nawal
- **Status:** executed — deployed; device check pending (operator)

## 1. Goal
The operator uploaded two complete RSAF No.4 dressed figures to Storage:
`models/uniforms/rasf_no4_male.glb` (1.785 m) and
`rasf_no4_female.glb` (1.733 m).

Each figure includes:
- Body, face and hair
- Camo shirt and trousers
- Beret and cap badge
- Boots
- Name and country tapes
- Chest rank tab
- Shoulder patches

They are well structured: named nodes, they face +Z, feet sit at y=0, and
they are centred. They can't be used as-is:
1. The name is misspelled (`rasf`, but the builder looks for `rsaf`).
2. They are in `uniforms/`. That path overlays the file onto the generic
   1.66 m body, so two people would overlap. A full figure belongs at
   `models/bodies/{branch}_{dress}_{gender}.glb`, the "unified" path
   `composeUniformModel` already prefers.
3. They have no socket nodes, so no accessory can attach.
4. Most No.4 accessories are already modelled into the figure. Attaching
   the procedural accessories on top would double them up (two berets,
   two pairs of boots, two rank tabs).
5. The name tape carries the artist's sample text ("ME5 A K TAN"). Its
   texture is stored vertically flipped to match its UVs, so the existing
   bake would draw the user's surname upside down over the sample text,
   in near-black on a black tape.

## 2. Scope
**In scope**

1. **`tool/prepare_unified_figure.mjs`** (Node + gltf-transform, resolved
   from `functions/node_modules`). It works on the existing scene graph,
   so materials and textures are untouched, and does four things:
   - Adds the 15 standard socket nodes plus `name_tag`, measured from the
     figure's own parts. The sockets that a replacement accessory might
     attach to (`head_top`, `cap_band_front`, `belt_center`) are placed so
     that the replacement lands where the built-in item sits.
   - Renames material `name_tape` to `name_tag_mat`.
   - Flips that material's UVs and replaces its image with a blank tape,
     so the existing bake writes the surname upright.
   - Writes a "baked slots" declaration into the GLB root
     `extras.saf_baked_slots`, read from a per-figure JSON config.
2. **`functions/src/glb_compose.ts`**:
   - `readBakedSlots`, `slotOf`, `planBakedDetaches` and `planBakedSkips`
     (pure, unit-tested).
   - `bakeNameTag` picks white or dark text from the tape's luminance.
     Existing white tapes keep dark text, so No.3 output is unchanged.
3. **`functions/src/composeUniformModel.ts`**, for unified figures only.
   Figures without the extras key, e.g. today's `army_no3_male`, behave
   exactly as before.
   - A mandatory accessory that differs from the built-in item for its
     slot detaches the built-in node and attaches the replacement. This
     covers a Sikh turban replacing the beret, the COL/BG cap badge, and
     the cadet rank tab.
   - An accessory that matches the built-in item, or an optional
     alternative in an occupied slot, is skipped.
   - Slots declared "covered" are skipped too: socks inside the boots, and
     the belt under the untucked shirt (as in the PDF's RSAF pictures).
4. Prepare both figures, write them to
   `assets/3d/bodies/rsaf_no4_{male,female}.glb`, upload them to
   `models/bodies/`, and keep the raw sources in `assets/3d_raw/`.
5. Deploy `composeUniformModel`.

**Out of scope**
- Deleting the misnamed `models/uniforms/rasf_*` objects. They are
  harmless once unused; the operator can delete them.
- Per-rank insignia inside the built-in rank tab. The figure models one
  tab; the cadet variant is swapped in, other ranks share it.
- Other branches' No.4 figures. They follow the same recipe when
  delivered.
- A `MODEL_BUNDLE_VERSION` bump. RSAF No.4 composition only started
  today, and a bump forces an app rebuild on every device.

## 3. Affected areas
- `tool/prepare_unified_figure.mjs` (new)
- `assets/3d/figures/rsaf_no4.json` (new)
- `assets/3d/bodies/rsaf_no4_{male,female}.glb` (new)
- `functions/src/glb_compose.ts`, `functions/src/composeUniformModel.ts`,
  `functions/src/glb_compose.test.ts`
- Storage `models/bodies/rsaf_no4_{male,female}.glb`
- `CLAUDE.md` §2 tools, §4/§5.5 compose pipeline, §8

## 4. Steps
1. Write the plan (this file).
2. Add the compose helpers and tests, then wire them in.
3. Write the prep tool and config, then run it on both figures.
4. Verify locally: re-run the real helpers (detach, attach, bake) on the
   prepared figures for these profiles and render them:
   - standard
   - Sikh COL
   - Officer Cadet
   - female
5. Run `npm test`, then upload and deploy.
6. Update CLAUDE.md and this plan's status.

## 5. Risks & rollback
- **Compose regression.** Every new code path is gated on
  `saf_baked_slots` being present, so existing figures are unaffected.
- **Rollback:** delete `models/bodies/rsaf_no4_*.glb`. The builder falls
  back to the generic body + accessories. Then redeploy the previous
  function.

## 6. Verification
- `npm test`, `flutter analyze`, `flutter test`
- Local compose renders for the four profiles above
- After deploy, a device check. That needs the operator.

## 7. Execution notes (2026-10-02)

**Found and fixed during execution**
- **Rank tab:** its insignia meshes are *siblings* of `rank_tab`, so
  detaching the tab left a floating diamond. The prep tool now wraps them
  in a `rank_tab_assembly` group (config `groups`).
- **Wing badge:** the figure also models a chest wing badge, which
  doctrine treats as optional. Added `optional: true` baked slots: removed
  unless `saf_badges_chest` is ticked.
- **Texture transforms:** `createComposeIO` didn't register
  `KHR_texture_transform`, so it silently dropped the figure's 14×
  fabric / 3× skin normal-map tiling. It is now registered.
- **Cadet tab size:** the procedural chest rank tabs were resized from
  5 × 7.5 cm to 3.2 × 5.2 cm, matching the figure. All 8 were
  regenerated and re-uploaded.
- **Boots:** live Firestore still had the pre-fix No.4 footwear (both
  boots mandatory), which would have stripped the modelled boots. It was
  re-seeded.

**Verification**
- `npm test`: 47/47, including 10 new baked-slot / name-colour tests.
- Local compose with the real helpers, Draco + WebP included, for five
  profiles: CPL, Sikh COL, OCT, female 2SG, and CPT with a ticked chest
  badge. Rendered and reviewed; each matches the expected
  skip/swap/remove outcome, with the name baked upright.
- Storage `models/bodies/rsaf_no4_{male,female}.glb` match local by
  SHA-256.
- Firestore No.4 doc matches local.
- `firebase deploy --only functions:composeUniformModel`: successful.

**Not done**
- Device check.
- One user already has a cached `user_models/WEQNNJ…/No4.glb` with an
  unchanged profile hash, so it won't rebuild by itself.
