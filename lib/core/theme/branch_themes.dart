import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/branch_id.dart';
import '../design/app_colors.dart';
import 'branch_theme_extension.dart';

const BranchTheme armyBranchTheme = BranchTheme(
  branch: BranchId.army,
  primary: AppColors.armyPrimary,
  onPrimary: Colors.white,
  accent: AppColors.armyPrimary,
  bright: AppColors.armyBright,
  surfaceTint: Color(0xFFE8EFE7),
  ghostModelBg: Color(0xFFF2F5F1),
  rankInsigniaTint: Color(0xFFCBA135),
);

const BranchTheme navyBranchTheme = BranchTheme(
  branch: BranchId.navy,
  primary: AppColors.navyPrimary,
  onPrimary: Colors.white,
  accent: AppColors.navyPrimary,
  bright: AppColors.navyBright,
  surfaceTint: Color(0xFFE3E7EE),
  ghostModelBg: Color(0xFFEDF1F6),
  rankInsigniaTint: Color(0xFFC8A24B),
);

const BranchTheme rsafBranchTheme = BranchTheme(
  branch: BranchId.rsaf,
  primary: AppColors.rsafPrimary,
  onPrimary: Colors.white,
  accent: AppColors.rsafPrimary,
  bright: AppColors.rsafBright,
  surfaceTint: Color(0xFFE6F0FA),
  ghostModelBg: Color(0xFFF1F7FD),
  rankInsigniaTint: Color(0xFFD4D9DD),
);

const BranchTheme disBranchTheme = BranchTheme(
  branch: BranchId.dis,
  primary: AppColors.disPrimary,
  onPrimary: Colors.white,
  accent: AppColors.disPrimary,
  bright: AppColors.disBright,
  surfaceTint: Color(0xFFEDEEEF),
  ghostModelBg: Color(0xFFF3F4F5),
  rankInsigniaTint: Color(0xFFB6BCC4),
);

BranchTheme branchThemeFor(BranchId branch) {
  return switch (branch) {
    BranchId.army => armyBranchTheme,
    BranchId.navy => navyBranchTheme,
    BranchId.rsaf => rsafBranchTheme,
    BranchId.dis => disBranchTheme,
  };
}
