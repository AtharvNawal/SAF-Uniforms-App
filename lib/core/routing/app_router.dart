import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ar_engine/presentation/screens/ghost_screen.dart';
import '../../features/ar_scanner/presentation/screens/ar_scanner_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/checklist/presentation/screens/checklist_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/dress_accessories_screen.dart';
import '../../features/dashboard/presentation/screens/generating_screen.dart';
import '../../features/dashboard/presentation/screens/rebuilding_screen.dart';
import '../../features/gallery/domain/entities/gallery_photo.dart';
import '../../features/gallery/presentation/screens/photo_viewer_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/profile/domain/entities/dress_code.dart';
import '../../features/profile/presentation/screens/config_screen.dart';
import '../../features/wearing_guide/presentation/screens/wearing_guide_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Trigger router redirect re-evaluation whenever the auth session
  // changes (e.g. when the background `claimDeviceIdentity` flow
  // resolves, or after Config Done flips `profileComplete`).
  final refresh = ValueNotifier<int>(0);
  ref.listen<Object?>(authSessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.welcome,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final loc = state.matchedLocation;

      // No session yet (cold start, never signed in, or background
      // auth still in flight without a cached session): only the
      // Welcome and Config screens are reachable. Everything else
      // bounces to Welcome so we don't render protected screens
      // against a `null` session.
      if (session == null) {
        if (loc == Routes.welcome || loc == Routes.config) return null;
        return Routes.welcome;
      }

      // The "returning user on `/` → /dashboard" redirect intentionally
      // lives in WelcomeScreen, not here. Welcome owns the minimum
      // brand-display window and only auto-routes after it elapses;
      // bouncing here would cause Welcome to flash and disappear
      // before users see it.

      // Returning user mid-onboarding: keep them in the wizard until
      // they finish, even if a deep link tries to bypass it.
      if (!session.profileComplete &&
          loc != Routes.config &&
          loc != Routes.welcome) {
        return Routes.config;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.config,
        builder: (context, state) => const ConfigScreen(),
      ),
      GoRoute(
        path: Routes.ghostModel,
        builder: (context, state) => const GhostScreen(),
      ),
      GoRoute(
        path: Routes.wearing,
        builder: (context, state) => const WearingGuideScreen(),
      ),
      GoRoute(
        path: Routes.ar,
        builder: (context, state) => const ARScannerScreen(),
      ),
      GoRoute(
        path: '/checklist',
        builder: (context, state) => const ChecklistScreen(),
      ),
      GoRoute(
        path: Routes.dressAccessories,
        builder: (context, state) {
          final wire = state.uri.queryParameters['dress'] ?? DressCode.no3.wireName;
          final code = DressCode.values.firstWhere(
            (c) => c.wireName == wire,
            orElse: () => DressCode.no3,
          );
          return DressAccessoriesScreen(dress: code);
        },
      ),
      GoRoute(
        path: Routes.generating,
        builder: (context, state) {
          final wire = state.uri.queryParameters['dress'] ?? 'No3';
          final dress = DressCode.values.firstWhere(
            (d) => d.wireName == wire,
            orElse: () => DressCode.no3,
          );
          return GeneratingScreen(dress: dress);
        },
      ),
      GoRoute(
        path: Routes.rebuilding,
        builder: (context, state) => const RebuildingScreen(),
      ),
      GoRoute(
        path: Routes.galleryViewer,
        builder: (context, state) {
          final extra = state.extra
              as ({List<GalleryPhoto> photos, int initialIndex});
          return PhotoViewerScreen(
            photos: extra.photos,
            initialIndex: extra.initialIndex,
          );
        },
      ),
    ],
  );

  // Persist the current location on every navigation, restricted to
  // `Routes.restorable` — lets `WelcomeScreen` return a returning user
  // to the screen they were on after a cold start instead of always
  // `/dashboard`, including an Android-triggered process-death respawn
  // (e.g. the OS camera app backgrounding this app for a photo capture).
  // See ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md.
  // `GoRouterDelegate` is a `Listenable` that notifies on every
  // navigation — there's no dedicated "route changed" callback.
  void persistCurrentRoute() {
    final uri = router.routerDelegate.currentConfiguration.uri;
    if (Routes.restorable.contains(uri.path)) {
      ref.read(localStorageServiceProvider).writeLastRoute(uri.toString());
    }
  }

  router.routerDelegate.addListener(persistCurrentRoute);
  ref.onDispose(() => router.routerDelegate.removeListener(persistCurrentRoute));

  return router;
});
