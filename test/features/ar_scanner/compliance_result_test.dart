import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/ar_scanner/domain/entities/compliance_result.dart';

void main() {
  group('ComplianceStatus.fromWireName', () {
    test('maps every wire value to its enum', () {
      expect(ComplianceStatus.fromWireName('correct'), ComplianceStatus.correct);
      expect(ComplianceStatus.fromWireName('missing'), ComplianceStatus.missing);
      expect(
          ComplianceStatus.fromWireName('incorrect'), ComplianceStatus.incorrect);
      expect(
          ComplianceStatus.fromWireName('uncertain'), ComplianceStatus.uncertain);
    });

    test('unknown value falls back to uncertain rather than throwing', () {
      expect(ComplianceStatus.fromWireName('who_knows'),
          ComplianceStatus.uncertain);
    });
  });

  group('ComplianceResult derived getters', () {
    ComplianceItem item(String id, ComplianceStatus status) => ComplianceItem(
          accessoryId: id,
          displayName: id,
          status: status,
          note: 'note for $id',
        );

    test('splits items into correct / issues / uncertain buckets', () {
      final result = ComplianceResult(
        overallScore: 60,
        summary: 'summary',
        items: [
          item('a', ComplianceStatus.correct),
          item('b', ComplianceStatus.missing),
          item('c', ComplianceStatus.incorrect),
          item('d', ComplianceStatus.uncertain),
          item('e', ComplianceStatus.correct),
        ],
      );

      expect(result.correctItems.map((i) => i.accessoryId), ['a', 'e']);
      expect(result.issues.map((i) => i.accessoryId), ['b', 'c']);
      expect(result.uncertainItems.map((i) => i.accessoryId), ['d']);
    });

    test('empty items produces empty buckets, not errors', () {
      const result = ComplianceResult(
        overallScore: 0,
        summary: 'no data',
        items: [],
      );
      expect(result.correctItems, isEmpty);
      expect(result.issues, isEmpty);
      expect(result.uncertainItems, isEmpty);
    });
  });
}
