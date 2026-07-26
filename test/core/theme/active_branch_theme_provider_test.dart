import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saf_uniforms/core/persistence/local_storage_service.dart';
import 'package:saf_uniforms/core/theme/active_branch_theme_provider.dart';
import 'package:saf_uniforms/core/theme/branch_themes.dart';
import 'package:saf_uniforms/core/theme/saf_crest_theme.dart';
import 'package:saf_uniforms/core/theme/theme_accent.dart';
import 'package:saf_uniforms/core/theme/theme_accent_provider.dart';
import 'package:saf_uniforms/features/auth/presentation/providers/auth_providers.dart';
import 'package:saf_uniforms/features/profile/domain/entities/branch_id.dart';
import 'package:saf_uniforms/features/profile/presentation/providers/uniform_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    SharedPreferences.setMockInitialValues({});
    return ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(LocalStorageService()),
      ],
    );
  }

  test('FollowBranch returns branchThemeFor(currentBranch) on both variants',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Default accent is SafCrest — opt out to exercise FollowBranch.
    await container
        .read(themeAccentProvider.notifier)
        .set(const FollowBranch());

    // Default profile branch is Army.
    final themes = container.read(activeBranchThemesProvider);
    expect(themes.light, equals(armyBranchTheme));
    expect(themes.dark, equals(armyBranchTheme));
  });

  test('FollowBranch reacts to currentBranch changes', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await container
        .read(themeAccentProvider.notifier)
        .set(const FollowBranch());
    container
        .read(uniformProfileProvider.notifier)
        .setBranch(BranchId.navy);

    final themes = container.read(activeBranchThemesProvider);
    expect(themes.light, equals(navyBranchTheme));
    expect(themes.dark, equals(navyBranchTheme));
  });

  test(
      'SafCrest returns SAF light + dark variants regardless of profile branch',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    // Set the profile branch to RSAF so we can prove the override ignores it.
    container
        .read(uniformProfileProvider.notifier)
        .setBranch(BranchId.rsaf);
    await container.read(themeAccentProvider.notifier).set(const SafCrest());

    final themes = container.read(activeBranchThemesProvider);
    expect(themes.light, equals(safCrestBranchTheme));
    expect(themes.dark, equals(safCrestBranchThemeDark));
  });

  test('switching back to FollowBranch restores branch-derived theme',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    container
        .read(uniformProfileProvider.notifier)
        .setBranch(BranchId.dis);
    await container.read(themeAccentProvider.notifier).set(const SafCrest());
    expect(container.read(activeBranchThemesProvider).light,
        equals(safCrestBranchTheme));

    await container
        .read(themeAccentProvider.notifier)
        .set(const FollowBranch());
    final themes = container.read(activeBranchThemesProvider);
    expect(themes.light, equals(disBranchTheme));
    expect(themes.dark, equals(disBranchTheme));
  });
}
