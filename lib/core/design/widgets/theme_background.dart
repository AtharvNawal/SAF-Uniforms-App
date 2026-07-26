import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme_accent.dart';
import '../../theme/theme_accent_provider.dart';
import 'saf_crest_background.dart';
import 'topo_background.dart';

/// Theme-aware backdrop. Routes to:
/// - [TopoBackground] (the default branch-themed topographic wash) when
///   the user follows their service branch.
/// - [SafCrestBackground] (heraldic navy + gold sunburst) when the user
///   selected the SAF Crest theme.
///
/// Drop-in replacement for `TopoBackground` everywhere it appears in the
/// app, so picking the SAF Crest theme automatically swaps the backdrop
/// across every screen.
class ThemeBackground extends ConsumerWidget {
  const ThemeBackground({
    super.key,
    this.accentColor,
    this.opacity = 0.35,
    this.gradientCenter = const Alignment(0, -0.4),
  });

  final Color? accentColor;
  final double opacity;
  final Alignment gradientCenter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeAccentProvider);
    return switch (accent) {
      SafCrest() => SafCrestBackground(
          opacity: opacity * 0.8,
          gradientCenter: gradientCenter,
        ),
      FollowBranch() => TopoBackground(
          accentColor: accentColor,
          opacity: opacity,
          gradientCenter: gradientCenter,
        ),
    };
  }
}
