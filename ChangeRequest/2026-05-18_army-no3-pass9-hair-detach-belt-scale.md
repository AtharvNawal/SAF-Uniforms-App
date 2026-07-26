# Army No.3 Male — Pass 9: hair detach + belt scale

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** in-progress
- **Supersedes:** none (follows pass-8
  `2026-05-18_army-no3-pass8-doctrine-alignment.md`)

## 1. Goal

After pass-8 rebuild, user reports two remaining issues:

1. **"Green beret" still appearing on top of the head** — actually
   the body's *scalp/hair geometry* showing through. The body's main
   `body` mesh (60k verts after pass-6 slice) has the head's hair
   region included, and the Tripo material's texture paints the
   scalp area in a green/khaki tint. The black `army_beret.glb`
   sits on top, but where it doesn't cover (sides of the head, gap
   between rim and ear) the green texture is visible. The user
   perceives this as "two berets."
2. **Belt isn't proper** — the placeholder is a 30 cm × 7 cm × 7 cm
   flat strip; it doesn't wrap around the waist. User wants a more
   prominent belt.

There IS a `hair` node in the body GLB and `composeUniformModel`
already calls `detachNodeByName(bodyDoc, HAIR_NODE)` when a
headdress mounts (see `glb_compose.ts:HAIR_NODE`). The detach
runs successfully, but the `hair` NODE has had its mesh reference
stripped (pass-7's marker-mesh strip) and the actual hair vertices
live in the `body` mesh — so detaching the node removes nothing.

## 2. Scope

In-scope, single change set:

1. **Re-slice the body mesh** in
   [assets/3d/bodies/male_apose.glb](../assets/3d/bodies/male_apose.glb).
   Currently the body has `body` (vertices ≥ y=0.10) and `feet`
   (vertices < y=0.10). Add a third sub-mesh `hair` containing the
   scalp vertices above y=1.65 (above the eyebrow line, including
   the top of head where the beret sits). The existing
   `composeUniformModel` hair-detach block will now find real
   geometry to drop when a headdress mounts.
2. **Scale up the belt mesh** in
   [assets/3d/accessories/nylon_belt.glb](../assets/3d/accessories/nylon_belt.glb).
   Apply scale (1.6, 1.5, 1.0) so the belt becomes
   48 cm × 10.5 cm × 7 cm — wider (covers more of the front waist),
   slightly taller (more like a real belt buckle band), depth
   unchanged.
3. **Bundle bump** `MODEL_BUNDLE_VERSION` 12 → 13 in
   [functions/src/profile_hash.ts](../functions/src/profile_hash.ts)
   and [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart).
4. Re-upload body + belt; redeploy CF.

Out of scope:
- Editing the body's texture to remove the green tint at the hair
  UV region (too invasive; detach is simpler).
- Authoring a true wrap-around belt mesh (placeholder works once
  scaled up).

## 3. Affected files

| File | Change |
| --- | --- |
| `assets/3d/bodies/male_apose.glb` | Slice `body` mesh at y=1.65; vertices above → new `hair` sub-mesh under the existing `hair` node. |
| `assets/3d/accessories/nylon_belt.glb` | Scale (1.6, 1.5, 1.0). |
| `functions/src/profile_hash.ts` | `MODEL_BUNDLE_VERSION = 13` + v13 docblock. |
| `lib/features/ar_engine/data/profile_hash.dart` | `kModelBundleVersion = 13` + matching docblock. |
| `CLAUDE.md` | §5.5 + §8 updates. |

## 4. Step-by-step plan

1. One-off Python on body GLB: walk the `body` mesh vertices,
   move every face whose centroid Y > 1.65 into a new `hair`
   sub-mesh. The existing `hair` node (already in the scene) gets
   the new mesh assignment.
2. One-off Python on belt GLB: apply scale (1.6, 1.5, 1.0) and
   recentre on x/z, snap to y=0.
3. Bump bundle 12 → 13.
4. `cd functions && npm run build && npm test`; `flutter analyze`.
5. Re-upload body + belt.
6. `firebase deploy --only functions:composeUniformModel`.
7. User: `flutter clean && flutter pub get && flutter run`.

## 5. Risks & rollback

- Cutting at y=1.65 might leave a visible "bald scalp" gap between
  where the beret rim sits (y≈1.69) and the cut (y=1.65). If so,
  raise cut to y=1.69 or tune the beret offset_y.
- Scaling up the belt to 48 cm might overshoot the body's waist
  bbox (waist half-width ~0.20). Mitigation: dial scale down to 1.4.
- Rollback: revert bundle, body, belt; redeploy.

## 6. Verification

1. `cd functions && npm run build && npm test` — green.
2. `flutter analyze` — clean.
3. Device — green dome gone (only black beret visible on head);
   belt visibly wider with buckle in centre.
