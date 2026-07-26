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
}
