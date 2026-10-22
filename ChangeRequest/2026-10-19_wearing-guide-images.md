# Wearing Guide shows the accessory pictures

- **Date:** 2026-10-19
- **Author:** Claude (agent)
- **Status:** executed (not device-verified)

## 1. Goal
The Wardrobe detail sheet now shows each item's pictures for the dress
being viewed (No.4 PDF pictures per service —
`ChangeRequest/2026-10-19_no4-wardrobe-imagery.md`). Show the same
ACCESSORY + PLACEMENT pictures on each Start Wearing step.

## 2. Scope
- In: accessory steps use `accessoryImagesFor(accessory, dress, branch)`;
  the medal / SAF-badge / sleeve-badge steps use the library entries
  `medal_ribbons`, `saf_badges_chest`, `skill_badges_sleeve`. The drawn
  silhouette stays as the fallback when a step has no picture
  (trousers, shirt, items without imagery).
- Out: new pictures, data changes.

## 3. Affected areas
- `checklist/presentation/widgets/accessory_detail_sheet.dart`: its
  private remote-image card moves to a shared
  `checklist/presentation/widgets/accessory_remote_image.dart`.
- `wearing_guide/presentation/screens/wearing_guide_screen.dart`.

## 4. Step-by-step plan
1. Extract the image card widget (no behaviour change in the sheet).
2. `_GuideStep` gains `imageUrl` / `placementUrl`; screen watches
   `accessoryLibraryProvider` for the badge/medal steps.
3. `_StepView` shows the pictures, silhouette otherwise.

## 5. Risks & rollback
Network images in the guide (cached, icon placeholder/fallback like the
sheet). Rollback: revert the two files.

## 6. Verification
`flutter analyze`, `flutter test`, release APK; device check by the user.

## 7. CLAUDE.md updates required
§4 `wearing_guide_screen.dart` line; checklist widgets list.

## 8. Execution notes (2026-10-19)
- `flutter analyze` clean, `flutter test` 188/188, release APK rebuilt.
- Trousers / shirt steps keep the silhouette (no picture exists); every
  accessory, medal and badge step shows its pictures.
