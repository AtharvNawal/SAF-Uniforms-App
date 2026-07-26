import '../../../../core/error/result.dart';
import '../entities/gallery_photo.dart';

abstract class GalleryRepository {
  /// Live stream of all gallery photos for the current user,
  /// ordered by [GalleryPhoto.uploadedAt] descending.
  Stream<List<GalleryPhoto>> watchPhotos();

  /// Uploads [imageBytes] (JPEG) to Firebase Storage and writes Firestore
  /// metadata. Progress (0.0–1.0) emitted via [onProgress].
  Future<Result<GalleryPhoto>> uploadPhoto({
    required List<int> imageBytes,
    String dressCode = '',
    void Function(double progress)? onProgress,
  });

  /// Deletes the photo from both Firebase Storage and Firestore.
  Future<Result<void>> deletePhoto(String photoId);

  /// Updates [dressCode] on an existing photo document.
  Future<Result<void>> updateMetadata({
    required String photoId,
    String? dressCode,
  });
}
