import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../ar_engine/presentation/providers/accessory_library_provider.dart';
import '../../../checklist/domain/services/accessory_presentation.dart';
import '../../../checklist/presentation/providers/dress_accessories_provider.dart';
import '../../../checklist/presentation/widgets/accessory_remote_image.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../../domain/wearing_steps.dart';

/// Localised view of one [WearingStep].
class _GuideStep {
  const _GuideStep(
    this.id,
    this.label,
    this.sub,
    this.tip,
    this.icon,
    this.zone, {
    this.imageUrl = '',
    this.placementUrl = '',
  });
  final String id;
  final String label;
  final String sub;
  final String tip;
  final IconData icon;
  final WearingZone zone;

  /// Pictures for the dress being worn (No.4 PDF pictures per service);
  /// empty when the step has none — the silhouette is shown instead.
  final String imageUrl;
  final String placementUrl;

  _GuideStep withImages(AccessoryImages? images) => images == null
      ? this
      : _GuideStep(
          id,
          label,
          sub,
          tip,
          icon,
          zone,
          imageUrl: images.imageUrl,
          placementUrl: images.placementDiagramUrl,
        );
}

/// Library entry whose pictures illustrate a non-accessory step.
const Map<WearingStepKind, String> _stepLibraryIds = {
  WearingStepKind.medals: 'medal_ribbons',
  WearingStepKind.chestBadges: 'saf_badges_chest',
  WearingStepKind.sleeveBadges: 'skill_badges_sleeve',
};

/// The step's pictures for [dress] / [branch]: its own accessory, or the
/// library entry for the medal / badge steps. Null when it has none.
AccessoryImages? _imagesForStep(
  WearingStep s,
  Map<String, Accessory> library,
  DressCode dress,
  BranchId branch,
) {
  final accessory = s.accessory ?? library[_stepLibraryIds[s.kind]];
  if (accessory == null) return null;
  return accessoryImagesFor(accessory, dress: dress, branch: branch);
}

String _zoneLabel(AppLocalizations l, WearingZone z) => switch (z) {
  WearingZone.head => l.wearingZoneHead,
  WearingZone.collar => l.wearingZoneCollar,
  WearingZone.shoulder => l.wearingZoneShoulder,
  WearingZone.chestCentre => l.wearingZoneChestCentre,
  WearingZone.rightChest => l.wearingZoneRightChest,
  WearingZone.leftChest => l.wearingZoneLeftChest,
  WearingZone.sleeves => l.wearingZoneSleeves,
  WearingZone.torso => l.wearingZoneTorso,
  WearingZone.waist => l.wearingZoneWaist,
  WearingZone.legs => l.wearingZoneLegs,
  WearingZone.feet => l.wearingZoneFeet,
};

IconData _iconFor(WearingStep s) {
  final category = s.accessory?.category ?? '';
  if (category.startsWith('headdress')) return Icons.emoji_events;
  return switch (s.kind) {
    WearingStepKind.trousers => Icons.straighten,
    WearingStepKind.shirt => Icons.checkroom,
    WearingStepKind.medals => Icons.workspace_premium_outlined,
    WearingStepKind.chestBadges => Icons.shield_outlined,
    WearingStepKind.sleeveBadges => Icons.military_tech,
    WearingStepKind.accessory => switch (category) {
      'inner_shirt' => Icons.checkroom,
      'belt' => Icons.horizontal_rule,
      'socks' || 'footwear' => Icons.hiking,
      'name_tag' || 'country_tag' => Icons.badge_outlined,
      'lanyard' => Icons.airline_stops,
      'cap_badge' || 'cap_embellishment' => Icons.military_tech,
      _ => Icons.shield_outlined,
    },
  };
}

_GuideStep _localise(
  AppLocalizations l,
  WearingStep s,
  DressCode dress,
  BranchId branch,
  Set<String> mandatoryIds,
) {
  final zone = _zoneLabel(l, s.zone);
  final required = '$zone · ${l.wearingRequired}';
  final isNo3 = dress == DressCode.no3;
  return switch (s.kind) {
    WearingStepKind.trousers => _GuideStep(
      s.id,
      l.wearingStepTrousersFor(dress.code(l)),
      required,
      isNo3 ? l.wearingStepTrousersTip : l.wearingStepTrousersTipGeneric,
      _iconFor(s),
      s.zone,
    ),
    WearingStepKind.shirt => _GuideStep(
      s.id,
      isNo3 ? l.wearingStepShirt : l.wearingStepShirtFor(dress.code(l)),
      required,
      isNo3 ? l.wearingStepShirtTip : l.wearingStepShirtTipGeneric,
      _iconFor(s),
      s.zone,
    ),
    WearingStepKind.medals => _GuideStep(
      s.id,
      l.wearingStepMedals,
      l.wearingStepMedalsSub,
      l.wearingStepMedalsTip,
      _iconFor(s),
      s.zone,
    ),
    WearingStepKind.chestBadges =>
      isNo3
          ? _GuideStep(
              s.id,
              l.wearingStepBadges,
              l.wearingStepBadgesSub,
              l.wearingStepBadgesTip,
              _iconFor(s),
              s.zone,
            )
          : _GuideStep(
              s.id,
              l.wearingStepChestBadgesNo4,
              l.wearingStepChestBadgesNo4Sub,
              // SAF No.4 Dress PDF: Army C-1..C-3, Navy C-1..C-3, DIS C-4..C-5.
              switch (branch) {
                BranchId.army => l.wearingStepChestBadgesTipArmy,
                BranchId.navy => l.wearingStepChestBadgesTipNavy,
                BranchId.rsaf ||
                BranchId.dis => l.wearingStepChestBadgesTipSingaporeTag,
              },
              _iconFor(s),
              s.zone,
            ),
    WearingStepKind.sleeveBadges => _GuideStep(
      s.id,
      l.wearingStepSleeveBadges,
      l.wearingStepSleeveBadgesSub,
      // SAF No.4 Dress PDF: Army C-4..C-7, RSAF C-4, DIS C-6..C-9.
      switch (branch) {
        BranchId.army => l.wearingStepSleeveBadgesTipArmy,
        BranchId.navy => l.wearingStepSleeveBadgesTipNavy,
        BranchId.rsaf => l.wearingStepSleeveBadgesTipRsaf,
        BranchId.dis => l.wearingStepSleeveBadgesTipDis,
      },
      _iconFor(s),
      s.zone,
    ),
    WearingStepKind.accessory => _GuideStep(
      s.id,
      s.accessory!.displayName,
      l.wearingAccessorySub(
        zone,
        mandatoryIds.contains(s.id) ? l.wearingRequired : l.wearingOptional,
      ),
      s.tip ?? l.wearingNoTip,
      _iconFor(s),
      s.zone,
    ),
  };
}

class WearingGuideScreen extends ConsumerStatefulWidget {
  const WearingGuideScreen({super.key});

  @override
  ConsumerState<WearingGuideScreen> createState() => _WearingGuideScreenState();
}

class _WearingGuideScreenState extends ConsumerState<WearingGuideScreen> {
  int _step = 0;
  bool _voice = true;
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final profile = ref.watch(uniformProfileProvider);
    final dress = profile.dressCode;
    final asyncSplit = ref.watch(
      dressAccessoriesByIdProvider(dress.requirementDocId),
    );
    // Only for the medal / badge step pictures; the guide doesn't wait on it.
    final library = {
      for (final a in ref.watch(accessoryLibraryProvider).value ??
          const <Accessory>[])
        a.id: a,
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: branchTheme.bright),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        BackButton(
                          color: Colors.white,
                          onPressed: () => context.go(Routes.ghostModel),
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.only(top: 8, right: 8, bottom: 8),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            AppChip(
                              label: '${l.wearingChip} · ${dress.code(l)}',
                              accent: true,
                              accentColor: branchTheme.bright,
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _voice = !_voice),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: AppColors.line,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  _voice ? Icons.volume_up : Icons.volume_off,
                                  color: _voice
                                      ? branchTheme.bright
                                      : AppColors.inkMuted,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...asyncSplit.when(
                    loading: () => [const Expanded(child: LoadingView())],
                    error: (e, st) {
                      log(
                        'build: accessories failed',
                        name: 'wearing_guide.screen',
                        error: e,
                        stackTrace: st,
                        level: 1000,
                      );
                      return [
                        Expanded(child: ErrorView(message: e.toString())),
                      ];
                    },
                    data: (split) {
                      final mandatoryIds = {
                        for (final a in split.mandatory) a.id,
                      };
                      final steps = [
                        for (final s in buildWearingSteps(
                          dressCode: dress,
                          split: split,
                          profile: profile,
                        ))
                          _localise(
                            l,
                            s,
                            dress,
                            profile.branch,
                            mandatoryIds,
                          ).withImages(
                            _imagesForStep(s, library, dress, profile.branch),
                          ),
                      ];
                      // Stub dresses (No.1/2/5) resolve only the generic belt /
                      // socks / footwear until their doctrine PDFs land.
                      final hasAccessories = split.mandatory.any(
                        (a) => !const {
                          'belt',
                          'socks',
                          'footwear',
                        }.contains(a.category),
                      );
                      return _guide(context, steps, hasAccessories);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _guide(
    BuildContext context,
    List<_GuideStep> steps,
    bool hasAccessories,
  ) {
    final branchTheme = context.branchTheme;
    // The step list can shrink when the profile changes underneath us.
    final step = _step.clamp(0, steps.length - 1);
    return [
      Expanded(
        child: _complete
            ? _CompleteView(
                stepCount: steps.length,
                steps: steps,
                onScan: () => context.go(Routes.ar),
                onRestart: () => setState(() {
                  _step = 0;
                  _complete = false;
                }),
              )
            : _StepView(
                step: step,
                steps: steps,
                voice: _voice,
                notice: hasAccessories
                    ? null
                    : context.l10n.wearingDoctrinePending,
              ),
      ),
      if (!_complete) _navRow(context, steps, step, branchTheme.accent),
    ];
  }

  Widget _navRow(
    BuildContext context,
    List<_GuideStep> steps,
    int step,
    Color accent,
  ) {
    final l = context.l10n;
    final isLast = step == steps.length - 1;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 18 + MediaQuery.of(context).viewPadding.bottom,
        top: 8,
      ),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              flex: 1,
              child: GhostButton(
                label: l.wearingPrev,
                icon: const Icon(Icons.arrow_back, size: 14),
                onPressed: () => setState(() => _step = step - 1),
              ),
            ),
          if (step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: isLast
                  ? l.wearingFinish
                  : l.wearingNextLabel(steps[step + 1].label),
              gradient: true,
              accentColor: accent,
              trailingIcon: const Icon(Icons.arrow_forward, size: 14),
              onPressed: () {
                if (isLast) {
                  setState(() => _complete = true);
                } else {
                  setState(() => _step = step + 1);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.step,
    required this.steps,
    required this.voice,
    this.notice,
  });
  final int step;
  final List<_GuideStep> steps;
  final bool voice;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    final cur = steps[step];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.wearingStepFormat(step + 1, steps.length),
                  style: AppTextStyles.mono(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(steps.length, (i) {
              final state = i < step
                  ? branchTheme.bright
                  : i == step
                  ? branchTheme.bright
                  : Colors.white.withValues(alpha: 0.10);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: state,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          // Pictures for this dress (same as the Wardrobe detail sheet);
          // the silhouette + active zone when the step has none.
          if (cur.imageUrl.isEmpty && cur.placementUrl.isEmpty)
            Center(
              child: SizedBox(
                width: 140,
                height: 240,
                child: CustomPaint(
                  painter: _SilhouettePainter(
                    zone: cur.zone,
                    accent: branchTheme.bright,
                  ),
                ),
              ),
            ),
          if (cur.imageUrl.isNotEmpty)
            AccessoryRemoteImage(
              url: cur.imageUrl,
              caption: 'ACCESSORY',
              icon: cur.icon,
              accent: branchTheme.bright,
            ),
          if (cur.imageUrl.isNotEmpty && cur.placementUrl.isNotEmpty)
            const SizedBox(height: 12),
          if (cur.placementUrl.isNotEmpty)
            AccessoryRemoteImage(
              url: cur.placementUrl,
              caption: 'PLACEMENT',
              icon: cur.icon,
              accent: branchTheme.bright,
            ),
          const SizedBox(height: 18),
          // Item card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  branchTheme.bright.withValues(alpha: 0.18),
                  branchTheme.bright.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(color: AppColors.line, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [branchTheme.accent, branchTheme.bright],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Icon(cur.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cur.label,
                            style: AppTextStyles.title(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cur.sub,
                            style: AppTextStyles.mono(
                              fontSize: 10.5,
                              color: branchTheme.bright,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (voice)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(color: AppColors.line, width: 1),
                        ),
                        child: const Icon(
                          Icons.replay,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.straighten,
                        color: branchTheme.bright,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cur.tip,
                          style: AppTextStyles.body(
                            color: AppColors.ink,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (notice != null) ...[
            const SizedBox(height: 12),
            Text(
              notice!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                color: AppColors.inkMuted,
                fontSize: 11.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.zone, required this.accent});
  final WearingZone zone;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(Offset(w * 0.5, h * 0.10), w * 0.10, body);
    canvas.drawRect(
      Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55),
      body,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.18, h * 0.21, w * 0.28, h * 0.52),
      body,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.72, h * 0.21, w * 0.82, h * 0.52),
      body,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.49, h * 0.95),
      body,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.51, h * 0.55, w * 0.70, h * 0.95),
      body,
    );

    // Front view: the wearer's right is on the viewer's left.
    final zones = switch (zone) {
      WearingZone.head => [Rect.fromLTRB(w * 0.30, 0, w * 0.70, h * 0.20)],
      WearingZone.collar => [
        Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.27),
      ],
      WearingZone.shoulder => [
        Rect.fromLTRB(w * 0.18, h * 0.20, w * 0.38, h * 0.26),
        Rect.fromLTRB(w * 0.62, h * 0.20, w * 0.82, h * 0.26),
      ],
      WearingZone.chestCentre => [
        Rect.fromLTRB(w * 0.42, h * 0.27, w * 0.58, h * 0.45),
      ],
      WearingZone.rightChest => [
        Rect.fromLTRB(w * 0.30, h * 0.27, w * 0.50, h * 0.40),
      ],
      WearingZone.leftChest => [
        Rect.fromLTRB(w * 0.50, h * 0.27, w * 0.70, h * 0.40),
      ],
      WearingZone.sleeves => [
        Rect.fromLTRB(w * 0.18, h * 0.24, w * 0.28, h * 0.38),
        Rect.fromLTRB(w * 0.72, h * 0.24, w * 0.82, h * 0.38),
      ],
      WearingZone.torso => [
        Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55),
      ],
      WearingZone.waist => [
        Rect.fromLTRB(w * 0.30, h * 0.50, w * 0.70, h * 0.58),
      ],
      WearingZone.legs => [
        Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.70, h * 0.95),
      ],
      WearingZone.feet => [
        Rect.fromLTRB(w * 0.28, h * 0.90, w * 0.72, h * 1.0),
      ],
    };
    final highlight = Paint()..color = accent.withValues(alpha: 0.45);
    for (final r in zones) {
      canvas.drawRect(r, highlight);
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.zone != zone || old.accent != accent;
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.stepCount,
    required this.steps,
    required this.onScan,
    required this.onRestart,
  });
  final int stepCount;
  final List<_GuideStep> steps;
  final VoidCallback onScan;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ok.withValues(alpha: 0.18),
              border: Border.all(color: AppColors.ok, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ok.withValues(alpha: 0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(Icons.check, color: AppColors.ok, size: 50),
          ),
          const SizedBox(height: 18),
          Text(l.wearingCompleteEyebrow, style: AppTextStyles.eyebrow()),
          const SizedBox(height: 8),
          Text(
            l.wearingCompleteTitle,
            style: AppTextStyles.title(fontSize: 26),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l.wearingCompleteBody(stepCount),
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final s in steps)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: AppColors.ok, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: AppTextStyles.body(
                          color: AppColors.ink,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: l.wearingProceedAr,
                    gradient: true,
                    accentColor: branchTheme.accent,
                    icon: const Icon(Icons.crop_free, size: 16),
                    onPressed: onScan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GhostButton(
                    label: l.wearingRestart,
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: onRestart,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
