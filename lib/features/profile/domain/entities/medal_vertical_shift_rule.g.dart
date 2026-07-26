// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medal_vertical_shift_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MedalVerticalShiftRule _$MedalVerticalShiftRuleFromJson(
  Map<String, dynamic> json,
) => _MedalVerticalShiftRule(
  minRows: (json['minRows'] as num?)?.toInt() ?? 3,
  verticalShiftCmPerExtraRow:
      (json['verticalShiftCmPerExtraRow'] as num?)?.toDouble() ?? 1.0,
  version: (json['version'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$MedalVerticalShiftRuleToJson(
  _MedalVerticalShiftRule instance,
) => <String, dynamic>{
  'minRows': instance.minRows,
  'verticalShiftCmPerExtraRow': instance.verticalShiftCmPerExtraRow,
  'version': instance.version,
};
