# Add belt / socks / footwear as universal mandatory accessories across all dresses

- **Date:** 2026-05-11
- **Author:** Claude (Datta-driven session)
- **Status:** executed (operator on-device verification pending)
- **Verification:**
  - `dart run build_runner build --delete-conflicting-outputs` — 36 outputs, clean diff (DressRequirement freezed regenerated to include `baseAccessories`).
  - `flutter analyze` — clean.
  - `flutter test` — 73/73 pass (no existing test asserted on resolved-id counts; all resolver tests pass with the new base_accessories path).
  - `cd functions && npm run build && npm test` — 18/18 pass.
  - Re-uploaded all bodies + accessories: 11 uploaded (bodies + new belt/socks/footwear placeholder GLBs), 55 sha256-skipped.
  - `dart run tool/seed_firestore.dart` — `dress_requirements: ok (5 docs)`, `accessory_library: ok (82 docs)`.
  - `firebase deploy --only functions:composeUniformModel` — successful (new PAIRED_SOCKETS entries for `ankle` + `foot_top` deployed).
  - User's `generatedDresses[no_3_dress_requirements]` deleted via Admin SDK.

## 1. Goal

Belt, socks, and footwear are mandatory uniform basics for every SAF dress code regardless of branch — but until today the `dress_requirements` collection didn't reference them and the resolver didn't return them. The merger consequently never attached belt/socks/shoes to the composed avatar.

Make all three categories mandatory for every dress code (No.1 through No.5), reuse the already-present `accessory_library` entries (`nylon_belt`, `leather_belt`, `black_socks`, `leather_shoes_low_cut`, `court_shoes`, …), wire up new body sockets so socks + shoes have a place to attach, and ship placeholder geometry for visual confirmation.

## 2. Scope

### In scope
- New top-level field `base_accessories` on each `dress_requirements` doc — universal mandatory selections keyed by category (belt / socks / footwear), with `{men, ladies}` selectors where appropriate.
- TS + Dart resolvers extended to read `base_accessories` after walking per-branch overrides.
- Dart entity `DressRequirement` + Firestore DTO extended with a `baseAccessories` field.
- Library entries for socks + all footwear flagged with `mirror_left_right: true` so the merger attaches them to both feet/ankles.
- New body sockets `left_ankle`, `right_ankle`, `left_foot_top`, `right_foot_top` in [tool/inject_sockets.py](tool/inject_sockets.py) and [tool/generate_placeholder_bodies.py](tool/generate_placeholder_bodies.py).
- Merger's `PAIRED_SOCKETS` map ([functions/src/glb_compose.ts](functions/src/glb_compose.ts)) extended with `ankle` and `foot_top` aliases so the singular library anchors resolve to the canonical left/right pair.
- Placeholder geometry for `belt` (torus), `socks` (cylinder), `footwear` (sole + upper + optional heel) in [tool/generate_placeholder_accessories.py](tool/generate_placeholder_accessories.py).
- Re-seed, re-upload, re-deploy, cache-wipe.

### Out of scope
- Real artist-authored belt/socks/shoes geometry — placeholder phase only.
- Patent-leather and gender-variant officer formal footwear selection (the existing library entries exist but the new `base_accessories` schema only picks the standard variant per gender).
- `MODEL_BUNDLE_VERSION` bump (no per-user cached entry needs invalidation beyond the test user's `no_3` — operator can wipe other devices' entries manually if needed).

## 3. Affected areas

### Data
- `assets/data/accessory_library.v1.json` — 5 entries gained `mirror_left_right: true` (black_socks + 4 footwear).
- `assets/data/dress_requirements.v1.json` — `base_accessories` added to all 5 docs.

### Flutter
- `lib/features/checklist/domain/entities/dress_requirement.dart` — new `baseAccessories` field.
- `lib/features/checklist/data/dtos/dress_requirement_firestore.dart` — decode `base_accessories`.
- `lib/features/checklist/domain/services/dress_accessory_resolver.dart` — read `requirement.baseAccessories`, add to mandatory.

### Backend
- `functions/src/dress_accessory_resolver.ts` — read `requirement.base_accessories`, gender-pick (men vs ladies/maternity), add to mandatory.
- `functions/src/glb_compose.ts` — `PAIRED_SOCKETS` map extended with `ankle` ↔ `[left_ankle, right_ankle]` and `foot_top` ↔ `[left_foot_top, right_foot_top]`.

### Tooling / assets
- `tool/inject_sockets.py` — 4 new socket positions (foot stance), socket count now printed from the dict size instead of hardcoded.
- `tool/generate_placeholder_bodies.py` — same 4 new sockets.
- `tool/generate_placeholder_accessories.py` — 3 new builders (`_build_belt`, `_build_socks`, `_build_footwear`) + `CATEGORY_BUILDERS` wires.

## 4. Step-by-step plan (as executed)

1. Patched `accessory_library.v1.json` — added `mirror_left_right: true` to `black_socks`, `leather_shoes_low_cut`, `patent_shoes_low_cut`, `court_shoes`, `patent_court_shoes`.
2. Patched `dress_requirements.v1.json` — added `base_accessories: {belt, socks, footwear}` to all 5 dress docs.
3. Extended Dart `DressRequirement` entity with `baseAccessories` + DTO decode.
4. Extended Dart resolver to walk `baseAccessories`, gender-pick, add to mandatory.
5. Extended TS resolver with the same logic.
6. Added 4 new sockets (`left/right_ankle`, `left/right_foot_top`) to both body generators.
7. Extended `PAIRED_SOCKETS` in `glb_compose.ts` for the new aliases.
8. Added belt / socks / footwear builders to `generate_placeholder_accessories.py`.
9. `dart run build_runner build --delete-conflicting-outputs` — freezed regen.
10. `flutter analyze` + `flutter test` + `cd functions && npm run build && npm test` — all green.
11. Regenerated bodies + accessories.
12. Uploaded to Firebase Storage.
13. Re-seeded Firestore.
14. Deployed CF.
15. Wiped user's `no_3` cache.

## 5. Risks & rollback

| Risk | Mitigation |
| --- | --- |
| New foot sockets are not on the actual body's feet (Tripo body's leg geometry varies) | Tunable in `tool/inject_sockets.py`. Iterate based on visual feedback. |
| Belt torus passes through body (placeholder ring has fixed radius 14 cm) | Placeholder accepted; real artist belt will conform to body. |
| Socks / shoes look like boxy primitives | Placeholder phase. |
| Resolver returns base accessories that don't have a GLB uploaded (e.g. patent variants) | Merger logs `accessory GLB missing; skipping` and continues; only standard variants are seeded in `base_accessories`. |

**Rollback:** revert `base_accessories` from each dress doc, re-seed; revert the resolver changes + redeploy CF; bodies still work because the new sockets are additive (their presence doesn't break the merger contract).

## 6. Verification

1. `flutter analyze` clean.
2. `flutter test` 73/73 pass.
3. `cd functions && npm run build && npm test` 18/18 pass.
4. Body GLB now has 15 sockets (was 11) + `name_tag` + `head` + `hair` = 18 named nodes total. Confirmed in inject_sockets output: `Injected: 15 sockets + name_tag(name_tag_mat) + head + hair = 18 named nodes.`
5. Re-seed prints `accessory_library: ok (82 docs), dress_requirements: ok (5 docs)`.
6. CF deploy succeeds.
7. On-device (pending): open GhostScreen → CF logs should show `accessory attached: nylon_belt`, `accessory mirrored: black_socks → [left_ankle, right_ankle]`, `accessory mirrored: leather_shoes_low_cut → [left_foot_top, right_foot_top]`, in addition to the existing 5 accessories. Visual: dark belt encircling the waist, dark sock cuffs at ankles, black shoes on each foot.

## 7. CLAUDE.md updates

- §5.5 `composeUniformModel` block — note that base_accessories now flow through the resolver in addition to per-branch overrides.
- §8 — strike "Out of scope for the No.3 placeholder population: footwear (no `foot_top` / `ankle` body sockets — would require extending the body-authoring contract)". Replace with note that those sockets now exist (paired, mirrored) and belt/socks/footwear placeholder geometry is generated.
- §4 source tree — note the 3 new placeholder builders in `tool/generate_placeholder_accessories.py`.
