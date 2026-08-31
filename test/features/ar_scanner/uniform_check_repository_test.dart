import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saf_uniforms/features/ar_scanner/data/uniform_check_repository.dart';
import 'package:saf_uniforms/features/ar_scanner/domain/entities/uniform_check_result.dart';

void main() {
  final photo = Uint8List.fromList(List.filled(16, 7));

  group('UniformCheckRepository.check', () {
    test('parses a 200 /check_uniform body into the model', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/check_uniform'));
        return http.Response(
          jsonEncode({
            'success': true,
            'overall_status': 'FAIL',
            'overall_score': 66.7,
            'image_quality': {'usable': true, 'confidence': 0.88},
            'person': {'detected': true, 'confidence': 0.97},
            'accessories': [
              {
                'name': 'army_beret',
                'present': true,
                'position_correct': true,
                'confidence': 0.9,
                'status': 'CORRECT',
                'visibility': 'full',
                'bounding_box': {'x': 10.0, 'y': 20.0, 'width': 30.0, 'height': 40.0},
                'expected_position': {'x': 100.0, 'y': 50.0},
                'detected_position': {'x': 103.0, 'y': 54.0},
                'error': {'x': 3.0, 'y': 4.0},
                'doctrine_ref': 'Picture C-1',
                'message': 'Matches expected placement.',
              },
              {
                'name': 'name_tag',
                'present': null,
                'position_correct': null,
                'confidence': null,
                'status': 'UNCERTAIN',
                'visibility': 'none',
                'bounding_box': null,
                'expected_position': null,
                'detected_position': null,
                'error': null,
                'doctrine_ref': 'Picture C-6',
                'message': 'No segmentation class for name_tag.',
              },
            ],
            'summary': {
              'detected_accessories': 1,
              'correct': 1,
              'incorrect': 1,
              'missing': 0,
              'uncertain': 1,
              'required_accessories': 3,
            },
          }),
          200,
        );
      });

      final repo = UniformCheckRepository(client: client);
      final result = await repo.check(
        photoBytes: photo,
        uniformType: 'army_no3_male',
        rankTier: 'enlistee',
      );

      expect(result.overallStatus, 'FAIL');
      expect(result.overallScore, 66.7);
      expect(result.imageQualityUsable, isTrue);
      expect(result.personConfidence, 0.97);
      expect(result.accessories, hasLength(2));

      final beret = result.accessories.first;
      expect(beret.name, 'army_beret');
      expect(beret.status, UniformCheckStatus.correct);
      expect(beret.visibility, 'FULL');
      expect(beret.boundingBox!.width, 30.0);
      expect(beret.errorMagnitudePx, closeTo(5, 1e-9));

      expect(result.accessories[1].status, UniformCheckStatus.uncertain);
      expect(result.summary.requiredAccessories, 3);
      expect(result.issues.map((a) => a.name), isEmpty); // only CORRECT/UNCERTAIN
      expect(result.uncertain.map((a) => a.name), ['name_tag']);
    });

    test('maps a 422 typed error body to UniformCheckException', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'UNSUPPORTED_UNIFORM',
            'message': "'navy_no3_male' is not a supported uniform_type.",
          }),
          422,
        );
      });

      final repo = UniformCheckRepository(client: client);

      await expectLater(
        repo.check(
          photoBytes: photo,
          uniformType: 'navy_no3_male',
          rankTier: 'enlistee',
        ),
        throwsA(
          isA<UniformCheckException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.errorCode, 'errorCode', 'UNSUPPORTED_UNIFORM'),
        ),
      );
    });

    test('an unreachable service surfaces as statusCode == null', () async {
      final client = MockClient((request) async {
        throw const _FakeSocketException();
      });

      final repo = UniformCheckRepository(client: client);

      await expectLater(
        repo.check(
          photoBytes: photo,
          uniformType: 'army_no3_male',
          rankTier: 'enlistee',
        ),
        throwsA(
          isA<UniformCheckException>().having(
            (e) => e.statusCode,
            'statusCode',
            isNull,
          ),
        ),
      );
    });
  });
}

class _FakeSocketException implements Exception {
  const _FakeSocketException();
}
