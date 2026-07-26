import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/features/checklist/domain/entities/dress_requirement.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';

void main() {
  group('DressRequirement.mergedFor', () {
    final base = DressRequirement(
      id: 'no_3_dress_requirements',
      dressName: 'No. 3 Dress',
      mandatoryRules: const [
        {
          'category': 'Headdress',
          'options': {
            'standard_men': ['beret_standard'],
          },
        },
      ],
      optionalLogic: const {
        'awards': ['medal_ribbons'],
      },
      branchOverrides: const {
        'navy': {
          'mandatory_rules': [
            {
              'category': 'Headdress',
              'options': {
                'standard_men': ['ladies_service_hat_b'],
              },
            },
          ],
        },
        'rsaf': {
          'optional_logic': {
            'awards': ['foreign_badges'],
          },
        },
      },
    );

    test('returns base unchanged when no override exists for branch', () {
      final merged = base.mergedFor(BranchId.army);
      expect(merged, equals(base));
    });

    test('replaces mandatory_rules with branch override (navy)', () {
      final merged = base.mergedFor(BranchId.navy);
      expect(merged.mandatoryRules.length, 1);
      expect(
        (merged.mandatoryRules.first['options']
            as Map<String, dynamic>)['standard_men'],
        equals(['ladies_service_hat_b']),
      );
      expect(merged.optionalLogic, equals(base.optionalLogic),
          reason: 'untouched keys fall back to base');
    });

    test('replaces optional_logic with branch override (rsaf)', () {
      final merged = base.mergedFor(BranchId.rsaf);
      expect(merged.optionalLogic['awards'], equals(['foreign_badges']));
      expect(merged.mandatoryRules, equals(base.mandatoryRules),
          reason: 'untouched keys fall back to base');
    });

    test('returns base unchanged when override is empty map', () {
      final withEmptyOverride = base.copyWith(
        branchOverrides: const {'dis': <String, dynamic>{}},
      );
      final merged = withEmptyOverride.mergedFor(BranchId.dis);
      expect(merged.mandatoryRules, equals(base.mandatoryRules));
      expect(merged.optionalLogic, equals(base.optionalLogic));
    });
  });
}
