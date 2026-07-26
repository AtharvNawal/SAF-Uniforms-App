// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accessory_library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accessoryLibraryRepository)
final accessoryLibraryRepositoryProvider =
    AccessoryLibraryRepositoryProvider._();

final class AccessoryLibraryRepositoryProvider
    extends
        $FunctionalProvider<
          AccessoryLibraryRepository,
          AccessoryLibraryRepository,
          AccessoryLibraryRepository
        >
    with $Provider<AccessoryLibraryRepository> {
  AccessoryLibraryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessoryLibraryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessoryLibraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccessoryLibraryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccessoryLibraryRepository create(Ref ref) {
    return accessoryLibraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccessoryLibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccessoryLibraryRepository>(value),
    );
  }
}

String _$accessoryLibraryRepositoryHash() =>
    r'e9687dd8a65656bb504874b77f131c14a788e296';

@ProviderFor(accessoryLibrary)
final accessoryLibraryProvider = AccessoryLibraryProvider._();

final class AccessoryLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Accessory>>,
          List<Accessory>,
          Stream<List<Accessory>>
        >
    with $FutureModifier<List<Accessory>>, $StreamProvider<List<Accessory>> {
  AccessoryLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessoryLibraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessoryLibraryHash();

  @$internal
  @override
  $StreamProviderElement<List<Accessory>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Accessory>> create(Ref ref) {
    return accessoryLibrary(ref);
  }
}

String _$accessoryLibraryHash() => r'9c0cb1bff460e91973ed9dfa08b8b2527a43538e';

@ProviderFor(accessoryById)
final accessoryByIdProvider = AccessoryByIdFamily._();

final class AccessoryByIdProvider
    extends $FunctionalProvider<Accessory?, Accessory?, Accessory?>
    with $Provider<Accessory?> {
  AccessoryByIdProvider._({
    required AccessoryByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'accessoryByIdProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$accessoryByIdHash();

  @override
  String toString() {
    return r'accessoryByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Accessory?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Accessory? create(Ref ref) {
    final argument = this.argument as String;
    return accessoryById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Accessory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Accessory?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AccessoryByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accessoryByIdHash() => r'5dedc28a99cb55600911091c00357660e10c5d8b';

final class AccessoryByIdFamily extends $Family
    with $FunctionalFamilyOverride<Accessory?, String> {
  AccessoryByIdFamily._()
    : super(
        retry: null,
        name: r'accessoryByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AccessoryByIdProvider call(String accessoryId) =>
      AccessoryByIdProvider._(argument: accessoryId, from: this);

  @override
  String toString() => r'accessoryByIdProvider';
}
