import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/branch_id.dart';
import '../../features/profile/domain/entities/dress_code.dart';
import '../../features/profile/domain/entities/gender.dart';
import 'generated/app_localizations.dart';

extension AppL10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension BranchIdL10n on BranchId {
  String label(AppLocalizations l) => switch (this) {
        BranchId.army => l.branchArmy,
        BranchId.navy => l.branchNavy,
        BranchId.rsaf => l.branchRsaf,
        BranchId.dis => l.branchDis,
      };
}

extension DressCodeL10n on DressCode {
  String code(AppLocalizations l) => switch (this) {
        DressCode.no1 => l.dressNo1Code,
        DressCode.no2 => l.dressNo2Code,
        DressCode.no3 => l.dressNo3Code,
        DressCode.no4 => l.dressNo4Code,
        DressCode.no5 => l.dressNo5Code,
      };

  String name(AppLocalizations l) => switch (this) {
        DressCode.no1 => l.dressNo1Name,
        DressCode.no2 => l.dressNo2Name,
        DressCode.no3 => l.dressNo3Name,
        DressCode.no4 => l.dressNo4Name,
        DressCode.no5 => l.dressNo5Name,
      };

  String tag(AppLocalizations l) => switch (this) {
        DressCode.no1 => l.dressNo1Tag,
        DressCode.no2 => l.dressNo2Tag,
        DressCode.no3 => l.dressNo3Tag,
        DressCode.no4 => l.dressNo4Tag,
        DressCode.no5 => l.dressNo5Tag,
      };
}

extension GenderL10n on Gender {
  String label(AppLocalizations l) => switch (this) {
        Gender.male => l.configIdentityMen,
        Gender.female => l.configIdentityLadies,
        Gender.maternity => l.configIdentityMaternity,
      };
}
