import 'package:freezed_annotation/freezed_annotation.dart';

part 'gallery_photo.freezed.dart';

@freezed
abstract class GalleryPhoto with _$GalleryPhoto {
  const factory GalleryPhoto({
    required String id,
    required String url,
    @Default('') String thumbnailUrl,
    required DateTime uploadedAt,
    @Default('') String dressCode,
  }) = _GalleryPhoto;
}
