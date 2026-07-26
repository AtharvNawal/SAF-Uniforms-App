import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/uniform_provider.dart';
import 'branch_theme_extension.dart';
import 'branch_themes.dart';
import 'saf_crest_theme.dart';
import 'theme_accent.dart';
import 'theme_accent_provider.dart';

/// Light + dark `BranchTheme` pair to feed `MaterialApp.theme` /
/// `darkTheme`. Resolved from the user's `ThemeAccent` selection:
///
/// - `FollowBranch()` → both variants are `branchThemeFor(currentBranch)`.
///   Mirrors today's behaviour where `_buildBranchThemeData` switches
///   surface colors based on `Brightness`.
/// - `SafCrest()` → returns the tuned light/dark SAF Crest themes
///   (`#000080` is too dark on dark surfaces, so dark mode lifts the
///   primary; gold stays the same).
typedef ActiveBranchThemes = ({BranchTheme light, BranchTheme dark});

final activeBranchThemesProvider = Provider<ActiveBranchThemes>((ref) {
  final accent = ref.watch(themeAccentProvider);
  switch (accent) {
    case FollowBranch():
      final theme = branchThemeFor(ref.watch(currentBranchProvider));
      return (light: theme, dark: theme);
    case SafCrest():
      return (light: safCrestBranchTheme, dark: safCrestBranchThemeDark);
  }
});
