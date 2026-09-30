import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saf_uniforms/features/ar_scanner/data/cv_service_health.dart';

void main() {
  group('normaliseCvServiceUrl', () {
    test('adds scheme and default port to a bare IP', () {
      expect(normaliseCvServiceUrl('192.168.1.20'), 'http://192.168.1.20:8001');
      expect(normaliseCvServiceUrl('  http://192.168.1.20/ '), 'http://192.168.1.20:8001');
    });

    test('keeps an explicit port, https and paths', () {
      expect(normaliseCvServiceUrl('192.168.1.20:9000'), 'http://192.168.1.20:9000');
      expect(normaliseCvServiceUrl('https://abc.trycloudflare.com'), 'https://abc.trycloudflare.com');
      expect(normaliseCvServiceUrl(kCvServiceUsbUrl), kCvServiceUsbUrl);
    });

    test('rejects junk', () {
      expect(normaliseCvServiceUrl(''), isNull);
      expect(normaliseCvServiceUrl('ftp://x'), isNull);
      expect(normaliseCvServiceUrl('http://'), isNull);
    });
  });

  group('CvServiceHealth.check', () {
    test('ok on 200 {"status":"ok"}', () async {
      final client = MockClient((r) async {
        expect(r.url.toString(), 'http://10.0.0.2:8001/health');
        return http.Response('{"status":"ok"}', 200);
      });
      final h = await CvServiceHealth.check('http://10.0.0.2:8001', client: client);
      expect(h.ok, isTrue);
      expect(h.detail, contains('HTTP 200'));
    });

    test('network error is reported, never thrown', () async {
      final client = MockClient((r) async => throw http.ClientException('Connection refused'));
      final h = await CvServiceHealth.check('http://10.0.0.2:8001', client: client);
      expect(h.ok, isFalse);
      expect(h.detail, contains('Connection refused'));
      expect(h.detail, contains('http://10.0.0.2:8001/health'));
    });

    test('timeout is reported', () async {
      final client = MockClient((r) => Completer<http.Response>().future);
      final h = await CvServiceHealth.check('http://10.0.0.2:8001', client: client, timeout: const Duration(milliseconds: 50));
      expect(h.ok, isFalse);
      expect(h.detail, contains('No answer'));
    });
  });
}
