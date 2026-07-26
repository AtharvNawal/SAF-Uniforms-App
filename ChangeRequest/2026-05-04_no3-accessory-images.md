# No.3 Accessory Images: Real Photos + Placement Diagrams via Firebase Storage

- **Date:** 2026-05-04
- **Author:** Claude Opus 4.7
- **Status:** verified (UI smoke-test on Android/iOS still pending)
  - `flutter analyze` clean (full project).
  - `flutter test` clean — 64 tests pass (3 new CheckCard widget tests +
    61 existing).
  - `dart run build_runner build --delete-conflicting-outputs` clean.
  - **Initial PNGs auto-extracted** from the SAF No.3 Dress PDF via a
    new operator-only tool
    [`tool/extract_pdf_accessories.py`](../tool/extract_pdf_accessories.py)
    (added 2026-05-05). Crops are pulled by auto-detected table-row
    indices for product-photo pages and explicit pixel boxes for
    placement-diagram pages, then auto-trimmed and padded. 140 files
    written into `assets/accessories/<id>/{image,placement}.png` across
    all 4 branches.
  - **Firebase Storage initialized** by operator (bucket
    `saf-uniforms.firebasestorage.app`, region asia-southeast1).
    `firebase deploy --only storage` succeeded.
  - **Image upload pipeline migrated to Python**
    ([`tool/upload_accessory_images.py`](../tool/upload_accessory_images.py))
    after the Dart `--upload-images` path proved unreliable — the
    shared `google_cloud_storage` HttpClient threw
    `HttpException: Unexpected response (unsolicited response without
    request)` after ~15 sequential uploads, and the exception escaped
    try/catch through an async stream callback. The Python tool uses
    urllib + openssl-signed JWTs; rock-solid for batches of this size.
    Same SHA-256 idempotency contract, same
    `firebaseStorageDownloadTokens` metadata so the existing
    `getDownloadURL` callers keep working.
  - **Live state**: 140/140 PNGs uploaded to
    `gs://saf-uniforms.firebasestorage.app/accessories/`,
    `accessory_library.v1.json` patched with 139 real
    `https://firebasestorage.googleapis.com/...` URLs (one missing
    target was an empty target list in the manifest, by design), all
    82 `accessory_library` Firestore docs pushed via
    `tool/seed_firestore.dart`. Sanity-check on
    `https://firebasestorage.googleapis.com/...?token=...` returns 200.
  - `flutter run` smoke pass on Android & iOS still pending.

## 1. Goal

Replace placeholder image URLs (`https://cdn.saf.sg/...`) on every No.3 dress
accessory entry in `accessory_library` with real PNGs hosted in Firebase
Storage, and surface them in the app:

- **Wardrobe row**: thumbnail of the accessory photo replaces the category icon.
- **Accessory detail sheet**: stacks the accessory photo and the placement
  diagram above the body text and the existing custom-painted torso fallback.

Every accessory has two images per the SAF No.3 Dress reference PDF — the
product/photo image and the placement-diagram image (e.g. Picture C-1 for
collar rank insignia position). Both are uploaded by the operator-only seed
script and read by the app over auth-required Storage URLs.

The data model already supports this: `Accessory` (Freezed) has `imageUrl` +
`placementDiagramUrl` and the DTO already maps `image_url` /
`placement_diagram` from Firestore — the values are just placeholder URLs
today.

## 2. Scope

**In scope (No.3 dress only):**
- The ~52 PDF-aligned per-branch + per-rank-tier entries in
  `assets/data/accessory_library.v1.json` (`army_*`, `navy_*`, `rsaf_*`,
  `dis_*`).
- The generic No.3 entries shared across branches (`name_tag_*`,
  `belt_nylon_men`, `belt_leather_ladies`, `lanyard_*`, `footwear_*`,
  `socks_black`).
- New asset tree `assets/accessories/{id}/{image,placement}.png`,
  populated manually by the operator from the SAF No.3 Dress PDF.
- New `firebase_storage` runtime dep + `cached_network_image` UI dep.
- New `storage.rules` (auth-required reads) registered in `firebase.json`.
- `tool/seed_firestore.dart` gains a `--upload-images` flag.
- UI changes in `CheckCard`, Wardrobe `_AccessoryRow`, and the accessory
  detail sheet.

**Out of scope:**
- Legacy No.1 / 2 / 4 / 5 placeholder entries
  (`render_logic.legacy_placeholder == true`). They keep using the icon
  fallback; the UI handles empty `imageUrl`/`placementDiagramUrl` gracefully.
  Their assets land when their doctrine PDFs do.
- Retiring the custom-painted `_PlacementDiagram` torso (kept as a fallback
  for entries without a real diagram URL).
- Any change to Firestore rules — `accessory_library` already requires auth.
- Animated overlays / 3D ghost-model image swap.

## 3. Affected areas

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `firebase_storage: ^13.x` and `cached_network_image: ^3.4.x` |
| `firebase.json` | Add `"storage": { "rules": "storage.rules" }` block |
| `storage.rules` (new) | Auth-required reads for `accessories/**`; writes blocked (Admin SDK only) |
| `assets/accessories/` (new) | Per-accessory subdirs holding `image.png` + `placement.png` |
| `assets/accessories/README.md` (new) | Per-id checklist mapping ids → PDF source pictures |
| `tool/seed_firestore.dart` | New `--upload-images` flag: SHA-256-keyed Storage upload, JSON URL backfill |
| `assets/data/accessory_library.v1.json` | Updated in-place by seed reruns (real Storage URLs) |
| `lib/core/design/widgets/check_card.dart` | Optional `imageUrl` parameter; `CachedNetworkImage` in `_Thumb` |
| `lib/features/dashboard/presentation/tabs/wardrobe_tab.dart` | Pass `accessory.imageUrl` into `CheckCard` |
| `lib/features/checklist/presentation/widgets/accessory_detail_sheet.dart` | Two new image slots above body text; threads imageUrl + placementDiagramUrl through `_AccessoryView` and `_showSheet` |
| `CLAUDE.md` | §3 deps, §2 layout, §5.5 Storage subsection, seed-script docs |

## 4. Step-by-step plan

1. Create this ChangeRequest file.  *(this step)*
2. `pubspec.yaml`: add `firebase_storage: ^13.x` + `cached_network_image:
   ^3.4.x`; `flutter pub get`.
3. Add repo-root `storage.rules` (auth-required reads, writes blocked) and
   register in `firebase.json` under a new `"storage"` key.
4. Create `assets/accessories/README.md` documenting the folder convention
   and a per-id source-picture checklist for the SAF No.3 Dress PDF.
5. Extend `tool/seed_firestore.dart` with a `--upload-images` flag:
   - Walk `assets/accessories/<id>/{image,placement}.png` for every JSON
     entry.
   - Upload to `gs://saf-uniforms.appspot.com/accessories/{id}/{name}.png`
     via Admin SDK; set `cacheControl: public, max-age=31536000, immutable`,
     `contentType: image/png`, and custom metadata `sha256=<hex>`.
   - Skip uploads when remote `sha256` matches local file (idempotent reruns).
   - Patch the in-memory JSON entry with the resolved
     `https://firebasestorage.googleapis.com/...` URL and persist back to
     disk.
   - Keep default behaviour Firestore-only when the flag is absent.
6. Extend `CheckCard` with optional `String? imageUrl`. When non-empty, the
   56×56 thumb renders `CachedNetworkImage` (icon as `errorWidget`, low-key
   shimmer placeholder). All existing icon-only call sites stay compatible.
7. Wardrobe tab: thread `accessory.imageUrl` into the `CheckCard` constructed
   inside `_AccessoryRow`.
8. Accessory detail sheet:
   - Extend `_showSheet`/`_AccessoryView` signatures to carry `imageUrl` +
     `placementDiagramUrl`.
   - Insert two new private widgets above the body text container —
     "ACCESSORY" image + "PLACEMENT" image — each rendering nothing when its
     URL is empty.
   - Keep the existing body text container, `_PlacementDiagram` torso, and
     "Got It" button untouched (torso remains a fallback for legacy
     entries).
   - Legacy `showAccessoryDetailSheet` (the `AccessoryItem` path, no longer
     reachable) passes empty strings.
9. Update CLAUDE.md per §7.
10. Verify per §6.
11. Update plan `Status:` to `executed` then `verified`.

## 5. Risks & rollback

| Risk | Mitigation |
|------|-----------|
| PDF photo resolution is low — thumbnails may pixelate on hi-dpi screens | Spot-check on iPhone 15 Pro + a Pixel during verification; flag a follow-up plan to source higher-res / vector replacements if visibly bad |
| First Wardrobe open issues ~10–15 image requests | `cached_network_image` after first run; `cacheControl: immutable` lets the CDN serve subsequent users from edge |
| Auth-required Storage URLs won't render outside the app (e.g. paste into a browser) | Documented in CLAUDE.md so future contributors don't waste time debugging "broken" URLs |
| Seed script overwrites JSON in-place — accidental double run produces no diff but a dirty git tree | Idempotent SHA-256 short-circuit; print "skipped" count so operator notices when nothing changed |
| Legacy entries with empty `imageUrl` could render a broken-image placeholder | UI renders nothing (collapses cleanly) when URL is empty; verified during step 10 by switching profile to a No.1/2/4/5 dress |
| Firebase Storage bucket not yet provisioned | Operator step `firebase deploy --only storage` (and ensuring the default bucket exists in the Firebase Console) is documented in CLAUDE.md §5.5 |

**Rollback:** revert the four UI/data files, keep the JSON URLs as-is (their
old placeholder values were never live anyway), and re-run
`firebase deploy --only firestore:rules` to leave Storage rules unused. The
`assets/accessories/` directory and `tool/seed_firestore.dart` flag are
inert without callers.

## 6. Verification

1. `dart run build_runner build --delete-conflicting-outputs` — sanity
   rebuild (no annotation changes, but DTO-adjacent code touched).
2. `flutter analyze` — clean.
3. `flutter test` — existing tests pass; add a `CheckCard` widget test that
   asserts the icon renders when `imageUrl` is null/empty and that a non-empty
   URL inserts a `CachedNetworkImage`.
4. Operator: drop a few real PNGs into `assets/accessories/army_beret/` and
   run `dart run tool/seed_firestore.dart <svc-account>.json --upload-images`;
   confirm the printed summary, that the JSON file got rewritten with real
   `firebasestorage.googleapis.com` URLs, and that the docs in the Firebase
   Console show the same URLs.
5. Operator: `firebase deploy --only storage`.
6. `flutter run` on Android **and** iOS:
   - Wardrobe tab: army_beret row shows the real beret photo thumbnail;
     legacy entries still show their icon (no broken-image placeholder).
   - Tap army_beret: detail sheet stacks the accessory photo and the C-1
     placement diagram above the body text. Loading shimmer appears briefly
     on first open; offline reopen after first cache works.
   - Switch profile to a No.1/2/4/5 dress: legacy entries still render with
     the icon fallback, no console errors.
7. Update plan `Status:` to `executed`, then `verified` after the live
   `flutter run` smoke pass.

## 7. CLAUDE.md updates required

- **§3 Tech stack table** — add `firebase_storage` and `cached_network_image`.
- **§2 Top-level layout** — add `assets/accessories/` and `storage.rules`.
- **§5.5 Backend → Firebase** — add a "Storage" subsection: bucket name
  (`saf-uniforms.appspot.com`), auth-required reads, layout
  `accessories/{accessoryId}/{image,placement}.png`, immutable cache
  headers, deploy command.
- **§5.5 Operator-only seed script** — document the `--upload-images` flag,
  the `assets/accessories/` convention, and that diagrams are duplicated
  rather than deduped.
- **§8 Known gaps / TODOs** — call out that legacy No.1/2/4/5 entries
  intentionally have empty image URLs and rely on the icon fallback until
  their doctrine PDFs land.
