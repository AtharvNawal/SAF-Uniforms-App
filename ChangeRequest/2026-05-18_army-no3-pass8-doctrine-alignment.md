# Army No.3 Male — Pass 8: doctrine-alignment corrections

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress (awaiting device verify)
- **Supersedes:** none (follows pass-7
  `2026-05-18_army-no3-pass7-accessory-details.md`)

## 1. Goal

User shared the SAF Army No.3 doctrine reference image and called
out three specific corrections needed after pass-7:

1. **Name plate is on the opposite pocket** — currently rendering
   on the wearer's left chest pocket. Doctrine puts it on the
   wearer's right chest pocket (camera-left side of screen).
2. **Beret should be black, not green; sized to head** — pass-7
   already overrode `army_beret.glb` material to flat black
   (verified via direct GLB inspection); if user still sees green
   it's because the device hasn't been rebuilt to pick up bundle
   v11 yet. Bundle bump to 12 force-flushes the cache.
3. **Lanyard should attach to the shoulder** — currently anchored
   at `right_shoulder_seam` with `offset_y_cm: -22`. After pass-7's
   180° X flip, the loop sits 8 cm above the shoulder; the cord
   hangs unanchored.

## 2. Scope

In-scope:

1. **Flip body `name_tag` socket X** in
   [assets/3d/bodies/male_apose.glb](../assets/3d/bodies/male_apose.glb):
   `+0.0599` → `-0.0599`. Confirmed empirically that this body
   GLB's socket naming has world +X = wearer's LEFT (camera-right);
   doctrine wants the name plate at wearer's RIGHT = world -X.
2. **`army_lanyard_sa_ma.render_logic.offset_y_cm`** in
   [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json)
   and Firestore: `-22.0` → `-30.0`. With this offset, the
   lanyard's loop (top of bbox after pass-7's flip) lands at
   world y = 1.477 + 0.30 − 0.30 = 1.477 = shoulder seam height ✓.
3. **Bundle bump** `MODEL_BUNDLE_VERSION` 11 → 12 in
   [functions/src/profile_hash.ts](../functions/src/profile_hash.ts)
   and [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart).

Out of scope (defer to follow-up):
- Shirt / trouser color matching the doctrine khaki / olive.
- Belt buckle gold visibility.
- Beret re-sizing (24×16×26 cm is plausible for a 1.78 m head).

## 3. Affected files

| File | Change |
| --- | --- |
| `assets/3d/bodies/male_apose.glb` | `name_tag` socket X: +0.0599 → −0.0599. |
| `assets/data/accessory_library.v1.json` | `army_lanyard_sa_ma.offset_y_cm`: −22.0 → −30.0. |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 12` + v12 docblock. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 12` + matching docblock. |
| `CLAUDE.md` | §5.5 + §8 updates. |

## 4. Step-by-step plan (executed)

1. One-off Python edit on body GLB: parsed JSON chunk, found
   `name_tag` node, changed matrix[12] from +0.0599 to −0.0599,
   re-encoded.
2. JSON edit on accessory_library.v1.json:
   `army_lanyard_sa_ma.render_logic.offset_y_cm`: −22.0 → −30.0.
3. Bumped MODEL_BUNDLE_VERSION + kModelBundleVersion 11 → 12 with
   v12 docblocks documenting both fixes.
4. `cd functions && npm run build && npm test` → 22/22 pass.
5. `flutter analyze` → clean.
6. (Operator) re-upload body GLB; patch Firestore for
   `army_lanyard_sa_ma` via Python admin client; redeploy CF;
   user runs `flutter run`.

## 5. Risks & rollback

- **Risk:** −0.0599 might be inboard of the actual chest pocket
  centre (the `left_chest_pocket` socket is at −0.0732). If
  device shows the name plate just inboard of the pocket, tune
  to −0.073 (i.e. use the chest-pocket X exactly).
- **Risk:** −30 cm Y offset on lanyard might leave the cord
  drooping past the chest. Iterate by ±5 cm if needed.
- **Risk:** the green-beret complaint is actually a model-viewer
  cache issue, not a material file issue. Bundle bump 11 → 12
  forces a fresh compose and a fresh download token on the
  per-user GLB; if green persists after that, the issue is the
  client-side WebView cache and a force-reload of the GhostScreen
  may be needed.
- **Rollback:** every change is gated by bundle 12. Revert the
  bump + the two file changes; redeploy.

## 6. Verification

Per CLAUDE.md §1.5:

1. `cd functions && npm run build && npm test` ✅ **22/22 pass**.
2. `flutter analyze` ✅ no issues.
3. **Device** — Army / REC / male / non-Sikh / No.3:
   - Beret renders matte black with cap badge visible on the
     front face.
   - Name plate on the wearer's RIGHT chest pocket (camera-left
     side), above the pocket flap.
   - Lanyard loop sits at the right shoulder seam with the cord
     draping down to chest height.

## 7. CLAUDE.md updates required

- §5.5 — `MODEL_BUNDLE_VERSION` 11 → 12.
- §8 — pass-8 entry under the Army No.3 alignment bullet.
