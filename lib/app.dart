import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/generated/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/active_branch_theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/profile/presentation/providers/uniform_provider.dart';

class SafUniformApp extends ConsumerWidget {
  const SafUniformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(activeBranchThemesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // Once auth establishes a session and the user's persisted profile
    // arrives from Firestore, replace the in-memory default with it.
    ref.listen(hydratedProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null) {
          ref.read(uniformProfileProvider.notifier).hydrate(profile);
        }
      });
    });

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      theme: AppTheme.light(themes.light),
      darkTheme: AppTheme.dark(themes.dark),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
