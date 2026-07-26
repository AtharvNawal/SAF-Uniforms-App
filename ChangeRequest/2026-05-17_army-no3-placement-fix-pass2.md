# Army No.3 Male — Placement Fix Pass 2

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** executed (awaiting device smoke test for `verified`)
- **Supersedes:** [2026-05-13_army-no3-placement-fix.md](2026-05-13_army-no3-placement-fix.md) (status `executed`; device test on 2026-05-17 revealed residual issues addressed here)

## Execution log (2026-05-17)

- **Phase 0 — GLB bbox audit** via `trimesh` against the 6 affected accessories. Key finding: `leather_shoes_low_cut.glb` is a **single shoe** with 25.3 × 13.3 × 28 cm extents and an asymmetric vertex distribution (median X = −0.017, 47% verts on X<−0.02 vs 28% on X>0.02), **not** the two-shoes-in-one-mesh the 2026-05-13 plan assumed. `army_beret.glb` measured 18.7 × 12.6 × 20 cm — rim too narrow to cover hair on the Tripo body, which lacks a separate `hair` node so `detachNodeByName(body, "hair")` returns false. `army_lanyard_sa_ma.glb` Y-axis was already the drape direction post-prior-rotate-z-90, but the loop curved leftward across the chest instead of toward the right pocket. `nylon_belt.glb` (30 × 7 × 7.3 cm) was fine but the `-5 cm` z-offset pushed it inside the torso (half-extent in Z is only 3.7 cm). `army_cap_badge_sltc_me6_below.glb` (5 × 5 × 0.6 cm centred) and `army_enlistee_insignia.glb` (2.6 × 7.3 × 8 cm, thin in X for sleeve-flat-face) needed no re-injection.

- **Phase 1 — Re-injections** (3 GLBs):
  - `leather_shoes_low_cut`: sliced at X=0 (kept X<0 half) via `trimesh.slice_plane(cap=False)`, recentred at origin, written to `assets/3d_raw/leather_shoes_low_cut_single.glb`; then re-injected via `tool/inject_accessory.py --target-size 0.25 --no-auto-orient` → final bbox ±0.063 × ±0.065 × ±0.125 m.
  - `army_beret`: re-injected via `--target-size 0.26 --no-auto-orient` (×1.30 scale) → final bbox ±0.122 × ±0.082 × ±0.130 m (24.3 cm wide rim now covers the head's parietal width).
  - `army_lanyard_sa_ma`: re-injected via `--target-size 0.30 --no-auto-orient --rotate-y 180` → flips loop direction so the cord curves toward the right pocket button per doctrine.
  - Installed `scipy`, `shapely`, `networkx` into `.venv-tools` for the slice operation.

- **Phase 2 — `accessory_library.v1.json` render_logic updates** (6 entries):
  | id | before | after | reason |
  |---|---|---|---|
  | `army_beret` | `{head_top, y:-3}` | `{head_top, y:-4}` | drop bigger beret slightly more so rim sits at brow level. |
  | `army_cap_badge_sltc_me6_below` | `{cap_band_front, y:0, z:+2}` | `{cap_band_front, y:-1, z:+1.5}` | drop badge 1 cm to sit on the larger beret's band; slightly less Z because the bigger beret's front face is already closer to camera. |
  | `army_enlistee_insignia` | unchanged | unchanged | `{sleeve_upper, mirror_left_right:true}` was already correct. |
  | `army_lanyard_sa_ma` | `{side:right, y:-15, z:+3}` | `{side:right, y:-12, z:+4}` | less Y-drop (post-flip the cord visually hangs further down on its own); +4 Z pushes loop in front of shirt. |
  | `nylon_belt` | `{belt_center, y:0, z:-5}` | `{belt_center, y:0, z:-2}` | reduce z-pullback so the belt's front face stays on the trouser surface instead of disappearing into the torso (Z half-extent is only 3.7 cm). |
  | `leather_shoes_low_cut` | `{left_foot_top, x:+10, y:+4}` | `{foot_top, y:+3, z:0, mirror_left_right:true}` | **key fix.** Switch from single-side anchor to generic `foot_top` so `PAIRED_SOCKETS["foot_top"]` attaches a mirrored copy under both `left_foot_top` and `right_foot_top`. Sole rests on ground with y:+3 (foot_top socket at y=0.03, shoe Y half-extent 0.065). |

- **Phase 3 — Bundle-version bump**:
  - `functions/src/profile_hash.ts`: `MODEL_BUNDLE_VERSION = 4 → 5`, with a v5 docblock note.
  - `lib/features/ar_engine/data/profile_hash.dart`: `kModelBundleVersion = 4 → 5`, matching docblock note. **Both constants must match** because the server validates the client's hash; bumping only one would 400-reject every compose request.

- **Phase 4 — Upload + seed + build + deploy**:
  - `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app` → `uploaded=3 skipped=65 failed=0` (the 3 re-injected GLBs).
  - `dart run tool/seed_firestore.dart <svc>.json` → `branch_configs: 4, global_logic_rules: 1, dress_requirements: 5, accessory_library: 82` docs pushed.
  - `cd functions && npm run build` → clean (no TS errors).
  - `firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated successfully. Bundle v5 + 2 GiB memory now live.

- **Phase 5 — Static verification**:
  - `cd functions && npm test` → 18/18 pass.
  - `flutter analyze` → "No issues found! (ran in 5.9s)".
  - `flutter test` → 73 tests pass.

**Outstanding:** device smoke test on Samsung (Front + Side GhostScreen vs reference image). User to run `flutter run`, regenerate Army / REC / male / No.3 (bundle v5 forces a fresh compose), and report. If any single accessory remains visibly off, iterate Phase 1 + 2 for that accessory and bump bundle to 6.

## 1. Goal

Make the composed Army / REC / male / No.3 GLB visually match the doctrine reference: beret seated on the crown with no hair poking through, cap badge centred on the band, rank chevrons on both upper sleeves, lanyard hanging from the right shoulder seam with the loop curving toward the right pocket, black belt wrapping the waistline visible from front, both feet shod, no gray-cube placeholders.

The 2026-05-13 pass shipped but the device smoke test (2026-05-17 screenshot) showed: beret too high with hair visible, cap badge floating above head, single chevron near left chest only, lanyard loop curving leftward across chest instead of toward right pocket, belt rendering as small black box near right hip, shoes stacked on left foot with right foot bare.

## 2. Scope

In scope: Army / No.3 / male — six accessory entries + the bundle-version constant in both `profile_hash.ts` and `profile_hash.dart`.

Out of scope: Navy / RSAF / DIS, No.1/2/4/5, female / female-maternity bodies, real hair-mesh segmentation on Tripo bodies (mitigated via bigger beret per user choice), lanyard physics drape, true left+right shoe authoring (mirror flip is acceptable for the placeholder).

## 3. Affected files

- [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json) — 6 render_logic blocks.
- [assets/3d/accessories/army_beret.glb](../assets/3d/accessories/army_beret.glb) — re-injected at 26 cm target.
- [assets/3d/accessories/army_lanyard_sa_ma.glb](../assets/3d/accessories/army_lanyard_sa_ma.glb) — re-injected with `--rotate-y 180`.
- [assets/3d/accessories/leather_shoes_low_cut.glb](../assets/3d/accessories/leather_shoes_low_cut.glb) — replaced with single-shoe (sliced + re-injected).
- [assets/3d_raw/leather_shoes_low_cut_single.glb](../assets/3d_raw/leather_shoes_low_cut_single.glb) — new intermediate (gitignored).
- [functions/src/profile_hash.ts](../functions/src/profile_hash.ts) — `MODEL_BUNDLE_VERSION = 5`.
- [lib/features/ar_engine/data/profile_hash.dart](../lib/features/ar_engine/data/profile_hash.dart) — `kModelBundleVersion = 5`.
- [CLAUDE.md](../CLAUDE.md) — §5.5 (bundle 4 → 5), §8 (shoe assumption corrected).

## 4. Risks & rollback

- **Bigger beret clips through the head on a Side view tilt.** Mitigation: if visible, drop the beret `--target-size` from 0.26 → 0.24 and re-inject.
- **Mirror-flipped right shoe looks visibly wrong** (laces/eyelets on the outer side instead of inner). Acceptable for the placeholder; the real artist deliverable will replace this.
- **Lanyard rotate-y 180 wrong direction.** If the loop now curves over the back of the shoulder instead of the front, replace with `--rotate-y 0` or `--rotate-z 180` and re-inject.
- **Belt z-offset still wrong.** -2 cm is a guess; iterate by ±1 cm.
- **Hair still pokes through the bigger beret.** Drop beret offset_y further (e.g. -6) or grow target-size to 0.28.
- **Rollback:** `git restore assets/data/accessory_library.v1.json assets/3d/accessories/{army_beret,army_lanyard_sa_ma,leather_shoes_low_cut}.glb functions/src/profile_hash.ts lib/features/ar_engine/data/profile_hash.dart` then `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app && dart run tool/seed_firestore.dart <svc>.json && firebase deploy --only functions:composeUniformModel`.

## 5. Verification

Per CLAUDE.md §1.5:
1. `cd functions && npm test` ✅ 18/18.
2. `flutter analyze` ✅ clean.
3. `flutter test` ✅ 73 pass.
4. `flutter run` on Samsung: Army / REC / male / non-Sikh / No.3 → GhostScreen. Bundle v5 forces a fresh compose. Expected: beret seated on crown (no hair gap), cap badge on band, both upper sleeves carry a chevron, lanyard hangs from right shoulder with loop curving toward right pocket, belt wraps waist visible front-to-side, both feet shod.
5. Once visually confirmed, mark this plan `Status: verified`.

## 6. CLAUDE.md updates

- §5.5 — `MODEL_BUNDLE_VERSION` mention 4 → 5.
- §8 — the "leather_shoes_low_cut.glb ships both shoes in one mesh" sentence is wrong; replace with "ships a single shoe; the merger mirrors it under both `left_foot_top` and `right_foot_top` via `mirror_left_right: true`". Also note that on Tripo bodies the `hair` node is not separable so the bigger-beret approach is the current mitigation.
