class Routes {
  const Routes._();

  static const String welcome = '/';
  static const String dashboard = '/dashboard';
  static const String config = '/config';
  static const String ghostModel = '/ghost-model';
  static const String wearing = '/wearing';
  static const String ar = '/ar';
  static const String generating = '/generating';
  static const String rebuilding = '/rebuilding';
  static const String dressAccessories = '/dress-accessories';
  static const String galleryViewer = '/gallery/viewer';

  // Reserved (legacy) — keep `home` and `profile` aliases for callers
  // still using the old names (none in the app today, but the constants
  // are referenced by the prior placeholder).
  static const String home = welcome;
  static const String profile = dashboard;

  /// Routes safe to cold-restore a returning user into — see
  /// `ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md`.
  /// Deliberately excludes: [welcome] (it's the default landing spot
  /// anyway); [generating]/[rebuilding] (transient, animation-driven
  /// screens that auto-navigate onward on their own — resuming directly
  /// into one mid-transition isn't a meaningful "resume point"); and
  /// [galleryViewer] (requires a typed `state.extra` record that can't
  /// be reconstructed from a persisted URL string alone — restoring
  /// into it would crash on the type cast in its `GoRoute` builder).
  static const Set<String> restorable = {
    dashboard,
    config,
    ghostModel,
    wearing,
    ar,
    '/checklist',
    dressAccessories,
  };

  /// Resolves a persisted last-route string (or `null`) to the route
  /// `WelcomeScreen` should send a returning user to, re-validating
  /// against [restorable] at restore time (not just at persist time) —
  /// defensive against a stale value left over from an older app
  /// version where the allowlist may have been different, or plain
  /// corruption. Falls back to [dashboard], the pre-fix default.
  static String resolveRestoreTarget(String? lastRoute) {
    if (lastRoute == null) return dashboard;
    final path = Uri.tryParse(lastRoute)?.path;
    if (path == null || !restorable.contains(path)) return dashboard;
    return lastRoute;
  }
}
