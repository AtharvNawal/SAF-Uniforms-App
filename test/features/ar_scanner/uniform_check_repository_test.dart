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
        photos: [photo],
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
          photos: [photo],
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

    test('reads the typed error code the service actually sends (`status`)', () async {
      // cv-service's error body is {"success": false, "status": CODE, ...};
      // the code used to be read from `error` only and was always lost.
      final client = MockClient((request) async => http.Response(
            jsonEncode({
              'success': false,
              'status': 'IMAGE_TOO_BLURRY',
              'message': 'Image is too blurry to analyze.',
            }),
            422,
          ));
      final repo = UniformCheckRepository(client: client);
      await expectLater(
        repo.check(photos: [photo], uniformType: 'army_no3_male', rankTier: 'enlistee'),
        throwsA(isA<UniformCheckException>()
            .having((e) => e.errorCode, 'errorCode', 'IMAGE_TOO_BLURRY')
            .having((e) => e.message, 'message', 'Image is too blurry to analyze.')),
      );
    });

    test('several frames go to /check_uniform_burst with the accuracy inputs', () async {
      late String body;
      late String path;
      final client = MockClient((request) async {
        path = request.url.path;
        body = latin1.decode(request.bodyBytes);
        // Real UTF-8 bytes, no charset — exactly what cv-service sends.
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'success': true,
            'overall_status': 'INCOMPLETE',
            'overall_score': 100.0,
            'image_quality': {'usable': true, 'confidence': 1.0},
            'person': {'detected': true, 'confidence': 0.9},
            'accessories': [
              {
                'name': 'army_cap_badge_sltc_me6_below',
                'status': 'SLIGHTLY_MISALIGNED',
                'visibility': 'VISIBLE',
                'required': true,
                'checkable': true,
                'instruction': 'Army Cap Badge: slightly off — move it about 1.0 cm up.',
                'detection_source': 'two_stage',
                'frame_agreement': '2/3',
              },
              {
                'name': 'medal_ribbons',
                'status': 'UNCERTAIN',
                'visibility': 'UNCERTAIN',
                'required': false,
                'checkable': false,
                'instruction': 'Medal Ribbons: can\'t be checked automatically yet.',
              },
              {
                'name': 'nylon_belt',
                'status': 'UNCERTAIN',
                'visibility': 'OUT_OF_FRAME',
                'required': true,
                'checkable': true,
              },
            ],
            'summary': {'slightly_misaligned': 1, 'uncertain': 2, 'required_accessories': 2},
            'coverage': {'verified_required': 1, 'checkable_required': 2, 'fraction': 0.5, 'not_checkable_required': 0},
            'camera': {'focal_source': 'exif_35mm'},
            'debug_image_base64': 'aGk=',
            'burst': {'frames': 3, 'usable_frames': 3, 'frame_errors': []},
          })),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = UniformCheckRepository(client: client);
      final result = await repo.check(
        photos: [photo, photo, photo],
        uniformType: 'army_no3_male',
        rankTier: 'enlistee',
        wearerName: 'Tan Ah Kow',
        heightCm: 172,
        gravityUpCamera: [0.01, -0.99, 0.12],
      );

      expect(path, endsWith('/check_uniform_burst'));
      expect('name="images"'.allMatches(body), hasLength(3));
      for (final field in ['wearer_name', 'height_cm', 'gravity_x', 'gravity_y', 'gravity_z', 'include_debug_image']) {
        expect(body, contains('name="$field"'), reason: field);
      }
      expect(body, contains('Tan Ah Kow'));

      expect(result.incomplete, isTrue);
      expect(result.summary.slightlyMisaligned, 1);
      expect(result.checkableRequired, 2);
      expect(result.verifiedRequired, 1);
      expect(result.debugImageBase64, 'aGk=');
      expect(result.burstFrames, 3);
      expect(result.focalSource, 'exif_35mm');
      final badge = result.accessories.first;
      expect(badge.instruction, contains('slightly off — move it about 1.0 cm up')); // UTF-8 intact
      expect(badge.detectionSource, 'two_stage');
      expect(badge.frameAgreement, '2/3');
      expect(result.couldNotCheck.map((a) => a.name), ['nylon_belt']);
      expect(result.checkByEye.map((a) => a.name), ['medal_ribbons']);
    });

    test('a single frame goes to /check_uniform without optional fields', () async {
      late String body;
      late String path;
      final client = MockClient((request) async {
        path = request.url.path;
        body = latin1.decode(request.bodyBytes);
        return http.Response(jsonEncode({'success': true, 'overall_status': 'PASS', 'overall_score': 100, 'accessories': []}), 200);
      });
      await UniformCheckRepository(client: client).check(photos: [photo], uniformType: 'army_no3_male', rankTier: 'enlistee', heightCm: 0);
      expect(path, endsWith('/check_uniform'));
      expect(body, contains('name="image"'));
      expect(body, isNot(contains('name="height_cm"')));
      expect(body, isNot(contains('name="wearer_name"')));
    });

    test('an unreachable service surfaces as statusCode == null', () async {
      final client = MockClient((request) async {
        throw const _FakeSocketException();
      });

      final repo = UniformCheckRepository(client: client);

      await expectLater(
        repo.check(
          photos: [photo],
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
