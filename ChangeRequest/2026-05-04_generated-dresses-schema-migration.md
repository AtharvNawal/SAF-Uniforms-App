# ChangeRequest: Migrate generatedDresses to dress-ID keyed, richer value schema

**Date:** 2026-05-04  
**Status:** executed

---

## Goal

Replace the `generatedDresses: Map<String, DateTime>` field on `UniformProfile`
with `Map<String, GeneratedDress>` where:
- Key = `dress_requirements` document ID (e.g. `no_3_dress_requirements`)
- Value = `GeneratedDress { builtAt: DateTime }` (extensible for future 3D model/image refs)

## Scope

- Domain: new `GeneratedDress` entity, updated `UniformProfile`, `DressCode.requirementDocId` getter
- Data: `UniformProfileDto` serialization + backward-compat migration for old wireName-keyed Firestore data
- Presentation: `UniformProfileNotifier.markDressGenerated`, `home_tab.dart`, `dashboard_screen.dart`

## Affected areas

| File | Change |
|------|--------|
| `lib/features/profile/domain/entities/dress_code.dart` | Add `requirementDocId` getter |
| `lib/features/profile/domain/entities/generated_dress.dart` | New freezed entity |
| `lib/features/profile/domain/entities/uniform_profile.dart` | Field type change |
| `lib/features/profile/data/dtos/uniform_profile_dto.dart` | Serialize/deserialize + migration |
| `lib/features/profile/presentation/providers/uniform_provider.dart` | `markDressGenerated` update |
| `lib/features/dashboard/presentation/tabs/home_tab.dart` | Key lookup update |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | `dressStates` update |

## Risks & rollback

- Old Firestore data (`{No1: epoch_ms}`) is migrated transparently in the DTO reader.
  No data loss. Rollback by reverting all 7 files + re-running build_runner.

## CLAUDE.md sections to refresh

- § 5.2 (UniformProfileNotifier — description of `generatedDresses` field)

## Verification

1. `flutter analyze` — clean
2. `flutter pub run build_runner build --delete-conflicting-outputs`
3. `flutter test` — all pass
4. `flutter run` — smoke test generated dress card, builtAt date, old-data migration
