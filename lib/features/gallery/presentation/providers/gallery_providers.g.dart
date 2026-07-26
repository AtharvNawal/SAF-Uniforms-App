// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(galleryRepository)
final galleryRepositoryProvider = GalleryRepositoryProvider._();

final class GalleryRepositoryProvider
    extends
        $FunctionalProvider<
          GalleryRepository,
          GalleryRepository,
          GalleryRepository
        >
    with $Provider<GalleryRepository> {
  GalleryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryRepositoryHash();

  @$internal
  @override
  $ProviderElement<GalleryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GalleryRepository create(Ref ref) {
    return galleryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GalleryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GalleryRepository>(value),
    );
  }
}

String _$galleryRepositoryHash() => r'334f45c4f661069a143b362493da24249c21b328';

@ProviderFor(galleryPhotos)
final galleryPhotosProvider = GalleryPhotosProvider._();

final class GalleryPhotosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GalleryPhoto>>,
          List<GalleryPhoto>,
          Stream<List<GalleryPhoto>>
        >
    with
        $FutureModifier<List<GalleryPhoto>>,
        $StreamProvider<List<GalleryPhoto>> {
  GalleryPhotosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryPhotosProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryPhotosHash();

  @$internal
  @override
  $StreamProviderElement<List<GalleryPhoto>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GalleryPhoto>> create(Ref ref) {
    return galleryPhotos(ref);
  }
}

String _$galleryPhotosHash() => r'e963f8deff3d3acfd5bc47ce778a64e997937899';

/// Holds upload progress (0.0–1.0) while an upload is in flight; null otherwise.
///
/// Photos are uploaded untagged. Dress-code tagging is a separate
/// post-upload action handled via [GalleryRepository.updateMetadata].

@ProviderFor(GalleryUploadNotifier)
final galleryUploadProvider = GalleryUploadNotifierProvider._();

/// Holds upload progress (0.0–1.0) while an upload is in flight; null otherwise.
///
/// Photos are uploaded untagged. Dress-code tagging is a separate
/// post-upload action handled via [GalleryRepository.updateMetadata].
final class GalleryUploadNotifierProvider
    extends $NotifierProvider<GalleryUploadNotifier, double?> {
  /// Holds upload progress (0.0–1.0) while an upload is in flight; null otherwise.
  ///
  /// Photos are uploaded untagged. Dress-code tagging is a separate
  /// post-upload action handled via [GalleryRepository.updateMetadata].
  GalleryUploadNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryUploadProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryUploadNotifierHash();

  @$internal
  @override
  GalleryUploadNotifier create() => GalleryUploadNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }
}

String _$galleryUploadNotifierHash() =>
    r'350fad599e707c18f8d01351d8bf87ae660c48d3';

/// Holds upload progress (0.0–1.0) while an upload is in flight; null otherwise.
///
/// Photos are uploaded untagged. Dress-code tagging is a separate
/// post-upload action handled via [GalleryRepository.updateMetadata].

abstract class _$GalleryUploadNotifier extends $Notifier<double?> {
  double? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<double?, double?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double?, double?>,
              double?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the id of the photo currently being deleted; null when idle.

@ProviderFor(GalleryDeleteNotifier)
final galleryDeleteProvider = GalleryDeleteNotifierProvider._();

/// Holds the id of the photo currently being deleted; null when idle.
final class GalleryDeleteNotifierProvider
    extends $NotifierProvider<GalleryDeleteNotifier, String?> {
  /// Holds the id of the photo currently being deleted; null when idle.
  GalleryDeleteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'galleryDeleteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$galleryDeleteNotifierHash();

  @$internal
  @override
  GalleryDeleteNotifier create() => GalleryDeleteNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$galleryDeleteNotifierHash() =>
    r'7392455acb39a17136e79c4d43ab5cb8234d2dd6';

/// Holds the id of the photo currently being deleted; null when idle.

abstract class _$GalleryDeleteNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
