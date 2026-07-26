# Army No.3 — Lanyard Drop Retune (Pass 4)

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** executed (awaiting device smoke test for `verified`)
- **Follows:** [2026-05-17_army-no3-body-uniform-alignment.md](2026-05-17_army-no3-body-uniform-alignment.md) (pass 3, executed earlier today)

## Execution log (2026-05-17, late evening)

- **Phase 1 — Firebase / Storage sanity check.** User asked explicitly *"Is anything pending to push on Firebase in the last change?"*
  - `python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app` → **`uploaded=0 skipped=68 failed=0`**. Every local GLB matches Storage by sha256. Pass 3 was fully shipped.

- **Phase 2 — Edited `army_lanyard_sa_ma` render_logic** in [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json):

  | field | before | after |
  |---|---|---|
  | `offset_y_cm` | `-12.0` | **`-22.0`** |
  | `side` | `right` | `right` (unchanged) |
  | `offset_z_cm` | `4.0` | `4.0` (unchanged) |
  | `allowance_min_cm` | `8.0` | `8.0` (unchanged) |
  | `allowance_max_cm` | `12.0` | `12.0` (unchanged) |

  **Reason.** Pass-3 device test showed the lanyard cord arcing from the back of the right shoulder FORWARD across the user's face and ending at the chin. Mesh-bounds inspection: the lanyard is `±0.054 × ±0.150 × ±0.139 m`, Y-axis is the drape direction, Y centroid `-0.020` (mass below centre), Z evenly split with the loop curving across both +Z and −Z. Anchored at the body's `right_shoulder_seam` (world `0.166, 1.48, 0.10`) with the old `-12 cm` drop, the cord's top reaches world y=1.51 (shoulder height) — geometrically correct, but the loop's forward Z-arc (reaching world z=+0.28) intersected the camera's sightline at face level due to perspective. Dropping the anchor a further 10 cm to **−22 cm** lands the cord between world y=0.98 (waist) and y=1.28 (low chest), so the entire forward arc is now well below shoulder level and reads as "draping down the right chest to the pocket" per doctrine.

- **Phase 3 — Bumped bundle version 6 → 7:**
  - [functions/src/profile_hash.ts:39](../functions/src/profile_hash.ts#L39) — `MODEL_BUNDLE_VERSION = 7` with a v7 docblock entry.
  - [lib/features/ar_engine/data/profile_hash.dart:36](../lib/features/ar_engine/data/profile_hash.dart#L36) — `kModelBundleVersion = 7` mirroring it. Both must match or every compose request 400-rejects.

- **Phase 4 — Reseed Firestore + redeploy CF:**
  - `dart run tool/seed_firestore.dart …` **failed** because `dart` is currently bundling native assets and the local Mac is missing Xcode Command Line Tools (`xcode-select: error: Unable to get active developer directory`). Same environmental issue blocked `flutter test` at the end of pass 3.
  - Worked around it by reseeding `accessory_library` directly via the Google Cloud Firestore Python client (admin-SDK service account):
    ```python
    from google.cloud import firestore
    db = firestore.Client(project="saf-uniforms")
    for e in json.load(open("assets/data/accessory_library.v1.json"))["accessories"]:
        db.collection("accessory_library").document(e["id"]).set(e, merge=True)
    ```
    → 82 docs upserted. Verified `army_lanyard_sa_ma.render_logic.offset_y_cm = -22.0` in Firestore.
  - `cd functions && npm run build` → clean.
  - `firebase deploy --only functions:composeUniformModel` → `composeUniformModel(asia-southeast1)` updated successfully.

- **Phase 5 — Static verification:**
  - `cd functions && npm test` → **18 / 18 pass**.
  - `flutter analyze` → clean.
  - `flutter test` → still blocked by missing Xcode CLI tools (`objective_c-9.3.0` build hook). Recovery: `sudo xcode-select --install`. No code under test was touched in this pass.

**Outstanding:** device smoke test on the Samsung. User to `flutter run`, regenerate Army / REC / male / non-Sikh / No.3 (bundle v7 forces a fresh compose), and confirm: lanyard now drapes from the right shoulder DOWN the right chest (no cord at face level), all other accessories unchanged from pass 3.

## 1. Goal

Make the lanyard cord drape from the right shoulder seam down to the right pocket button per SAF No.3 doctrine, without crossing the face — matching the visual target in `~/Downloads/military officer 3d model.glb`.

## 2. Scope

In scope: a single render_logic offset on `army_lanyard_sa_ma`, plus the bundle-version constants and the deploy round.

Out of scope: any other accessory (the new side-view screenshot confirms beret / cap badge / shoes / name-tag are all on-body now); the lanyard GLB itself (mesh is fine; only the offset needed to change); body + uniform GLBs (already correct from pass 3); fixing the missing Xcode CLI on this machine (operator action).

## 3. Affected files

- [assets/data/accessory_library.v1.json](../assets/data/accessory_library.v1.json) — `army_lanyard_sa_ma.render_logic.offset_y_cm: -12.0 → -22.0`.
- [functions/src/profile_hash.ts:39](../functions/src/profile_hash.ts#L39) — `MODEL_BUNDLE_VERSION = 7`.
- [lib/features/ar_engine/data/profile_hash.dart:36](../lib/features/ar_engine/data/profile_hash.dart#L36) — `kModelBundleVersion = 7`.
- [CLAUDE.md](../CLAUDE.md) — §5.5 (bundle 6 → 7), §8 Army No.3 placement table (`army_lanyard_sa_ma` offset_y_cm 6 → 7).

## 4. Risks & rollback

- **-22 cm overshoots** and the cord now disappears into the trouser leg / below the waist. Mitigation: small JSON tweak to -18 or -20 and bump bundle v7→v8. Single-line iteration.
- **-22 cm doesn't fully push the loop below the face** (the forward arc is even more upward-biased than the mesh inspection suggested). Fallback: revert pass-2's `--rotate-y 180` on the lanyard GLB (re-inject without that rotation) and retune from scratch — that's pass 5.
- **Other accessories drift** under a front-view test that wasn't captured in the side-view screenshot. Acceptable; address ad-hoc.
- **Rollback:** `git restore assets/data/accessory_library.v1.json functions/src/profile_hash.ts lib/features/ar_engine/data/profile_hash.dart`, then reseed Firestore + redeploy CF (no GLB changes). Returns to pass-3 visual state.

## 5. Verification

Per CLAUDE.md §1.5:
1. `cd functions && npm test` ✅ 18/18.
2. `flutter analyze` ✅ clean.
3. `flutter test` ⚠️ blocked on local Xcode CLI tools (`sudo xcode-select --install` to recover).
4. `flutter run` on Samsung → Army / REC / male / non-Sikh / No.3 → GhostScreen. Bundle v7 forces a fresh compose. Expected: lanyard drapes from right shoulder DOWN the right chest.
5. Mark this plan `Status: verified` once device check confirms.

## 6. CLAUDE.md updates

- §5.5 — `MODEL_BUNDLE_VERSION` 6 → 7.
- §8 Army No.3 placement table — `army_lanyard_sa_ma` row: `offset_y_cm` -12 → **-22**.
- §8 — note that the operator step "reseed Firestore" can be done via `dart run tool/seed_firestore.dart …` OR (if dart is blocked by missing Xcode CLI) directly via the Python `google-cloud-firestore` admin SDK — same service-account JSON, same idempotent merge semantics. A `tool/seed_firestore.py` parallel would formalise this when more pure-data pushes land.
