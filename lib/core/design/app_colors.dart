import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/branch_id.dart';

class AppColors {
  const AppColors._();

  // Surfaces (dark)
  static const Color charcoal = Color(0xFF16191C);
  static const Color charcoal2 = Color(0xFF1F2326);
  static const Color charcoal3 = Color(0xFF2A2F33);
  static const Color bg = Color(0xFF0B0D0E);

  // Lines / borders (dark)
  static const Color line = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color lineStrong = Color(0x2EFFFFFF); // rgba(255,255,255,0.18)

  // Text on dark
  static const Color ink = Color(0xFFFFFFFF);
  static const Color inkMuted = Color(0x8CFFFFFF); // 0.55
  static const Color inkSubtle = Color(0x66FFFFFF); // 0.40

  // Surfaces (light)
  static const Color surface = Color(0xFFF5F6F4);
  static const Color surface2 = Color(0xFFFFFFFF);
  static const Color inkDark = Color(0xFF0D1014);
  static const Color inkDark2 = Color(0xFF2C3138);
  static const Color mutedLight = Color(0xFF6B7480);
  static const Color lineLight = Color(0x140D1014);
  static const Color lineLightStrong = Color(0x290D1014);

  // Semantic
  static const Color ok = Color(0xFF5FBF6A);
  static const Color warn = Color(0xFFE8B042);
  static const Color err = Color(0xFFD8533F);

  // Service themes (primary + bright)
  static const Color armyPrimary = Color(0xFF3A5A3A);
  static const Color armyBright = Color(0xFF6A8F4D);
  static const Color navyPrimary = Color(0xFF14213D);
  static const Color navyBright = Color(0xFF3A6EA5);
  static const Color rsafPrimary = Color(0xFF2F7FBF);
  static const Color rsafBright = Color(0xFF7FC1EC);
  static const Color disPrimary = Color(0xFF4A4F55);
  static const Color disBright = Color(0xFF8A9099);
}

class ServicePalette {
  const ServicePalette({
    required this.primary,
    required this.bright,
    required this.collarRule,
  });

  final Color primary;
  final Color bright;
  final String collarRule;

  static const ServicePalette army = ServicePalette(
    primary: AppColors.armyPrimary,
    bright: AppColors.armyBright,
    collarRule: '3 cm collar',
  );
  static const ServicePalette navy = ServicePalette(
    primary: AppColors.navyPrimary,
    bright: AppColors.navyBright,
    collarRule: '1 cm collar',
  );
  static const ServicePalette rsaf = ServicePalette(
    primary: AppColors.rsafPrimary,
    bright: AppColors.rsafBright,
    collarRule: '1 cm collar',
  );
  static const ServicePalette dis = ServicePalette(
    primary: AppColors.disPrimary,
    bright: AppColors.disBright,
    collarRule: '1 cm collar',
  );

  static ServicePalette of(BranchId branch) => switch (branch) {
        BranchId.army => army,
        BranchId.navy => navy,
        BranchId.rsaf => rsaf,
        BranchId.dis => dis,
      };

  static String tagOf(BranchId branch) => switch (branch) {
        BranchId.army => 'SAF',
        BranchId.navy => 'RSN',
        BranchId.rsaf => 'RSAF',
        BranchId.dis => 'DIS',
      };

  static String labelOf(BranchId branch) => switch (branch) {
        BranchId.army => 'Army',
        BranchId.navy => 'Navy',
        BranchId.rsaf => 'RSAF',
        BranchId.dis => 'DIS',
      };
}
