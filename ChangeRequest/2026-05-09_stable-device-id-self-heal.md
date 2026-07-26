# Stable Device ID: Hardware-First, Cache-as-Hint Self-Heal

- **Date:** 2026-05-09
- **Author:** Claude Opus 4.7
- **Status:** executed (verification: `flutter analyze` clean, 72 / 72 tests pass including 8 new device-identity tests, `cd functions && npm run build` clean. Pending physical-device smoke test before flipping to `verified`.)

## 1. Goal

Make device-identity recovery on uninstall + reinstall self-healing. Today, after a reinstall on the same Android device, the app wrote `device_registrations/00000000-0000-0000-0000-000000000000` (the Nil UUID) and routed the user back into the Configuration wizard, despite an existing-and-correct `device_registrations/c936e93b-1266-506e-aecb-864ca0898861` for the same physical device (verified: `v5(Namespace.url, "saf-uniforms:android:19fd6c81908c7473") == c936e93b-…`).

Outcome we want: same physical device → same Firebase uid → skip Configuration wizard, regardless of cache state.

## 2. Scope

**In scope:**
- Rewrite `DeviceIdentityService.resolve()` to derive from hardware on every launch and reconcile against secure-storage cache (cache becomes a fast-path hint, not authoritative).
- Detect Nil UUID / empty cache and overwrite with hardware-derived ID.
- Add a hard `StateError` guard so a Nil UUID can never be returned from the service.
- Add diagnostic logging of the raw `Settings.Secure.ANDROID_ID` value.
- Reject Nil UUID server-side in `claimDeviceIdentity` and `markProfileComplete` (defence in depth).
- Client-side guard in `_runLiveAuthInner` so a bad deviceId throws loudly instead of orphaning a registration.
- Unit tests covering cache-hit, cache-miss, Nil-UUID poisoning self-heal, hardware mismatch, and hardware-unavailable fallback paths.

**Out of scope:**
- Investigating *how* the Nil UUID got into the cache originally (no logs from the bad install). The fix makes the question moot — next launch self-heals.
- The truncated `WelcomeScreen` build exception in the user's log paste (not enough info; bootstrap pipeline is independent of widget build errors).
- Migrating profile data the user might have entered against the orphaned `00000000-…` registration (user reported they were sent back to Configuration, so there's nothing to preserve).
- iOS-side changes beyond the symmetric refactor (uses `identifierForVendor`, already a UUID).

## 3. Affected areas

| File | Change |
|------|--------|
| `lib/features/auth/data/device_identity_service.dart` | Rewrite `resolve()` flow; refactor `_deriveHardwareId()` to return `String?` (null on hardware-unavailable); add Nil-UUID guard + reconciliation logic. |
| `functions/src/index.ts` | Tighten `ClaimRequest` and `MarkRequest` Zod schemas to reject Nil UUID. |
| `lib/features/onboarding/presentation/providers/app_bootstrap_provider.dart` | Add Nil/empty deviceId guard before `registry.claim(...)`. |
| `test/features/auth/device_identity_service_test.dart` (new) | Unit tests covering 7 scenarios. |
| `CLAUDE.md` | Update §5.4 (`saf.deviceId` row) and §5.5 (`claimDeviceIdentity` bullet). |
| Firebase Console (manual, post-deploy) | Delete `device_registrations/00000000-0000-0000-0000-000000000000`. |

## 4. Step-by-step plan

1. Create this ChangeRequest file. ✅
2. Rewrite `DeviceIdentityService`:
   - Extract a new `_deriveHardwareId()` that returns `String?` — null when the platform call fails or returns null/empty. No fallback inside this method.
   - Rewrite `resolve()`:
     - Derive `hardwareId` first (fast, single MethodChannel call).
     - Read `cachedId` from secure storage.
     - If hardware succeeded and matches cache → cache hit, return.
     - If hardware succeeded and mismatches cache (including Nil/empty cache) → log mismatch at info, overwrite cache, return hardware.
     - If hardware failed and cache is non-empty AND non-Nil → log warning, return cache.
     - If hardware failed and cache is empty/Nil → generate `_uuid.v4()`, persist, return.
     - Final guard: if the value is the Nil UUID for any reason, throw `StateError`.
   - Add the `_kNilUuid` constant.
   - Log raw ANDROID_ID at info level (length + content) for future diagnostics.
3. Add Nil-UUID rejection in `functions/src/index.ts` Zod schemas with `.refine()`.
4. Add Nil/empty deviceId guard in `_runLiveAuthInner` (throws `StateError` before the cloud function call).
5. Write unit tests in `test/features/auth/device_identity_service_test.dart`:
   - Inject a fake `LocalStorageService` (in-memory map) and a stubbed hardware-derivation function via constructor parameter.
   - 7 scenarios per plan §3.4.
6. Run `flutter analyze` — must be clean.
7. Run `flutter test` — all tests pass.
8. Run `cd functions && npm run build && cd ..` — TypeScript compiles.
9. Update `CLAUDE.md` §5.4 and §5.5.
10. Update this plan's `Status:` to `executed`, then `verified` after end-to-end smoke test on a physical Android device.

## 5. Risks & rollback

| Risk | Mitigation |
|------|-----------|
| `AndroidId().getId()` is slow on cold start | Already a single ContentResolver read — sub-ms in practice. We measured the bootstrap pipeline budget at 8 s; one extra ContentResolver call is negligible. |
| Hardware ID returns differently per app-signing-key on Android 8+ | Already true today; this fix doesn't change that behaviour. The cache-overwrite path means a signing-key change creates a new identity (correct — different signing key = different app). |
| Server-side Nil-UUID rejection breaks legitimate clients | The Nil UUID is by definition not a valid device identifier; refusing it is the correct behaviour. No legitimate flow ever produces it. |
| Self-heal overwrites a legitimate cached value when hardware is briefly flaky | Hardware-derivation success is binary (returns a non-empty rawId or doesn't). On flaky hardware → null → cache wins. Mismatch path only fires when hardware succeeds AND value differs. |
| The orphaned `00000000-…` Firestore entry continues to exist | Manually delete via Firebase Console after deploy. Listed as a verification step (§6.8). |

**Rollback:** revert `device_identity_service.dart`, `functions/src/index.ts`, and `app_bootstrap_provider.dart` to their pre-plan state. The `flutter_secure_storage` cache will still contain whatever value the new code most recently wrote, but the old (pre-plan) code reads cache-first and will accept it. No data migration required.

## 6. Verification

1. `flutter analyze` — clean.
2. `flutter test` — all tests pass; new device-identity tests pass.
3. `cd functions && npm run build && cd ..` — TypeScript compiles.
4. `firebase deploy --only functions` — deploys Nil-UUID rejection.
5. **End-to-end on Android physical device:**
   - Install fresh, complete Configuration. Confirm `device_registrations/<UUID>` created. Note the UUID — should be `v5(Namespace.url, "saf-uniforms:android:<ANDROID_ID>")`.
   - Uninstall.
   - Reinstall. Open the app. Should auto-route to `/dashboard` after the 1.5 s Welcome window — no Configuration wizard.
   - Verify in Firestore: only the original `device_registrations/<UUID>` exists, no new Nil-UUID entry, `lastSeenAt` bumped.
6. **Cache-poisoning regression test (manual, optional):** seed `flutter_secure_storage` with `"00000000-0000-0000-0000-000000000000"` via a debug shim, relaunch, confirm logs show "cache mismatch — overwriting with hardware-derived" and the cloud function call uses the correct UUID.
7. **Manual cleanup:** delete `device_registrations/00000000-0000-0000-0000-000000000000` in the Firebase Console.

## 7. CLAUDE.md updates required

- **§5.4** — `saf.deviceId` row: change description to "Hardware-derived UUID. Re-derived on every launch and reconciled against cache; cache is a fast-path hint, not authoritative. Self-heals when cache is corrupted (e.g. Nil UUID poisoning) by overwriting cache with hardware-derived value."
- **§5.5** — `claimDeviceIdentity` bullet: add "Rejects Nil UUID (`00000000-0000-0000-0000-000000000000`) server-side via Zod `.refine()` as defence in depth — no legitimate client should ever send it."
