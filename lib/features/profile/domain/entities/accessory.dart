import 'package:freezed_annotation/freezed_annotation.dart';

part 'accessory.freezed.dart';

@freezed
abstract class Accessory with _$Accessory {
  const factory Accessory({
    required String id,
    required String displayName,
    @Default('') String imageUrl,
    @Default('') String placementDiagramUrl,
    @Default(<String, dynamic>{}) Map<String, dynamic> rules,
    @Default(<String, dynamic>{}) Map<String, dynamic> renderLogic,
    String? branchId,
    String? category,
    String? gender,
    @Default(1) int version,
  }) = _Accessory;
}
