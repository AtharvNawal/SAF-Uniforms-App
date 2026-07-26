import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _logName = 'persistence.local';

/// Hardware-/keychain-backed local cache for the small handful of values
/// the app needs to render the Welcome / Dashboard branch synchronously
/// before Firebase auth has confirmed the session.
///
/// Storage split:
/// - Secure (`flutter_secure_storage`): `deviceId`, `cachedUid`. iOS
///   keychain entries persist across normal app uninstalls; Android
///   encrypted SharedPreferences persist if Auto Backup runs.
/// - Plain (`shared_preferences`): `profileComplete` flag,
///   `lastBranchId` for theme bootstrap.
///
/// Reads return `null` when nothing is cached. All methods catch + log
/// per CLAUDE.md §1.4 and surface the underlying value (or null) rather
/// than rethrow — losing the cache is recoverable, the auth flow re-fills
/// it on next sign-in.
class LocalStorageService {
  LocalStorageService({
    FlutterSecureStorage? secure,
    Future<SharedPreferences>? preferences,
  })  : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _preferences = preferences ?? SharedPreferences.getInstance();

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> _preferences;

  static const String _kDeviceId = 'saf.deviceId';
  static const String _kCachedUid = 'saf.cachedUid';
  static const String _kProfileComplete = 'saf.profileComplete';
  static const String _kLastBranchId = 'saf.lastBranchId';
  static const String _kThemeAccent = 'saf.themeAccent';

  Future<String?> readDeviceId() async {
    try {
      return await _secure.read(key: _kDeviceId);
    } catch (e, st) {
      developer.log('readDeviceId failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
      return null;
    }
  }

  Future<void> writeDeviceId(String deviceId) async {
    try {
      await _secure.write(key: _kDeviceId, value: deviceId);
      developer.log('deviceId persisted', name: _logName, level: 800);
    } catch (e, st) {
      developer.log('writeDeviceId failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  Future<String?> readCachedUid() async {
    try {
      return await _secure.read(key: _kCachedUid);
    } catch (e, st) {
      developer.log('readCachedUid failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
      return null;
    }
  }

  Future<void> writeCachedUid(String? uid) async {
    try {
      if (uid == null) {
        await _secure.delete(key: _kCachedUid);
      } else {
        await _secure.write(key: _kCachedUid, value: uid);
      }
    } catch (e, st) {
      developer.log('writeCachedUid failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  Future<bool> readProfileComplete() async {
    try {
      final prefs = await _preferences;
      return prefs.getBool(_kProfileComplete) ?? false;
    } catch (e, st) {
      developer.log('readProfileComplete failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
      return false;
    }
  }

  Future<void> writeProfileComplete(bool value) async {
    try {
      final prefs = await _preferences;
      await prefs.setBool(_kProfileComplete, value);
      developer.log('profileComplete=$value', name: _logName, level: 800);
    } catch (e, st) {
      developer.log('writeProfileComplete failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  Future<String?> readLastBranchId() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_kLastBranchId);
    } catch (e, st) {
      developer.log('readLastBranchId failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
      return null;
    }
  }

  Future<void> writeLastBranchId(String wireName) async {
    try {
      final prefs = await _preferences;
      await prefs.setString(_kLastBranchId, wireName);
    } catch (e, st) {
      developer.log('writeLastBranchId failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  Future<String?> readThemeAccent() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_kThemeAccent);
    } catch (e, st) {
      developer.log('readThemeAccent failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
      return null;
    }
  }

  Future<void> writeThemeAccent(String? wireName) async {
    try {
      final prefs = await _preferences;
      if (wireName == null) {
        await prefs.remove(_kThemeAccent);
      } else {
        await prefs.setString(_kThemeAccent, wireName);
      }
    } catch (e, st) {
      developer.log('writeThemeAccent failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }

  Future<void> clear() async {
    try {
      await _secure.delete(key: _kDeviceId);
      await _secure.delete(key: _kCachedUid);
      final prefs = await _preferences;
      await prefs.remove(_kProfileComplete);
      await prefs.remove(_kLastBranchId);
      await prefs.remove(_kThemeAccent);
    } catch (e, st) {
      developer.log('clear failed', name: _logName,
          error: e, stackTrace: st, level: 1000);
    }
  }
}
