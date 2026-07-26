// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(branchConfigRepository)
final branchConfigRepositoryProvider = BranchConfigRepositoryProvider._();

final class BranchConfigRepositoryProvider
    extends
        $FunctionalProvider<
          BranchConfigRepository,
          BranchConfigRepository,
          BranchConfigRepository
        >
    with $Provider<BranchConfigRepository> {
  BranchConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchConfigRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchConfigRepositoryHash();

  @$internal
  @override
  $ProviderElement<BranchConfigRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BranchConfigRepository create(Ref ref) {
    return branchConfigRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchConfigRepository>(value),
    );
  }
}

String _$branchConfigRepositoryHash() =>
    r'1fe94a0c6dcbfbb1499f21beb0984d654b8a4620';

@ProviderFor(branchConfigs)
final branchConfigsProvider = BranchConfigsProvider._();

final class BranchConfigsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BranchConfig>>,
          List<BranchConfig>,
          Stream<List<BranchConfig>>
        >
    with
        $FutureModifier<List<BranchConfig>>,
        $StreamProvider<List<BranchConfig>> {
  BranchConfigsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'branchConfigsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$branchConfigsHash();

  @$internal
  @override
  $StreamProviderElement<List<BranchConfig>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BranchConfig>> create(Ref ref) {
    return branchConfigs(ref);
  }
}

String _$branchConfigsHash() => r'1bc92fa8d844200acc00b7031152f497556bec20';

@ProviderFor(branchConfigFor)
final branchConfigForProvider = BranchConfigForFamily._();

final class BranchConfigForProvider
    extends $FunctionalProvider<BranchConfig?, BranchConfig?, BranchConfig?>
    with $Provider<BranchConfig?> {
  BranchConfigForProvider._({
    required BranchConfigForFamily super.from,
    required BranchId super.argument,
  }) : super(
         retry: null,
         name: r'branchConfigForProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$branchConfigForHash();

  @override
  String toString() {
    return r'branchConfigForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<BranchConfig?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BranchConfig? create(Ref ref) {
    final argument = this.argument as BranchId;
    return branchConfigFor(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BranchConfig? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BranchConfig?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BranchConfigForProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$branchConfigForHash() => r'9cddaf9e7c86bc3cfcb25001fd2c50733d6fbada';

final class BranchConfigForFamily extends $Family
    with $FunctionalFamilyOverride<BranchConfig?, BranchId> {
  BranchConfigForFamily._()
    : super(
        retry: null,
        name: r'branchConfigForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  BranchConfigForProvider call(BranchId branch) =>
      BranchConfigForProvider._(argument: branch, from: this);

  @override
  String toString() => r'branchConfigForProvider';
}
