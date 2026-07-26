// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8c3e9d11b27110ca96130356b5ef4d5d34a5ffc2';

@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider = FirebaseFirestoreProvider._();

final class FirebaseFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  FirebaseFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFirestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'211c9d7cd91051da8adfacbf85a09b8bad1d41e8';

@ProviderFor(firebaseFunctions)
final firebaseFunctionsProvider = FirebaseFunctionsProvider._();

final class FirebaseFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions,
          FirebaseFunctions,
          FirebaseFunctions
        >
    with $Provider<FirebaseFunctions> {
  FirebaseFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFunctionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions create(Ref ref) {
    return firebaseFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$firebaseFunctionsHash() => r'6860446391d417e2af4f0190502f2bea4a67e301';

@ProviderFor(localStorageService)
final localStorageServiceProvider = LocalStorageServiceProvider._();

final class LocalStorageServiceProvider
    extends
        $FunctionalProvider<
          LocalStorageService,
          LocalStorageService,
          LocalStorageService
        >
    with $Provider<LocalStorageService> {
  LocalStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localStorageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localStorageServiceHash();

  @$internal
  @override
  $ProviderElement<LocalStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalStorageService create(Ref ref) {
    return localStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalStorageService>(value),
    );
  }
}

String _$localStorageServiceHash() =>
    r'6009aa818e95c9c1fc8fbf24de965b0b9d0b3951';

@ProviderFor(deviceIdentityService)
final deviceIdentityServiceProvider = DeviceIdentityServiceProvider._();

final class DeviceIdentityServiceProvider
    extends
        $FunctionalProvider<
          DeviceIdentityService,
          DeviceIdentityService,
          DeviceIdentityService
        >
    with $Provider<DeviceIdentityService> {
  DeviceIdentityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdentityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdentityServiceHash();

  @$internal
  @override
  $ProviderElement<DeviceIdentityService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceIdentityService create(Ref ref) {
    return deviceIdentityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceIdentityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceIdentityService>(value),
    );
  }
}

String _$deviceIdentityServiceHash() =>
    r'92fd24766d290b70d3efb4cc062536311cdf35c5';

@ProviderFor(deviceRegistryService)
final deviceRegistryServiceProvider = DeviceRegistryServiceProvider._();

final class DeviceRegistryServiceProvider
    extends
        $FunctionalProvider<
          DeviceRegistryService,
          DeviceRegistryService,
          DeviceRegistryService
        >
    with $Provider<DeviceRegistryService> {
  DeviceRegistryServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRegistryServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRegistryServiceHash();

  @$internal
  @override
  $ProviderElement<DeviceRegistryService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceRegistryService create(Ref ref) {
    return deviceRegistryService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceRegistryService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceRegistryService>(value),
    );
  }
}

String _$deviceRegistryServiceHash() =>
    r'af03b324c4849dc854f4606dd0030dd893ce6b73';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'dfeb572520e314eb018a1620583cac1ec93c8a8c';

@ProviderFor(authSessionStream)
final authSessionStreamProvider = AuthSessionStreamProvider._();

final class AuthSessionStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSession?>,
          AuthSession?,
          Stream<AuthSession?>
        >
    with $FutureModifier<AuthSession?>, $StreamProvider<AuthSession?> {
  AuthSessionStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionStreamHash();

  @$internal
  @override
  $StreamProviderElement<AuthSession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthSession?> create(Ref ref) {
    return authSessionStream(ref);
  }
}

String _$authSessionStreamHash() => r'ccb6dd9f141a7d293e7309386ca02f66d306bf6c';
