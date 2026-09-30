import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/utils/app_logger.dart';

const String _tag = 'arScanner.cvHealth';

/// USB preset: with the phone plugged in and `adb reverse tcp:8001 tcp:8001`
/// running on the laptop (`deploy/connect-phone-usb.sh`), the phone's own
/// `127.0.0.1:8001` is forwarded over the cable to the laptop's server — no
/// Wi-Fi, firewall or IP address involved.
const String kCvServiceUsbUrl = 'http://127.0.0.1:8001';

/// Normalises what a user typed into a base URL: trims, adds `http://`
/// when no scheme is given, adds `:8001` when no port is given on a bare
/// `http` IP/host, and drops a trailing slash. Returns `null` for input
/// that still isn't a valid http(s) URL.
String? normaliseCvServiceUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'http://$text';
  while (text.endsWith('/')) {
    text = text.substring(0, text.length - 1);
  }
  final uri = Uri.tryParse(text);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
    return null;
  }
  if (!uri.hasPort && uri.scheme == 'http' && uri.path.isEmpty) {
    return uri.replace(port: 8001).toString();
  }
  return text;
}

/// Result of a `GET /health` probe — [ok] plus a human-readable [detail]
/// (the service's answer, or the actual network error).
class CvServiceHealth {
  const CvServiceHealth({required this.ok, required this.detail});

  final bool ok;
  final String detail;

  /// Calls `<baseUrl>/health` with a short timeout. Never throws.
  static Future<CvServiceHealth> check(
    String baseUrl, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final owned = client == null;
    final c = client ?? http.Client();
    final uri = Uri.parse('$baseUrl/health');
    AppLog.i('check: GET $uri', tag: _tag);
    try {
      final response = await c.get(uri).timeout(timeout);
      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final ok = response.statusCode == 200 && body.contains('"ok"');
      AppLog.i('check: HTTP ${response.statusCode} ok=$ok', tag: _tag);
      return CvServiceHealth(ok: ok, detail: 'HTTP ${response.statusCode} · ${body.trim()}');
    } on TimeoutException catch (e, st) {
      AppLog.e('check: timeout', tag: _tag, error: e, st: st);
      return CvServiceHealth(ok: false, detail: 'No answer from $uri within ${timeout.inSeconds}s');
    } catch (e, st) {
      AppLog.e('check: failed', tag: _tag, error: e, st: st);
      return CvServiceHealth(ok: false, detail: '$uri\n$e');
    } finally {
      if (owned) c.close();
    }
  }
}
