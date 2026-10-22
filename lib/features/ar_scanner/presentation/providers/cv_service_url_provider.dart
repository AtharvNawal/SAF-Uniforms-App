import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/cv_service_inspection_repository.dart';
import '../../data/cv_service_health.dart';

part 'cv_service_url_provider.g.dart';

const String _tag = 'arScanner.cvUrl';

/// Old compiled-in LAN default (a dev Mac's Wi-Fi IP). A saved override
/// equal to it is dropped so the Cloud Run default takes over.
const String _staleLanDefault = 'http://192.168.1.144:8001';

/// The dev `cv-service` base URL the AR Scanner calls. Starts at the
/// compiled-in [kCvServiceBaseUrl] and switches to the user's saved
/// override (`saf.cvServiceUrl`) as soon as it's loaded — so the address
/// can be changed on the phone (Settings → Analysis server, or the
/// scanner's "Connection problem" screen) instead of rebuilding the APK.
/// See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`.
@Riverpod(keepAlive: true)
class CvServiceUrl extends _$CvServiceUrl {
  @override
  String build() {
    unawaited(_loadOverride());
    return kCvServiceBaseUrl;
  }

  /// Whether the current address is a user override (vs. the default).
  bool _isOverride = false;
  bool get isOverride => _isOverride;

  Future<void> _loadOverride() async {
    try {
      final saved = await ref.read(localStorageServiceProvider).readCvServiceUrl();
      var url = saved == null ? null : normaliseCvServiceUrl(saved);
      if (url == _staleLanDefault) {
        AppLog.i('dropping stale LAN override $url', tag: _tag);
        await ref.read(localStorageServiceProvider).writeCvServiceUrl(null);
        url = null;
      }
      if (url != null && url != state) {
        _isOverride = true;
        state = url;
        AppLog.i('loaded override $url', tag: _tag);
      }
    } catch (e, st) {
      AppLog.e('load override failed', tag: _tag, error: e, st: st);
    }
  }

  /// Saves a new address. Returns the normalised URL, or `null` when
  /// [input] isn't a usable http(s) address (nothing is changed then).
  Future<String?> set(String input) async {
    final url = normaliseCvServiceUrl(input);
    AppLog.d('set  input="$input"  normalised=$url', tag: _tag);
    if (url == null) return null;
    _isOverride = true;
    state = url;
    await ref.read(localStorageServiceProvider).writeCvServiceUrl(url);
    AppLog.i('set $url', tag: _tag);
    return url;
  }

  /// Back to the compiled-in default.
  Future<void> reset() async {
    _isOverride = false;
    state = kCvServiceBaseUrl;
    await ref.read(localStorageServiceProvider).writeCvServiceUrl(null);
    AppLog.i('reset to $kCvServiceBaseUrl', tag: _tag);
  }
}
