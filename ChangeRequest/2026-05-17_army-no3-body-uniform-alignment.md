# Army No.3 — Body / Uniform Scale Alignment (Pass 3)

- **Date:** 2026-05-17
- **Author:** Claude (with Datta)
- **Status:** executed (awaiting device smoke test for `verified`)
- **Supersedes context for:** [2026-05-13_army-no3-placement-fix.md](2026-05-13_army-no3-placement-fix.md) and [2026-05-17_army-no3-placement-fix-pass2.md](2026-05-17_army-no3-placement-fix-pass2.md) — pass 2's per-accessory tuning was correct in spirit, but built on top of a broken body GLB and a scale-mismatched uniform. This pass fixes the root cause.

## Execution log (2026-05-17, late afternoon)

- **Phase 0 — Body + uniform scale audit**:
  - `assets/3d/bodies/male_apose.glb` (live, in git): **62,803 of 62,907 verts at z=0 exactly** (a flat XY strip x=±0.10, y=0..1.78), 104 verts > 0 z (the socket markers). Bounds [-0.172, 0, 0] → [0.172, 1.78, 0.165]. This is **not a 3D body** — it's a 2-D silhouette plus the 18 contract sockets / name_tag / head / hair markers. Origin is unknown (probably an older buggy inject_sockets run, or a hand edit).
  - `assets/3d/uniforms/army_no3_male.glb` (live): bounds [-0.088, 0, -0.176] → [0.087, 0.979, 0.176]. **0.98 m tall**, properly 3-D, 62 730 verts. This is the actual mesh rendered by the device — the body GLB contributes no visible geometry.
  - Sockets in the live body were placed assuming a **1.78 m** figure (head_top y=1.78, belt_center y=1.015, right_shoulder_seam (0.156, 1.45, 0.10), etc.). Against the 0.98 m uniform that's actually visible, every upper-body socket sits **~80 cm above** the uniform's head. The screenshot symptom of accessories floating in the upper-left of the viewport (when the uniform is in the lower half) is the exact geometric consequence.
  - Confirmed by running the **current** `tool/inject_sockets.py` on `assets/3d_raw/male_apose_tripo_source.glb` — produces a properly 3-D body with bounds [-0.186, 0, -0.324] → [0.186, 1.81, 0.324] and z-spread of vertices across the full ±0.32 m. The script works; the file in git was just stale / wrong.

- **Phase 1a — Regenerated `assets/3d/bodies/male_apose.glb`**:
  ```bash
  .venv-tools/bin/python tool/inject_sockets.py \
    --in assets/3d_raw/male_apose_tripo_source.glb \
    --out assets/3d/bodies/male_apose.glb \
    --target-height 1.78
  ```
  Output: 13.7 MB GLB, bounds [-0.186, 0, -0.324] → [0.186, 1.812, 0.324]. 18 named nodes (15 sockets + name_tag + head + hair) at sane positions.

- **Phase 1b — Scaled `assets/3d/uniforms/army_no3_male.glb` to 1.78 m**:
  - Backed up the original to `assets/3d_raw/army_no3_male_source.glb` (the 0.98 m Tripo native scale).
  - Loaded with `trimesh.load(force='mesh', process=False)`, applied uniform scale `1.78 / 0.9787 ≈ 1.819`, recentred x/z, dropped feet to y=0.
  - Result bounds: [-0.159, 0, -0.321] → [0.159, 1.78, 0.321]. 15.5 MB, **matches the body's bounds within centimetres**.

- **Phase 2 — Verified body + uniform alignment**: both files now bounded inside the same box (~37 cm × 178 cm × 64 cm). Socket positions sit ON the body's anatomy: head_top (0, 1.81, 0), belt_center (0, 1.03, 0.16), right_shoulder_seam (0.166, 1.48, 0.10), foot_top (±0.10, 0.03, 0.08), name_tag (0.06, 1.23, 0.165).

- **Phase 3 — Bumped bundle version 5 → 6**:
  - `functions/src/profile_hash.ts:35` and `lib/features/ar_engine/data/profile_hash.dart:31`. Both updated with matching docblock entries.

- **Phase 4 — Upload + build + deploy**:
  - `python3 tool/upload_models.py …` → uploaded=2 (body + uniform), skipped=66, failed=0.
  - `cd functions && npm run build` → clean.
  - `firebase deploy --only functions:composeUniformModel` → updated `asia-southeast1`. Bundle v6 live.

- **Phase 5 — Verification**:
  - `cd functions && npm test` → **18 / 18 pass**.
  - `flutter analyze` → "No issues found! (ran in 6.8 s)".
  - `flutter test` → **BLOCKED** by a missing Xcode Command Line Tools install on this Mac (the `objective_c-9.3.0` build hook tries `xcrun --sdk macosx --show-sdk-path` and gets back an empty string, then `Iterable.first` throws on the next line). This is purely an environment regression mid-session (the same `flutter test` passed earlier today at 73 / 73). No code path under test was touched in this pass. To recover: `sudo xcode-select --install` then re-run.

**Outstanding:** device smoke test on the Samsung. User to `flutter run`, regenerate Army / REC / male / non-Sikh / No.3 (bundle v6 forces a fresh compose), and report. Per the pass-2 plan, residual ±2 cm offsets are tuned per-accessory in `accessory_library.v1.json` — not another full pass.

## 1. Goal

Make the composed Army / REC / male / No.3 GLB visually match the reference [`~/Downloads/military officer 3d model.glb`](../../Downloads/military%20officer%203d%20model.glb): beret on the crown, cap badge centred on the band, both upper sleeves carry a chevron, lanyard hanging from the right shoulder ON the body (not floating beside it), belt around the waist, both feet shod.

The pass-2 device test (2026-05-17 15:45 SGT) showed accessories drifting to one side and floating in space because the body / uniform pair was internally mis-scaled — pass 3 fixes that scale alignment.

## 2. Scope

In scope: `male_apose.glb` body + `army_no3_male.glb` uniform + the bundle-version constant in both `profile_hash.ts` and `profile_hash.dart`.

Out of scope: Navy / RSAF / DIS, No.1/2/4/5, female / female-maternity bodies and uniforms (their uniforms are still empty placeholders), the per-accessory `render_logic` (pass 2's values are kept; re-tune in a small follow-up only if specific accessories still look off after the scale fix), the missing-`hair`-node issue on the Tripo body (still mitigated via the bigger beret from pass 2).

## 3. Affected files

- [assets/3d/bodies/male_apose.glb](../assets/3d/bodies/male_apose.glb) — regenerated via `tool/inject_sockets.py` from the Tripo source.
- [assets/3d/uniforms/army_no3_male.glb](../assets/3d/uniforms/army_no3_male.glb) — scaled to 1.78 m height.
- [assets/3d_raw/army_no3_male_source.glb](../assets/3d_raw/army_no3_male_source.glb) — new backup of the original 0.98 m uniform (gitignored alongside the other raws).
- [functions/src/profile_hash.ts:35](../functions/src/profile_hash.ts#L35) — `MODEL_BUNDLE_VERSION = 6`.
- [lib/features/ar_engine/data/profile_hash.dart:31](../lib/features/ar_engine/data/profile_hash.dart#L31) — `kModelBundleVersion = 6`.
- [CLAUDE.md](../CLAUDE.md) — §5.5 (bundle 5 → 6), §8 (note that the body GLB was previously stale + the uniform was at half-height; both have to be re-normalised to 1.78 m for the merger's socket positions to line up).

## 4. Risks & rollback

- **Per-accessory pass-2 offsets need re-tuning**: those offsets were tuned against the broken body + half-scale uniform. With the body and uniform now both 1.78 m and the sockets in their proper anatomic positions, some accessories may now overshoot by a few centimetres (e.g. the beret's `offset_y_cm: -4` might want to be `-2`). Acceptable — single-accessory tweaks are quick to ship.
- **Scaling the uniform changed its bytes** so the per-uniform Storage cache is invalidated. Bundle bump handles the per-user cached GLBs.
- **Other uniforms / dresses** (Navy / RSAF / DIS, No.1/2/4/5) — still empty placeholders, so unaffected by this pass; the same scale alignment will need to be applied when those land.
- **Female / female-maternity bodies** — still untouched. Their uniforms are also empty. When female content lands, apply the same recipe (1.65 m target height for the body, scale the uniform to match).
- **Rollback**: `git restore assets/3d/bodies/male_apose.glb assets/3d/uniforms/army_no3_male.glb functions/src/profile_hash.ts lib/features/ar_engine/data/profile_hash.dart`, then re-upload (sha256 idempotency restores the prior Storage state) and redeploy. Pass-2 visual state returns.

## 5. Verification

Per CLAUDE.md §1.5:
1. `cd functions && npm test` ✅ 18/18.
2. `flutter analyze` ✅ clean.
3. `flutter test` ⚠️ blocked on local Xcode CLI tools (`sudo xcode-select --install` to recover). No code under test was changed in this pass.
4. `flutter run` on Samsung: Army / REC / male / non-Sikh / No.3 → GhostScreen. Bundle v6 forces a fresh compose. Compare side-by-side against `~/Downloads/military officer 3d model.glb`.
5. Mark this plan `Status: verified` once the device check matches the reference.

## 6. CLAUDE.md updates

- §5.5 — `MODEL_BUNDLE_VERSION` mention 5 → 6.
- §8 — add a note: the live `male_apose.glb` in git through 2026-05-17 morning was a corrupted flat-strip placeholder (62 k verts at z=0); the recipe to regenerate it from `assets/3d_raw/male_apose_tripo_source.glb` via `tool/inject_sockets.py --target-height 1.78` is documented. Uniform GLBs from Tripo land at the source's native scale (~0.98 m); they MUST be normalised to 1.78 m (matching the body) before the merger will align accessories — a one-off Python scale is sufficient for the current single-mesh uniform; a `tool/inject_uniform.py` would formalise this when more uniforms land.
