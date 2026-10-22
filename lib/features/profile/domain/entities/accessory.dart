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

    /// Dress-specific pictures, keyed `no4` or `no4_<branch>` →
    /// `{image_url, placement_diagram}` (e.g. the No.4 name tape for an
    /// accessory shared with No.3). Resolved by `accessoryImagesFor`.
    @Default(<String, Map<String, String>>{})
    Map<String, Map<String, String>> dressImages,
    String? branchId,
    String? category,
    String? gender,
    @Default(1) int version,
  }) = _Accessory;
}
