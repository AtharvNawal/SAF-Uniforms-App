import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle mono({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing = 1.7,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Eyebrow: small mono uppercase wide-spaced — "h-eyebrow"
  static TextStyle eyebrow({Color color = AppColors.inkMuted}) => mono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 2.2,
      );

  // Title: 26px semibold tight tracking — "h-title"
  static TextStyle title({Color color = AppColors.ink, double fontSize = 26}) =>
      dmSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.15,
        letterSpacing: -0.5,
      );

  // Subtitle: 14px regular — "h-sub"
  static TextStyle subtitle({Color color = AppColors.inkMuted}) => dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  // Body / general
  static TextStyle body({Color color = AppColors.ink, double fontSize = 13}) =>
      dmSans(fontSize: fontSize, fontWeight: FontWeight.w400, color: color);

  // Body strong
  static TextStyle bodyStrong({Color color = AppColors.ink, double fontSize = 14}) =>
      dmSans(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);

  // Field label — mono uppercase 11px wide
  static TextStyle fieldLabel({Color color = AppColors.inkMuted}) =>
      mono(fontSize: 11, color: color, letterSpacing: 1.5);

  // Button
  static TextStyle button({Color color = AppColors.ink, double fontSize = 15}) =>
      dmSans(fontSize: fontSize, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.15);

  static TextTheme dmSansTextTheme(TextTheme base) =>
      GoogleFonts.dmSansTextTheme(base);
}
