# Generic accessory inject tool + apply to MP cap badge

- **Date:** 2026-05-10
- **Author:** Claude (Datta-driven session)
- **Status:** executed (operator on-device verification pending)
- **Verification:**
  - `tool/inject_accessory.py` built and run on the MP badge source:
    - Input: 13.4 MB, 0.102 × 0.921 × 0.979 m (Tripo default scale, thin axis = X).
    - Auto-detected thin axis = X, applied -90° around Y → thin axis now Z.
    - Scale ×0.0511 → max-dim = 0.05 m.
    - Recentred at origin via translation (+0.0000, -0.0235, +0.0000).
    - Output: 28.0 MB, 0.050 × 0.047 × 0.005 m, centroid at (0,0,0).
  - gltf-transform validate: 1 mesh, 1 material (`tripo_mat_dd34a04f-…`), centroid within ±0.0001 of origin.
  - Upload: `tool/upload_models.py --only "accessories/army_cap_badge*"` → `uploaded=1 skipped=3` (3 other army_cap_badge_* IDs sha256-skipped).
  - Wipe: `users/WEQNNJ9PUPejc3fBZd9dzAX5qr63/profile/current.generatedDresses.no_3_dress_requirements` deleted via Admin SDK; remaining keys `[no_1, no_2, no_4]`.
  - **Pending:** operator on-device — open GhostScreen, confirm CF logs show `accessory attached: army_cap_badge_sltc_me6_below socket=cap_band_front`, confirm visual: artist-styled badge on the front of the turban band. If badge faces -Z (away from camera), re-run inject_accessory with `--rotate-y 180`.

## 1. Goal

Build a reusable tool `tool/inject_accessory.py` that takes any raw artist GLB (Tripo / Meshy / Luma export, scale + orientation undefined) and emits a contract-compliant accessory GLB ready to drop under `assets/3d/accessories/{id}.glb` and feed the Phase-2 merger. Apply it to the user's Tripo-generated Military Police cap badge → output to `army_cap_badge_sltc_me6_below.glb` so their Army-REC-Sikh profile renders the artist-style badge on the front of the turban band instead of the current procedural gold plate.

## 2. Scope

### In scope
- `tool/inject_accessory.py` — generic GLB normaliser (scale + orient + recentre).
- Process the user's MP badge file → write to `assets/3d/accessories/army_cap_badge_sltc_me6_below.glb`. Preserve raw source at `assets/3d_raw/army_cap_badge_sltc_me6_below_source.glb`.
- Upload the new accessory GLB.
- Wipe the user's `generatedDresses[no_3_dress_requirements]` cache so the next regen sees the new geometry.
- CLAUDE.md §4 source tree update.

### Out of scope
- Body, merger, Cloud Function changes.
- Other accessories.
- Schema changes to `accessory_library.v1.json` (existing `render_logic.anchor: "cap_band_front"` + `offset_y_cm: 1.3` works for the new geometry).
- Material / lighting tuning.

## 3. Affected areas

### Tooling
- `tool/inject_accessory.py` — **NEW**.

### Storage / data
- `assets/3d_raw/army_cap_badge_sltc_me6_below_source.glb` — **NEW** (gitignored).
- `assets/3d/accessories/army_cap_badge_sltc_me6_below.glb` — replaced.
- `gs://saf-uniforms.firebasestorage.app/models/accessories/army_cap_badge_sltc_me6_below.glb` — replaced.
- Firestore: user's `generatedDresses.no_3_dress_requirements` field deleted (single uid).

## 4. Step-by-step plan

1. Build `tool/inject_accessory.py` — load via `trimesh.load(force="mesh")`, auto-orient thin axis to Z, scale uniformly to `--target-size` (default 5 cm), recentre at origin, write GLB.
2. Copy the MP badge to `assets/3d_raw/army_cap_badge_sltc_me6_below_source.glb`.
3. Run inject_accessory.py.
4. Validate via gltf-transform.
5. Upload via `tool/upload_models.py --only "accessories/army_cap_badge*"`.
6. Wipe user's no_3 cache via Admin SDK.
7. CLAUDE.md update.

## 5. Risks & rollback

| Risk | Mitigation |
| --- | --- |
| Badge faces -Z (away from camera) | `--rotate-y 180` flag, re-run, re-upload, re-wipe. |
| Auto-thin-axis pick wrong | `--no-auto-orient` + manual `--rotate-{x,y,z}` overrides. |
| Final size off | `--target-size` knob, re-run. |

**Rollback:** the previous procedural cap-badge generation lives in `tool/generate_placeholder_accessories.py`. Re-running that script regenerates the procedural plate; uploading + wiping rolls back the visible badge.

## 6. Verification

1. `.venv-tools/bin/python tool/inject_accessory.py …` exits 0.
2. Output GLB: 1 mesh, max bbox dim ≤ 0.06 m, centroid within ±5 mm of origin.
3. Upload step prints `uploaded ≥ 1`.
4. Admin-SDK wipe confirms `no_3_dress_requirements` removed from `generatedDresses` keys.
5. User opens GhostScreen → CF log shows `accessory attached: army_cap_badge_sltc_me6_below socket=cap_band_front`; visual: artist badge on the front of turban band.

## 7. CLAUDE.md updates

- §4 source tree — `tool/inject_accessory.py` description.
- §8 — note that artist accessory GLBs can now be dropped into the pipeline via the inject tool.
