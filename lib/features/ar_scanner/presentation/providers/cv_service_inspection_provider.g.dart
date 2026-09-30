// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_service_inspection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cvServiceInspectionRepository)
final cvServiceInspectionRepositoryProvider =
    CvServiceInspectionRepositoryProvider._();

final class CvServiceInspectionRepositoryProvider
    extends
        $FunctionalProvider<
          CvServiceInspectionRepository,
          CvServiceInspectionRepository,
          CvServiceInspectionRepository
        >
    with $Provider<CvServiceInspectionRepository> {
  CvServiceInspectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cvServiceInspectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cvServiceInspectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<CvServiceInspectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CvServiceInspectionRepository create(Ref ref) {
    return cvServiceInspectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CvServiceInspectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CvServiceInspectionRepository>(
        value,
      ),
    );
  }
}

String _$cvServiceInspectionRepositoryHash() =>
    r'613169c7f59bfad64b3104f7b45ccc6261bc3f89';

/// Drives a single Phase-2 `cv-service` inspection. Same shape as
/// `UniformComplianceController` (Phase 1) deliberately — state is
/// `AsyncValue<CvInspectionResult?>`, `null` means no check has run
/// yet, nothing is persisted. Kept as a fully separate controller
/// rather than merged into the Phase-1 one, since the two backends
/// return different report shapes and `cv-service` is dev-only today
/// (see `CvServiceInspectionRepository`'s `kCvServiceBaseUrl` doc).

@ProviderFor(CvServiceInspectionController)
final cvServiceInspectionControllerProvider =
    CvServiceInspectionControllerProvider._();

/// Drives a single Phase-2 `cv-service` inspection. Same shape as
/// `UniformComplianceController` (Phase 1) deliberately — state is
/// `AsyncValue<CvInspectionResult?>`, `null` means no check has run
/// yet, nothing is persisted. Kept as a fully separate controller
/// rather than merged into the Phase-1 one, since the two backends
/// return different report shapes and `cv-service` is dev-only today
/// (see `CvServiceInspectionRepository`'s `kCvServiceBaseUrl` doc).
final class CvServiceInspectionControllerProvider
    extends
        $AsyncNotifierProvider<
          CvServiceInspectionController,
          CvInspectionResult?
        > {
  /// Drives a single Phase-2 `cv-service` inspection. Same shape as
  /// `UniformComplianceController` (Phase 1) deliberately — state is
  /// `AsyncValue<CvInspectionResult?>`, `null` means no check has run
  /// yet, nothing is persisted. Kept as a fully separate controller
  /// rather than merged into the Phase-1 one, since the two backends
  /// return different report shapes and `cv-service` is dev-only today
  /// (see `CvServiceInspectionRepository`'s `kCvServiceBaseUrl` doc).
  CvServiceInspectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cvServiceInspectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cvServiceInspectionControllerHash();

  @$internal
  @override
  CvServiceInspectionController create() => CvServiceInspectionController();
}

String _$cvServiceInspectionControllerHash() =>
    r'a2038c6b8a6465c8078ebf0b08b04ad2e69331bd';

/// Drives a single Phase-2 `cv-service` inspection. Same shape as
/// `UniformComplianceController` (Phase 1) deliberately — state is
/// `AsyncValue<CvInspectionResult?>`, `null` means no check has run
/// yet, nothing is persisted. Kept as a fully separate controller
/// rather than merged into the Phase-1 one, since the two backends
/// return different report shapes and `cv-service` is dev-only today
/// (see `CvServiceInspectionRepository`'s `kCvServiceBaseUrl` doc).

abstract class _$CvServiceInspectionController
    extends $AsyncNotifier<CvInspectionResult?> {
  FutureOr<CvInspectionResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CvInspectionResult?>, CvInspectionResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CvInspectionResult?>, CvInspectionResult?>,
              AsyncValue<CvInspectionResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
