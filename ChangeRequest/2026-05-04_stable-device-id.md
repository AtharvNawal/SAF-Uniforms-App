# Stable Device ID: Hardware-Derived UUID

- **Date:** 2026-05-04
- **Author:** Claude Sonnet 4.6
- **Status:** executed

## 1. Goal

Make the device ID stable across uninstall + reinstall on both platforms by using hardware-bound identifiers as the authoritative source:

- **Android**: `Settings.Secure.ANDROID_ID` (via `android_id` package) → UUID v5
- **iOS**: `identifierForVendor` (via `device_info_plus`, already installed) → used as-is (already UUID format)

Secure storage stays as a fast read cache; hardware derivation is the fallback when storage is empty (e.g. post-reinstall on Android without Auto Backup).

**Root cause:** The previous implementation generated a random UUIDv4 on first launch and cached it in `flutter_secure_storage`. On iOS (production), the keychain survives reinstalls so the ID was stable. On Android, encrypted SharedPreferences are only preserved when Auto Backup runs — without it, every reinstall generated a new UUID, causing `claimDeviceIdentity` to create a brand-new Firebase user and orphan the previous Firestore profile.

## 2. Scope

**In scope:**
- Add `android_id: ^3.0.0` to `pubspec.yaml`
- Update `DeviceIdentityService.resolve()` to use hardware IDs on cache miss
- Update CLAUDE.md §5.4 and §8

**Out of scope:**
- Cloud Function changes (UUID v5 is a valid UUID, passes `z.string().uuid()` Zod validation)
- Firestore rules / schema changes
- Migration of existing users' random UUIDs (cache-hit path unchanged)

## 3. Affected areas

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `android_id: ^3.0.0` |
| `lib/features/auth/data/device_identity_service.dart` | Add `_deriveHardwareId()` fallback |
| `CLAUDE.md` | Update §5.4 and §8 |

## 4. Step-by-step plan

1. Create this ChangeRequest file.
2. Add `android_id: ^3.0.0` to `pubspec.yaml`; run `flutter pub get`.
3. Update `DeviceIdentityService`:
   - Add imports for `android_id` and `device_info_plus`.
   - Replace raw `_uuid.v4()` on cache miss with `await _deriveHardwareId()`.
   - Implement `_deriveHardwareId()`: iOS → `identifierForVendor`; Android → UUID v5 of `ANDROID_ID`; fallback → random UUID.
4. Update CLAUDE.md §5.4 `saf.deviceId` row and §8 known-gaps bullet.
5. Run `flutter analyze` (must be clean).

## 5. Risks & rollback

| Risk | Mitigation |
|------|-----------|
| `android_id` conflicts with existing deps | Check `flutter pub get` output carefully |
| `identifierForVendor` null on iOS simulator | Handled by fallback path |
| Existing Android users without backup get new hardware UUID on next reinstall | Unavoidable — they were already getting a new random UUID each install; hardware UUID is stable going forward |
| Existing users with cached UUID | Unaffected — cache-hit path returns stored value unchanged |

**Rollback:** Revert `device_identity_service.dart` and `pubspec.yaml`. Cached UUIDs in secure storage are unaffected.

## 6. Verification

1. `flutter analyze` — clean.
2. `flutter pub get` — no dependency conflicts.
3. On Android physical device: note UUID from logs, uninstall, reinstall, confirm same UUID derived from `ANDROID_ID`. Confirm Firestore shows `lastSeenAt` updated on existing doc, not a new doc created.
4. On iOS: confirm `identifierForVendor` used; smoke-test dashboard flow.

## 7. CLAUDE.md updates required

- §5.4 — `saf.deviceId` row: update description to hardware-derived UUID
- §8 Known gaps — update/remove the Android reinstall recovery best-effort bullet
