import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/dress_code.dart';

class RebuildingScreen extends ConsumerStatefulWidget {
  const RebuildingScreen({super.key});

  @override
  ConsumerState<RebuildingScreen> createState() => _RebuildingScreenState();
}

class _RebuildingScreenState extends ConsumerState<RebuildingScreen> {
  double _progress = 0;
  int _current = 0;
  Timer? _timer;
  static const int _dressCount = 5;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      setState(() {
        _progress = (_progress + 3).clamp(0, 100).toDouble();
        _current = ((_progress / 100) * _dressCount).floor().clamp(0, _dressCount - 1);
      });
      if (_progress >= 100) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go(Routes.dashboard);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final dresses = DressCode.values;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: branchTheme.bright),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _RingChart(progress: _progress / 100, accent: branchTheme.bright),
                          const SizedBox(height: 24),
                          Text(l.rebuildingEyebrow,
                              style: AppTextStyles.eyebrow(),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          Text(l.rebuildingTitle,
                              style: AppTextStyles.title(fontSize: 22),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text(
                            '${dresses[_current].name(l)} · ${dresses[_current].code(l)}',
                            style: AppTextStyles.mono(
                              fontSize: 11,
                              color: branchTheme.bright,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          for (var i = 0; i < dresses.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _DressRow(
                              label: '${dresses[i].code(l)} ${dresses[i].name(l)}',
                              done: _progress >= ((i + 1) / dresses.length) * 100,
                              active: _current == i && _progress < 100,
                              accent: branchTheme.bright,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l.rebuildingFooter,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.mono(
                        fontSize: 10,
                        color: AppColors.inkSubtle,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingChart extends StatelessWidget {
  const _RingChart({required this.progress, required this.accent});
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: '${(progress * 100).floor()}',
                    style: AppTextStyles.mono(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      letterSpacing: 0,
                    ),
                  ),
                  TextSpan(
                    text: '%',
                    style: AppTextStyles.mono(
                      fontSize: 13,
                      color: AppColors.inkSubtle,
                      letterSpacing: 0,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                'REBUILDING',
                style: AppTextStyles.mono(
                  fontSize: 9,
                  color: AppColors.inkSubtle,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DressRow extends StatelessWidget {
  const _DressRow({
    required this.label,
    required this.done,
    required this.active,
    required this.accent,
  });
  final String label;
  final bool done;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? AppColors.ok.withValues(alpha: 0.07)
        : active
            ? accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.03);
    final dotColor = done
        ? AppColors.ok
        : active
            ? accent
            : Colors.white.withValues(alpha: 0.15);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mono(
                fontSize: 11,
                color: done
                    ? AppColors.ok
                    : active
                        ? AppColors.ink
                        : AppColors.inkSubtle,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (done)
            const Icon(Icons.check, color: AppColors.ok, size: 14)
          else if (active)
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
        ],
      ),
    );
  }
}
