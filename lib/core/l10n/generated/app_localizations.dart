import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SAF Uniforms'**
  String get appTitle;

  /// No description provided for @branchArmy.
  ///
  /// In en, this message translates to:
  /// **'Army'**
  String get branchArmy;

  /// No description provided for @branchNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get branchNavy;

  /// No description provided for @branchRsaf.
  ///
  /// In en, this message translates to:
  /// **'RSAF'**
  String get branchRsaf;

  /// No description provided for @branchDis.
  ///
  /// In en, this message translates to:
  /// **'DIS'**
  String get branchDis;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it · Mark verified'**
  String get commonGotIt;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get commonSetup;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSoldier.
  ///
  /// In en, this message translates to:
  /// **'Soldier'**
  String get commonSoldier;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SAF Dress Compliance'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeTitleLine1.
  ///
  /// In en, this message translates to:
  /// **'Precision in'**
  String get welcomeTitleLine1;

  /// No description provided for @welcomeTitleLine2.
  ///
  /// In en, this message translates to:
  /// **'every detail.'**
  String get welcomeTitleLine2;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personalised guide to SAF Dress compliance — built from the master regulation, calibrated to the centimetre.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get welcomeGetStarted;

  /// No description provided for @configSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your profile — check your connection and tap Done to try again'**
  String get configSaveFailed;

  /// No description provided for @configHeaderConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configHeaderConfiguration;

  /// No description provided for @configStep01.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get configStep01;

  /// No description provided for @configStep02.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get configStep02;

  /// No description provided for @configStep03.
  ///
  /// In en, this message translates to:
  /// **'Rank · Vocation'**
  String get configStep03;

  /// No description provided for @configStep04.
  ///
  /// In en, this message translates to:
  /// **'Accoutrements'**
  String get configStep04;

  /// No description provided for @configStepFormat.
  ///
  /// In en, this message translates to:
  /// **'Step {current} / {total}'**
  String configStepFormat(String current, String total);

  /// No description provided for @configStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Pick your service.'**
  String get configStep1Title;

  /// No description provided for @configStep1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Determines accent colour and rule set. Army uses 3 cm collar logic; Navy/RSAF/DIS use 1 cm.'**
  String get configStep1Subtitle;

  /// No description provided for @configStep1WhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this matters'**
  String get configStep1WhyTitle;

  /// No description provided for @configStep1WhyBody.
  ///
  /// In en, this message translates to:
  /// **'Army collar rank insignias are worn 3 cm from the collar edge. Navy uses 1 cm. The whole UI re-themes accordingly.'**
  String get configStep1WhyBody;

  /// No description provided for @configStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Identity.'**
  String get configStep2Title;

  /// No description provided for @configStep2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sikh personnel wear a turban with red fifti instead of a beret.'**
  String get configStep2Subtitle;

  /// No description provided for @configStandardSikh.
  ///
  /// In en, this message translates to:
  /// **'Standard / Sikh'**
  String get configStandardSikh;

  /// No description provided for @configStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get configStandard;

  /// No description provided for @configSikhPersonnel.
  ///
  /// In en, this message translates to:
  /// **'Sikh Personnel'**
  String get configSikhPersonnel;

  /// No description provided for @configSexBuild.
  ///
  /// In en, this message translates to:
  /// **'Sex / Build'**
  String get configSexBuild;

  /// No description provided for @configIdentityMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get configIdentityMen;

  /// No description provided for @configIdentityLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get configIdentityLadies;

  /// No description provided for @configIdentityMaternity.
  ///
  /// In en, this message translates to:
  /// **'Maternity'**
  String get configIdentityMaternity;

  /// No description provided for @configSikhRuleEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Sikh Personnel · Headdress Rule'**
  String get configSikhRuleEyebrow;

  /// No description provided for @configSikhRuleBody.
  ///
  /// In en, this message translates to:
  /// **'Sikh personnel wear a turban of the same colour instead of beret. COL/ME7 and above wear a red band on the turban.'**
  String get configSikhRuleBody;

  /// No description provided for @configStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Rank & vocation.'**
  String get configStep3Title;

  /// No description provided for @configStep3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Determines collar pins, cap badge variant, and turban embellishment for Sikh personnel.'**
  String get configStep3Subtitle;

  /// No description provided for @configFieldRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get configFieldRank;

  /// No description provided for @configFieldVocation.
  ///
  /// In en, this message translates to:
  /// **'Vocation'**
  String get configFieldVocation;

  /// No description provided for @configFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get configFieldName;

  /// No description provided for @configNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get configNamePlaceholder;

  /// No description provided for @configAutoAppliedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Auto-applied'**
  String get configAutoAppliedEyebrow;

  /// No description provided for @configAutoAppliedBody.
  ///
  /// In en, this message translates to:
  /// **'White turban with black fifti will be rendered (Navy 3WO/ME3 and above).'**
  String get configAutoAppliedBody;

  /// No description provided for @configStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Accoutrements.'**
  String get configStep4Title;

  /// No description provided for @configStep4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Medal placement adjusts automatically — 3 or more rows shifts SAF badges to 1 cm above ribbons.'**
  String get configStep4Subtitle;

  /// No description provided for @configMedalRows.
  ///
  /// In en, this message translates to:
  /// **'Medal ribbon rows · {count}'**
  String configMedalRows(int count);

  /// No description provided for @configAutoRuleApplied.
  ///
  /// In en, this message translates to:
  /// **'Auto-rule applied. SAF badges will be rendered 1 cm above ribbons (instead of 3 cm above pocket).'**
  String get configAutoRuleApplied;

  /// No description provided for @configBadgesLabel.
  ///
  /// In en, this message translates to:
  /// **'SAF Badges (max 3)'**
  String get configBadgesLabel;

  /// No description provided for @configBadgesExclusion.
  ///
  /// In en, this message translates to:
  /// **'Mutual exclusion: Marksmanship · Sniper · Fitness Specialist'**
  String get configBadgesExclusion;

  /// No description provided for @configBuildGhost.
  ///
  /// In en, this message translates to:
  /// **'Build Ghost Model'**
  String get configBuildGhost;

  /// No description provided for @dashHomeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashHomeQuickActions;

  /// No description provided for @dashHomeActionAr.
  ///
  /// In en, this message translates to:
  /// **'AR Scan'**
  String get dashHomeActionAr;

  /// No description provided for @dashHomeActionMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get dashHomeActionMeasure;

  /// No description provided for @dashHomeActionInspect.
  ///
  /// In en, this message translates to:
  /// **'Inspect'**
  String get dashHomeActionInspect;

  /// No description provided for @dashSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'SETUP REQUIRED'**
  String get dashSetupRequired;

  /// No description provided for @dashSetupTitle1.
  ///
  /// In en, this message translates to:
  /// **'Set up your'**
  String get dashSetupTitle1;

  /// No description provided for @dashSetupTitle2.
  ///
  /// In en, this message translates to:
  /// **'uniform profile'**
  String get dashSetupTitle2;

  /// No description provided for @dashSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us your service, identity, rank and accoutrements so we can render your personalised No. 3 Dress models.'**
  String get dashSetupBody;

  /// No description provided for @dashSetupStep1.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get dashSetupStep1;

  /// No description provided for @dashSetupStep2.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get dashSetupStep2;

  /// No description provided for @dashSetupStep3.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get dashSetupStep3;

  /// No description provided for @dashSetupStep4.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get dashSetupStep4;

  /// No description provided for @dressNo1Code.
  ///
  /// In en, this message translates to:
  /// **'No. 1'**
  String get dressNo1Code;

  /// No description provided for @dressNo2Code.
  ///
  /// In en, this message translates to:
  /// **'No. 2'**
  String get dressNo2Code;

  /// No description provided for @dressNo3Code.
  ///
  /// In en, this message translates to:
  /// **'No. 3'**
  String get dressNo3Code;

  /// No description provided for @dressNo4Code.
  ///
  /// In en, this message translates to:
  /// **'No. 4'**
  String get dressNo4Code;

  /// No description provided for @dressNo5Code.
  ///
  /// In en, this message translates to:
  /// **'No. 5'**
  String get dressNo5Code;

  /// No description provided for @dressNo1Name.
  ///
  /// In en, this message translates to:
  /// **'Ceremonial'**
  String get dressNo1Name;

  /// No description provided for @dressNo2Name.
  ///
  /// In en, this message translates to:
  /// **'Mess Dress'**
  String get dressNo2Name;

  /// No description provided for @dressNo3Name.
  ///
  /// In en, this message translates to:
  /// **'Service Dress'**
  String get dressNo3Name;

  /// No description provided for @dressNo4Name.
  ///
  /// In en, this message translates to:
  /// **'Smart No. 4'**
  String get dressNo4Name;

  /// No description provided for @dressNo5Name.
  ///
  /// In en, this message translates to:
  /// **'Field / Combat'**
  String get dressNo5Name;

  /// No description provided for @dressNo1Tag.
  ///
  /// In en, this message translates to:
  /// **'White ceremonial · Officers'**
  String get dressNo1Tag;

  /// No description provided for @dressNo2Tag.
  ///
  /// In en, this message translates to:
  /// **'Formal evening · Officers'**
  String get dressNo2Tag;

  /// No description provided for @dressNo3Tag.
  ///
  /// In en, this message translates to:
  /// **'Office / parades · Daily'**
  String get dressNo3Tag;

  /// No description provided for @dressNo4Tag.
  ///
  /// In en, this message translates to:
  /// **'Working · Pixelised'**
  String get dressNo4Tag;

  /// No description provided for @dressNo5Tag.
  ///
  /// In en, this message translates to:
  /// **'Operations · combat'**
  String get dressNo5Tag;

  /// No description provided for @dressStateReady.
  ///
  /// In en, this message translates to:
  /// **'● READY'**
  String get dressStateReady;

  /// No description provided for @dressStateGenerating.
  ///
  /// In en, this message translates to:
  /// **'◐ GENERATING'**
  String get dressStateGenerating;

  /// No description provided for @dressStateNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'○ NOT BUILT'**
  String get dressStateNotBuilt;

  /// No description provided for @dressStateBuilding.
  ///
  /// In en, this message translates to:
  /// **'◐ BUILDING'**
  String get dressStateBuilding;

  /// No description provided for @dressBadgeRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get dressBadgeRecommended;

  /// No description provided for @dressBadge3D.
  ///
  /// In en, this message translates to:
  /// **'3D'**
  String get dressBadge3D;

  /// No description provided for @dressView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get dressView;

  /// No description provided for @dressAccessoriesBuildBtn.
  ///
  /// In en, this message translates to:
  /// **'Build my Dress'**
  String get dressAccessoriesBuildBtn;

  /// No description provided for @dressAccessoriesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Mandatory accessories incomplete'**
  String get dressAccessoriesDialogTitle;

  /// No description provided for @dressAccessoriesDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Not all mandatory accessories have been selected. You can build now with what you\'ve selected, or go back to complete the checklist.'**
  String get dressAccessoriesDialogBody;

  /// No description provided for @dressAccessoriesDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dressAccessoriesDialogClose;

  /// No description provided for @dressAccessoriesDialogBuild.
  ///
  /// In en, this message translates to:
  /// **'Build My Dress'**
  String get dressAccessoriesDialogBuild;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get navWardrobe;

  /// No description provided for @navGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get navGallery;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @checklistVerified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get checklistVerified;

  /// No description provided for @checklistTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view placement'**
  String get checklistTapToView;

  /// No description provided for @checklistVerifiedPrefix.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED ·'**
  String get checklistVerifiedPrefix;

  /// No description provided for @checklistVerifyMore.
  ///
  /// In en, this message translates to:
  /// **'Verify {count} more to continue'**
  String checklistVerifyMore(int count);

  /// No description provided for @checklistAllVerified.
  ///
  /// In en, this message translates to:
  /// **'All Verified — Continue'**
  String get checklistAllVerified;

  /// No description provided for @checklistVerbatimManual.
  ///
  /// In en, this message translates to:
  /// **'Verbatim from manual'**
  String get checklistVerbatimManual;

  /// No description provided for @checklistDressCode.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get checklistDressCode;

  /// No description provided for @checklistDressAll.
  ///
  /// In en, this message translates to:
  /// **'All Accessories'**
  String get checklistDressAll;

  /// No description provided for @checklistDressAllDesc.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get checklistDressAllDesc;

  /// No description provided for @checklistDressNo1Desc.
  ///
  /// In en, this message translates to:
  /// **'White ceremonial · Officers'**
  String get checklistDressNo1Desc;

  /// No description provided for @checklistDressNo2Desc.
  ///
  /// In en, this message translates to:
  /// **'Formal evening · Officers'**
  String get checklistDressNo2Desc;

  /// No description provided for @checklistDressNo3Desc.
  ///
  /// In en, this message translates to:
  /// **'Office / parades · Daily'**
  String get checklistDressNo3Desc;

  /// No description provided for @checklistDressNo4Desc.
  ///
  /// In en, this message translates to:
  /// **'Working · Pixelised'**
  String get checklistDressNo4Desc;

  /// No description provided for @checklistDressNo5Desc.
  ///
  /// In en, this message translates to:
  /// **'Operations · combat'**
  String get checklistDressNo5Desc;

  /// No description provided for @accCollarTitle.
  ///
  /// In en, this message translates to:
  /// **'Collar Rank Insignias'**
  String get accCollarTitle;

  /// No description provided for @accCollarMono.
  ///
  /// In en, this message translates to:
  /// **'3 cm'**
  String get accCollarMono;

  /// No description provided for @accCollarBody.
  ///
  /// In en, this message translates to:
  /// **'Worn centrally on each side of the collar with the base of the rank insignia 3 cm away from the collar edge.'**
  String get accCollarBody;

  /// No description provided for @accCollarRef.
  ///
  /// In en, this message translates to:
  /// **'Picture C-1'**
  String get accCollarRef;

  /// No description provided for @accBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'SAF Badges'**
  String get accBadgesTitle;

  /// No description provided for @accBadgesMono.
  ///
  /// In en, this message translates to:
  /// **'1 cm above'**
  String get accBadgesMono;

  /// No description provided for @accBadgesBody.
  ///
  /// In en, this message translates to:
  /// **'When three or more rows of medal ribbons are worn, badges are placed 1 cm above the top edge of the ribbons. Otherwise, 3 cm above the pocket.'**
  String get accBadgesBody;

  /// No description provided for @accBadgesRef.
  ///
  /// In en, this message translates to:
  /// **'Picture D-10'**
  String get accBadgesRef;

  /// No description provided for @accMedalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medal Ribbons'**
  String get accMedalsTitle;

  /// No description provided for @accMedalsMono.
  ///
  /// In en, this message translates to:
  /// **'— pocket edge'**
  String get accMedalsMono;

  /// No description provided for @accMedalsBody.
  ///
  /// In en, this message translates to:
  /// **'For men, medal ribbons are worn centred, immediately above and parallel to the top edge of the left chest pocket.'**
  String get accMedalsBody;

  /// No description provided for @accMedalsRef.
  ///
  /// In en, this message translates to:
  /// **'Picture D-3'**
  String get accMedalsRef;

  /// No description provided for @accNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Tag'**
  String get accNameTitle;

  /// No description provided for @accNameMono.
  ///
  /// In en, this message translates to:
  /// **'— pocket edge'**
  String get accNameMono;

  /// No description provided for @accNameBody.
  ///
  /// In en, this message translates to:
  /// **'Men: centred immediately above and parallel to the top edge of the right chest pocket. Ladies: between 2nd and 3rd buttons.'**
  String get accNameBody;

  /// No description provided for @accNameRef.
  ///
  /// In en, this message translates to:
  /// **'Picture C-6'**
  String get accNameRef;

  /// No description provided for @accBeltTitle.
  ///
  /// In en, this message translates to:
  /// **'Nylon Belt'**
  String get accBeltTitle;

  /// No description provided for @accBeltMono.
  ///
  /// In en, this message translates to:
  /// **'centred'**
  String get accBeltMono;

  /// No description provided for @accBeltBody.
  ///
  /// In en, this message translates to:
  /// **'Buckle centred to the trousers slit opening and shirt button line. Metal end shown immediately next to the edge of the buckle.'**
  String get accBeltBody;

  /// No description provided for @accBeltRef.
  ///
  /// In en, this message translates to:
  /// **'Picture C-8'**
  String get accBeltRef;

  /// No description provided for @accLanyardTitle.
  ///
  /// In en, this message translates to:
  /// **'Lanyard'**
  String get accLanyardTitle;

  /// No description provided for @accLanyardMono.
  ///
  /// In en, this message translates to:
  /// **'8 – 12 cm'**
  String get accLanyardMono;

  /// No description provided for @accLanyardBody.
  ///
  /// In en, this message translates to:
  /// **'Lanyard knot must sit between 8 cm and 12 cm from the armpit on the right shoulder.'**
  String get accLanyardBody;

  /// No description provided for @accLanyardRef.
  ///
  /// In en, this message translates to:
  /// **'Picture C-9'**
  String get accLanyardRef;

  /// No description provided for @ghostBack.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get ghostBack;

  /// No description provided for @ghostChip.
  ///
  /// In en, this message translates to:
  /// **'Ghost Model'**
  String get ghostChip;

  /// No description provided for @ghostStepReference.
  ///
  /// In en, this message translates to:
  /// **'Step 04 · Reference'**
  String get ghostStepReference;

  /// No description provided for @ghostFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get ghostFront;

  /// No description provided for @ghostBackView.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get ghostBackView;

  /// No description provided for @ghostTapBack.
  ///
  /// In en, this message translates to:
  /// **'↺ Tap Back to rotate'**
  String get ghostTapBack;

  /// No description provided for @ghostTapFront.
  ///
  /// In en, this message translates to:
  /// **'↺ Tap Front to rotate'**
  String get ghostTapFront;

  /// No description provided for @ghostStartArScan.
  ///
  /// In en, this message translates to:
  /// **'Start AR Scan'**
  String get ghostStartArScan;

  /// No description provided for @ghostStartWearing.
  ///
  /// In en, this message translates to:
  /// **'Start Wearing'**
  String get ghostStartWearing;

  /// No description provided for @ghostBadgeRule3cm.
  ///
  /// In en, this message translates to:
  /// **'Tap any pin · 3 cm badge rule active'**
  String get ghostBadgeRule3cm;

  /// No description provided for @ghostBadgeRule1cm.
  ///
  /// In en, this message translates to:
  /// **'Tap any pin · 1 cm badge rule active'**
  String get ghostBadgeRule1cm;

  /// No description provided for @ghostBackViewNoHotspots.
  ///
  /// In en, this message translates to:
  /// **'Back view · no hotspots'**
  String get ghostBackViewNoHotspots;

  /// No description provided for @wearingBack.
  ///
  /// In en, this message translates to:
  /// **'3D Model'**
  String get wearingBack;

  /// No description provided for @wearingChip.
  ///
  /// In en, this message translates to:
  /// **'Wearing Guide'**
  String get wearingChip;

  /// No description provided for @wearingStepFormat.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String wearingStepFormat(int current, int total);

  /// No description provided for @wearingNowWearing.
  ///
  /// In en, this message translates to:
  /// **'NOW WEARING'**
  String get wearingNowWearing;

  /// No description provided for @wearingReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get wearingReplay;

  /// No description provided for @wearingNextLabel.
  ///
  /// In en, this message translates to:
  /// **'Next · {next}'**
  String wearingNextLabel(String next);

  /// No description provided for @wearingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get wearingFinish;

  /// No description provided for @wearingPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get wearingPrev;

  /// No description provided for @wearingCompleteEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Wearing Guide Complete'**
  String get wearingCompleteEyebrow;

  /// No description provided for @wearingCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re dressed!'**
  String get wearingCompleteTitle;

  /// No description provided for @wearingCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'All {count} items worn correctly. Your uniform is ready for inspection.'**
  String wearingCompleteBody(int count);

  /// No description provided for @wearingProceedAr.
  ///
  /// In en, this message translates to:
  /// **'Proceed to AR Scan'**
  String get wearingProceedAr;

  /// No description provided for @wearingRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart Guide'**
  String get wearingRestart;

  /// No description provided for @wearingStepTrousers.
  ///
  /// In en, this message translates to:
  /// **'No. 3 Trousers'**
  String get wearingStepTrousers;

  /// No description provided for @wearingStepTrousersSub.
  ///
  /// In en, this message translates to:
  /// **'Bottom · Start here'**
  String get wearingStepTrousersSub;

  /// No description provided for @wearingStepTrousersTip.
  ///
  /// In en, this message translates to:
  /// **'Sharp centre crease · waistband at natural waist'**
  String get wearingStepTrousersTip;

  /// No description provided for @wearingStepShirt.
  ///
  /// In en, this message translates to:
  /// **'No. 3 Service Shirt'**
  String get wearingStepShirt;

  /// No description provided for @wearingStepShirtSub.
  ///
  /// In en, this message translates to:
  /// **'Base layer'**
  String get wearingStepShirtSub;

  /// No description provided for @wearingStepShirtTip.
  ///
  /// In en, this message translates to:
  /// **'Tuck firm · shirt-front aligned to trouser slit'**
  String get wearingStepShirtTip;

  /// No description provided for @wearingStepBelt.
  ///
  /// In en, this message translates to:
  /// **'Nylon Belt'**
  String get wearingStepBelt;

  /// No description provided for @wearingStepBeltSub.
  ///
  /// In en, this message translates to:
  /// **'Centred to slit'**
  String get wearingStepBeltSub;

  /// No description provided for @wearingStepBeltTip.
  ///
  /// In en, this message translates to:
  /// **'Buckle centred to slit · metal end flush to edge'**
  String get wearingStepBeltTip;

  /// No description provided for @wearingStepMedals.
  ///
  /// In en, this message translates to:
  /// **'Medal Ribbons'**
  String get wearingStepMedals;

  /// No description provided for @wearingStepMedalsSub.
  ///
  /// In en, this message translates to:
  /// **'Left chest pocket'**
  String get wearingStepMedalsSub;

  /// No description provided for @wearingStepMedalsTip.
  ///
  /// In en, this message translates to:
  /// **'Centred above left pocket · rows flush and even'**
  String get wearingStepMedalsTip;

  /// No description provided for @wearingStepBadges.
  ///
  /// In en, this message translates to:
  /// **'SAF Badges'**
  String get wearingStepBadges;

  /// No description provided for @wearingStepBadgesSub.
  ///
  /// In en, this message translates to:
  /// **'1 cm above ribbons'**
  String get wearingStepBadgesSub;

  /// No description provided for @wearingStepBadgesTip.
  ///
  /// In en, this message translates to:
  /// **'1 cm above ribbons (3+ rows) · 3 cm above pocket otherwise'**
  String get wearingStepBadgesTip;

  /// No description provided for @wearingStepNametag.
  ///
  /// In en, this message translates to:
  /// **'Name Tag'**
  String get wearingStepNametag;

  /// No description provided for @wearingStepNametagSub.
  ///
  /// In en, this message translates to:
  /// **'Right chest pocket'**
  String get wearingStepNametagSub;

  /// No description provided for @wearingStepNametagTip.
  ///
  /// In en, this message translates to:
  /// **'Centred above right pocket · perfectly level'**
  String get wearingStepNametagTip;

  /// No description provided for @wearingStepCollar.
  ///
  /// In en, this message translates to:
  /// **'Collar Rank Insignias'**
  String get wearingStepCollar;

  /// No description provided for @wearingStepCollarSub.
  ///
  /// In en, this message translates to:
  /// **'3 cm from collar edge'**
  String get wearingStepCollarSub;

  /// No description provided for @wearingStepCollarTip.
  ///
  /// In en, this message translates to:
  /// **'3 cm from collar edge · symmetrical both sides'**
  String get wearingStepCollarTip;

  /// No description provided for @wearingStepLanyard.
  ///
  /// In en, this message translates to:
  /// **'Lanyard'**
  String get wearingStepLanyard;

  /// No description provided for @wearingStepLanyardSub.
  ///
  /// In en, this message translates to:
  /// **'Right shoulder'**
  String get wearingStepLanyardSub;

  /// No description provided for @wearingStepLanyardTip.
  ///
  /// In en, this message translates to:
  /// **'Knot 8–12 cm from armpit · right shoulder'**
  String get wearingStepLanyardTip;

  /// No description provided for @wearingStepHeaddress.
  ///
  /// In en, this message translates to:
  /// **'Headdress'**
  String get wearingStepHeaddress;

  /// No description provided for @wearingStepHeaddressSub.
  ///
  /// In en, this message translates to:
  /// **'Final touch'**
  String get wearingStepHeaddressSub;

  /// No description provided for @wearingStepHeaddressTip.
  ///
  /// In en, this message translates to:
  /// **'Beret tilted right · or turban with fifti'**
  String get wearingStepHeaddressTip;

  /// No description provided for @arClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get arClose;

  /// No description provided for @arInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get arInfo;

  /// No description provided for @arLive.
  ///
  /// In en, this message translates to:
  /// **'AR · LIVE'**
  String get arLive;

  /// No description provided for @arAligning.
  ///
  /// In en, this message translates to:
  /// **'Aligning…'**
  String get arAligning;

  /// No description provided for @arAlignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Pose locked'**
  String get arAlignedTitle;

  /// No description provided for @arAligningSub.
  ///
  /// In en, this message translates to:
  /// **'Stand 1.5 m from camera, face forward'**
  String get arAligningSub;

  /// No description provided for @arAlignedSub.
  ///
  /// In en, this message translates to:
  /// **'Tap capture — we take 3 quick frames'**
  String get arAlignedSub;

  /// No description provided for @arHintNoPerson.
  ///
  /// In en, this message translates to:
  /// **'Step into the frame'**
  String get arHintNoPerson;

  /// No description provided for @arHintNotFullBody.
  ///
  /// In en, this message translates to:
  /// **'Show the whole body — head to feet'**
  String get arHintNotFullBody;

  /// No description provided for @arHintTooFar.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the camera'**
  String get arHintTooFar;

  /// No description provided for @arHintTooClose.
  ///
  /// In en, this message translates to:
  /// **'Step back — keep head and feet in frame'**
  String get arHintTooClose;

  /// No description provided for @arHintNotCentered.
  ///
  /// In en, this message translates to:
  /// **'Centre the person in the frame'**
  String get arHintNotCentered;

  /// No description provided for @arHintFacingAway.
  ///
  /// In en, this message translates to:
  /// **'Face the camera'**
  String get arHintFacingAway;

  /// No description provided for @arHintTurnedSideways.
  ///
  /// In en, this message translates to:
  /// **'Turn to face the camera square-on'**
  String get arHintTurnedSideways;

  /// No description provided for @arHintArmsRaised.
  ///
  /// In en, this message translates to:
  /// **'Relax your arms at your sides'**
  String get arHintArmsRaised;

  /// No description provided for @arHintPhoneTilted.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone upright and level'**
  String get arHintPhoneTilted;

  /// No description provided for @arHintHoldStill.
  ///
  /// In en, this message translates to:
  /// **'Hold still…'**
  String get arHintHoldStill;

  /// No description provided for @arHintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live guidance unavailable — check the framing yourself'**
  String get arHintUnavailable;

  /// No description provided for @cvServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis server'**
  String get cvServerTitle;

  /// No description provided for @cvServerHint.
  ///
  /// In en, this message translates to:
  /// **'Address of the laptop running the uniform-scan service.'**
  String get cvServerHint;

  /// No description provided for @cvServerSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get cvServerSave;

  /// No description provided for @cvServerUsb.
  ///
  /// In en, this message translates to:
  /// **'USB cable'**
  String get cvServerUsb;

  /// No description provided for @cvServerReset.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get cvServerReset;

  /// No description provided for @cvServerTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get cvServerTest;

  /// No description provided for @cvServerTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get cvServerTesting;

  /// No description provided for @cvServerOk.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get cvServerOk;

  /// No description provided for @cvServerFail.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach it'**
  String get cvServerFail;

  /// No description provided for @cvServerInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid address'**
  String get cvServerInvalid;

  /// No description provided for @cvServerUsbHelp.
  ///
  /// In en, this message translates to:
  /// **'USB cable: plug the phone into the laptop and run deploy/connect-phone-usb.sh there, then tap USB cable.'**
  String get cvServerUsbHelp;

  /// No description provided for @cvServerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cvServerSaved;

  /// No description provided for @arServerSettings.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get arServerSettings;

  /// No description provided for @arRescan.
  ///
  /// In en, this message translates to:
  /// **'Re-Scan'**
  String get arRescan;

  /// No description provided for @arShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get arShare;

  /// No description provided for @arVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification · Scorecard'**
  String get arVerification;

  /// No description provided for @arCompliance.
  ///
  /// In en, this message translates to:
  /// **'COMPLIANCE'**
  String get arCompliance;

  /// No description provided for @arRedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Red Alerts · {count}'**
  String arRedAlerts(int count);

  /// No description provided for @arGreenChecks.
  ///
  /// In en, this message translates to:
  /// **'Green Checks · {count}'**
  String arGreenChecks(int count);

  /// No description provided for @arMetaSvc.
  ///
  /// In en, this message translates to:
  /// **'SVC'**
  String get arMetaSvc;

  /// No description provided for @arMetaRnk.
  ///
  /// In en, this message translates to:
  /// **'RNK'**
  String get arMetaRnk;

  /// No description provided for @arMetaMed.
  ///
  /// In en, this message translates to:
  /// **'MED'**
  String get arMetaMed;

  /// No description provided for @arMetaBdg.
  ///
  /// In en, this message translates to:
  /// **'BDG'**
  String get arMetaBdg;

  /// No description provided for @arAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your photo…'**
  String get arAnalyzing;

  /// No description provided for @arAnalyzingSub.
  ///
  /// In en, this message translates to:
  /// **'Comparing against your expected accessories'**
  String get arAnalyzingSub;

  /// No description provided for @arCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete the check'**
  String get arCheckFailed;

  /// No description provided for @arCheckFailedSub.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get arCheckFailedSub;

  /// No description provided for @arErrorSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Still signing you in'**
  String get arErrorSignInTitle;

  /// No description provided for @arErrorSignInSub.
  ///
  /// In en, this message translates to:
  /// **'Please wait a moment and try again'**
  String get arErrorSignInSub;

  /// No description provided for @arErrorProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish your profile first'**
  String get arErrorProfileTitle;

  /// No description provided for @arErrorProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Complete Configuration before running a compliance check'**
  String get arErrorProfileSub;

  /// No description provided for @arErrorPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Something\'s wrong with that photo'**
  String get arErrorPhotoTitle;

  /// No description provided for @arErrorPhotoSub.
  ///
  /// In en, this message translates to:
  /// **'Please retake it and try again'**
  String get arErrorPhotoSub;

  /// No description provided for @arErrorConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get arErrorConnectionTitle;

  /// No description provided for @arErrorConnectionSub.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get arErrorConnectionSub;

  /// No description provided for @arErrorCvUnreachableSub.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the dev CV service — make sure it\'s running'**
  String get arErrorCvUnreachableSub;

  /// No description provided for @arErrorCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get arErrorCameraTitle;

  /// No description provided for @arErrorCameraSub.
  ///
  /// In en, this message translates to:
  /// **'Check camera permission in Settings and try again'**
  String get arErrorCameraSub;

  /// No description provided for @arRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get arRetry;

  /// No description provided for @arUncertainChecks.
  ///
  /// In en, this message translates to:
  /// **'Uncertain · {count}'**
  String arUncertainChecks(int count);

  /// No description provided for @generatingChip.
  ///
  /// In en, this message translates to:
  /// **'BUILDING'**
  String get generatingChip;

  /// No description provided for @generatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your Dress'**
  String get generatingTitle;

  /// No description provided for @generatingFooter.
  ///
  /// In en, this message translates to:
  /// **'Calibrated to your profile · runs once per dress'**
  String get generatingFooter;

  /// No description provided for @generatingStage1.
  ///
  /// In en, this message translates to:
  /// **'Pulling profile…'**
  String get generatingStage1;

  /// No description provided for @generatingStage2.
  ///
  /// In en, this message translates to:
  /// **'Compositing geometry…'**
  String get generatingStage2;

  /// No description provided for @generatingStage3.
  ///
  /// In en, this message translates to:
  /// **'Applying ribbons & badges…'**
  String get generatingStage3;

  /// No description provided for @generatingStage4.
  ///
  /// In en, this message translates to:
  /// **'Rendering ghost mesh…'**
  String get generatingStage4;

  /// No description provided for @rebuildingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get rebuildingEyebrow;

  /// No description provided for @rebuildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding all models'**
  String get rebuildingTitle;

  /// No description provided for @rebuildingFooter.
  ///
  /// In en, this message translates to:
  /// **'Calibrated to updated profile · runs once'**
  String get rebuildingFooter;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get settingsMode;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsAccent;

  /// Label for the SAF Crest visual theme tile in the settings sheet.
  ///
  /// In en, this message translates to:
  /// **'SAF Crest'**
  String get themeAccentSafCrest;

  /// No description provided for @profileSection1.
  ///
  /// In en, this message translates to:
  /// **'Service Branch'**
  String get profileSection1;

  /// No description provided for @profileSection2.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get profileSection2;

  /// No description provided for @profileSection3.
  ///
  /// In en, this message translates to:
  /// **'Rank & Vocation'**
  String get profileSection3;

  /// No description provided for @profileSection4.
  ///
  /// In en, this message translates to:
  /// **'Medals & Ribbons'**
  String get profileSection4;

  /// No description provided for @profileSection5.
  ///
  /// In en, this message translates to:
  /// **'Badges & Qualifications'**
  String get profileSection5;

  /// No description provided for @profileFieldBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get profileFieldBranch;

  /// No description provided for @profileFieldBuild.
  ///
  /// In en, this message translates to:
  /// **'Build / cut'**
  String get profileFieldBuild;

  /// No description provided for @profileSikhToggle.
  ///
  /// In en, this message translates to:
  /// **'Sikh personnel (turban exemption)'**
  String get profileSikhToggle;

  /// No description provided for @profileFieldRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get profileFieldRank;

  /// No description provided for @profileFieldVocation.
  ///
  /// In en, this message translates to:
  /// **'Vocation'**
  String get profileFieldVocation;

  /// No description provided for @profileFieldMedalRows.
  ///
  /// In en, this message translates to:
  /// **'Medal ribbon rows'**
  String get profileFieldMedalRows;

  /// No description provided for @profileFieldHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get profileFieldHeight;

  /// No description provided for @profileHeightHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps the uniform scan measure more accurately.'**
  String get profileHeightHint;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullName;

  /// No description provided for @profileMedalRowsLabel.
  ///
  /// In en, this message translates to:
  /// **'ROWS'**
  String get profileMedalRowsLabel;

  /// No description provided for @profileBadgesNote.
  ///
  /// In en, this message translates to:
  /// **'Some badges are mutually exclusive — selecting one deselects incompatible awards.'**
  String get profileBadgesNote;

  /// No description provided for @profileUpdateRebuild.
  ///
  /// In en, this message translates to:
  /// **'Update & Rebuild Models'**
  String get profileUpdateRebuild;

  /// No description provided for @profileUpToDate.
  ///
  /// In en, this message translates to:
  /// **'PROFILE UP TO DATE'**
  String get profileUpToDate;

  /// No description provided for @profileRebuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Rebuild 3D models?'**
  String get profileRebuildTitle;

  /// No description provided for @profileRebuildSub.
  ///
  /// In en, this message translates to:
  /// **'Profile changes need a fresh render'**
  String get profileRebuildSub;

  /// No description provided for @profileRebuildBody.
  ///
  /// In en, this message translates to:
  /// **'Your updated profile will be saved and all dress models will be re-generated to reflect the changes. Existing models will be replaced.'**
  String get profileRebuildBody;

  /// No description provided for @profileRebuildConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Rebuild'**
  String get profileRebuildConfirm;

  /// No description provided for @galleryEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get galleryEyebrow;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryTitle;

  /// No description provided for @galleryUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get galleryUpload;

  /// No description provided for @galleryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get galleryEmptyTitle;

  /// No description provided for @galleryEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap Upload to add photos to your gallery'**
  String get galleryEmptyBody;

  /// No description provided for @galleryUploadCta.
  ///
  /// In en, this message translates to:
  /// **'Upload Photos'**
  String get galleryUploadCta;

  /// No description provided for @galleryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete photo?'**
  String get galleryDeleteTitle;

  /// No description provided for @galleryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone'**
  String get galleryDeleteBody;

  /// No description provided for @galleryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get galleryDeleteConfirm;

  /// No description provided for @galleryPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} =1{1 photo} other{{count} photos}}'**
  String galleryPhotoCount(num count);

  /// No description provided for @galleryUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {pct}%'**
  String galleryUploadProgress(int pct);

  /// No description provided for @galleryUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get galleryUploadFailed;

  /// No description provided for @galleryDressCodeTag.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get galleryDressCodeTag;

  /// No description provided for @galleryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get galleryFilterAll;

  /// No description provided for @galleryFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get galleryFromCamera;

  /// No description provided for @galleryFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get galleryFromLibrary;

  /// No description provided for @galleryPickSource.
  ///
  /// In en, this message translates to:
  /// **'Add photo from…'**
  String get galleryPickSource;

  /// No description provided for @galleryShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share this photo.'**
  String get galleryShareFailed;

  /// No description provided for @wardrobeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'3D Models'**
  String get wardrobeEyebrow;

  /// No description provided for @wardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get wardrobeTitle;

  /// No description provided for @wardrobeStatReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get wardrobeStatReady;

  /// No description provided for @wardrobeStatBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get wardrobeStatBuilding;

  /// No description provided for @wardrobeStatPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get wardrobeStatPending;

  /// No description provided for @wardrobeAllDresses.
  ///
  /// In en, this message translates to:
  /// **'All dresses'**
  String get wardrobeAllDresses;

  /// No description provided for @wardrobeFilterAllChip.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get wardrobeFilterAllChip;

  /// No description provided for @wardrobeFilterDressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show {dressName} only'**
  String wardrobeFilterDressSubtitle(String dressName);

  /// No description provided for @wardrobeMandatoryChip.
  ///
  /// In en, this message translates to:
  /// **'MANDATORY'**
  String get wardrobeMandatoryChip;

  /// No description provided for @wardrobeOptionalChip.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get wardrobeOptionalChip;

  /// No description provided for @wardrobeEmptyDress.
  ///
  /// In en, this message translates to:
  /// **'No accessories required for this dress yet.'**
  String get wardrobeEmptyDress;

  /// No description provided for @wardrobeEmptyPendingDoctrine.
  ///
  /// In en, this message translates to:
  /// **'Pending doctrine review.'**
  String get wardrobeEmptyPendingDoctrine;

  /// No description provided for @rankInsigniaSpecMarksman.
  ///
  /// In en, this message translates to:
  /// **'Marksman'**
  String get rankInsigniaSpecMarksman;

  /// No description provided for @badgeIppt.
  ///
  /// In en, this message translates to:
  /// **'IPPT Gold'**
  String get badgeIppt;

  /// No description provided for @badgeMarksmanship.
  ///
  /// In en, this message translates to:
  /// **'Marksmanship'**
  String get badgeMarksmanship;

  /// No description provided for @badgeSniper.
  ///
  /// In en, this message translates to:
  /// **'Sniper'**
  String get badgeSniper;

  /// No description provided for @badgeFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness Specialist'**
  String get badgeFitness;

  /// No description provided for @badgeAirborne.
  ///
  /// In en, this message translates to:
  /// **'Airborne'**
  String get badgeAirborne;

  /// No description provided for @badgeDive.
  ///
  /// In en, this message translates to:
  /// **'Combat Diver'**
  String get badgeDive;

  /// No description provided for @badgePilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot Wings'**
  String get badgePilot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
