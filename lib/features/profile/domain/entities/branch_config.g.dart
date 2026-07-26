// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MedalAnchor _$MedalAnchorFromJson(Map<String, dynamic> json) => _MedalAnchor(
  anchor: json['anchor'] as String,
  offsetCm: AnchorOffset.fromJson(json['offsetCm'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MedalAnchorToJson(_MedalAnchor instance) =>
    <String, dynamic>{'anchor': instance.anchor, 'offsetCm': instance.offsetCm};

_AnchorOffset _$AnchorOffsetFromJson(Map<String, dynamic> json) =>
    _AnchorOffset(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$AnchorOffsetToJson(_AnchorOffset instance) =>
    <String, dynamic>{'x': instance.x, 'y': instance.y};

_SikhTurbanLogic _$SikhTurbanLogicFromJson(Map<String, dynamic> json) =>
    _SikhTurbanLogic(
      replacesHeadgear: json['replacesHeadgear'] as bool,
      color: json['color'] as String,
      alignmentOverride: json['alignmentOverride'] as String,
    );

Map<String, dynamic> _$SikhTurbanLogicToJson(_SikhTurbanLogic instance) =>
    <String, dynamic>{
      'replacesHeadgear': instance.replacesHeadgear,
      'color': instance.color,
      'alignmentOverride': instance.alignmentOverride,
    };

_BranchConfig _$BranchConfigFromJson(Map<String, dynamic> json) =>
    _BranchConfig(
      branchId: $enumDecode(_$BranchIdEnumMap, json['branchId']),
      displayName: json['displayName'] as String,
      collarOffsetCm: (json['collarOffsetCm'] as num).toDouble(),
      ladiesMedalAnchor: MedalAnchor.fromJson(
        json['ladiesMedalAnchor'] as Map<String, dynamic>,
      ),
      sikhTurbanLogic: SikhTurbanLogic.fromJson(
        json['sikhTurbanLogic'] as Map<String, dynamic>,
      ),
      dressCodes: (json['dressCodes'] as List<dynamic>)
          .map((e) => $enumDecode(_$DressCodeEnumMap, e))
          .toList(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$BranchConfigToJson(
  _BranchConfig instance,
) => <String, dynamic>{
  'branchId': _$BranchIdEnumMap[instance.branchId]!,
  'displayName': instance.displayName,
  'collarOffsetCm': instance.collarOffsetCm,
  'ladiesMedalAnchor': instance.ladiesMedalAnchor,
  'sikhTurbanLogic': instance.sikhTurbanLogic,
  'dressCodes': instance.dressCodes.map((e) => _$DressCodeEnumMap[e]!).toList(),
  'version': instance.version,
};

const _$BranchIdEnumMap = {
  BranchId.army: 'army',
  BranchId.navy: 'navy',
  BranchId.rsaf: 'rsaf',
  BranchId.dis: 'dis',
};

const _$DressCodeEnumMap = {
  DressCode.no1: 'no1',
  DressCode.no2: 'no2',
  DressCode.no3: 'no3',
  DressCode.no4: 'no4',
  DressCode.no5: 'no5',
};
