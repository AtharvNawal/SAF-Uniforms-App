import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_scanner/domain/entities/uniform_check_result.dart';

void main() {
  group('UniformCheckStatus.fromWireName', () {
    test('maps every wire value to its enum', () {
      for (final s in UniformCheckStatus.values) {
        expect(UniformCheckStatus.fromWireName(s.wireName), s);
      }
    });

    test('unknown value falls back to uncertain', () {
      expect(
        UniformCheckStatus.fromWireName('SOMETHING_ELSE'),
        UniformCheckStatus.uncertain,
      );
    });
  });

  group('UniformCheckAccessory.errorMagnitudePx', () {
    test('null when no error vector reported', () {
      const a = UniformCheckAccessory(
        name: 'army_beret',
        status: UniformCheckStatus.correct,
        visibility: 'FULL',
      );
      expect(a.errorMagnitudePx, isNull);
    });

    test('is the euclidean magnitude of the (dx, dy) vector', () {
      const a = UniformCheckAccessory(
        name: 'army_beret',
        status: UniformCheckStatus.incorrect,
        visibility: 'FULL',
        error: UniformCheckPoint(x: 3, y: 4),
      );
      expect(a.errorMagnitudePx, closeTo(5, 1e-9));
    });
  });

  group('UniformCheckResult derived getters', () {
    UniformCheckResult make(List<UniformCheckStatus> statuses) {
      return UniformCheckResult(
        success: true,
        overallStatus: 'FAIL',
        overallScore: 50,
        imageQualityUsable: true,
        imageQualityConfidence: 0.9,
        personDetected: true,
        personConfidence: 0.95,
        accessories: [
          for (var i = 0; i < statuses.length; i++)
            UniformCheckAccessory(
              name: 'item_$i',
              status: statuses[i],
              visibility: 'FULL',
            ),
        ],
        summary: const UniformCheckSummary(),
      );
    }

    test('issues = incorrect + missing + slightlyMisaligned', () {
      final r = make([
        UniformCheckStatus.correct,
        UniformCheckStatus.incorrect,
        UniformCheckStatus.missing,
        UniformCheckStatus.slightlyMisaligned,
        UniformCheckStatus.uncertain,
      ]);
      expect(r.issues.map((a) => a.name), ['item_1', 'item_2', 'item_3']);
      expect(r.passes.map((a) => a.name), ['item_0']);
      expect(r.uncertain.map((a) => a.name), ['item_4']);
    });

    test('verdict groups account for every accessory exactly once', () {
      final base = make([
        UniformCheckStatus.correct,
        UniformCheckStatus.incorrect,
        UniformCheckStatus.missing,
        UniformCheckStatus.slightlyMisaligned,
        UniformCheckStatus.uncertain,
      ]);
      final r = base.copyWith(
        accessories: [
          ...base.accessories.take(4),
          base.accessories.last.copyWith(checkable: false),
        ],
      );
      expect(
        {...r.issues, ...r.passes, ...r.couldNotCheck, ...r.checkByEye}.length,
        r.accessories.length,
      );
    });

    test('passed reflects overallStatus, case-insensitively', () {
      expect(
        make([
          UniformCheckStatus.correct,
        ]).copyWith(overallStatus: 'pass').passed,
        isTrue,
      );
      expect(
        make([
          UniformCheckStatus.correct,
        ]).copyWith(overallStatus: 'FAIL').passed,
        isFalse,
      );
    });

    test('incomplete is distinct from passed and failed', () {
      final r = make([
        UniformCheckStatus.uncertain,
      ]).copyWith(overallStatus: 'INCOMPLETE');
      expect(r.incomplete, isTrue);
      expect(r.passed, isFalse);
      expect(
        make([
          UniformCheckStatus.correct,
        ]).copyWith(overallStatus: 'FAIL').incomplete,
        isFalse,
      );
    });
  });
}
