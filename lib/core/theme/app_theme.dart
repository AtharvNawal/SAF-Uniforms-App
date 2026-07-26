import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_text_styles.dart';
import 'branch_theme_extension.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light(BranchTheme ext) =>
      _buildBranchThemeData(ext, Brightness.light);

  static ThemeData dark(BranchTheme ext) =>
      _buildBranchThemeData(ext, Brightness.dark);
}

ThemeData _buildBranchThemeData(BranchTheme ext, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: ext.primary,
    brightness: brightness,
  ).copyWith(
    primary: ext.primary,
    secondary: ext.bright,
    onPrimary: ext.onPrimary,
    surface: isDark ? AppColors.charcoal : AppColors.surface,
    onSurface: isDark ? AppColors.ink : AppColors.inkDark,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppColors.charcoal : AppColors.surface,
    extensions: <ThemeExtension<dynamic>>[ext],
  );

  return base.copyWith(
    textTheme: AppTextStyles.dmSansTextTheme(base.textTheme).apply(
      bodyColor: isDark ? AppColors.ink : AppColors.inkDark,
      displayColor: isDark ? AppColors.ink : AppColors.inkDark,
    ),
    primaryTextTheme: AppTextStyles.dmSansTextTheme(base.primaryTextTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: isDark ? AppColors.ink : AppColors.inkDark,
      elevation: 0,
      titleTextStyle: AppTextStyles.bodyStrong(
        color: isDark ? AppColors.ink : AppColors.inkDark,
      ),
    ),
    iconTheme: IconThemeData(
      color: isDark ? AppColors.ink : AppColors.inkDark,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
