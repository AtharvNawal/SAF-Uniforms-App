import 'dart:io' show Platform;

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/device_identity.dart';

const String _tag = 'auth.deviceIdentity';

/// The Nil UUID. Disallowed as a deviceId because it is not a real
/// hardware identifier — it appears only as the result of corruption,
/// uninitialised state, or a buggy upstream caller.
const String _kNilUuid = '00000000-0000-0000-0000-000000000000';

/// Function that resolves a stable hardware-derived device id, or
/// `null` when hardware lookup is unavailable (simulator, plugin
/// failure). Pulled out as a typedef so unit tests can inject a stub.
typedef HardwareIdResolver = Future<String?> Function(Uuid uuid);

/// Resolves a stable per-device id, creating one if necessary.
///
/// **Strategy: hardware-first, cache-as-hint.** Every launch derives a
/// hardware-bound UUID from the platform (`Settings.Secure.ANDROID_ID`
/// hashed to UUID v5 on Android, `identifierForVendor` on iOS) and
/// reconciles it against the secure-storage cache:
///
/// - Hardware succeeds, cache matches → return cached value (cache hit).
/// - Hardware succeeds, cache differs (incl. empty / Nil UUID / stale
///   random v4 from older builds) → overwrite cache with the
///   hardware-derived value and return it. **This is the self-heal
///   path.**
/// - Hardware fails → fall back to the cached value if it's non-empty
///   and non-Nil; otherwise mint a fresh random v4 and persist it.
///
/// Why hardware-first instead of cache-first: the previous cache-first
/// flow returned whatever was in `flutter_secure_storage`, which on at
/// least one occasion ended up as the Nil UUID and got happily round-
/// tripped to the `claimDeviceIdentity` Cloud Function — orphaning the
/// real `device_registrations/<correctUuid>` entry and dropping the
/// user back into the Configuration wizard.
///
/// A final guard throws `StateError` if the value about to be returned
/// is the Nil UUID. This is unreachable in practice (every code path
/// already filters Nil), but ensures we will never silently emit one
/// again.
class DeviceIdentityService {
  DeviceIdentityService({
    required LocalStorageService storage,
    Uuid? uuid,
    HardwareIdResolver? hardwareIdResolver,
    String? platformOverride,
  })  : _storage = storage,
        _uuid = uuid ?? const Uuid(),
        _hardwareIdResolver = hardwareIdResolver ?? _defaultHardwareIdResolver,
        _platformOverride = platformOverride;

  final LocalStorageService _storage;
  final Uuid _uuid;
  final HardwareIdResolver _hardwareIdResolver;
  final String? _platformOverride;

  Future<DeviceIdentity> resolve() async {
    AppLog.d('resolve: START', tag: _tag);
    try {
      final hardwareId = await _hardwareIdResolver(_uuid);
      final cached = await _storage.readDeviceId();

      final chosen = await _reconcile(hardwareId: hardwareId, cached: cached);

      if (chosen.isEmpty || chosen == _kNilUuid) {
        // Hard guard — every branch above already filters Nil.
        throw StateError(
          'DeviceIdentityService produced an invalid deviceId="$chosen". '
          'This is unreachable; if you see this, a code path was added '
          'without filtering the Nil UUID.',
        );
      }

      AppLog.i('resolve: DONE  deviceId=$chosen', tag: _tag);
      return DeviceIdentity(deviceId: chosen, platform: _platform());
    } catch (e, st) {
      AppLog.e('resolve: FAILED', tag: _tag, error: e, st: st);
      rethrow;
    }
  }

  /// Picks the right deviceId given what hardware and the cache say.
  /// Writes back to cache when the chosen value differs from the
  /// cached one, so subsequent launches hit the fast path.
  Future<String> _reconcile({
    required String? hardwareId,
    required String? cached,
  }) async {
    final hardwareValid =
        hardwareId != null && hardwareId.isNotEmpty && hardwareId != _kNilUuid;
    final cacheValid =
        cached != null && cached.isNotEmpty && cached != _kNilUuid;

    if (hardwareValid) {
      if (cached == hardwareId) {
        AppLog.i('reconcile: cache hit  deviceId=$hardwareId', tag: _tag);
        return hardwareId;
      }
      if (!cacheValid) {
        AppLog.i(
          'reconcile: cache empty/invalid (cached="${cached ?? "<null>"}") '
          '— writing hardware-derived  deviceId=$hardwareId',
          tag: _tag,
        );
      } else {
        AppLog.i(
          'reconcile: cache MISMATCH — overwriting cache with hardware. '
          'cached=$cached  hardware=$hardwareId',
          tag: _tag,
        );
      }
      await _storage.writeDeviceId(hardwareId);
      return hardwareId;
    }

    // Hardware unavailable.
    if (cacheValid) {
      AppLog.w(
        'reconcile: hardware unavailable — falling back to cache  '
        'deviceId=$cached',
        tag: _tag,
      );
      return cached;
    }
    final fresh = _uuid.v4();
    AppLog.w(
      'reconcile: hardware unavailable AND cache empty/invalid — '
      'minting random v4 deviceId=$fresh',
      tag: _tag,
    );
    await _storage.writeDeviceId(fresh);
    return fresh;
  }

  String _platform() {
    if (_platformOverride != null) return _platformOverride;
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    throw UnsupportedError(
      'DeviceIdentityService supports Android and iOS only.',
    );
  }
}

/// Default hardware id resolver — calls the platform plugin and
/// derives a UUID. Returns `null` (not a fallback v4) when hardware is
/// unavailable so the caller can decide what to do; this keeps the
/// reconciliation logic in one place.
Future<String?> _defaultHardwareIdResolver(Uuid uuid) async {
  AppLog.d('hardwareId: querying platform', tag: _tag);
  try {
    if (Platform.isIOS) {
      final info = await DeviceInfoPlugin().iosInfo;
      final vendor = info.identifierForVendor;
      AppLog.i(
        'hardwareId: iOS identifierForVendor='
        '"${vendor ?? "<null>"}" (length=${vendor?.length ?? 0})',
        tag: _tag,
      );
      if (vendor != null && vendor.isNotEmpty) {
        return vendor;
      }
    } else if (Platform.isAndroid) {
      const androidIdPlugin = AndroidId();
      final rawId = await androidIdPlugin.getId();
      AppLog.i(
        'hardwareId: Android Settings.Secure.ANDROID_ID='
        '"${rawId ?? "<null>"}" (length=${rawId?.length ?? 0})',
        tag: _tag,
      );
      if (rawId != null && rawId.isNotEmpty) {
        // ANDROID_ID is a 16-char hex string (e.g. "19fd6c81908c7473").
        // UUID v5 converts it to a deterministic UUID so the Cloud
        // Function's z.string().uuid() validator accepts it.
        final id = uuid.v5(
          Namespace.url.value,
          'saf-uniforms:android:$rawId',
        );
        AppLog.i('hardwareId: Android rawId → uuid=$id', tag: _tag);
        return id;
      }
    }
  } catch (e, st) {
    AppLog.e(
      'hardwareId: platform lookup failed',
      tag: _tag,
      error: e,
      st: st,
    );
  }
  AppLog.w('hardwareId: unavailable — caller should fall back', tag: _tag);
  return null;
}
