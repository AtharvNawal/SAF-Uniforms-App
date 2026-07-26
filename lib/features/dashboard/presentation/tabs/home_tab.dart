import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/dress_mini_preview.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../checklist/presentation/providers/dress_requirements_provider.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../screens/dashboard_screen.dart' show dressCodeLabel;

DressCode? _safeDressCode(String id) => switch (id) {
  'no_1_dress_requirements' => DressCode.no1,
  'no_2_dress_requirements' => DressCode.no2,
  'no_3_dress_requirements' => DressCode.no3,
  'no_4_dress_requirements' => DressCode.no4,
  'no_5_dress_requirements' => DressCode.no5,
  _ => null,
};

class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.dressStates,
    required this.onOpenDress,
    required this.onSetup,
  });

  final Map<DressCode, String> dressStates;
  final void Function(DressCode) onOpenDress;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accent = context.branchTheme.bright;
    final profile = ref.watch(uniformProfileProvider);
    final hasMedals = profile.medalRowCount > 0;
    final profileComplete = hasMedals; // simple placeholder until provider supports it

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
      children: [
        if (!profileComplete) _SetupCard(onTap: onSetup),
        if (!profileComplete) const SizedBox(height: 16),
        // Generated dresses → full-width hero card.
        // Unbuilt dresses → small 2-column grid card.
        ref.watch(dressRequirementsAllProvider).when(
              data: (reqs) {
                final generatedReqs = reqs
                    .where((r) => profile.generatedDresses.containsKey(r.id))
                    .toList(growable: false);
                final pendingReqs = reqs
                    .where((r) => !profile.generatedDresses.containsKey(r.id))
                    .toList(growable: false);

                if (generatedReqs.isEmpty && pendingReqs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return LayoutBuilder(
                  builder: (ctx, c) {
                    const spacing = 10.0;
                    final w = (c.maxWidth - spacing) / 2;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final req in generatedReqs) ...[
                          Builder(builder: (_) {
                            final code = _safeDressCode(req.id)!;
                            return _DressCardHero(
                              dress: code,
                              displayName: req.displayName,
                              subtitle: req.subtitle,
                              state: dressStates[code] ?? 'ready',
                              builtAt: profile.generatedDresses[req.id]?.builtAt,
                              onTap: () => onOpenDress(code),
                              accent: accent,
                            );
                          }),
                          const SizedBox(height: 10),
                        ],
                        if (pendingReqs.isNotEmpty)
                          Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: pendingReqs.map((req) {
                              final code = _safeDressCode(req.id);
                              final state = code != null
                                  ? (dressStates[code] ?? 'idle')
                                  : 'idle';
                              return SizedBox(
                                width: w,
                                child: _DressCard(
                                  dressId: req.id,
                                  dressName: req.displayName.isNotEmpty ? req.displayName : req.dressName,
                                  state: state,
                                  onTap: code != null
                                      ? () => onOpenDress(code)
                                      : null,
                                  accent: accent,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const SizedBox(
                height: 112,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => _DressGridError(message: e.toString()),
            ),
        const SizedBox(height: 22),
        Text(l.dashHomeQuickActions, style: AppTextStyles.eyebrow()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _QuickAction(icon: Icons.crop_free, label: l.dashHomeActionAr, accent: accent)),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(icon: Icons.straighten, label: l.dashHomeActionMeasure, accent: accent)),
            const SizedBox(width: 10),
            Expanded(child: _QuickAction(icon: Icons.shield_outlined, label: l.dashHomeActionInspect, accent: accent)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Setup card
// ---------------------------------------------------------------------------

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bright = context.branchTheme.bright;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: AppColors.lineStrong, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Top accent line
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(height: 1.5, color: bright.withValues(alpha: 0.45)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l.dashSetupRequired,
                            style: AppTextStyles.mono(
                              fontSize: 9.5,
                              color: AppColors.ink,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${l.dashSetupTitle1}\n${l.dashSetupTitle2}',
                      style: AppTextStyles.title(fontSize: 19),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.dashSetupBody,
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                      ).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final s in [
                          l.dashSetupStep1,
                          l.dashSetupStep2,
                          l.dashSetupStep3,
                          l.dashSetupStep4,
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.mono(
                                      fontSize: 9,
                                      color: AppColors.inkMuted,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

// ---------------------------------------------------------------------------
// Hero dress card (No. 3)
// ---------------------------------------------------------------------------

String _formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

class _DressCardHero extends StatelessWidget {
  const _DressCardHero({
    required this.dress,
    required this.displayName,
    required this.subtitle,
    required this.state,
    required this.onTap,
    required this.accent,
    this.builtAt,
  });
  final DressCode dress;
  final String displayName;
  final String subtitle;
  final String state;
  final VoidCallback onTap;
  final Color accent;
  final DateTime? builtAt;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = state == 'ready';
    final generating = state == 'generating';
    final bright = context.branchTheme.bright;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.lineStrong, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Top accent line
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(height: 1.5, color: bright.withValues(alpha: 0.45)),
              ),
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Preview pane
                    Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border(
                          right: BorderSide(color: AppColors.line, width: 1),
                        ),
                      ),
                      child: Center(
                        child: ready
                            ? DressMiniPreview(dress: dress, size: 72, accent: accent)
                            : _DressPlaceholder(generating: generating, accent: accent),
                      ),
                    ),
                    // Text pane
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dressCodeLabel(l, dress),
                                  style: AppTextStyles.mono(
                                    fontSize: 9.5,
                                    color: accent,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.title(fontSize: 15),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body(
                                    color: AppColors.inkMuted,
                                    fontSize: 10,
                                  ).copyWith(height: 1.4),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ready && builtAt != null
                                        ? 'BUILT · ${_formatDate(builtAt!)}'
                                        : ready
                                            ? l.dressStateReady
                                            : generating
                                                ? l.dressStateGenerating
                                                : l.dressStateNotBuilt,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.mono(
                                      fontSize: 9,
                                      color: ready
                                          ? AppColors.ok
                                          : generating
                                              ? AppColors.warn
                                              : AppColors.inkMuted,
                                      letterSpacing: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

// ---------------------------------------------------------------------------
// Grid dress card
// ---------------------------------------------------------------------------

class _DressCard extends StatelessWidget {
  const _DressCard({
    required this.dressId,
    required this.dressName,
    required this.state,
    required this.onTap,
    required this.accent,
  });
  final String dressId;
  final String dressName;
  final String state;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = state == 'ready';
    final generating = state == 'generating';
    final bright = context.branchTheme.bright;
    final code = _safeDressCode(dressId);
    final eyebrow = code != null ? dressCodeLabel(l, code) : dressId;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.lineStrong, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Top accent line — same as hero
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(height: 1.5, color: bright.withValues(alpha: 0.45)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 13, 10, 11),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(color: AppColors.lineStrong, width: 1),
                            ),
                          ),
                          if (ready && code != null)
                            DressMiniPreview(dress: code, size: 24, accent: accent),
                          if (generating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (!(ready && code != null) && !generating)
                            Icon(Icons.add, color: AppColors.inkMuted, size: 13),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ready
                                    ? AppColors.ok
                                    : generating
                                        ? AppColors.warn
                                        : AppColors.inkMuted.withValues(alpha: 0.4),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.mono(
                        fontSize: 9.5,
                        color: accent,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dressName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong(color: AppColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ready
                          ? l.dressStateReady
                          : generating
                              ? l.dressStateGenerating
                              : l.dressStateNotBuilt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.mono(
                        fontSize: 9.5,
                        color: ready
                            ? AppColors.ok
                            : generating
                                ? AppColors.warn
                                : AppColors.inkMuted,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dress grid error
// ---------------------------------------------------------------------------

class _DressGridError extends StatelessWidget {
  const _DressGridError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.warn.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.mono(
                fontSize: 10.5,
                color: AppColors.inkMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dress placeholder (not yet built / generating)
// ---------------------------------------------------------------------------

class _DressPlaceholder extends StatelessWidget {
  const _DressPlaceholder({required this.generating, required this.accent});
  final bool generating;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text('BUILDING',
              style: AppTextStyles.mono(
                fontSize: 9,
                color: AppColors.inkMuted,
                letterSpacing: 1.8,
              )),
        ],
      );
    }
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
      ),
      child: Icon(Icons.add, color: AppColors.inkMuted, size: 13),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick action tile
// ---------------------------------------------------------------------------

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.lineStrong, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Top accent line
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 1.5, color: accent.withValues(alpha: 0.45)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.22), width: 1),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.mono(
                      fontSize: 9.5,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.4,
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
