import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saf_uniforms/features/ar_scanner/data/cv_service_inspection_repository.dart'
    show IdTokenProvider;
import 'package:saf_uniforms/features/ar_scanner/data/uniform_check_repository.dart';

/// The deployed cv-service (Cloud Run, CV_SERVICE_REQUIRE_AUTH=1) needs the
/// signed-in user's Firebase ID token — see
/// ChangeRequest/2026-10-02_cv-service-cloud-run-deploy.md.
void main() {
  final photo = Uint8List.fromList(List.filled(16, 7));

  group('UniformCheckRepository — Firebase ID token (Cloud Run auth)', () {
    final okBody = jsonEncode({
      'success': true,
      'overall_status': 'PASS',
      'overall_score': 100.0,
      'accessories': <Object>[],
      'summary': <String, Object>{},
    });

    Future<String?> capture(IdTokenProvider? idToken) async {
      String? header;
      final client = MockClient((request) async {
        header = request.headers['Authorization'];
        return http.Response(okBody, 200);
      });
      await UniformCheckRepository(client: client, idToken: idToken)
          .check(photos: [photo], uniformType: 'army_no3_male', rankTier: 'enlistee');
      return header;
    }

    test('sends Authorization: Bearer <token> when signed in', () async {
      expect(await capture(() async => 'tok-123'), 'Bearer tok-123');
    });

    test('sends no header when there is no user / no provider', () async {
      expect(await capture(() async => null), isNull);
      expect(await capture(null), isNull);
    });

    test('a token failure does not block the request', () async {
      expect(await capture(() async => throw StateError('offline')), isNull);
    });

    test('a 401 from the deployed service surfaces as UNAUTHENTICATED', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'success': false, 'status': 'UNAUTHENTICATED', 'message': 'Sign in'}),
            401,
          ));
      await expectLater(
        UniformCheckRepository(client: client)
            .check(photos: [photo], uniformType: 'army_no3_male', rankTier: 'enlistee'),
        throwsA(isA<UniformCheckException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.errorCode, 'errorCode', 'UNAUTHENTICATED')),
      );
    });
  });
}
