import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

enum _ArPhase { aligning, aligned, scorecard }

class ARScannerScreen extends ConsumerStatefulWidget {
  const ARScannerScreen({super.key});

  @override
  ConsumerState<ARScannerScreen> createState() => _ARScannerScreenState();
}

class _ARScannerScreenState extends ConsumerState<ARScannerScreen> {
  _ArPhase _phase = _ArPhase.aligning;
  Timer? _timer;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Auto transition to aligned after 1.8s for demo
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _phase = _ArPhase.aligned);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _capture() {
    setState(() {
      _phase = _ArPhase.scorecard;
      _score = 86;
    });
  }

  void _rescan() {
    _timer?.cancel();
    setState(() => _phase = _ArPhase.aligning);
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _phase = _ArPhase.aligned);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _ArPhase.scorecard) {
      return _Scorecard(score: _score, onRescan: _rescan);
    }
    return _ScanningPhase(
      aligned: _phase == _ArPhase.aligned,
      onCapture: _capture,
      onClose: () => context.go(Routes.ghostModel),
    );
  }
}

class _ScanningPhase extends StatelessWidget {
  const _ScanningPhase({
    required this.aligned,
    required this.onCapture,
    required this.onClose,
  });
  final bool aligned;
  final VoidCallback onCapture;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera placeholder dark gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  branchTheme.bright.withValues(alpha: 0.10),
                  Colors.black,
                ],
              ),
            ),
          ),
          // Corner brackets
          const Positioned.fill(child: _CornerBrackets()),
          // Ghost figure overlay
          Center(
            child: SizedBox(
              width: 200,
              height: 380,
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  painter: _GhostOverlayPainter(
                    accent: aligned ? AppColors.ok : AppColors.warn,
                  ),
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(icon: Icons.close, onTap: onClose),
                AppChip(
                  label: l.arLive,
                  accent: true,
                  accentColor: AppColors.err,
                  icon: const Icon(Icons.fiber_manual_record),
                ),
                _CircleBtn(icon: Icons.info_outline, onTap: () {}),
              ],
            ),
          ),
          // Status banner
          Positioned(
            bottom: 140 + MediaQuery.of(context).viewPadding.bottom,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (aligned ? AppColors.ok : AppColors.warn)
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: aligned ? AppColors.ok : AppColors.warn,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    aligned ? Icons.check_circle_outline : Icons.adjust,
                    color: aligned ? AppColors.ok : AppColors.warn,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          aligned ? l.arAlignedTitle : l.arAligning,
                          style: AppTextStyles.bodyStrong(
                              color: AppColors.ink, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          aligned ? l.arAlignedSub : l.arAligningSub,
                          style: AppTextStyles.body(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capture button
          Positioned(
            bottom: 32 + MediaQuery.of(context).viewPadding.bottom,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: aligned ? onCapture : null,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: aligned ? AppColors.ok : Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: aligned
                        ? [
                            BoxShadow(
                              color: AppColors.ok.withValues(alpha: 0.6),
                              blurRadius: 24,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();
  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.6);
    return Stack(
      children: [
        Positioned(top: 70, left: 24, child: _bracket(color, Alignment.topLeft)),
        Positioned(top: 70, right: 24, child: _bracket(color, Alignment.topRight)),
        Positioned(bottom: 220, left: 24, child: _bracket(color, Alignment.bottomLeft)),
        Positioned(bottom: 220, right: 24, child: _bracket(color, Alignment.bottomRight)),
      ],
    );
  }

  Widget _bracket(Color color, Alignment a) {
    final stroke = Border(
      top: a.y < 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      bottom: a.y > 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      left: a.x < 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      right: a.x > 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
    );
    return SizedBox(
      width: 30,
      height: 30,
      child: DecoratedBox(decoration: BoxDecoration(border: stroke)),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _GhostOverlayPainter extends CustomPainter {
  _GhostOverlayPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.10), w * 0.10, paint);
    canvas.drawRect(Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55), paint);
    canvas.drawRect(Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.49, h * 0.95), paint);
    canvas.drawRect(Rect.fromLTRB(w * 0.51, h * 0.55, w * 0.70, h * 0.95), paint);
  }

  @override
  bool shouldRepaint(covariant _GhostOverlayPainter old) => old.accent != accent;
}

class _Scorecard extends ConsumerWidget {
  const _Scorecard({required this.score, required this.onRescan});
  final int score;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    final profile = ref.watch(uniformProfileProvider);
    final color = score >= 90
        ? AppColors.ok
        : score >= 70
            ? AppColors.warn
            : AppColors.err;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppChip(
                      label: l.arVerification,
                      accent: true,
                      accentColor: branchTheme.bright,
                    ),
                    Text(
                      DateTime.now()
                          .toString()
                          .substring(0, 10),
                      style: AppTextStyles.mono(
                        fontSize: 10.5,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 12),
                    Center(child: _ScoreRing(score: score, color: color)),
                    const SizedBox(height: 24),
                    Text(
                      l.arRedAlerts(2),
                      style: AppTextStyles.bodyStrong(color: AppColors.warn, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _IssueCard(title: l.arIssue1Title, body: l.arIssue1Body),
                    const SizedBox(height: 8),
                    _IssueCard(title: l.arIssue2Title, body: l.arIssue2Body),
                    const SizedBox(height: 18),
                    Text(
                      l.arGreenChecks(4),
                      style: AppTextStyles.bodyStrong(color: AppColors.ok, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    for (final p in [l.arPass1, l.arPass2, l.arPass3, l.arPass4])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _PassCard(label: p),
                      ),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      childAspectRatio: 1.7,
                      children: [
                        _MetaTile(label: l.arMetaSvc, value: profile.branch.name.toUpperCase()),
                        _MetaTile(label: l.arMetaRnk, value: profile.rank.code),
                        _MetaTile(label: l.arMetaMed, value: '${profile.medalRowCount}'),
                        _MetaTile(label: l.arMetaBdg, value: '0'),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
                  top: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        label: l.arRescan,
                        icon: const Icon(Icons.refresh, size: 14),
                        onPressed: onRescan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: l.arShare,
                        gradient: true,
                        accentColor: branchTheme.accent,
                        icon: const Icon(Icons.ios_share, size: 14),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score%',
                  style: AppTextStyles.title(color: AppColors.ink, fontSize: 30)),
              const SizedBox(height: 4),
              Text(l.arCompliance,
                  style: AppTextStyles.mono(
                    fontSize: 9.5,
                    color: AppColors.inkSubtle,
                    letterSpacing: 1.8,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.err.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.err.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.err, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong(color: AppColors.ink, fontSize: 13)),
                const SizedBox(height: 2),
                Text(body, style: AppTextStyles.body(color: AppColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ok.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(color: AppColors.ok.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ok),
            child: const Icon(Icons.check, color: AppColors.bg, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTextStyles.body(color: AppColors.ink, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: AppTextStyles.mono(
                fontSize: 9,
                color: AppColors.inkSubtle,
                letterSpacing: 1.4,
              )),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong(color: AppColors.ink, fontSize: 13)),
        ],
      ),
    );
  }
}
