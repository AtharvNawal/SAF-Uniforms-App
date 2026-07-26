// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SAF Uniforms';

  @override
  String get branchArmy => 'Army';

  @override
  String get branchNavy => 'Navy';

  @override
  String get branchRsaf => 'RSAF';

  @override
  String get branchDis => 'DIS';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonGotIt => 'Got it · Mark verified';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSetup => 'Setup';

  @override
  String get commonSave => 'Save';

  @override
  String get commonUpdate => 'Update';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSoldier => 'Soldier';

  @override
  String get commonDone => 'Done';

  @override
  String get welcomeEyebrow => 'SAF Dress Compliance';

  @override
  String get welcomeTitleLine1 => 'Precision in';

  @override
  String get welcomeTitleLine2 => 'every detail.';

  @override
  String get welcomeSubtitle =>
      'Your personalised guide to SAF Dress compliance — built from the master regulation, calibrated to the centimetre.';

  @override
  String get welcomeGetStarted => 'Get Started';

  @override
  String get configHeaderConfiguration => 'Configuration';

  @override
  String get configStep01 => 'Service';

  @override
  String get configStep02 => 'Identity';

  @override
  String get configStep03 => 'Rank · Vocation';

  @override
  String get configStep04 => 'Accoutrements';

  @override
  String configStepFormat(String current, String total) {
    return 'Step $current / $total';
  }

  @override
  String get configStep1Title => 'Pick your service.';

  @override
  String get configStep1Subtitle =>
      'Determines accent colour and rule set. Army uses 3 cm collar logic; Navy/RSAF/DIS use 1 cm.';

  @override
  String get configStep1WhyTitle => 'Why this matters';

  @override
  String get configStep1WhyBody =>
      'Army collar rank insignias are worn 3 cm from the collar edge. Navy uses 1 cm. The whole UI re-themes accordingly.';

  @override
  String get configStep2Title => 'Identity.';

  @override
  String get configStep2Subtitle =>
      'Sikh personnel wear a turban with red fifti instead of a beret.';

  @override
  String get configStandardSikh => 'Standard / Sikh';

  @override
  String get configStandard => 'Standard';

  @override
  String get configSikhPersonnel => 'Sikh Personnel';

  @override
  String get configSexBuild => 'Sex / Build';

  @override
  String get configIdentityMen => 'Men';

  @override
  String get configIdentityLadies => 'Ladies';

  @override
  String get configIdentityMaternity => 'Maternity';

  @override
  String get configSikhRuleEyebrow => 'Sikh Personnel · Headdress Rule';

  @override
  String get configSikhRuleBody =>
      'Sikh personnel wear a turban of the same colour instead of beret. COL/ME7 and above wear a red band on the turban.';

  @override
  String get configStep3Title => 'Rank & vocation.';

  @override
  String get configStep3Subtitle =>
      'Determines collar pins, cap badge variant, and turban embellishment for Sikh personnel.';

  @override
  String get configFieldRank => 'Rank';

  @override
  String get configFieldVocation => 'Vocation';

  @override
  String get configFieldName => 'Name';

  @override
  String get configNamePlaceholder => 'Surname';

  @override
  String get configAutoAppliedEyebrow => 'Auto-applied';

  @override
  String get configAutoAppliedBody =>
      'White turban with black fifti will be rendered (Navy 3WO/ME3 and above).';

  @override
  String get configStep4Title => 'Accoutrements.';

  @override
  String get configStep4Subtitle =>
      'Medal placement adjusts automatically — 3 or more rows shifts SAF badges to 1 cm above ribbons.';

  @override
  String configMedalRows(int count) {
    return 'Medal ribbon rows · $count';
  }

  @override
  String get configAutoRuleApplied =>
      'Auto-rule applied. SAF badges will be rendered 1 cm above ribbons (instead of 3 cm above pocket).';

  @override
  String get configBadgesLabel => 'SAF Badges (max 3)';

  @override
  String get configBadgesExclusion =>
      'Mutual exclusion: Marksmanship · Sniper · Fitness Specialist';

  @override
  String get configBuildGhost => 'Build Ghost Model';

  @override
  String get dashHomeQuickActions => 'Quick actions';

  @override
  String get dashHomeActionAr => 'AR Scan';

  @override
  String get dashHomeActionMeasure => 'Measure';

  @override
  String get dashHomeActionInspect => 'Inspect';

  @override
  String get dashSetupRequired => 'SETUP REQUIRED';

  @override
  String get dashSetupTitle1 => 'Set up your';

  @override
  String get dashSetupTitle2 => 'uniform profile';

  @override
  String get dashSetupBody =>
      'Tell us your service, identity, rank and accoutrements so we can render your personalised No. 3 Dress models.';

  @override
  String get dashSetupStep1 => 'Service';

  @override
  String get dashSetupStep2 => 'Identity';

  @override
  String get dashSetupStep3 => 'Rank';

  @override
  String get dashSetupStep4 => 'Badges';

  @override
  String get dressNo1Code => 'No. 1';

  @override
  String get dressNo2Code => 'No. 2';

  @override
  String get dressNo3Code => 'No. 3';

  @override
  String get dressNo4Code => 'No. 4';

  @override
  String get dressNo5Code => 'No. 5';

  @override
  String get dressNo1Name => 'Ceremonial';

  @override
  String get dressNo2Name => 'Mess Dress';

  @override
  String get dressNo3Name => 'Service Dress';

  @override
  String get dressNo4Name => 'Smart No. 4';

  @override
  String get dressNo5Name => 'Field / Combat';

  @override
  String get dressNo1Tag => 'White ceremonial · Officers';

  @override
  String get dressNo2Tag => 'Formal evening · Officers';

  @override
  String get dressNo3Tag => 'Office / parades · Daily';

  @override
  String get dressNo4Tag => 'Working · long sleeve';

  @override
  String get dressNo5Tag => 'Operations · combat';

  @override
  String get dressStateReady => '● READY';

  @override
  String get dressStateGenerating => '◐ GENERATING';

  @override
  String get dressStateNotBuilt => '○ NOT BUILT';

  @override
  String get dressStateBuilding => '◐ BUILDING';

  @override
  String get dressBadgeRecommended => 'Recommended';

  @override
  String get dressBadge3D => '3D';

  @override
  String get dressView => 'View';

  @override
  String get dressAccessoriesBuildBtn => 'Build my Dress';

  @override
  String get dressAccessoriesDialogTitle => 'Mandatory accessories incomplete';

  @override
  String get dressAccessoriesDialogBody =>
      'Not all mandatory accessories have been selected. You can build now with what you\'ve selected, or go back to complete the checklist.';

  @override
  String get dressAccessoriesDialogClose => 'Close';

  @override
  String get dressAccessoriesDialogBuild => 'Build My Dress';

  @override
  String get navHome => 'Home';

  @override
  String get navWardrobe => 'Wardrobe';

  @override
  String get navGallery => 'Gallery';

  @override
  String get navProfile => 'Profile';

  @override
  String get checklistVerified => 'VERIFIED';

  @override
  String get checklistTapToView => 'Tap to view placement';

  @override
  String get checklistVerifiedPrefix => 'VERIFIED ·';

  @override
  String checklistVerifyMore(int count) {
    return 'Verify $count more to continue';
  }

  @override
  String get checklistAllVerified => 'All Verified — Continue';

  @override
  String get checklistVerbatimManual => 'Verbatim from manual';

  @override
  String get checklistDressCode => 'Dress code';

  @override
  String get checklistDressAll => 'All Accessories';

  @override
  String get checklistDressAllDesc => 'Show everything';

  @override
  String get checklistDressNo1Desc => 'White ceremonial · Officers';

  @override
  String get checklistDressNo2Desc => 'Formal evening · Officers';

  @override
  String get checklistDressNo3Desc => 'Office / parades · Daily';

  @override
  String get checklistDressNo4Desc => 'Working · long sleeve';

  @override
  String get checklistDressNo5Desc => 'Operations · combat';

  @override
  String get accCollarTitle => 'Collar Rank Insignias';

  @override
  String get accCollarMono => '3 cm';

  @override
  String get accCollarBody =>
      'Worn centrally on each side of the collar with the base of the rank insignia 3 cm away from the collar edge.';

  @override
  String get accCollarRef => 'Picture C-1';

  @override
  String get accBadgesTitle => 'SAF Badges';

  @override
  String get accBadgesMono => '1 cm above';

  @override
  String get accBadgesBody =>
      'When three or more rows of medal ribbons are worn, badges are placed 1 cm above the top edge of the ribbons. Otherwise, 3 cm above the pocket.';

  @override
  String get accBadgesRef => 'Picture D-10';

  @override
  String get accMedalsTitle => 'Medal Ribbons';

  @override
  String get accMedalsMono => '— pocket edge';

  @override
  String get accMedalsBody =>
      'For men, medal ribbons are worn centred, immediately above and parallel to the top edge of the left chest pocket.';

  @override
  String get accMedalsRef => 'Picture D-3';

  @override
  String get accNameTitle => 'Name Tag';

  @override
  String get accNameMono => '— pocket edge';

  @override
  String get accNameBody =>
      'Men: centred immediately above and parallel to the top edge of the right chest pocket. Ladies: between 2nd and 3rd buttons.';

  @override
  String get accNameRef => 'Picture C-6';

  @override
  String get accBeltTitle => 'Nylon Belt';

  @override
  String get accBeltMono => 'centred';

  @override
  String get accBeltBody =>
      'Buckle centred to the trousers slit opening and shirt button line. Metal end shown immediately next to the edge of the buckle.';

  @override
  String get accBeltRef => 'Picture C-8';

  @override
  String get accLanyardTitle => 'Lanyard';

  @override
  String get accLanyardMono => '8 – 12 cm';

  @override
  String get accLanyardBody =>
      'Lanyard knot must sit between 8 cm and 12 cm from the armpit on the right shoulder.';

  @override
  String get accLanyardRef => 'Picture C-9';

  @override
  String get ghostBack => 'Checklist';

  @override
  String get ghostChip => 'Ghost Model';

  @override
  String get ghostStepReference => 'Step 04 · Reference';

  @override
  String get ghostFront => 'Front';

  @override
  String get ghostBackView => 'Back';

  @override
  String get ghostTapBack => '↺ Tap Back to rotate';

  @override
  String get ghostTapFront => '↺ Tap Front to rotate';

  @override
  String get ghostStartArScan => 'Start AR Scan';

  @override
  String get ghostStartWearing => 'Start Wearing';

  @override
  String get ghostBadgeRule3cm => 'Tap any pin · 3 cm badge rule active';

  @override
  String get ghostBadgeRule1cm => 'Tap any pin · 1 cm badge rule active';

  @override
  String get ghostBackViewNoHotspots => 'Back view · no hotspots';

  @override
  String get wearingBack => '3D Model';

  @override
  String get wearingChip => 'Wearing Guide';

  @override
  String wearingStepFormat(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get wearingNowWearing => 'NOW WEARING';

  @override
  String get wearingReplay => 'Replay';

  @override
  String wearingNextLabel(String next) {
    return 'Next · $next';
  }

  @override
  String get wearingFinish => 'Finish';

  @override
  String get wearingPrev => 'Prev';

  @override
  String get wearingCompleteEyebrow => 'Wearing Guide Complete';

  @override
  String get wearingCompleteTitle => 'You\'re dressed!';

  @override
  String wearingCompleteBody(int count) {
    return 'All $count items worn correctly. Your uniform is ready for inspection.';
  }

  @override
  String get wearingProceedAr => 'Proceed to AR Scan';

  @override
  String get wearingRestart => 'Restart Guide';

  @override
  String get wearingStepTrousers => 'No. 3 Trousers';

  @override
  String get wearingStepTrousersSub => 'Bottom · Start here';

  @override
  String get wearingStepTrousersTip =>
      'Sharp centre crease · waistband at natural waist';

  @override
  String get wearingStepShirt => 'No. 3 Service Shirt';

  @override
  String get wearingStepShirtSub => 'Base layer';

  @override
  String get wearingStepShirtTip =>
      'Tuck firm · shirt-front aligned to trouser slit';

  @override
  String get wearingStepBelt => 'Nylon Belt';

  @override
  String get wearingStepBeltSub => 'Centred to slit';

  @override
  String get wearingStepBeltTip =>
      'Buckle centred to slit · metal end flush to edge';

  @override
  String get wearingStepMedals => 'Medal Ribbons';

  @override
  String get wearingStepMedalsSub => 'Left chest pocket';

  @override
  String get wearingStepMedalsTip =>
      'Centred above left pocket · rows flush and even';

  @override
  String get wearingStepBadges => 'SAF Badges';

  @override
  String get wearingStepBadgesSub => '1 cm above ribbons';

  @override
  String get wearingStepBadgesTip =>
      '1 cm above ribbons (3+ rows) · 3 cm above pocket otherwise';

  @override
  String get wearingStepNametag => 'Name Tag';

  @override
  String get wearingStepNametagSub => 'Right chest pocket';

  @override
  String get wearingStepNametagTip =>
      'Centred above right pocket · perfectly level';

  @override
  String get wearingStepCollar => 'Collar Rank Insignias';

  @override
  String get wearingStepCollarSub => '3 cm from collar edge';

  @override
  String get wearingStepCollarTip =>
      '3 cm from collar edge · symmetrical both sides';

  @override
  String get wearingStepLanyard => 'Lanyard';

  @override
  String get wearingStepLanyardSub => 'Right shoulder';

  @override
  String get wearingStepLanyardTip =>
      'Knot 8–12 cm from armpit · right shoulder';

  @override
  String get wearingStepHeaddress => 'Headdress';

  @override
  String get wearingStepHeaddressSub => 'Final touch';

  @override
  String get wearingStepHeaddressTip =>
      'Beret tilted right · or turban with fifti';

  @override
  String get arClose => 'Close';

  @override
  String get arInfo => 'Info';

  @override
  String get arLive => 'AR · LIVE';

  @override
  String get arAligning => 'Aligning…';

  @override
  String get arAlignedTitle => 'Pose locked';

  @override
  String get arAligningSub => 'Stand 1.5 m from camera, face forward';

  @override
  String get arAlignedSub => 'Hold still — capturing in 3…';

  @override
  String get arRescan => 'Re-Scan';

  @override
  String get arShare => 'Share';

  @override
  String get arVerification => 'Verification · Scorecard';

  @override
  String get arCompliance => 'COMPLIANCE';

  @override
  String arRedAlerts(int count) {
    return 'Red Alerts · $count';
  }

  @override
  String arGreenChecks(int count) {
    return 'Green Checks · $count';
  }

  @override
  String get arMetaSvc => 'SVC';

  @override
  String get arMetaRnk => 'RNK';

  @override
  String get arMetaMed => 'MED';

  @override
  String get arMetaBdg => 'BDG';

  @override
  String get arIssue1Title => 'Name tag tilted';

  @override
  String get arIssue1Body =>
      'Detected ~3° rotation. Inspection threshold is 1°.';

  @override
  String get arIssue2Title => 'Beret angle off';

  @override
  String get arIssue2Body => 'Tilted left at ~12°. Should slope right at 22°.';

  @override
  String get arPass1 => 'Collar rank pins · 3 cm centred';

  @override
  String get arPass2 => 'Medal ribbons · level and flush';

  @override
  String get arPass3 => 'Lanyard knot · 10 cm from armpit';

  @override
  String get arPass4 => 'Belt buckle · centred to slit';

  @override
  String get generatingChip => 'BUILDING';

  @override
  String get generatingTitle => 'Building your Dress';

  @override
  String get generatingFooter =>
      'Calibrated to your profile · runs once per dress';

  @override
  String get generatingStage1 => 'Pulling profile…';

  @override
  String get generatingStage2 => 'Compositing geometry…';

  @override
  String get generatingStage3 => 'Applying ribbons & badges…';

  @override
  String get generatingStage4 => 'Rendering ghost mesh…';

  @override
  String get rebuildingEyebrow => 'Profile updated';

  @override
  String get rebuildingTitle => 'Rebuilding all models';

  @override
  String get rebuildingFooter => 'Calibrated to updated profile · runs once';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsMode => 'Mode';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get themeAccentSafCrest => 'SAF Crest';

  @override
  String get profileSection1 => 'Service Branch';

  @override
  String get profileSection2 => 'Identity';

  @override
  String get profileSection3 => 'Rank & Vocation';

  @override
  String get profileSection4 => 'Medals & Ribbons';

  @override
  String get profileSection5 => 'Badges & Qualifications';

  @override
  String get profileFieldBranch => 'Branch';

  @override
  String get profileFieldBuild => 'Build / cut';

  @override
  String get profileSikhToggle => 'Sikh personnel (turban exemption)';

  @override
  String get profileFieldRank => 'Rank';

  @override
  String get profileFieldVocation => 'Vocation';

  @override
  String get profileFieldMedalRows => 'Medal ribbon rows';

  @override
  String get profileFullName => 'Full name';

  @override
  String get profileMedalRowsLabel => 'ROWS';

  @override
  String get profileBadgesNote =>
      'Some badges are mutually exclusive — selecting one deselects incompatible awards.';

  @override
  String get profileUpdateRebuild => 'Update & Rebuild Models';

  @override
  String get profileUpToDate => 'PROFILE UP TO DATE';

  @override
  String get profileRebuildTitle => 'Rebuild 3D models?';

  @override
  String get profileRebuildSub => 'Profile changes need a fresh render';

  @override
  String get profileRebuildBody =>
      'Your updated profile will be saved and all dress models will be re-generated to reflect the changes. Existing models will be replaced.';

  @override
  String get profileRebuildConfirm => 'Confirm & Rebuild';

  @override
  String get galleryEyebrow => 'Photo Library';

  @override
  String get galleryTitle => 'Gallery';

  @override
  String get galleryUpload => 'Upload';

  @override
  String get galleryEmptyTitle => 'No photos yet';

  @override
  String get galleryEmptyBody => 'Tap Upload to add photos to your gallery';

  @override
  String get galleryUploadCta => 'Upload Photos';

  @override
  String get galleryDeleteTitle => 'Delete photo?';

  @override
  String get galleryDeleteBody => 'This cannot be undone';

  @override
  String get galleryDeleteConfirm => 'Delete';

  @override
  String galleryPhotoCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String galleryUploadProgress(int pct) {
    return 'Uploading… $pct%';
  }

  @override
  String get galleryUploadFailed => 'Upload failed. Please try again.';

  @override
  String get galleryDressCodeTag => 'Dress code';

  @override
  String get galleryFilterAll => 'All';

  @override
  String get galleryFromCamera => 'Camera';

  @override
  String get galleryFromLibrary => 'Photo Library';

  @override
  String get galleryPickSource => 'Add photo from…';

  @override
  String get galleryShareFailed => 'Could not share this photo.';

  @override
  String get wardrobeEyebrow => '3D Models';

  @override
  String get wardrobeTitle => 'Wardrobe';

  @override
  String get wardrobeStatReady => 'Ready';

  @override
  String get wardrobeStatBuilding => 'Building';

  @override
  String get wardrobeStatPending => 'Pending';

  @override
  String get wardrobeAllDresses => 'All dresses';

  @override
  String get wardrobeFilterAllChip => 'ALL';

  @override
  String wardrobeFilterDressSubtitle(String dressName) {
    return 'Show $dressName only';
  }

  @override
  String get wardrobeMandatoryChip => 'MANDATORY';

  @override
  String get wardrobeOptionalChip => 'OPTIONAL';

  @override
  String get wardrobeEmptyDress =>
      'No accessories required for this dress yet.';

  @override
  String get wardrobeEmptyPendingDoctrine => 'Pending doctrine review.';

  @override
  String get rankInsigniaSpecMarksman => 'Marksman';

  @override
  String get badgeIppt => 'IPPT Gold';

  @override
  String get badgeMarksmanship => 'Marksmanship';

  @override
  String get badgeSniper => 'Sniper';

  @override
  String get badgeFitness => 'Fitness Specialist';

  @override
  String get badgeAirborne => 'Airborne';

  @override
  String get badgeDive => 'Combat Diver';

  @override
  String get badgePilot => 'Pilot Wings';
}
