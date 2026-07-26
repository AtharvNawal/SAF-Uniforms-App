import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/persistence/local_storage_service.dart';
import 'package:saf_uniforms/features/auth/data/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNilUuid = '00000000-0000-0000-0000-000000000000';
const _kHardwareUuid = 'c936e93b-1266-506e-aecb-864ca0898861';

/// In-memory fake. Overrides only the deviceId path; the other
/// LocalStorageService methods aren't touched by DeviceIdentityService.
///
/// The base `LocalStorageService` constructor eagerly calls
/// `SharedPreferences.getInstance()` for the `_preferences` field, so
/// the test binding must be initialised + mock values seeded before
/// constructing this fake.
class _FakeStorage extends LocalStorageService {
  _FakeStorage({String? initial}) : _value = initial;

  String? _value;
  int writeCount = 0;
  String? lastWritten;

  @override
  Future<String?> readDeviceId() async => _value;

  @override
  Future<void> writeDeviceId(String deviceId) async {
    _value = deviceId;
    lastWritten = deviceId;
    writeCount += 1;
  }
}

DeviceIdentityService _makeSvc({
  required LocalStorageService storage,
  required HardwareIdResolver resolver,
}) =>
    DeviceIdentityService(
      storage: storage,
      hardwareIdResolver: resolver,
      platformOverride: 'android',
    );

/// Test stub for the hardware resolver. Returns whatever it was
/// constructed with.
HardwareIdResolver _stubHardware(String? value) =>
    (uuid) async => value;

/// Test stub that throws — simulates a device where the platform
/// channel call fails.
HardwareIdResolver _throwingHardware() =>
    (uuid) async => throw Exception('platform channel offline');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeviceIdentityService.resolve', () {
    test('cache hit when cache matches hardware-derived value', () async {
      final storage = _FakeStorage(initial: _kHardwareUuid);
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(_kHardwareUuid),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, _kHardwareUuid);
      expect(storage.writeCount, 0,
          reason: 'cache hit must not write back');
    });

    test('cache miss writes hardware-derived value', () async {
      final storage = _FakeStorage();
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(_kHardwareUuid),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, _kHardwareUuid);
      expect(storage.lastWritten, _kHardwareUuid);
      expect(storage.writeCount, 1);
    });

    test('Nil UUID in cache is overwritten with hardware-derived value',
        () async {
      // This is the regression test for the user-reported bug.
      final storage = _FakeStorage(initial: _kNilUuid);
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(_kHardwareUuid),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, _kHardwareUuid,
          reason: 'must not return Nil UUID from cache');
      expect(storage.lastWritten, _kHardwareUuid,
          reason: 'cache must self-heal to hardware-derived value');
    });

    test('stale random UUID in cache is overwritten with hardware-derived',
        () async {
      const stale = 'deadbeef-dead-beef-dead-beefdeadbeef';
      final storage = _FakeStorage(initial: stale);
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(_kHardwareUuid),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, _kHardwareUuid);
      expect(storage.lastWritten, _kHardwareUuid);
    });

    test('hardware unavailable falls back to valid cached value', () async {
      const cached = 'a1b2c3d4-e5f6-7890-1234-567890abcdef';
      final storage = _FakeStorage(initial: cached);
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(null),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, cached);
      expect(storage.writeCount, 0,
          reason: 'should not rewrite when cache is the chosen value');
    });

    test('hardware unavailable + empty cache mints a fresh v4', () async {
      final storage = _FakeStorage();
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(null),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, isNot(_kNilUuid));
      expect(identity.deviceId, isNotEmpty);
      expect(storage.lastWritten, identity.deviceId);
    });

    test('hardware unavailable + Nil cache mints a fresh v4 (no Nil leak)',
        () async {
      final storage = _FakeStorage(initial: _kNilUuid);
      final svc = _makeSvc(
        storage: storage,
        resolver: _stubHardware(null),
      );

      final identity = await svc.resolve();

      expect(identity.deviceId, isNot(_kNilUuid));
      expect(identity.deviceId, isNotEmpty);
      expect(storage.lastWritten, identity.deviceId);
    });

    test('throwing hardware resolver propagates (caller is responsible '
        'for catching)', () async {
      // The default resolver catches plugin exceptions and returns
      // null; the service itself does not. A resolver that throws
      // is treated as a bug — the resolve() future fails so callers
      // see the underlying error rather than silently corrupting
      // state.
      final svc = _makeSvc(
        storage: _FakeStorage(initial: _kHardwareUuid),
        resolver: _throwingHardware(),
      );
      expect(svc.resolve(), throwsException);
    });
  });
}
