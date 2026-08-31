import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/l10n/generated/app_localizations_en.dart';
import 'package:saf_uniforms/features/ar_scanner/data/cv_service_inspection_repository.dart';
import 'package:saf_uniforms/features/ar_scanner/data/uniform_check_repository.dart';
import 'package:saf_uniforms/features/ar_scanner/presentation/utils/capture_error_message.dart';

void main() {
  final l = AppLocalizationsEn();

  group('describeCaptureError — FirebaseFunctionsException', () {
    test('unauthenticated maps to the sign-in message, not a connection one',
        () {
      final (title, subtitle) = describeCaptureError(
        FirebaseFunctionsException(code: 'unauthenticated', message: 'x'),
        l,
      );
      expect(title, l.arErrorSignInTitle);
      expect(subtitle, l.arErrorSignInSub);
      expect(subtitle, isNot(contains('connection')));
    });

    test('not-found maps to the profile-incomplete message', () {
      final (title, subtitle) = describeCaptureError(
        FirebaseFunctionsException(code: 'not-found', message: 'x'),
        l,
      );
      expect(title, l.arErrorProfileTitle);
      expect(subtitle, l.arErrorProfileSub);
    });

    test('failed-precondition maps to the same profile-incomplete message',
        () {
      final (title, _) = describeCaptureError(
        FirebaseFunctionsException(code: 'failed-precondition', message: 'x'),
        l,
      );
      expect(title, l.arErrorProfileTitle);
    });

    test('invalid-argument maps to the retake-photo message', () {
      final (title, subtitle) = describeCaptureError(
        FirebaseFunctionsException(code: 'invalid-argument', message: 'x'),
        l,
      );
      expect(title, l.arErrorPhotoTitle);
      expect(subtitle, l.arErrorPhotoSub);
    });

    test('unavailable and deadline-exceeded are the only codes that keep '
        'the connection-flavored message', () {
      for (final code in ['unavailable', 'deadline-exceeded']) {
        final (title, subtitle) = describeCaptureError(
          FirebaseFunctionsException(code: code, message: 'x'),
          l,
        );
        expect(title, l.arErrorConnectionTitle, reason: code);
        expect(subtitle, l.arErrorConnectionSub, reason: code);
      }
    });

    test('an unmapped code falls back to the generic message', () {
      final (title, subtitle) = describeCaptureError(
        FirebaseFunctionsException(code: 'internal', message: 'x'),
        l,
      );
      expect(title, l.arCheckFailed);
      expect(subtitle, l.arCheckFailedSub);
    });
  });

  group('describeCaptureError — CvServiceInspectionException', () {
    test('no status code (never got a response) maps to the cv-service '
        'unreachable message', () {
      final (title, subtitle) = describeCaptureError(
        CvServiceInspectionException('connection refused'),
        l,
      );
      expect(title, l.arErrorConnectionTitle);
      expect(subtitle, l.arErrorCvUnreachableSub);
    });

    test('a real HTTP error response surfaces its own reason, not a '
        'connection message', () {
      final (title, subtitle) = describeCaptureError(
        CvServiceInspectionException('camera_pose_unreliable', statusCode: 422),
        l,
      );
      expect(title, l.arCheckFailed);
      expect(subtitle, 'camera_pose_unreliable');
    });
  });

  group('describeCaptureError — UniformCheckException', () {
    test('no status code maps to the cv-service unreachable message', () {
      final (title, subtitle) = describeCaptureError(
        UniformCheckException('Connection refused'),
        l,
      );
      expect(title, l.arErrorConnectionTitle);
      expect(subtitle, l.arErrorCvUnreachableSub);
    });

    test('a typed pose error surfaces its own reason under a photo title', () {
      final (title, subtitle) = describeCaptureError(
        UniformCheckException(
          'Could not reliably determine the camera angle.',
          statusCode: 422,
          errorCode: 'POSE_UNRELIABLE',
        ),
        l,
      );
      expect(title, l.arErrorPhotoTitle);
      expect(subtitle, 'Could not reliably determine the camera angle.');
    });

    test('an unsupported-uniform error keeps the generic title', () {
      final (title, subtitle) = describeCaptureError(
        UniformCheckException(
          "'navy_no3_male' is not supported.",
          statusCode: 422,
          errorCode: 'UNSUPPORTED_UNIFORM',
        ),
        l,
      );
      expect(title, l.arCheckFailed);
      expect(subtitle, "'navy_no3_male' is not supported.");
    });
  });

  group('describeCaptureError — generic fallback', () {
    test('an unrecognized error type falls back to the generic message', () {
      final (title, subtitle) = describeCaptureError(Exception('boom'), l);
      expect(title, l.arCheckFailed);
      expect(subtitle, l.arCheckFailedSub);
    });

    test('null error falls back to the generic message', () {
      final (title, subtitle) = describeCaptureError(null, l);
      expect(title, l.arCheckFailed);
      expect(subtitle, l.arCheckFailedSub);
    });
  });
}
