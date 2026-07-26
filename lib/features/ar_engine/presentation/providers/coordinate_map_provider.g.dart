// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coordinate_map_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pure derivation: `(profile, branchConfig, verticalShiftRule) -> CoordinateMap`.
///
/// Any change to any input causes Riverpod to re-evaluate, which triggers a
/// rebuild of the GhostModelView. Reactive bridge between profile state,
/// branch config, global rules, and the 3D renderer.

@ProviderFor(coordinateMap)
final coordinateMapProvider = CoordinateMapProvider._();

/// Pure derivation: `(profile, branchConfig, verticalShiftRule) -> CoordinateMap`.
///
/// Any change to any input causes Riverpod to re-evaluate, which triggers a
/// rebuild of the GhostModelView. Reactive bridge between profile state,
/// branch config, global rules, and the 3D renderer.

final class CoordinateMapProvider
    extends $FunctionalProvider<CoordinateMap, CoordinateMap, CoordinateMap>
    with $Provider<CoordinateMap> {
  /// Pure derivation: `(profile, branchConfig, verticalShiftRule) -> CoordinateMap`.
  ///
  /// Any change to any input causes Riverpod to re-evaluate, which triggers a
  /// rebuild of the GhostModelView. Reactive bridge between profile state,
  /// branch config, global rules, and the 3D renderer.
  CoordinateMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coordinateMapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coordinateMapHash();

  @$internal
  @override
  $ProviderElement<CoordinateMap> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoordinateMap create(Ref ref) {
    return coordinateMap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoordinateMap value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoordinateMap>(value),
    );
  }
}

String _$coordinateMapHash() => r'62d1327f71462571062eca4545a0f688df11ba07';
