import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../ar_engine/presentation/providers/generated_dress_provider.dart';
import '../../../ar_engine/presentation/providers/model_generation_controller.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({super.key, required this.dress});
  final DressCode dress;

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  // Progress is 0-100; caps at 90 until the CF reports ready (then jumps to 100)
  int _progress = 0;
  int _stage = 0;
  Timer? _timer;
  Timer? _timeoutTimer;
  bool _navigated = false;
  bool _hasFailed = false;

  // Matches the CF client-side timeout (90s) plus a small buffer
  static const int _timeoutSeconds = 95;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (_progress < 90) {
        setState(() {
          _progress += 1;
          _stage = ((_progress / 100) * 4).floor().clamp(0, 3);
        });
      }
    });
  }

  // Safety net: if the CF hasn't responded within 95s (or is stuck
  // in a stale generating state), force an error so the user can retry.
  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: _timeoutSeconds), () {
      if (!mounted || _navigated || _hasFailed) return;
      // markGenerationFailed clears generationStartedAt so a retry can
      // call generate() without hitting the in-flight idempotency guard.
      ref
          .read(uniformProfileProvider.notifier)
          .markGenerationFailed(widget.dress, 'Generation timed out.');
      _timer?.cancel();
      setState(() => _hasFailed = true);
    });
  }

  void _retry() {
    _timeoutTimer?.cancel();
    setState(() {
      _hasFailed = false;
      _progress = 0;
      _stage = 0;
    });
    _startTimer();
    _startTimeout();
    ref.read(modelGenerationControllerProvider.notifier).generate(widget.dress);
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(modelGenerationControllerProvider.notifier).generate(widget.dress);
      _startTimeout();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ModelStatus>(modelStatusProvider(widget.dress), (prev, next) {
      if (!mounted || _navigated) return;
      if (next == ModelStatus.ready) {
        _navigated = true;
        _timer?.cancel();
        _timeoutTimer?.cancel();
        setState(() => _progress = 100);
        final router = GoRouter.of(context);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) router.go(Routes.ghostModel);
        });
      } else if (next == ModelStatus.failed) {
        _timer?.cancel();
        _timeoutTimer?.cancel();
        setState(() => _hasFailed = true);
      }
    });

    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final stages = [
      l.generatingStage1,
      l.generatingStage2,
      l.generatingStage3,
      l.generatingStage4,
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: branchTheme.bright),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => context.go(Routes.dashboard),
                          child: Text(
                            l.commonCancel,
                            style: AppTextStyles.body(color: Colors.white70),
                          ),
                        ),
                        AppChip(
                          label: l.generatingChip,
                          accent: true,
                          accentColor: branchTheme.bright,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _hasFailed
                      ? _ErrorState(
                          accent: branchTheme.bright,
                          onRetry: _retry,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Ring(
                              progress: _progress / 100.0,
                              accent: branchTheme.bright,
                            ),
                            const SizedBox(height: 28),
                            Text(
                              '${widget.dress.name(l)} · ${widget.dress.code(l)}',
                              style: AppTextStyles.eyebrow(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.generatingTitle,
                              style: AppTextStyles.title(fontSize: 22),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              stages[_stage],
                              style: AppTextStyles.mono(
                                fontSize: 11,
                                color: branchTheme.bright,
                                letterSpacing: 1.6,
                              ).copyWith(),
                            ),
                            // Once the ring caps at 90%, let the user know
                            // the server is still working on the model
                            if (_progress >= 90) ...[
                              const SizedBox(height: 8),
                              Text(
                                'This may take a moment...',
                                style: AppTextStyles.mono(
                                  fontSize: 10,
                                  color: AppColors.inkSubtle,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Text(
                    l.generatingFooter,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mono(
                      fontSize: 10,
                      color: AppColors.inkSubtle,
                      letterSpacing: 1.8,
                    ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.accent, required this.onRetry});
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: accent, size: 48),
          const SizedBox(height: 16),
          Text(
            'GENERATION FAILED',
            style: AppTextStyles.mono(
              fontSize: 11,
              color: accent,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Something went wrong building\nyour uniform model.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(color: Colors.white70),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'TRY AGAIN', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress, required this.accent});
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.10),
              border: Border.all(color: accent, width: 1),
            ),
            alignment: Alignment.center,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(
                  text: '${(progress * 100).floor()}',
                  style: AppTextStyles.mono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0,
                  ),
                ),
                TextSpan(
                  text: '%',
                  style: AppTextStyles.mono(
                    fontSize: 12,
                    color: AppColors.inkSubtle,
                    letterSpacing: 0,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
