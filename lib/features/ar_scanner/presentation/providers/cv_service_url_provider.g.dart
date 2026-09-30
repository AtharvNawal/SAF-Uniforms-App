// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cv_service_url_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dev `cv-service` base URL the AR Scanner calls. Starts at the
/// compiled-in [kCvServiceBaseUrl] and switches to the user's saved
/// override (`saf.cvServiceUrl`) as soon as it's loaded — so the address
/// can be changed on the phone (Settings → Analysis server, or the
/// scanner's "Connection problem" screen) instead of rebuilding the APK.
/// See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`.

@ProviderFor(CvServiceUrl)
final cvServiceUrlProvider = CvServiceUrlProvider._();

/// The dev `cv-service` base URL the AR Scanner calls. Starts at the
/// compiled-in [kCvServiceBaseUrl] and switches to the user's saved
/// override (`saf.cvServiceUrl`) as soon as it's loaded — so the address
/// can be changed on the phone (Settings → Analysis server, or the
/// scanner's "Connection problem" screen) instead of rebuilding the APK.
/// See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`.
final class CvServiceUrlProvider
    extends $NotifierProvider<CvServiceUrl, String> {
  /// The dev `cv-service` base URL the AR Scanner calls. Starts at the
  /// compiled-in [kCvServiceBaseUrl] and switches to the user's saved
  /// override (`saf.cvServiceUrl`) as soon as it's loaded — so the address
  /// can be changed on the phone (Settings → Analysis server, or the
  /// scanner's "Connection problem" screen) instead of rebuilding the APK.
  /// See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`.
  CvServiceUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cvServiceUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cvServiceUrlHash();

  @$internal
  @override
  CvServiceUrl create() => CvServiceUrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$cvServiceUrlHash() => r'40f2d092590ac6daa3d5f568714d47aadf1caa0d';

/// The dev `cv-service` base URL the AR Scanner calls. Starts at the
/// compiled-in [kCvServiceBaseUrl] and switches to the user's saved
/// override (`saf.cvServiceUrl`) as soon as it's loaded — so the address
/// can be changed on the phone (Settings → Analysis server, or the
/// scanner's "Connection problem" screen) instead of rebuilding the APK.
/// See `ChangeRequest/2026-09-30_cv-service-url-setting-and-usb.md`.

abstract class _$CvServiceUrl extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
