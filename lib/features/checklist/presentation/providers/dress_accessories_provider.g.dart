// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dress_accessories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The list of accessories the UI should render for the active
/// [UniformProfile]. Pure derivation of:
///
///   `(uniformProfile, dressRequirementForBranch, accessoryLibrary)`
///
/// All three sources are Firestore-backed real-time streams, so any change
/// — locally (user toggles a profile field) or remotely (admin portal
/// edits a doc) — re-emits a fresh list automatically.
///
/// Returns an [AsyncValue] so callers can show loading / error states.
/// Empty list when the dress requirement has no branch override for the
/// user's branch (e.g. No.1/2/4/5 today, where only legacy placeholders
/// exist in the accessory library and they are filtered out by
/// [DressAccessoryResolver]).

@ProviderFor(dressAccessories)
final dressAccessoriesProvider = DressAccessoriesProvider._();

/// The list of accessories the UI should render for the active
/// [UniformProfile]. Pure derivation of:
///
///   `(uniformProfile, dressRequirementForBranch, accessoryLibrary)`
///
/// All three sources are Firestore-backed real-time streams, so any change
/// — locally (user toggles a profile field) or remotely (admin portal
/// edits a doc) — re-emits a fresh list automatically.
///
/// Returns an [AsyncValue] so callers can show loading / error states.
/// Empty list when the dress requirement has no branch override for the
/// user's branch (e.g. No.1/2/4/5 today, where only legacy placeholders
/// exist in the accessory library and they are filtered out by
/// [DressAccessoryResolver]).

final class DressAccessoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Accessory>>,
          AsyncValue<List<Accessory>>,
          AsyncValue<List<Accessory>>
        >
    with $Provider<AsyncValue<List<Accessory>>> {
  /// The list of accessories the UI should render for the active
  /// [UniformProfile]. Pure derivation of:
  ///
  ///   `(uniformProfile, dressRequirementForBranch, accessoryLibrary)`
  ///
  /// All three sources are Firestore-backed real-time streams, so any change
  /// — locally (user toggles a profile field) or remotely (admin portal
  /// edits a doc) — re-emits a fresh list automatically.
  ///
  /// Returns an [AsyncValue] so callers can show loading / error states.
  /// Empty list when the dress requirement has no branch override for the
  /// user's branch (e.g. No.1/2/4/5 today, where only legacy placeholders
  /// exist in the accessory library and they are filtered out by
  /// [DressAccessoryResolver]).
  DressAccessoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dressAccessoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dressAccessoriesHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Accessory>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Accessory>> create(Ref ref) {
    return dressAccessories(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Accessory>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Accessory>>>(value),
    );
  }
}

String _$dressAccessoriesHash() => r'4e021d0c9a798ed6f0f8272a90bf12b3f5bca74d';

/// Like [dressAccessories] but parameterised by an explicit [dressId]
/// (so the Wardrobe tab can show a checklist for any dress, not only
/// the one the user is currently configured to wear) and split into
/// mandatory + optional so the UI can label rows.

@ProviderFor(dressAccessoriesById)
final dressAccessoriesByIdProvider = DressAccessoriesByIdFamily._();

/// Like [dressAccessories] but parameterised by an explicit [dressId]
/// (so the Wardrobe tab can show a checklist for any dress, not only
/// the one the user is currently configured to wear) and split into
/// mandatory + optional so the UI can label rows.

final class DressAccessoriesByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<AccessorySplit>,
          AsyncValue<AccessorySplit>,
          AsyncValue<AccessorySplit>
        >
    with $Provider<AsyncValue<AccessorySplit>> {
  /// Like [dressAccessories] but parameterised by an explicit [dressId]
  /// (so the Wardrobe tab can show a checklist for any dress, not only
  /// the one the user is currently configured to wear) and split into
  /// mandatory + optional so the UI can label rows.
  DressAccessoriesByIdProvider._({
    required DressAccessoriesByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dressAccessoriesByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dressAccessoriesByIdHash();

  @override
  String toString() {
    return r'dressAccessoriesByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<AccessorySplit>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<AccessorySplit> create(Ref ref) {
    final argument = this.argument as String;
    return dressAccessoriesById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<AccessorySplit> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<AccessorySplit>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DressAccessoriesByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dressAccessoriesByIdHash() =>
    r'83826c6162ffba66e8e056d2cb556d42e7820dcb';

/// Like [dressAccessories] but parameterised by an explicit [dressId]
/// (so the Wardrobe tab can show a checklist for any dress, not only
/// the one the user is currently configured to wear) and split into
/// mandatory + optional so the UI can label rows.

final class DressAccessoriesByIdFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<AccessorySplit>, String> {
  DressAccessoriesByIdFamily._()
    : super(
        retry: null,
        name: r'dressAccessoriesByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Like [dressAccessories] but parameterised by an explicit [dressId]
  /// (so the Wardrobe tab can show a checklist for any dress, not only
  /// the one the user is currently configured to wear) and split into
  /// mandatory + optional so the UI can label rows.

  DressAccessoriesByIdProvider call(String dressId) =>
      DressAccessoriesByIdProvider._(argument: dressId, from: this);

  @override
  String toString() => r'dressAccessoriesByIdProvider';
}

/// Deduped union of accessories across every dress in
/// `dress_requirements`, applied to the active profile. Powers the
/// "All Accessories" filter in the Wardrobe tab. Order is determined by
/// each dress's resolved order on first encounter, which keeps the UI
/// stable across rebuilds.

@ProviderFor(allDressesAccessoriesCombined)
final allDressesAccessoriesCombinedProvider =
    AllDressesAccessoriesCombinedProvider._();

/// Deduped union of accessories across every dress in
/// `dress_requirements`, applied to the active profile. Powers the
/// "All Accessories" filter in the Wardrobe tab. Order is determined by
/// each dress's resolved order on first encounter, which keeps the UI
/// stable across rebuilds.

final class AllDressesAccessoriesCombinedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Accessory>>,
          AsyncValue<List<Accessory>>,
          AsyncValue<List<Accessory>>
        >
    with $Provider<AsyncValue<List<Accessory>>> {
  /// Deduped union of accessories across every dress in
  /// `dress_requirements`, applied to the active profile. Powers the
  /// "All Accessories" filter in the Wardrobe tab. Order is determined by
  /// each dress's resolved order on first encounter, which keeps the UI
  /// stable across rebuilds.
  AllDressesAccessoriesCombinedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allDressesAccessoriesCombinedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allDressesAccessoriesCombinedHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Accessory>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Accessory>> create(Ref ref) {
    return allDressesAccessoriesCombined(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Accessory>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Accessory>>>(value),
    );
  }
}

String _$allDressesAccessoriesCombinedHash() =>
    r'3b448d226f70590eb5220ee850d5f009b1db322a';

/// Maps an accessory id back to every dress (by Firestore doc id) that
/// resolves to it for the active profile. The Wardrobe "All Accessories"
/// view uses this to fan a tick out across every dress that lists it,
/// so the verified count stays coherent regardless of which view the
/// user toggles from.

@ProviderFor(accessoryDressIndex)
final accessoryDressIndexProvider = AccessoryDressIndexProvider._();

/// Maps an accessory id back to every dress (by Firestore doc id) that
/// resolves to it for the active profile. The Wardrobe "All Accessories"
/// view uses this to fan a tick out across every dress that lists it,
/// so the verified count stays coherent regardless of which view the
/// user toggles from.

final class AccessoryDressIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Set<String>>>,
          AsyncValue<Map<String, Set<String>>>,
          AsyncValue<Map<String, Set<String>>>
        >
    with $Provider<AsyncValue<Map<String, Set<String>>>> {
  /// Maps an accessory id back to every dress (by Firestore doc id) that
  /// resolves to it for the active profile. The Wardrobe "All Accessories"
  /// view uses this to fan a tick out across every dress that lists it,
  /// so the verified count stays coherent regardless of which view the
  /// user toggles from.
  AccessoryDressIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessoryDressIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessoryDressIndexHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<Map<String, Set<String>>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<Map<String, Set<String>>> create(Ref ref) {
    return accessoryDressIndex(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Map<String, Set<String>>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<Map<String, Set<String>>>>(value),
    );
  }
}

String _$accessoryDressIndexHash() =>
    r'abcf19bae4466ddacc3bb9ddba35517deda9d1e7';

/// `(checked, total)` count for the Wardrobe verified card, scoped to
/// the active filter. For [SingleDressFilter] it counts only checks on
/// that dress; for [AllAccessoriesFilter] an accessory counts as
/// verified if at least one dress that lists it is checked.

@ProviderFor(wardrobeProgress)
final wardrobeProgressProvider = WardrobeProgressFamily._();

/// `(checked, total)` count for the Wardrobe verified card, scoped to
/// the active filter. For [SingleDressFilter] it counts only checks on
/// that dress; for [AllAccessoriesFilter] an accessory counts as
/// verified if at least one dress that lists it is checked.

final class WardrobeProgressProvider
    extends
        $FunctionalProvider<
          ({int checked, int total}),
          ({int checked, int total}),
          ({int checked, int total})
        >
    with $Provider<({int checked, int total})> {
  /// `(checked, total)` count for the Wardrobe verified card, scoped to
  /// the active filter. For [SingleDressFilter] it counts only checks on
  /// that dress; for [AllAccessoriesFilter] an accessory counts as
  /// verified if at least one dress that lists it is checked.
  WardrobeProgressProvider._({
    required WardrobeProgressFamily super.from,
    required WardrobeFilter super.argument,
  }) : super(
         retry: null,
         name: r'wardrobeProgressProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wardrobeProgressHash();

  @override
  String toString() {
    return r'wardrobeProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<({int checked, int total})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({int checked, int total}) create(Ref ref) {
    final argument = this.argument as WardrobeFilter;
    return wardrobeProgress(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int checked, int total}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int checked, int total})>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WardrobeProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wardrobeProgressHash() => r'1d3d88fcd5c1b2a84ed80477a54494a41c7ce1bb';

/// `(checked, total)` count for the Wardrobe verified card, scoped to
/// the active filter. For [SingleDressFilter] it counts only checks on
/// that dress; for [AllAccessoriesFilter] an accessory counts as
/// verified if at least one dress that lists it is checked.

final class WardrobeProgressFamily extends $Family
    with $FunctionalFamilyOverride<({int checked, int total}), WardrobeFilter> {
  WardrobeProgressFamily._()
    : super(
        retry: null,
        name: r'wardrobeProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// `(checked, total)` count for the Wardrobe verified card, scoped to
  /// the active filter. For [SingleDressFilter] it counts only checks on
  /// that dress; for [AllAccessoriesFilter] an accessory counts as
  /// verified if at least one dress that lists it is checked.

  WardrobeProgressProvider call(WardrobeFilter filter) =>
      WardrobeProgressProvider._(argument: filter, from: this);

  @override
  String toString() => r'wardrobeProgressProvider';
}
