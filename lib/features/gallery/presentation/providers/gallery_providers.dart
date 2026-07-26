import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/gallery_repository_impl.dart';
import '../../domain/entities/gallery_photo.dart';
import '../../domain/repositories/gallery_repository.dart';

part 'gallery_providers.g.dart';

@Riverpod(keepAlive: true)
GalleryRepository galleryRepository(Ref ref) {
  return GalleryRepositoryImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    uid: ref.watch(authSessionProvider)?.uid ?? '',
  );
}

@Riverpod(keepAlive: true)
Stream<List<GalleryPhoto>> galleryPhotos(Ref ref) {
  return ref.watch(galleryRepositoryProvider).watchPhotos();
}

/// Holds upload progress (0.0–1.0) while an upload is in flight; null otherwise.
///
/// Photos are uploaded untagged. Dress-code tagging is a separate
/// post-upload action handled via [GalleryRepository.updateMetadata].
@Riverpod(keepAlive: true)
class GalleryUploadNotifier extends _$GalleryUploadNotifier {
  @override
  double? build() => null;

  Future<Result<GalleryPhoto>> upload({
    required List<int> imageBytes,
  }) async {
    state = 0.0;
    final result = await ref.read(galleryRepositoryProvider).uploadPhoto(
          imageBytes: imageBytes,
          onProgress: (p) => state = p,
        );
    state = null;
    return result;
  }
}

/// Holds the id of the photo currently being deleted; null when idle.
@Riverpod(keepAlive: true)
class GalleryDeleteNotifier extends _$GalleryDeleteNotifier {
  @override
  String? build() => null;

  Future<Result<void>> delete(String photoId) async {
    state = photoId;
    final result =
        await ref.read(galleryRepositoryProvider).deletePhoto(photoId);
    state = null;
    return result;
  }
}
