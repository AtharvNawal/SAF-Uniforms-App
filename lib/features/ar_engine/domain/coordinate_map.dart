import 'package:freezed_annotation/freezed_annotation.dart';

import '../../profile/domain/entities/branch_id.dart';
import '../../profile/domain/entities/dress_code.dart';
import '../../profile/domain/entities/gender.dart';

part 'coordinate_map.freezed.dart';

@freezed
abstract class Anchor3D with _$Anchor3D {
  const factory Anchor3D({
    required String id,
    required double x,
    required double y,
    required double z,
  }) = _Anchor3D;
}

@freezed
abstract class CoordinateMap with _$CoordinateMap {
  const factory CoordinateMap({
    required BranchId branch,
    required DressCode dressCode,
    required Gender gender,
    required bool isSikh,
    required double collarOffsetCm,
    required Map<String, Anchor3D> anchors,
  }) = _CoordinateMap;

  static const CoordinateMap empty = CoordinateMap(
    branch: BranchId.army,
    dressCode: DressCode.no3,
    gender: Gender.male,
    isSikh: false,
    collarOffsetCm: 0.0,
    anchors: <String, Anchor3D>{},
  );
}
