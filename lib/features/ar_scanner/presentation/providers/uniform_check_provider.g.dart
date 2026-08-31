// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uniform_check_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(uniformCheckRepository)
final uniformCheckRepositoryProvider = UniformCheckRepositoryProvider._();

final class UniformCheckRepositoryProvider
    extends
        $FunctionalProvider<
          UniformCheckRepository,
          UniformCheckRepository,
          UniformCheckRepository
        >
    with $Provider<UniformCheckRepository> {
  UniformCheckRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uniformCheckRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uniformCheckRepositoryHash();

  @$internal
  @override
  $ProviderElement<UniformCheckRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UniformCheckRepository create(Ref ref) {
    return uniformCheckRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UniformCheckRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UniformCheckRepository>(value),
    );
  }
}

String _$uniformCheckRepositoryHash() =>
    r'cce69449de7494e0202228687dbfb0a395b565e3';

/// Drives a single real (geometry/pixel) uniform check from
/// `ARScannerScreen`'s default capture button, via `cv-service`'s
/// `POST /check_uniform`. State is `AsyncValue<UniformCheckResult?>`:
/// `null` = no check has run yet, non-null = latest result. Nothing is
/// persisted — a fresh screen visit starts at `null` again.
///
/// This is the default capture path now (replacing the old fabricated
/// "100% match" stand-in). The Phase-1 Node/Anthropic
/// `checkUniformCompliance` path stays disabled — see
/// `ar_scanner_screen.dart` `_capture` and
/// `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.

@ProviderFor(UniformCheckController)
final uniformCheckControllerProvider = UniformCheckControllerProvider._();

/// Drives a single real (geometry/pixel) uniform check from
/// `ARScannerScreen`'s default capture button, via `cv-service`'s
/// `POST /check_uniform`. State is `AsyncValue<UniformCheckResult?>`:
/// `null` = no check has run yet, non-null = latest result. Nothing is
/// persisted — a fresh screen visit starts at `null` again.
///
/// This is the default capture path now (replacing the old fabricated
/// "100% match" stand-in). The Phase-1 Node/Anthropic
/// `checkUniformCompliance` path stays disabled — see
/// `ar_scanner_screen.dart` `_capture` and
/// `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.
final class UniformCheckControllerProvider
    extends
        $AsyncNotifierProvider<UniformCheckController, UniformCheckResult?> {
  /// Drives a single real (geometry/pixel) uniform check from
  /// `ARScannerScreen`'s default capture button, via `cv-service`'s
  /// `POST /check_uniform`. State is `AsyncValue<UniformCheckResult?>`:
  /// `null` = no check has run yet, non-null = latest result. Nothing is
  /// persisted — a fresh screen visit starts at `null` again.
  ///
  /// This is the default capture path now (replacing the old fabricated
  /// "100% match" stand-in). The Phase-1 Node/Anthropic
  /// `checkUniformCompliance` path stays disabled — see
  /// `ar_scanner_screen.dart` `_capture` and
  /// `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.
  UniformCheckControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uniformCheckControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uniformCheckControllerHash();

  @$internal
  @override
  UniformCheckController create() => UniformCheckController();
}

String _$uniformCheckControllerHash() =>
    r'f24f977c2c6e0b79061e22cba09136cbf0fd4163';

/// Drives a single real (geometry/pixel) uniform check from
/// `ARScannerScreen`'s default capture button, via `cv-service`'s
/// `POST /check_uniform`. State is `AsyncValue<UniformCheckResult?>`:
/// `null` = no check has run yet, non-null = latest result. Nothing is
/// persisted — a fresh screen visit starts at `null` again.
///
/// This is the default capture path now (replacing the old fabricated
/// "100% match" stand-in). The Phase-1 Node/Anthropic
/// `checkUniformCompliance` path stays disabled — see
/// `ar_scanner_screen.dart` `_capture` and
/// `ChangeRequest/2026-08-30_ar-scanner-real-geometry-scorecard.md`.

abstract class _$UniformCheckController
    extends $AsyncNotifier<UniformCheckResult?> {
  FutureOr<UniformCheckResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UniformCheckResult?>, UniformCheckResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UniformCheckResult?>, UniformCheckResult?>,
              AsyncValue<UniformCheckResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
