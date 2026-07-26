# ChangeRequest: Gallery Feature

**Date:** 2026-05-05
**Status:** verified

---

## Goal

Implement the Dashboard Gallery tab end-to-end: user photo upload to Firebase Storage, Firestore metadata persistence, a responsive 3-column photo grid with dress-code filter bar, and a full-screen pinch-to-zoom viewer with share and delete.

---

## Scope

New feature — does not modify any existing business logic. The Gallery tab was a non-functional placeholder.

---

## Affected areas

- `pubspec.yaml` — new deps: `image_picker ^1.1.2`, `photo_view ^0.14.0`, `share_plus ^13.1.0`
- `android/app/src/main/AndroidManifest.xml` — `READ_MEDIA_IMAGES` + `READ_EXTERNAL_STORAGE` permissions
- `ios/Runner/Info.plist` — updated camera/library strings + `NSPhotoLibraryAddUsageDescription`
- `storage.rules` — new `user_photos/{uid}/{allPaths=**}` owner read/write rule
- `lib/core/l10n/arb/app_en.arb` + `app_zh.arb` — new gallery keys
- `lib/core/routing/routes.dart` — `galleryViewer` constant
- `lib/core/routing/app_router.dart` — `/gallery/viewer` GoRoute
- `lib/features/gallery/` — entire new feature module (domain / data / presentation)
- `lib/features/dashboard/presentation/tabs/gallery_tab.dart` — full rewrite

---

## Step-by-step plan

1. Add `image_picker`, `photo_view`, `share_plus` to `pubspec.yaml` + `flutter pub get`
2. Add Android + iOS platform permissions
3. Update `storage.rules` + `firebase deploy --only storage`
4. Add L10N strings + `flutter gen-l10n`
5. Create `gallery_photo.dart` (Freezed entity) + `gallery_repository.dart` (abstract interface)
6. Create `gallery_repository_impl.dart` (FirebaseStorage upload + Firestore watch/delete)
7. Create `gallery_providers.dart` (4 Riverpod providers) + `dart run build_runner build`
8. Add `galleryViewer` route constant and GoRoute (expects record-typed `extra`)
9. Create `photo_viewer_screen.dart` (PhotoViewGallery, Hero, share, delete)
10. Rewrite `gallery_tab.dart` (CustomScrollView + SliverGrid + filter bar + shimmer + upload flow)
11. Update CLAUDE.md

---

## Risks & rollback

- **Rollback:** delete `lib/features/gallery/`, revert `gallery_tab.dart` to the placeholder, revert `storage.rules`, `pubspec.yaml`, `routes.dart`, `app_router.dart`.
- **Storage rules deploy required** before upload works on device. Deploy: `firebase deploy --only storage`.
- **share_plus ^13** requires `win32 ^6` — compatible with `device_info_plus ^13`; `^10` was incompatible.

---

## Verification

1. `flutter analyze` — ✅ No issues found.
2. `dart run build_runner build --delete-conflicting-outputs` — ✅ 32 outputs generated.
3. `flutter gen-l10n` — ✅ ran cleanly.
4. `flutter test` — ✅ 64/64 tests passed.
5. `firebase deploy --only storage` — pending operator run.
6. Device smoke test — pending.

---

## CLAUDE.md sections refreshed

- §3 Tech stack table — gallery packages added
- §4 Source tree — `features/gallery/` subtree added; `gallery_tab.dart` description updated; `storage.rules` description updated
- §5.5 Firestore collections — `users/{uid}/gallery/{photoId}` documented
- §5.6 Routing — `/gallery/viewer` documented
