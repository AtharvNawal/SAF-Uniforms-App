# Army No.3 Pass 13 — Arm Badge Face Direction Fix

- **Date:** 2026-05-18
- **Author:** Claude (with Datta)
- **Status:** executed

## Context

Both arm rank-insignia badges show their backing (inner face) toward the camera. The embroidered outer face should be visible from the front.

**Root cause:** `army_enlistee_insignia.glb` was processed with `inject_accessory.py --no-auto-orient --rotate-y 90 --target-size 0.08`. The source GLB had its embroidered face along +X; after +90°Y rotation, that face moved to −Z (away from camera). The `sleeve_upper` socket sits at Z ≈ +0.10 (front of arm). From the front view the +Z face of the mesh is closest to the camera — which is the backing, not the embroidery. Both arms use the same GLB with identity scale, so both show the backing.

## Fix

Apply an additional 180°Y rotation to all 8 sleeve-insignia GLBs using `inject_accessory.py --no-auto-orient --rotate-y 180`. This flips the −Z embroidered face to +Z (toward camera). Placeholder GLBs (other branches) are visually symmetric — the rotation is a no-op for them but applied for consistency.

Bump `MODEL_BUNDLE_VERSION` / `kModelBundleVersion` from 20 → 21 to invalidate every cached composed GLB.

## Affected files

- `assets/3d/accessories/army_enlistee_insignia.glb` — 180°Y rotation
- `assets/3d/accessories/army_specialist_insignia.glb` — same
- `assets/3d/accessories/navy_rating_insignia.glb` — same
- `assets/3d/accessories/navy_specialist_insignia.glb` — same
- `assets/3d/accessories/rsaf_enlistee_insignia.glb` — same
- `assets/3d/accessories/rsaf_specialist_insignia.glb` — same
- `assets/3d/accessories/dis_enlistee_insignia.glb` — same
- `assets/3d/accessories/dis_specialist_insignia.glb` — same
- `lib/features/ar_engine/data/profile_hash.dart` — kModelBundleVersion 20 → 21
- `functions/src/profile_hash.ts` — MODEL_BUNDLE_VERSION 20 → 21

## Operator steps (post-code)

1. `GOOGLE_APPLICATION_CREDENTIALS=<svc>.json python3 tool/upload_models.py --bucket saf-uniforms.firebasestorage.app --only "models/accessories/*insignia*.glb"`
2. `firebase deploy --only functions`
3. `flutter run` (rebuild so kModelBundleVersion = 21 bakes in)

## Verification

- `flutter analyze` clean
- GhostScreen Army · REC: both arm badges show embroidered face from front
- No regression on beret, belt, name tag, shoes
