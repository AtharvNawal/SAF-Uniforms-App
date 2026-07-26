# Phase-2 — Accessory population + name-tag position fix

- **Date:** 2026-05-09
- **Author:** Claude (Datta-driven session)
- **Status:** executed
- **Verification:**
  - `flutter analyze` clean (4.8s).
  - `flutter test` 73/73 pass.
  - `cd functions && npm run build && npm test` clean — 15/15 pass (12 prior + 3 new mirror tests).
  - `tool/inject_sockets.py` re-run on the Tripo male source produces `name_tag` at z=0.105m (was 0.355m), all 11 sockets at non-zero anatomic node transforms.
  - 26 anchor renames applied to `accessory_library.v1.json` + `mirror_left_right=true` set on 1 entry that was missing it. Re-seed: `dart run tool/seed_firestore.dart` → `accessory_library: ok (82 docs)`.
  - 55 placeholder accessory GLBs generated: 13 cap_badge, 7 ladies hat, 6 sikh turban, 6 cap embellishment, 4 each beret / epaulette / sleeve specialist / sleeve enlistee / lanyard, 2 arms_badge, 1 vocation_badge. Skipped 10 legacy + 17 out-of-scope.
  - Re-uploaded male body (13.7 MB) and 55 accessory GLBs to Firebase Storage. Female + maternity bodies sha256-skipped.
  - `firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated successfully.
  - Bundle version `MODEL_BUNDLE_VERSION = 3` deployed; client constant bumped to match.
  - **Pending operator step:** rebuild app (`flutter run`) so the Flutter-side `kModelBundleVersion = 3` constant takes effect. Until then, the user's old client sends `profileHash` computed against v2 and the CF rejects with `failed-precondition: stale request`.

### Hotfix 2026-05-09 — multi-buffer GLB write error

After the original deploy, the operator deleted their `generatedDresses` Firestore entry to force a fresh regen and saw:
```
Compose failed: GLB must have 0–1 buffers.
```

`@gltf-transform/core`'s `NodeIO.writeBinary` enforces "exactly 0 or 1
buffers per GLB". `mergeDocuments(target, source)` accumulates one
`Buffer` per source — body + 7 accessories = 8 buffers — and the writer
rejects this. The previous Phase-2 testing on placeholder bodies didn't
hit this because no accessories were merged in.

**Fix:** new helper `consolidateBuffersToOne(doc)` in
[functions/src/glb_compose.ts](functions/src/glb_compose.ts) that:
1. Picks the first buffer as primary.
2. Reassigns every accessor's buffer to it via `accessor.setBuffer(primary)`.
3. Disposes the now-orphan secondary buffers.

Wired into `compressForWeb` as the FINAL step (must run after Draco,
which can create new accessors) so the flow is:
`merge → dedup+prune → draco → webp → consolidate → writeBinary`.

3 unit tests added (collapse N→1, write succeeds where it previously
errored, no-op for ≤1-buffer docs). 18/18 tests pass. Re-deployed.

## 1. Goal

Close the three reasons GhostScreen renders a body but no accessories:

1. **Chest-side socket offsets are wrong on Tripo bodies** — the bbox-derived
   `body_depth * 0.55` heuristic in `tool/inject_sockets.py` puts every
   front-side socket (name_tag, chest pockets, collar tips, belt center,
   cap_band_front) ~25 cm in front of the actual chest surface. Replace with
   anatomic constants.
2. **No accessory GLBs exist in Storage** — populate critical-path No.3 IDs
   with procedural placeholder geometry via a new
   `tool/generate_placeholder_accessories.py`.
3. **Accessory library schema is misaligned with the merger contract** —
   54 of 72 active No.3 entries use anchor names that don't match the body's
   11-socket contract; 15 set `mirror_left_right: true` (a flag the merger
   doesn't honor); 9 use special-case keys (`anchor_men`/`anchor_ladies`,
   `side`). Rename anchors in the JSON; add mirror + side support to the
   merger; route name tag through the existing bake step rather than via
   socket-attach.

After this lands, an Army / 3SG / male / no.3 profile renders body + name-tag
on chest + beret + cap badge + sleeve insignia (both arms, mirrored) +
epaulettes (both shoulders) + optional lanyard + optional arms badge.

## 2. Scope

### In scope
- Bug fix: chest offsets in `tool/inject_sockets.py`.
- Anchor renames in `assets/data/accessory_library.v1.json` (canonical
  body-socket names).
- `mirror_left_right` + `side` support in `functions/src/glb_compose.ts` and
  `functions/src/composeUniformModel.ts`.
- Name-tag filter (skip `category === "name_tag"` accessories — handled by
  the bake step).
- New tool `tool/generate_placeholder_accessories.py` — emits ~15 placeholder
  GLBs covering the critical-path No.3 categories.
- Re-seed `accessory_library` Firestore collection from patched JSON.
- Upload accessory GLBs.
- Bump `MODEL_BUNDLE_VERSION` 2 → 3 (TS + Dart). Redeploy `composeUniformModel`.

### Out of scope (future plans)
- Footwear (`foot_top` / `ankle` body sockets don't exist).
- Medal ribbons / SAF badges / foreign badges (no `anchor`; need stack-layout).
- Gorgettes (officer/cadet, complex placement).
- Collar rank pins.
- Real artist accessory GLBs (placeholders only).

## 3. Affected areas

### Backend (Cloud Functions)
- `functions/src/glb_compose.ts` — `mirror` param + paired-socket map.
- `functions/src/glb_compose.test.ts` — mirror unit test.
- `functions/src/composeUniformModel.ts` — anchor resolver helper, name-tag filter.
- `functions/src/profile_hash.ts` — `MODEL_BUNDLE_VERSION = 3`.

### Flutter
- `lib/features/ar_engine/data/profile_hash.dart` — `kModelBundleVersion = 3`.

### Tooling
- `tool/inject_sockets.py` — chest offset fix.
- `tool/generate_placeholder_accessories.py` — **NEW**.

### Data / Storage
- `assets/data/accessory_library.v1.json` — anchor renames.
- `assets/3d/accessories/*.glb` — **NEW** ~15 placeholders.
- Re-seed Firestore `accessory_library` collection.
- Upload accessories to `gs://…/models/accessories/*`.
- Re-upload `gs://…/models/bodies/male_apose.glb` (corrected sockets).

## 4. Step-by-step plan

1. Fix `_socket_positions` and `_name_tag_position` in `tool/inject_sockets.py`
   — replace bbox-fraction Z with anatomic constants.
2. Re-run inject on the existing Tripo source; verify name_tag Z ≈ 0.105 m.
3. Re-upload body to Storage.
4. Patch anchor names in `accessory_library.v1.json`.
5. Add `mirror` param + paired-socket map to `glb_compose.ts`.
6. Add unit test in `glb_compose.test.ts`.
7. Add anchor-resolver helper + name-tag filter in `composeUniformModel.ts`.
8. `cd functions && npm run build && npm test`.
9. Re-seed Firestore via `dart run tool/seed_firestore.dart`.
10. Write `tool/generate_placeholder_accessories.py`.
11. Run it; eyeball each output GLB in gltf-viewer if possible.
12. `tool/upload_models.py --only "accessories/*"`.
13. Bump `MODEL_BUNDLE_VERSION = 3` in TS + Dart.
14. `flutter analyze` and `cd functions && npm run build && npm test` clean.
15. `firebase deploy --only functions:composeUniformModel`.
16. Refresh CLAUDE.md §5.5 + §8.

## 5. Risks & rollback

| Risk | Mitigation |
| --- | --- |
| Anchor rename breaks resolver tests | `flutter test` before re-seed; resolver tests check IDs not anchor strings. |
| Mirroring causes z-fighting on symmetric mesh | Test fixture in `glb_compose.test.ts`; iterate offset by ±2 mm if seen. |
| Bundle bump leaves old client app caching v2 hashes | User rebuilds app; `kModelBundleVersion` is compile-time. |
| Tripo chest depth differs from 0.10 m constant | Eyeball Milestone A output before continuing. |
| Re-seed overwrites operator-edited fields | `seed_firestore.dart` does `SetOptions.merge()` — non-JSON fields preserved. |

**Rollback:** Revert `MODEL_BUNDLE_VERSION` to 2; redeploy CF; revert
`accessory_library.v1.json` and re-seed. Existing `user_models/{uid}/{dressCode}.glb`
v2 blobs remain valid (body-only).

## 6. Verification

1. `flutter analyze` clean.
2. `cd functions && npm run build && npm test` clean (12 existing + 1 new test).
3. `flutter test` 73/73 pass.
4. `gltf-transform` validate the new male body: `name_tag` Z ≈ 0.105 m.
5. Upload step prints `uploaded=N` for accessories.
6. CF logs after a GhostScreen open show `accessory attached` for each
   resolved accessory; **zero** `socket node not found` warnings for the
   user's profile.
7. Visual on device: beret + cap badge + sleeve insignia (both arms) +
   epaulettes (both shoulders) + name-tag on right chest with surname.
8. Toggle optional accessories in Wardrobe → confirm regen + appearance.

## 7. CLAUDE.md updates

- §5.5 Cloud Storage `models/**` block — note `models/accessories/**` populated.
- §5.5 `composeUniformModel` block — note `mirror_left_right` and `side`
  handling, and that name-tag is bake-only (filtered from accessory loop).
- §8 Known gaps — strike "Uniform + accessory GLBs are still unpopulated";
  replace with note about footwear, medal ribbons, gorgettes still pending.
- §4 Source tree — add `tool/generate_placeholder_accessories.py`.
