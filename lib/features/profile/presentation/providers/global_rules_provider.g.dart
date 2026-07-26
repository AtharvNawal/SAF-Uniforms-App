// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_rules_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(globalRulesRepository)
final globalRulesRepositoryProvider = GlobalRulesRepositoryProvider._();

final class GlobalRulesRepositoryProvider
    extends
        $FunctionalProvider<
          GlobalRulesRepository,
          GlobalRulesRepository,
          GlobalRulesRepository
        >
    with $Provider<GlobalRulesRepository> {
  GlobalRulesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalRulesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalRulesRepositoryHash();

  @$internal
  @override
  $ProviderElement<GlobalRulesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GlobalRulesRepository create(Ref ref) {
    return globalRulesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalRulesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalRulesRepository>(value),
    );
  }
}

String _$globalRulesRepositoryHash() =>
    r'f124ce488012b28bfd71e30fc90ae8f3d4152012';

@ProviderFor(medalVerticalShiftRule)
final medalVerticalShiftRuleProvider = MedalVerticalShiftRuleProvider._();

final class MedalVerticalShiftRuleProvider
    extends
        $FunctionalProvider<
          AsyncValue<MedalVerticalShiftRule?>,
          MedalVerticalShiftRule?,
          Stream<MedalVerticalShiftRule?>
        >
    with
        $FutureModifier<MedalVerticalShiftRule?>,
        $StreamProvider<MedalVerticalShiftRule?> {
  MedalVerticalShiftRuleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medalVerticalShiftRuleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medalVerticalShiftRuleHash();

  @$internal
  @override
  $StreamProviderElement<MedalVerticalShiftRule?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MedalVerticalShiftRule?> create(Ref ref) {
    return medalVerticalShiftRule(ref);
  }
}

String _$medalVerticalShiftRuleHash() =>
    r'7e58a18390868b09e7c99ce3376fb38c6c89736b';
