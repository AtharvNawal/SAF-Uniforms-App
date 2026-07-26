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

class _WearingStep {
  const _WearingStep(this.id, this.label, this.sub, this.tip, this.icon);
  final String id;
  final String label;
  final String sub;
  final String tip;
  final IconData icon;
}

List<_WearingStep> _stepsFor(AppLocalizations l) => [
      _WearingStep('trousers', l.wearingStepTrousers, l.wearingStepTrousersSub, l.wearingStepTrousersTip, Icons.straighten),
      _WearingStep('shirt', l.wearingStepShirt, l.wearingStepShirtSub, l.wearingStepShirtTip, Icons.checkroom),
      _WearingStep('belt', l.wearingStepBelt, l.wearingStepBeltSub, l.wearingStepBeltTip, Icons.horizontal_rule),
      _WearingStep('medals', l.wearingStepMedals, l.wearingStepMedalsSub, l.wearingStepMedalsTip, Icons.workspace_premium_outlined),
      _WearingStep('badges', l.wearingStepBadges, l.wearingStepBadgesSub, l.wearingStepBadgesTip, Icons.shield_outlined),
      _WearingStep('nametag', l.wearingStepNametag, l.wearingStepNametagSub, l.wearingStepNametagTip, Icons.badge_outlined),
      _WearingStep('collar', l.wearingStepCollar, l.wearingStepCollarSub, l.wearingStepCollarTip, Icons.star_border),
      _WearingStep('lanyard', l.wearingStepLanyard, l.wearingStepLanyardSub, l.wearingStepLanyardTip, Icons.airline_stops),
      _WearingStep('headdress', l.wearingStepHeaddress, l.wearingStepHeaddressSub, l.wearingStepHeaddressTip, Icons.emoji_events),
    ];

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
    final steps = _stepsFor(l);

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
                            AppChip(label: l.wearingChip, accent: true, accentColor: branchTheme.bright),
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
                                  border: Border.all(color: AppColors.line, width: 1),
                                ),
                                child: Icon(
                                  _voice ? Icons.volume_up : Icons.volume_off,
                                  color: _voice ? branchTheme.bright : AppColors.inkMuted,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                            step: _step,
                            steps: steps,
                            voice: _voice,
                          ),
                  ),
                  if (!_complete) _navRow(context, steps, branchTheme.accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, List<_WearingStep> steps, Color accent) {
    final l = context.l10n;
    final isLast = _step == steps.length - 1;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 18 + MediaQuery.of(context).viewPadding.bottom,
        top: 8,
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: GhostButton(
                label: l.wearingPrev,
                icon: const Icon(Icons.arrow_back, size: 14),
                onPressed: () => setState(() => _step--),
              ),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: isLast
                  ? l.wearingFinish
                  : l.wearingNextLabel(steps[_step + 1].label),
              gradient: true,
              accentColor: accent,
              trailingIcon: const Icon(Icons.arrow_forward, size: 14),
              onPressed: () {
                if (isLast) {
                  setState(() => _complete = true);
                } else {
                  setState(() => _step++);
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
  });
  final int step;
  final List<_WearingStep> steps;
  final bool voice;

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
          // Silhouette + active zone
          Center(
            child: SizedBox(
              width: 140,
              height: 240,
              child: CustomPaint(
                painter: _SilhouettePainter(
                  highlightStep: cur.id,
                  accent: branchTheme.bright,
                ),
              ),
            ),
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
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(cur.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cur.label,
                              style: AppTextStyles.title(fontSize: 18)),
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
                        child: const Icon(Icons.replay, color: Colors.white, size: 16),
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
                      Icon(Icons.straighten, color: branchTheme.bright, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cur.tip.toUpperCase(),
                          style: AppTextStyles.mono(
                            fontSize: 10.5,
                            color: AppColors.ink,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.highlightStep, required this.accent});
  final String highlightStep;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = Colors.white.withValues(alpha: 0.16);
    canvas.drawCircle(Offset(w * 0.5, h * 0.10), w * 0.10, body);
    canvas.drawRect(Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55), body);
    canvas.drawRect(Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.49, h * 0.95), body);
    canvas.drawRect(Rect.fromLTRB(w * 0.51, h * 0.55, w * 0.70, h * 0.95), body);

    // Highlight zone
    Rect zone = Rect.zero;
    switch (highlightStep) {
      case 'trousers':
        zone = Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.70, h * 0.95);
        break;
      case 'belt':
        zone = Rect.fromLTRB(w * 0.30, h * 0.50, w * 0.70, h * 0.58);
        break;
      case 'shirt':
        zone = Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55);
        break;
      case 'medals':
      case 'badges':
        zone = Rect.fromLTRB(w * 0.30, h * 0.27, w * 0.50, h * 0.40);
        break;
      case 'nametag':
        zone = Rect.fromLTRB(w * 0.50, h * 0.27, w * 0.70, h * 0.40);
        break;
      case 'collar':
        zone = Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.27);
        break;
      case 'lanyard':
        zone = Rect.fromLTRB(w * 0.55, h * 0.22, w * 0.70, h * 0.40);
        break;
      case 'headdress':
        zone = Rect.fromLTRB(w * 0.30, h * 0.0, w * 0.70, h * 0.20);
        break;
    }
    canvas.drawRect(
      zone,
      Paint()..color = accent.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.highlightStep != highlightStep || old.accent != accent;
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.stepCount,
    required this.steps,
    required this.onScan,
    required this.onRestart,
  });
  final int stepCount;
  final List<_WearingStep> steps;
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
          Text(l.wearingCompleteTitle, style: AppTextStyles.title(fontSize: 26)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      Text(s.label,
                          style: AppTextStyles.body(color: AppColors.ink, fontSize: 11.5)),
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
