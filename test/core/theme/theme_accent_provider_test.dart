import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/persistence/local_storage_service.dart';
import 'package:saf_uniforms/core/theme/theme_accent.dart';
import 'package:saf_uniforms/core/theme/theme_accent_provider.dart';
import 'package:saf_uniforms/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer({Map<String, Object> initialPrefs = const {}}) {
    SharedPreferences.setMockInitialValues(initialPrefs);
    final container = ProviderContainer(
      overrides: [
        // Use a fresh LocalStorageService bound to the mocked
        // SharedPreferences. Default secure-storage is unused here.
        localStorageServiceProvider.overrideWithValue(LocalStorageService()),
      ],
    );
    return container;
  }

  test('default state is SafCrest', () {
    final container = makeContainer();
    addTearDown(container.dispose);
    expect(container.read(themeAccentProvider), isA<SafCrest>());
  });

  test('hydrate restores SafCrest from persisted "saf_crest" key', () async {
    final container = makeContainer(
      initialPrefs: {'saf.themeAccent': 'saf_crest'},
    );
    addTearDown(container.dispose);

    // Trigger build, then wait for the hydrate Future scheduled in build().
    container.read(themeAccentProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(themeAccentProvider), isA<SafCrest>());
  });

  test('hydrate restores FollowBranch from persisted "follow" key', () async {
    final container = makeContainer(
      initialPrefs: {'saf.themeAccent': 'follow'},
    );
    addTearDown(container.dispose);

    container.read(themeAccentProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(themeAccentProvider), isA<FollowBranch>());
  });

  test('malformed persisted value falls back to SafCrest', () async {
    final container = makeContainer(
      initialPrefs: {'saf.themeAccent': 'not_a_real_accent'},
    );
    addTearDown(container.dispose);

    container.read(themeAccentProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(themeAccentProvider), isA<SafCrest>());
  });

  test('set persists wireName so a fresh container hydrates the same value',
      () async {
    SharedPreferences.setMockInitialValues({});
    final c1 = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(LocalStorageService()),
      ],
    );
    addTearDown(c1.dispose);

    await c1.read(themeAccentProvider.notifier).set(const SafCrest());
    expect(c1.read(themeAccentProvider), isA<SafCrest>());

    // A second container shares the same SharedPreferences mock store, so
    // it should hydrate the persisted "saf_crest" value.
    final c2 = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(LocalStorageService()),
      ],
    );
    addTearDown(c2.dispose);

    c2.read(themeAccentProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c2.read(themeAccentProvider), isA<SafCrest>());
  });
}
