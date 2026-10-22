// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '新加坡武装部队制服';

  @override
  String get branchArmy => '陆军';

  @override
  String get branchNavy => '海军';

  @override
  String get branchRsaf => '空军';

  @override
  String get branchDis => '数字与情报军';

  @override
  String get loading => '加载中…';

  @override
  String get errorGeneric => '出错了。';

  @override
  String get commonContinue => '继续';

  @override
  String get commonBack => '返回';

  @override
  String get commonNext => '下一步';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonDelete => '删除';

  @override
  String get commonGotIt => '明白 · 标记已确认';

  @override
  String get commonShare => '分享';

  @override
  String get commonSetup => '设置';

  @override
  String get commonSave => '保存';

  @override
  String get commonUpdate => '更新';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSoldier => '军人';

  @override
  String get commonDone => '完成';

  @override
  String get welcomeEyebrow => '新加坡武装部队着装合规';

  @override
  String get welcomeTitleLine1 => '细节中';

  @override
  String get welcomeTitleLine2 => '见精准。';

  @override
  String get welcomeSubtitle => '您的个性化军服合规指南——以总规为本,精确到厘米。';

  @override
  String get welcomeGetStarted => '开始使用';

  @override
  String get configSaveFailed => '无法保存您的个人资料 — 请检查网络连接后点击「完成」重试';

  @override
  String get configHeaderConfiguration => '配置';

  @override
  String get configStep01 => '兵种';

  @override
  String get configStep02 => '身份';

  @override
  String get configStep03 => '军衔 · 兵种';

  @override
  String get configStep04 => '饰物';

  @override
  String configStepFormat(String current, String total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String get configStep1Title => '选择您的兵种。';

  @override
  String get configStep1Subtitle =>
      '决定主题色和规则集。陆军使用 3 厘米衣领规则;海军/空军/数字情报军使用 1 厘米。';

  @override
  String get configStep1WhyTitle => '为什么这很重要';

  @override
  String get configStep1WhyBody => '陆军衣领军衔徽章距衣领边缘 3 厘米。海军为 1 厘米。整个界面会相应重新主题化。';

  @override
  String get configStep2Title => '身份。';

  @override
  String get configStep2Subtitle => '锡克教徒佩戴红色裹布的头巾,而非贝雷帽。';

  @override
  String get configStandardSikh => '标准 / 锡克';

  @override
  String get configStandard => '标准';

  @override
  String get configSikhPersonnel => '锡克教人员';

  @override
  String get configSexBuild => '性别 / 体型';

  @override
  String get configIdentityMen => '男性';

  @override
  String get configIdentityLadies => '女性';

  @override
  String get configIdentityMaternity => '孕装';

  @override
  String get configSikhRuleEyebrow => '锡克教人员 · 头饰规则';

  @override
  String get configSikhRuleBody => '锡克教人员佩戴同色头巾代替贝雷帽。COL/ME7 及以上佩戴红色头巾。';

  @override
  String get configStep3Title => '军衔与专业。';

  @override
  String get configStep3Subtitle => '决定衣领徽章、帽徽款式以及锡克教人员的头巾装饰。';

  @override
  String get configFieldRank => '军衔';

  @override
  String get configFieldVocation => '专业';

  @override
  String get configFieldName => '姓名';

  @override
  String get configNamePlaceholder => '姓';

  @override
  String get configAutoAppliedEyebrow => '已自动应用';

  @override
  String get configAutoAppliedBody => '将渲染白色头巾配黑色裹布(海军 3WO/ME3 及以上)。';

  @override
  String get configStep4Title => '饰物。';

  @override
  String get configStep4Subtitle => '勋表位置自动调整 — 3 排或更多时,SAF 徽章移至勋表上方 1 厘米。';

  @override
  String configMedalRows(int count) {
    return '勋表排数 · $count';
  }

  @override
  String get configAutoRuleApplied =>
      '已自动应用规则。SAF 徽章将渲染在勋表上方 1 厘米处(而非口袋上方 3 厘米)。';

  @override
  String get configBadgesLabel => 'SAF 徽章(最多 3 枚)';

  @override
  String get configBadgesExclusion => '互斥:神枪手 · 狙击手 · 体能专长';

  @override
  String get configBuildGhost => '生成 3D 模型';

  @override
  String get dashHomeQuickActions => '快捷操作';

  @override
  String get dashHomeActionAr => 'AR 扫描';

  @override
  String get dashHomeActionMeasure => '测量';

  @override
  String get dashHomeActionInspect => '检查';

  @override
  String get dashSetupRequired => '需要设置';

  @override
  String get dashSetupTitle1 => '设置您的';

  @override
  String get dashSetupTitle2 => '军服档案';

  @override
  String get dashSetupBody => '告诉我们您的兵种、身份、军衔和饰物,以便为您渲染个性化的 3 号制服模型。';

  @override
  String get dashSetupStep1 => '兵种';

  @override
  String get dashSetupStep2 => '身份';

  @override
  String get dashSetupStep3 => '军衔';

  @override
  String get dashSetupStep4 => '徽章';

  @override
  String get dressNo1Code => '1 号';

  @override
  String get dressNo2Code => '2 号';

  @override
  String get dressNo3Code => '3 号';

  @override
  String get dressNo4Code => '4 号';

  @override
  String get dressNo5Code => '5 号';

  @override
  String get dressNo1Name => '礼服';

  @override
  String get dressNo2Name => '正餐礼服';

  @override
  String get dressNo3Name => '勤务服';

  @override
  String get dressNo4Name => '便制服';

  @override
  String get dressNo5Name => '野战 / 战斗';

  @override
  String get dressNo1Tag => '白色礼服 · 军官';

  @override
  String get dressNo2Tag => '正式晚宴 · 军官';

  @override
  String get dressNo3Tag => '办公 / 检阅 · 日常';

  @override
  String get dressNo4Tag => '工作 · 数码迷彩';

  @override
  String get dressNo5Tag => '作战 · 战斗';

  @override
  String get dressStateReady => '● 就绪';

  @override
  String get dressStateGenerating => '◐ 生成中';

  @override
  String get dressStateNotBuilt => '○ 未生成';

  @override
  String get dressStateBuilding => '◐ 构建中';

  @override
  String get dressBadgeRecommended => '推荐';

  @override
  String get dressBadge3D => '3D';

  @override
  String get dressView => '查看';

  @override
  String get dressAccessoriesBuildBtn => '建立我的制服';

  @override
  String get dressAccessoriesDialogTitle => '必备饰物未完成';

  @override
  String get dressAccessoriesDialogBody => '并非所有必备饰物均已选择。您可以立即建立，或返回完成清单。';

  @override
  String get dressAccessoriesDialogClose => '关闭';

  @override
  String get dressAccessoriesDialogBuild => '建立制服';

  @override
  String get navHome => '首页';

  @override
  String get navWardrobe => '衣橱';

  @override
  String get navGallery => '相册';

  @override
  String get navProfile => '档案';

  @override
  String get checklistVerified => '已确认';

  @override
  String get checklistTapToView => '点击查看位置';

  @override
  String get checklistVerifiedPrefix => '已确认 ·';

  @override
  String checklistVerifyMore(int count) {
    return '再确认 $count 项以继续';
  }

  @override
  String get checklistAllVerified => '全部确认 — 继续';

  @override
  String get checklistVerbatimManual => '原文摘自手册';

  @override
  String get checklistDressCode => '军服类型';

  @override
  String get checklistDressAll => '全部饰物';

  @override
  String get checklistDressAllDesc => '显示全部';

  @override
  String get checklistDressNo1Desc => '白色礼服 · 军官';

  @override
  String get checklistDressNo2Desc => '正式晚宴 · 军官';

  @override
  String get checklistDressNo3Desc => '办公 / 检阅 · 日常';

  @override
  String get checklistDressNo4Desc => '工作 · 数码迷彩';

  @override
  String get checklistDressNo5Desc => '作战 · 战斗';

  @override
  String get accCollarTitle => '衣领军衔徽章';

  @override
  String get accCollarMono => '3 厘米';

  @override
  String get accCollarBody => '佩戴于衣领两侧居中位置,军衔徽章底部距衣领边缘 3 厘米。';

  @override
  String get accCollarRef => '图 C-1';

  @override
  String get accBadgesTitle => 'SAF 徽章';

  @override
  String get accBadgesMono => '上方 1 厘米';

  @override
  String get accBadgesBody => '佩戴 3 排或更多勋表时,徽章置于勋表顶边上方 1 厘米。否则置于口袋上方 3 厘米。';

  @override
  String get accBadgesRef => '图 D-10';

  @override
  String get accMedalsTitle => '勋表';

  @override
  String get accMedalsMono => '— 口袋边缘';

  @override
  String get accMedalsBody => '男性的勋表佩戴在左胸口袋顶边正上方,与口袋边平行居中。';

  @override
  String get accMedalsRef => '图 D-3';

  @override
  String get accNameTitle => '姓名牌';

  @override
  String get accNameMono => '— 口袋边缘';

  @override
  String get accNameBody => '男性:佩戴于右胸口袋顶边正上方居中。女性:佩戴于第 2 与第 3 颗扣子之间。';

  @override
  String get accNameRef => '图 C-6';

  @override
  String get accBeltTitle => '尼龙腰带';

  @override
  String get accBeltMono => '居中';

  @override
  String get accBeltBody => '扣环对齐裤裆开口及衬衫纽扣线。金属端紧贴扣环边缘。';

  @override
  String get accBeltRef => '图 C-8';

  @override
  String get accLanyardTitle => '肩绳';

  @override
  String get accLanyardMono => '8 – 12 厘米';

  @override
  String get accLanyardBody => '肩绳结须置于右肩腋下 8 至 12 厘米处。';

  @override
  String get accLanyardRef => '图 C-9';

  @override
  String get ghostBack => '确认清单';

  @override
  String get ghostChip => '幽灵模型';

  @override
  String get ghostStepReference => '第 04 步 · 参考';

  @override
  String get ghostFront => '正面';

  @override
  String get ghostBackView => '背面';

  @override
  String get ghostTapBack => '↺ 点击背面旋转';

  @override
  String get ghostTapFront => '↺ 点击正面旋转';

  @override
  String get ghostStartArScan => '开始 AR 扫描';

  @override
  String get ghostStartWearing => '开始穿戴';

  @override
  String get ghostBadgeRule3cm => '点击任意标记 · 3 厘米徽章规则启用';

  @override
  String get ghostBadgeRule1cm => '点击任意标记 · 1 厘米徽章规则启用';

  @override
  String get ghostBackViewNoHotspots => '背面视图 · 无热点';

  @override
  String get wearingBack => '3D 模型';

  @override
  String get wearingChip => '穿戴指南';

  @override
  String wearingStepFormat(int current, int total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String get wearingNowWearing => '正在穿戴';

  @override
  String get wearingReplay => '重播';

  @override
  String wearingNextLabel(String next) {
    return '下一步 · $next';
  }

  @override
  String get wearingFinish => '完成';

  @override
  String get wearingPrev => '上一步';

  @override
  String get wearingCompleteEyebrow => '穿戴指南完成';

  @override
  String get wearingCompleteTitle => '您已穿好!';

  @override
  String wearingCompleteBody(int count) {
    return '全部 $count 项穿戴正确。您的军服可供检阅。';
  }

  @override
  String get wearingProceedAr => '前往 AR 扫描';

  @override
  String get wearingRestart => '重新开始指南';

  @override
  String get wearingStepTrousers => '3 号长裤';

  @override
  String get wearingStepTrousersSub => '下装 · 从此开始';

  @override
  String get wearingStepTrousersTip => '中线笔挺 · 腰带于自然腰部';

  @override
  String get wearingStepShirt => '3 号勤务衬衫';

  @override
  String get wearingStepShirtSub => '底层';

  @override
  String get wearingStepShirtTip => '扎紧 · 衬衫前襟与裤裆对齐';

  @override
  String get wearingStepBelt => '尼龙腰带';

  @override
  String get wearingStepBeltSub => '对齐裤裆';

  @override
  String get wearingStepBeltTip => '扣环居中 · 金属端齐边';

  @override
  String get wearingStepMedals => '勋表';

  @override
  String get wearingStepMedalsSub => '左胸口袋';

  @override
  String get wearingStepMedalsTip => '居中于左口袋上方 · 排排平齐';

  @override
  String get wearingStepBadges => 'SAF 徽章';

  @override
  String get wearingStepBadgesSub => '勋表上方 1 厘米';

  @override
  String get wearingStepBadgesTip => '3+ 排时上方 1 厘米 · 否则口袋上方 3 厘米';

  @override
  String get wearingStepNametag => '姓名牌';

  @override
  String get wearingStepNametagSub => '右胸口袋';

  @override
  String get wearingStepNametagTip => '居中于右口袋上方 · 完全水平';

  @override
  String get wearingStepCollar => '衣领军衔徽章';

  @override
  String get wearingStepCollarSub => '距衣领边 3 厘米';

  @override
  String get wearingStepCollarTip => '距衣领边 3 厘米 · 两侧对称';

  @override
  String get wearingStepLanyard => '肩绳';

  @override
  String get wearingStepLanyardSub => '右肩';

  @override
  String get wearingStepLanyardTip => '结距腋下 8–12 厘米 · 右肩';

  @override
  String get wearingStepHeaddress => '头饰';

  @override
  String get wearingStepHeaddressSub => '最后一步';

  @override
  String get wearingStepHeaddressTip => '贝雷帽右倾 · 或佩戴头巾';

  @override
  String wearingStepTrousersFor(String dress) {
    return '$dress 长裤';
  }

  @override
  String wearingStepShirtFor(String dress) {
    return '$dress 衬衫';
  }

  @override
  String get wearingStepTrousersTipGeneric => '腰头位于自然腰线 · 裤子平直整齐';

  @override
  String get wearingStepShirtTipGeneric => '扣好所有纽扣 · 衣领平整 · 衬衫端正';

  @override
  String wearingAccessorySub(String zone, String kind) {
    return '$zone · $kind';
  }

  @override
  String get wearingRequired => '必需';

  @override
  String get wearingOptional => '可选';

  @override
  String get wearingNoTip => '按位置示意图佩戴';

  @override
  String get wearingDoctrinePending => '此制服的详细配件尚待条令审核 — 目前仅列出基本服装。';

  @override
  String get wearingZoneHead => '头部';

  @override
  String get wearingZoneCollar => '衣领';

  @override
  String get wearingZoneShoulder => '肩部';

  @override
  String get wearingZoneChestCentre => '胸前正中';

  @override
  String get wearingZoneRightChest => '右胸';

  @override
  String get wearingZoneLeftChest => '左胸';

  @override
  String get wearingZoneSleeves => '袖子';

  @override
  String get wearingZoneTorso => '躯干';

  @override
  String get wearingZoneWaist => '腰部';

  @override
  String get wearingZoneLegs => '腿部';

  @override
  String get wearingZoneFeet => '脚部';

  @override
  String get wearingStepChestBadgesNo4 => '新加坡武装部队徽章';

  @override
  String get wearingStepChestBadgesNo4Sub => '左胸 · 最多 3 枚';

  @override
  String get wearingStepChestBadgesTipArmy => '居中佩戴于左胸口袋上缘正上方 · 最多 3 枚';

  @override
  String get wearingStepChestBadgesTipNavy => '居中佩戴于左胸口袋上缘上方 3 厘米 · 最多 3 枚';

  @override
  String get wearingStepChestBadgesTipSingaporeTag =>
      '居中佩戴于 Singapore 名牌上缘正上方 · 最多 3 枚';

  @override
  String get wearingStepSleeveBadges => '袖章';

  @override
  String get wearingStepSleeveBadgesSub => '左袖 · 最多 2 枚';

  @override
  String get wearingStepSleeveBadgesTipArmy =>
      '射击章位于左肩缝下 1 厘米 · IPPT 章居中位于其下 0.5 厘米 · 只可佩戴一种射击章';

  @override
  String get wearingStepSleeveBadgesTipRsaf => '居中佩戴于左袖单位臂章下 5 毫米 · 只可佩戴一种射击章';

  @override
  String get wearingStepSleeveBadgesTipDis => '居中佩戴于左袖臂章下约 0.4 厘米 · 只可佩戴一种射击章';

  @override
  String get wearingStepSleeveBadgesTipNavy => '居中佩戴于左袖肩缝下方 · 只可佩戴一种射击章';

  @override
  String get arClose => '关闭';

  @override
  String get arInfo => '信息';

  @override
  String get arLive => 'AR · 实时';

  @override
  String get arAligning => '对齐中…';

  @override
  String get arAlignedTitle => '姿势已锁定';

  @override
  String get arAligningSub => '距摄像头 1.5 米,面向前方';

  @override
  String get arAlignedSub => '点击拍摄——将连续拍摄 3 张';

  @override
  String arUnsupportedTitle(String uniform) {
    return '暂不支持检查 $uniform';
  }

  @override
  String arUnsupportedSub(String list) {
    return '目前可检查:$list';
  }

  @override
  String get arChooseUniform => '在首页选择制服 →';

  @override
  String get arHintNoPerson => '请走进画面';

  @override
  String get arHintNotFullBody => '请露出全身——从头到脚';

  @override
  String get arHintTooFar => '请靠近镜头';

  @override
  String get arHintTooClose => '请后退——头和脚都要在画面内';

  @override
  String get arHintNotCentered => '请让人物位于画面中央';

  @override
  String get arHintFacingAway => '请面向镜头';

  @override
  String get arHintTurnedSideways => '请正面面对镜头';

  @override
  String get arHintArmsRaised => '双臂自然下垂放在身体两侧';

  @override
  String get arHintPhoneTilted => '请将手机竖直并保持水平';

  @override
  String get arHintHoldStill => '请保持不动…';

  @override
  String get arHintUnavailable => '实时引导不可用——请自行检查取景';

  @override
  String get cvServerTitle => '分析服务器';

  @override
  String get cvServerHint => '运行制服扫描服务的笔记本电脑地址。';

  @override
  String get cvServerSave => '保存';

  @override
  String get cvServerUsb => 'USB 数据线';

  @override
  String get cvServerReset => '默认';

  @override
  String get cvServerTest => '测试连接';

  @override
  String get cvServerTesting => '测试中…';

  @override
  String get cvServerOk => '已连接';

  @override
  String get cvServerFail => '无法连接';

  @override
  String get cvServerInvalid => '地址无效';

  @override
  String get cvServerUsbHelp =>
      'USB 数据线：用数据线连接手机和电脑，在电脑上运行 deploy/connect-phone-usb.sh，然后点“USB 数据线”。';

  @override
  String get cvServerSaved => '已保存';

  @override
  String get arServerSettings => '服务器设置';

  @override
  String get arRescan => '重新扫描';

  @override
  String get arShare => '分享';

  @override
  String get arVerification => '验证 · 计分卡';

  @override
  String get arCompliance => '合规度';

  @override
  String arRedAlerts(int count) {
    return '红色警示 · $count';
  }

  @override
  String arGreenChecks(int count) {
    return '绿色通过 · $count';
  }

  @override
  String get arMetaSvc => '兵';

  @override
  String get arMetaRnk => '衔';

  @override
  String get arMetaMed => '勋';

  @override
  String get arMetaBdg => '徽';

  @override
  String get arAnalyzing => '正在分析照片…';

  @override
  String get arAnalyzingSub => '正在与预期配件进行比对';

  @override
  String get arCheckFailed => '无法完成检查';

  @override
  String get arCheckFailedSub => '请检查网络连接后重试';

  @override
  String get arErrorSignInTitle => '正在登录中';

  @override
  String get arErrorSignInSub => '请稍候片刻后重试';

  @override
  String get arErrorProfileTitle => '请先完成个人资料设置';

  @override
  String get arErrorProfileSub => '请先完成配置设置后再进行合规检查';

  @override
  String get arErrorPhotoTitle => '照片有问题';

  @override
  String get arErrorPhotoSub => '请重新拍摄后再试';

  @override
  String get arErrorConnectionTitle => '连接问题';

  @override
  String get arErrorConnectionSub => '请检查网络连接后重试';

  @override
  String get arErrorCvUnreachableSub => '无法连接开发用CV服务 — 请确认其正在运行';

  @override
  String get arErrorCameraTitle => '相机不可用';

  @override
  String get arErrorCameraSub => '请在设置中检查相机权限后重试';

  @override
  String get arRetry => '重试';

  @override
  String arUncertainChecks(int count) {
    return '不确定 · $count';
  }

  @override
  String get generatingChip => '构建中';

  @override
  String get generatingTitle => '正在构建您的制服';

  @override
  String get generatingFooter => '已根据档案校准 · 每件军服仅运行一次';

  @override
  String get generatingStage1 => '拉取档案中…';

  @override
  String get generatingStage2 => '组合几何体中…';

  @override
  String get generatingStage3 => '应用勋表与徽章…';

  @override
  String get generatingStage4 => '渲染幽灵网格…';

  @override
  String get rebuildingEyebrow => '档案已更新';

  @override
  String get rebuildingTitle => '正在重建所有模型';

  @override
  String get rebuildingFooter => '已根据更新档案校准 · 仅运行一次';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsMode => '模式';

  @override
  String get settingsSystem => '跟随系统';

  @override
  String get settingsLight => '浅色';

  @override
  String get settingsDark => '深色';

  @override
  String get settingsAccent => '主题色';

  @override
  String get themeAccentSafCrest => 'SAF 徽章';

  @override
  String get profileSection1 => '兵种';

  @override
  String get profileSection2 => '身份';

  @override
  String get profileSection3 => '军衔与专业';

  @override
  String get profileSection4 => '勋表';

  @override
  String get profileSection5 => '徽章与资格';

  @override
  String get profileFieldBranch => '兵种';

  @override
  String get profileFieldBuild => '体型 / 剪裁';

  @override
  String get profileSikhToggle => '锡克教人员(头巾豁免)';

  @override
  String get profileFieldRank => '军衔';

  @override
  String get profileFieldVocation => '专业';

  @override
  String get profileFieldMedalRows => '勋表排数';

  @override
  String get profileFieldHeight => '身高（厘米）';

  @override
  String get profileHeightHint => '选填——可提高制服扫描的测量精度。';

  @override
  String get profileFullName => '全名';

  @override
  String get profileMedalRowsLabel => '排';

  @override
  String get profileBadgesNote => '部分徽章互斥 — 选择一个会取消不兼容的徽章。';

  @override
  String get profileUpdateRebuild => '更新并重建模型';

  @override
  String get profileUpToDate => '档案已是最新';

  @override
  String get profileRebuildTitle => '重建 3D 模型?';

  @override
  String get profileRebuildSub => '档案变更需要重新渲染';

  @override
  String get profileRebuildBody => '您的更新档案将被保存,所有军服模型将根据变更重新生成。现有模型将被替换。';

  @override
  String get profileRebuildConfirm => '确认并重建';

  @override
  String get galleryEyebrow => '照片库';

  @override
  String get galleryTitle => '相册';

  @override
  String get galleryUpload => '上传';

  @override
  String get galleryEmptyTitle => '暂无照片';

  @override
  String get galleryEmptyBody => '点击「上传」添加照片到相册';

  @override
  String get galleryUploadCta => '上传照片';

  @override
  String get galleryDeleteTitle => '删除照片?';

  @override
  String get galleryDeleteBody => '此操作无法撤销';

  @override
  String get galleryDeleteConfirm => '删除';

  @override
  String galleryPhotoCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString张照片',
      one: '1张照片',
      zero: '没有照片',
    );
    return '$_temp0';
  }

  @override
  String galleryUploadProgress(int pct) {
    return '上传中… $pct%';
  }

  @override
  String get galleryUploadFailed => '上传失败，请重试。';

  @override
  String get galleryDressCodeTag => '制服代码';

  @override
  String get galleryFilterAll => '全部';

  @override
  String get galleryFromCamera => '相机';

  @override
  String get galleryFromLibrary => '相册';

  @override
  String get galleryPickSource => '从以下位置添加照片…';

  @override
  String get galleryShareFailed => '无法分享此照片。';

  @override
  String get wardrobeEyebrow => '3D 模型';

  @override
  String get wardrobeTitle => '衣橱';

  @override
  String get wardrobeStatReady => '就绪';

  @override
  String get wardrobeStatBuilding => '构建中';

  @override
  String get wardrobeStatPending => '待生成';

  @override
  String get wardrobeAllDresses => '所有军服';

  @override
  String get wardrobeFilterAllChip => '全部';

  @override
  String wardrobeFilterDressSubtitle(String dressName) {
    return '仅显示 $dressName';
  }

  @override
  String get wardrobeMandatoryChip => '必备';

  @override
  String get wardrobeOptionalChip => '选配';

  @override
  String get wardrobeEmptyDress => '此军服暂无所需饰物。';

  @override
  String get wardrobeEmptyPendingDoctrine => '等待规章审核。';

  @override
  String get rankInsigniaSpecMarksman => '神枪手';

  @override
  String get badgeIppt => 'IPPT 金奖';

  @override
  String get badgeMarksmanship => '神枪手';

  @override
  String get badgeSniper => '狙击手';

  @override
  String get badgeFitness => '体能专长';

  @override
  String get badgeAirborne => '空降';

  @override
  String get badgeDive => '战斗潜水员';

  @override
  String get badgePilot => '飞行员翼章';
}
