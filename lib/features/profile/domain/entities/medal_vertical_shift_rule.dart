import 'package:freezed_annotation/freezed_annotation.dart';

part 'medal_vertical_shift_rule.freezed.dart';
part 'medal_vertical_shift_rule.g.dart';

/// Cross-branch rule sourced from Firestore `global_logic_rules/medal_vertical_shift`.
///
/// When a profile's medal row count meets or exceeds [minRows], every chest
/// badge anchor is shifted downward by
/// `(rows - minRows + 1) * verticalShiftCmPerExtraRow`, expressed in cm.
@freezed
abstract class MedalVerticalShiftRule with _$MedalVerticalShiftRule {
  const factory MedalVerticalShiftRule({
    @Default(3) int minRows,
    @Default(1.0) double verticalShiftCmPerExtraRow,
    @Default(1) int version,
  }) = _MedalVerticalShiftRule;

  const MedalVerticalShiftRule._();

  factory MedalVerticalShiftRule.fromJson(Map<String, dynamic> json) =>
      _$MedalVerticalShiftRuleFromJson(json);

  /// Builds the rule from a `global_logic_rules` Firestore document where
  /// `params: { minRows, verticalShiftCmPerExtraRow }`. Falls back to the
  /// freezed defaults when keys are missing.
  factory MedalVerticalShiftRule.fromFirestore(
    Map<String, dynamic> doc,
  ) {
    final params = (doc['params'] as Map<String, dynamic>?) ?? const {};
    return MedalVerticalShiftRule(
      minRows: (params['minRows'] as num?)?.toInt() ?? 3,
      verticalShiftCmPerExtraRow:
          (params['verticalShiftCmPerExtraRow'] as num?)?.toDouble() ?? 1.0,
      version: (doc['version'] as num?)?.toInt() ?? 1,
    );
  }

  /// The downward Y shift in cm applied to chest-badge anchors for the
  /// given medal row count. Returns 0 when the rule does not yet apply.
  double shiftCmFor(int medalRowCount) {
    if (medalRowCount < minRows) return 0.0;
    return (medalRowCount - minRows + 1) * verticalShiftCmPerExtraRow;
  }
}
