import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/branch_id.dart';
import 'branch_theme_extension.dart';

/// Palette tokens sourced directly from the SAF Crest itself. The dominant
/// brand colours are the crest navy and the laurel-wreath gold; the shield
/// red is reserved as a subtle alarm/highlight tint and isn't exposed
/// directly on `BranchTheme`.
const Color safCrestNavy = Color(0xFF000080); // outer ring + banner
const Color safCrestGold = Color(0xFFFFCC00); // wreath, lions, text
const Color safCrestGoldDeep = Color(0xFFD4A017); // deeper gold for surfaces
const Color safCrestRed = Color(0xFFED2939); // shield red (reserved accent)

const Color _safNavyLight = Color(0xFF3A3AB8); // dark-mode primary
const Color _safNavyDeep = Color(0xFF0A0A1F); // deepest navy for dark surface
const Color _safCream = Color(0xFFFAF6E8); // pale cream wash for light surfaces

/// Light variant of the SAF Crest theme.
///
/// `bright` is set to **gold** rather than a lifted navy so chips, active
/// tiles, and the welcome-screen glow render in the crest's signature
/// gold-on-navy palette. `branch: BranchId.army` is a no-op placeholder —
/// `BranchTheme.branch` is only consulted by the theme system (for `lerp`).
const BranchTheme safCrestBranchTheme = BranchTheme(
  branch: BranchId.army,
  primary: safCrestNavy,
  onPrimary: Colors.white,
  accent: safCrestGold,
  bright: safCrestGold,
  surfaceTint: _safCream,
  ghostModelBg: Color(0xFFFFFDF2),
  rankInsigniaTint: safCrestGoldDeep,
);

/// Dark variant — pure `#000080` collapses against `AppColors.charcoal`,
/// so the primary is lifted. Gold reads beautifully on dark navy and stays
/// the dominant accent.
const BranchTheme safCrestBranchThemeDark = BranchTheme(
  branch: BranchId.army,
  primary: _safNavyLight,
  onPrimary: Colors.white,
  accent: safCrestGold,
  bright: safCrestGold,
  surfaceTint: _safNavyDeep,
  ghostModelBg: _safNavyDeep,
  rankInsigniaTint: safCrestGold,
);
