import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/branch_id.dart';

@immutable
class BranchTheme extends ThemeExtension<BranchTheme> {
  const BranchTheme({
    required this.branch,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.bright,
    required this.surfaceTint,
    required this.ghostModelBg,
    required this.rankInsigniaTint,
  });

  final BranchId branch;
  final Color primary;
  final Color onPrimary;
  final Color accent;

  /// Brighter shade used for active states / chips / highlights —
  /// matches the design's `--accent-bright` CSS variable.
  final Color bright;

  final Color surfaceTint;
  final Color ghostModelBg;
  final Color rankInsigniaTint;

  @override
  BranchTheme copyWith({
    BranchId? branch,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? bright,
    Color? surfaceTint,
    Color? ghostModelBg,
    Color? rankInsigniaTint,
  }) {
    return BranchTheme(
      branch: branch ?? this.branch,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      bright: bright ?? this.bright,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      ghostModelBg: ghostModelBg ?? this.ghostModelBg,
      rankInsigniaTint: rankInsigniaTint ?? this.rankInsigniaTint,
    );
  }

  @override
  BranchTheme lerp(ThemeExtension<BranchTheme>? other, double t) {
    if (other is! BranchTheme) return this;
    return BranchTheme(
      branch: t < 0.5 ? branch : other.branch,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      bright: Color.lerp(bright, other.bright, t)!,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      ghostModelBg: Color.lerp(ghostModelBg, other.ghostModelBg, t)!,
      rankInsigniaTint:
          Color.lerp(rankInsigniaTint, other.rankInsigniaTint, t)!,
    );
  }
}

/// Convenience accessor for the active branch theme.
extension BranchThemeContext on BuildContext {
  BranchTheme get branchTheme =>
      Theme.of(this).extension<BranchTheme>()!;
}
