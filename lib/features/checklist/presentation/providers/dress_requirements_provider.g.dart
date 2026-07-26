// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dress_requirements_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dressRequirementsRepository)
final dressRequirementsRepositoryProvider =
    DressRequirementsRepositoryProvider._();

final class DressRequirementsRepositoryProvider
    extends
        $FunctionalProvider<
          DressRequirementsRepository,
          DressRequirementsRepository,
          DressRequirementsRepository
        >
    with $Provider<DressRequirementsRepository> {
  DressRequirementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dressRequirementsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dressRequirementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<DressRequirementsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DressRequirementsRepository create(Ref ref) {
    return dressRequirementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DressRequirementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DressRequirementsRepository>(value),
    );
  }
}

String _$dressRequirementsRepositoryHash() =>
    r'94baf48511f85d9ef6334d5c31b9935df9c1d798';

@ProviderFor(dressRequirementById)
final dressRequirementByIdProvider = DressRequirementByIdFamily._();

final class DressRequirementByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<DressRequirement?>,
          DressRequirement?,
          Stream<DressRequirement?>
        >
    with
        $FutureModifier<DressRequirement?>,
        $StreamProvider<DressRequirement?> {
  DressRequirementByIdProvider._({
    required DressRequirementByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dressRequirementByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dressRequirementByIdHash();

  @override
  String toString() {
    return r'dressRequirementByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<DressRequirement?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DressRequirement?> create(Ref ref) {
    final argument = this.argument as String;
    return dressRequirementById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DressRequirementByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dressRequirementByIdHash() =>
    r'677af21dd0074369eeaa4afbe8488e6fda25d617';

final class DressRequirementByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<DressRequirement?>, String> {
  DressRequirementByIdFamily._()
    : super(
        retry: null,
        name: r'dressRequirementByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  DressRequirementByIdProvider call(String dressId) =>
      DressRequirementByIdProvider._(argument: dressId, from: this);

  @override
  String toString() => r'dressRequirementByIdProvider';
}

/// Branch-resolved dress requirement: applies any matching `branch_overrides`
/// over the base entry. Falls back to the base when no override is present.

@ProviderFor(dressRequirementForBranch)
final dressRequirementForBranchProvider = DressRequirementForBranchFamily._();

/// Branch-resolved dress requirement: applies any matching `branch_overrides`
/// over the base entry. Falls back to the base when no override is present.

final class DressRequirementForBranchProvider
    extends
        $FunctionalProvider<
          AsyncValue<DressRequirement?>,
          DressRequirement?,
          Stream<DressRequirement?>
        >
    with
        $FutureModifier<DressRequirement?>,
        $StreamProvider<DressRequirement?> {
  /// Branch-resolved dress requirement: applies any matching `branch_overrides`
  /// over the base entry. Falls back to the base when no override is present.
  DressRequirementForBranchProvider._({
    required DressRequirementForBranchFamily super.from,
    required (String, BranchId) super.argument,
  }) : super(
         retry: null,
         name: r'dressRequirementForBranchProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dressRequirementForBranchHash();

  @override
  String toString() {
    return r'dressRequirementForBranchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<DressRequirement?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DressRequirement?> create(Ref ref) {
    final argument = this.argument as (String, BranchId);
    return dressRequirementForBranch(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DressRequirementForBranchProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dressRequirementForBranchHash() =>
    r'884adbb9d50b2dad3cdb32419c64f6b7dfcb56ab';

/// Branch-resolved dress requirement: applies any matching `branch_overrides`
/// over the base entry. Falls back to the base when no override is present.

final class DressRequirementForBranchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<DressRequirement?>,
          (String, BranchId)
        > {
  DressRequirementForBranchFamily._()
    : super(
        retry: null,
        name: r'dressRequirementForBranchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Branch-resolved dress requirement: applies any matching `branch_overrides`
  /// over the base entry. Falls back to the base when no override is present.

  DressRequirementForBranchProvider call(String dressId, BranchId branch) =>
      DressRequirementForBranchProvider._(
        argument: (dressId, branch),
        from: this,
      );

  @override
  String toString() => r'dressRequirementForBranchProvider';
}

/// Streams every document in `dress_requirements`. Drives the dynamic
/// Dashboard Home grid, which renders one tile per doc.

@ProviderFor(dressRequirementsAll)
final dressRequirementsAllProvider = DressRequirementsAllProvider._();

/// Streams every document in `dress_requirements`. Drives the dynamic
/// Dashboard Home grid, which renders one tile per doc.

final class DressRequirementsAllProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DressRequirement>>,
          List<DressRequirement>,
          Stream<List<DressRequirement>>
        >
    with
        $FutureModifier<List<DressRequirement>>,
        $StreamProvider<List<DressRequirement>> {
  /// Streams every document in `dress_requirements`. Drives the dynamic
  /// Dashboard Home grid, which renders one tile per doc.
  DressRequirementsAllProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dressRequirementsAllProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dressRequirementsAllHash();

  @$internal
  @override
  $StreamProviderElement<List<DressRequirement>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DressRequirement>> create(Ref ref) {
    return dressRequirementsAll(ref);
  }
}

String _$dressRequirementsAllHash() =>
    r'2903189c36280e72e1701cc21b7dfb753758d4af';
