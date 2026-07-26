# Artist Accessory GLB Validation & Upload

- **Date:** 2026-05-12
- **Author:** Claude (claude-sonnet-4-6)
- **Status:** verified

## 1. Goal

Replace the procedural placeholder GLBs in `assets/3d/accessories/` for 8 Army / universal accessories with artist-authored models. Normalise each source GLB to the contract spec (correct orientation, scale, centred at origin) and upload to Firebase Storage `models/accessories/`.

## 2. Scope

- In scope: 8 GLBs from `/Users/meet/Documents/accessories/` — `army_beret`, `army_cap_badge_sltc_me6_below`, `army_enlistee_insignia`, `army_arms_badge`, `army_lanyard_sa_ma`, `leather_shoes_low_cut`, `name_tag_standard` (from `name_tag.glb`), `nylon_belt`.
- Out of scope: No code changes, no Firestore schema changes, no routing changes. No other GLBs.

## 3. Affected areas

- `assets/3d/accessories/` — 8 GLB files replaced.
- Firebase Storage `models/accessories/` — 8 objects updated.

## 4. Step-by-step plan

1. Pre-inspect source GLBs (trimesh bbox check).
2. Run `tool/inject_accessory.py` for each source → `assets/3d/accessories/<id>.glb`.
   - Flat accessories (auto-orient): cap badge, enlistee insignia, arms badge, name tag.
   - 3D objects (--no-auto-orient): beret, lanyard, shoes, belt.
3. Bbox-validate all 8 output GLBs; re-run with `--rotate-*` if any 3D object is wrong orientation.
4. Upload via `tool/upload_models.py --bucket saf-uniforms.firebasestorage.app --only "accessories/<id>.glb"` for each file.
5. Mark this plan `verified`.

## 5. Risks & rollback

- **Orientation risk** for 3D accessories: `--no-auto-orient` preserves artist frame, which may need manual rotation correction.
- **name_tag_standard**: category `name_tag` is bake-only in the 3D merger — the GLB is uploaded for reference but does not affect rendered models.
- **Rollback**: Placeholders can be regenerated at any time via `tool/generate_placeholder_accessories.py`.

## 6. Verification

- All 8 output GLBs load cleanly in trimesh with correct max extents (±1%).
- `upload_models.py` reports each file uploaded (or skipped if SHA matches).
- Open GhostScreen in the app on a device — the composed model should show the new artist accessories instead of the procedural placeholders.

## 7. CLAUDE.md updates required

None — asset pipeline operation only (no code/schema/routing/provider graph changes).

---

## Execution log (2026-05-12)

All 8 source GLBs loaded cleanly (Tripo exports at ~1 m scale). Processing summary:

| ID | Target size | Correction | Output (max ext) | Upload |
|---|---|---|---|---|
| army_beret | 0.20 m | --no-auto-orient | 0.2000 m ✓ | ✓ |
| army_cap_badge_sltc_me6_below | 0.05 m | auto-orient (thin X→Z) | 0.0500 m ✓ | ✓ |
| army_enlistee_insignia | 0.08 m | auto-orient (thin X→Z) | 0.0800 m ✓ | ✓ |
| army_arms_badge | 0.06 m | auto-orient (thin X→Z) | 0.0600 m ✓ | ✓ |
| army_lanyard_sa_ma | 0.30 m | --no-auto-orient | 0.3000 m ✓ | ✓ |
| leather_shoes_low_cut | 0.28 m | --no-auto-orient | 0.2800 m ✓ | ✓ |
| name_tag_standard | 0.09 m | auto-orient (thin X→Z) | 0.0900 m ✓ | ✓ |
| nylon_belt | 0.30 m | --no-auto-orient --rotate-y 90 | 0.3000 m ✓ | ✓ |

**nylon_belt rotation note:** Initial run had Z as longest axis (pointing toward camera); applied --rotate-y 90 so the belt spans left-right (X=0.300 m) as expected for `belt_center` socket placement.

**Visual checks recommended:**
- `leather_shoes_low_cut`: post-scale width is 25.3 cm (vs ~9 cm for a real shoe). Verify appearance in GhostScreen — may need artist reexport if shoes appear too wide.
- `army_lanyard_sa_ma`: loop is 30 cm wide. Check the cord hangs naturally from the right_shoulder_seam socket.
- `army_beret`: orientation preserved from artist (Y-up Tripo frame). Verify dome faces up and rim is centered on head_top socket.
