import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/branch_theme_extension.dart';
import '../app_colors.dart';

/// Reusable SAF crest logo. Used at 132 px on the Welcome screen
/// (with glow) and at 26 px in the Dashboard app bar (no glow).
///
/// The crest itself is rendered from `assets/branding/saf_crest.svg`
/// — sharp at every DPI without per-density PNG rasters.
class SafCrestLogo extends StatelessWidget {
  const SafCrestLogo({
    super.key,
    required this.size,
    this.withGlow = false,
    this.accentColor,
  });

  final double size;

  /// When true, wraps the crest in a circular radial-gradient halo
  /// matching the existing welcome-screen affordance. Defaults to false
  /// for compact in-bar usage.
  final bool withGlow;

  /// Glow tint. Falls back to `context.branchTheme.bright` so the halo
  /// inherits the active theme's accent (army green / navy blue / SAF navy / …).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final crest = SvgPicture.asset(
      'assets/branding/saf_crest.svg',
      width: size,
      height: size,
      semanticsLabel: 'SAF crest',
    );

    if (!withGlow) {
      return SizedBox(width: size, height: size, child: crest);
    }

    final accent = accentColor ?? context.branchTheme.bright;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 0.6,
          colors: [accent.withValues(alpha: 0.45), Colors.transparent],
        ),
        border: Border.all(color: AppColors.lineStrong, width: 1),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.7,
        height: size * 0.7,
        child: crest,
      ),
    );
  }
}
