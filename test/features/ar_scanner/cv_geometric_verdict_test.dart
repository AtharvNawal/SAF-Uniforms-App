import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_scanner/domain/entities/cv_inspection_result.dart';

void main() {
  group('GeometricVerdictStatus.fromWireName', () {
    test('maps every wire value to its enum', () {
      expect(GeometricVerdictStatus.fromWireName('pass'),
          GeometricVerdictStatus.pass_);
      expect(GeometricVerdictStatus.fromWireName('fail'),
          GeometricVerdictStatus.fail);
      expect(GeometricVerdictStatus.fromWireName('missing'),
          GeometricVerdictStatus.missing);
      expect(GeometricVerdictStatus.fromWireName('unverifiable'),
          GeometricVerdictStatus.unverifiable);
    });

    test('unknown value falls back to unverifiable rather than throwing', () {
      // Matches the pipeline's own honesty principle: an unrecognized
      // status should never silently read as a confident pass.
      expect(GeometricVerdictStatus.fromWireName('who_knows'),
          GeometricVerdictStatus.unverifiable);
    });

    test('round-trips through wireName', () {
      for (final status in GeometricVerdictStatus.values) {
        expect(GeometricVerdictStatus.fromWireName(status.wireName), status);
      }
    });
  });

  group('CvInspectionResult.geometricVerdicts', () {
    test('defaults to an empty list, not null, when omitted', () {
      const result = CvInspectionResult(
        overallScore: 80,
        status: 'Minor Issues',
        subscores: CvSubscores(),
        issues: [],
        uncertain: [],
        itemsEvaluated: 3,
        cameraDiagnostics: CvCameraDiagnostics(
          reprojectionErrorPx: 10,
          correspondenceCount: 8,
          cmPerPx: 0.2,
        ),
      );
      expect(result.geometricVerdicts, isEmpty);
    });

    test('carries per-accessory status + doctrine reference', () {
      const verdict = GeometricVerdict(
        accessory: 'army_beret',
        status: GeometricVerdictStatus.missing,
        reason: 'no headwear segment detected in the expected (in-frame) region',
        doctrineRef: 'Army No.3, Accessories p.4',
      );
      expect(verdict.status, GeometricVerdictStatus.missing);
      expect(verdict.doctrineRef, isNotEmpty);
      expect(verdict.reason, isNotEmpty);
    });
  });
}
