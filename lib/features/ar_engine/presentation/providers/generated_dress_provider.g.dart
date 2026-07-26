// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_dress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wraps the `composeUniformModel` callable so consumers can inject
/// the `FirebaseFunctions` instance via Riverpod overrides in tests.

@ProviderFor(modelGenerationRepository)
final modelGenerationRepositoryProvider = ModelGenerationRepositoryProvider._();

/// Wraps the `composeUniformModel` callable so consumers can inject
/// the `FirebaseFunctions` instance via Riverpod overrides in tests.

final class ModelGenerationRepositoryProvider
    extends
        $FunctionalProvider<
          ModelGenerationRepository,
          ModelGenerationRepository,
          ModelGenerationRepository
        >
    with $Provider<ModelGenerationRepository> {
  /// Wraps the `composeUniformModel` callable so consumers can inject
  /// the `FirebaseFunctions` instance via Riverpod overrides in tests.
  ModelGenerationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelGenerationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelGenerationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModelGenerationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModelGenerationRepository create(Ref ref) {
    return modelGenerationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelGenerationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelGenerationRepository>(value),
    );
  }
}

String _$modelGenerationRepositoryHash() =>
    r'dd55fa8fb56a7b68f3d439b2bf75721ca78cb90e';

/// Reactive view of the current `GeneratedDress` for [dress] derived
/// from the live `UniformProfile`. Returns `null` when nothing has
/// been generated yet for that dress code.

@ProviderFor(generatedDress)
final generatedDressProvider = GeneratedDressFamily._();

/// Reactive view of the current `GeneratedDress` for [dress] derived
/// from the live `UniformProfile`. Returns `null` when nothing has
/// been generated yet for that dress code.

final class GeneratedDressProvider
    extends
        $FunctionalProvider<GeneratedDress?, GeneratedDress?, GeneratedDress?>
    with $Provider<GeneratedDress?> {
  /// Reactive view of the current `GeneratedDress` for [dress] derived
  /// from the live `UniformProfile`. Returns `null` when nothing has
  /// been generated yet for that dress code.
  GeneratedDressProvider._({
    required GeneratedDressFamily super.from,
    required DressCode super.argument,
  }) : super(
         retry: null,
         name: r'generatedDressProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$generatedDressHash();

  @override
  String toString() {
    return r'generatedDressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<GeneratedDress?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeneratedDress? create(Ref ref) {
    final argument = this.argument as DressCode;
    return generatedDress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeneratedDress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeneratedDress?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GeneratedDressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$generatedDressHash() => r'96e8c2f814c6639066d5d2c460aa759c12a853d5';

/// Reactive view of the current `GeneratedDress` for [dress] derived
/// from the live `UniformProfile`. Returns `null` when nothing has
/// been generated yet for that dress code.

final class GeneratedDressFamily extends $Family
    with $FunctionalFamilyOverride<GeneratedDress?, DressCode> {
  GeneratedDressFamily._()
    : super(
        retry: null,
        name: r'generatedDressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Reactive view of the current `GeneratedDress` for [dress] derived
  /// from the live `UniformProfile`. Returns `null` when nothing has
  /// been generated yet for that dress code.

  GeneratedDressProvider call(DressCode dress) =>
      GeneratedDressProvider._(argument: dress, from: this);

  @override
  String toString() => r'generatedDressProvider';
}

/// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
/// into a single status the UI can switch on. Treats a missing
/// entry as `needsGeneration` and an entry whose `profileHash`
/// matches the current profile as `ready`.

@ProviderFor(modelStatus)
final modelStatusProvider = ModelStatusFamily._();

/// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
/// into a single status the UI can switch on. Treats a missing
/// entry as `needsGeneration` and an entry whose `profileHash`
/// matches the current profile as `ready`.

final class ModelStatusProvider
    extends $FunctionalProvider<ModelStatus, ModelStatus, ModelStatus>
    with $Provider<ModelStatus> {
  /// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
  /// into a single status the UI can switch on. Treats a missing
  /// entry as `needsGeneration` and an entry whose `profileHash`
  /// matches the current profile as `ready`.
  ModelStatusProvider._({
    required ModelStatusFamily super.from,
    required DressCode super.argument,
  }) : super(
         retry: null,
         name: r'modelStatusProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelStatusHash();

  @override
  String toString() {
    return r'modelStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ModelStatus> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ModelStatus create(Ref ref) {
    final argument = this.argument as DressCode;
    return modelStatus(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModelStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelStatusHash() => r'c1c1116c2dba9ea688690a3c4f78aaa3b404286e';

/// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
/// into a single status the UI can switch on. Treats a missing
/// entry as `needsGeneration` and an entry whose `profileHash`
/// matches the current profile as `ready`.

final class ModelStatusFamily extends $Family
    with $FunctionalFamilyOverride<ModelStatus, DressCode> {
  ModelStatusFamily._()
    : super(
        retry: null,
        name: r'modelStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Folds [GeneratedDress] + freshly-computed [computeProfileHash]
  /// into a single status the UI can switch on. Treats a missing
  /// entry as `needsGeneration` and an entry whose `profileHash`
  /// matches the current profile as `ready`.

  ModelStatusProvider call(DressCode dress) =>
      ModelStatusProvider._(argument: dress, from: this);

  @override
  String toString() => r'modelStatusProvider';
}
