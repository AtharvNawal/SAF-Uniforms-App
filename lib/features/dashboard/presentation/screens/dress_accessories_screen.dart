import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/design/widgets/check_card.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../checklist/presentation/providers/dress_accessories_provider.dart';
import '../../../checklist/presentation/providers/dress_requirements_provider.dart';
import '../../../checklist/presentation/widgets/accessory_detail_sheet.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

class DressAccessoriesScreen extends ConsumerWidget {
  const DressAccessoriesScreen({super.key, required this.dress});

  final DressCode dress;

  String get _dressId => switch (dress) {
        DressCode.no1 => 'no_1_dress_requirements',
        DressCode.no2 => 'no_2_dress_requirements',
        DressCode.no3 => 'no_3_dress_requirements',
        DressCode.no4 => 'no_4_dress_requirements',
        DressCode.no5 => 'no_5_dress_requirements',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('DressAccessoriesScreen.build: dress=${dress.wireName}',
        name: 'dress_accessories');

    final l = context.l10n;
    final branchTheme = context.branchTheme;
    final accent = branchTheme.bright;
    final dressId = _dressId;

    final asyncSplit = ref.watch(dressAccessoriesByIdProvider(dressId));
    final profile = ref.watch(uniformProfileProvider);
    final checked = profile.dressAccessoryChecks[dressId] ?? const <String>{};

    final asyncReqs = ref.watch(dressRequirementsAllProvider);
    final dressName = asyncReqs.value
            ?.where((r) => r.id == dressId)
            .map((r) => r.dressName)
            .firstOrNull ??
        dress.name(l);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: accent),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => context.pop(),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.line, width: 1),
                              ),
                              child: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dressName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.bodyStrong(color: AppColors.ink),
                          ),
                        ),
                        AppChip(
                          label: dress.code(l),
                          accent: true,
                          accentColor: accent,
                        ),
                      ],
                    ),
                  ),
                ),
                // Accent divider
                Container(
                    height: 1, color: accent.withValues(alpha: 0.25)),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: asyncSplit.when(
                    loading: () => const LoadingView(),
                    error: (e, st) {
                      log('DressAccessoriesScreen: accessories error',
                          name: 'dress_accessories',
                          error: e,
                          stackTrace: st,
                          level: 1000);
                      return ErrorView(message: e.toString());
                    },
                    data: (split) {
                      final mandatoryChecked = split.mandatory
                          .where((a) => checked.contains(a.id))
                          .length;
                      final allMandatoryChecked = split.mandatory.isEmpty ||
                          split.mandatory
                              .every((a) => checked.contains(a.id));
                      final isEmpty = split.mandatory.isEmpty &&
                          split.optional.isEmpty;

                      return Stack(
                        children: [
                          Column(
                            children: [
                              // ── Sticky verified bar ────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    18, 12, 18, 8),
                                child: _VerifiedCard(
                                  checked: mandatoryChecked,
                                  total: split.mandatory.length,
                                  accent: accent,
                                ),
                              ),
                              // ── Scrollable accessory list ──────────────────
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                      18, 0, 18, 110),
                                  children: [
                                    if (isEmpty) ...[
                                      const SizedBox(height: 16),
                                      _EmptyState(),
                                    ] else ...[
                                      if (split.mandatory.isNotEmpty) ...[
                                        _SectionHeader(
                                          label: l.wardrobeMandatoryChip,
                                          accent: accent,
                                        ),
                                        const SizedBox(height: 10),
                                        ...split.mandatory.map(
                                          (a) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: _AccessoryRow(
                                              accessory: a,
                                              dressId: dressId,
                                              checked: checked.contains(a.id),
                                              mandatory: true,
                                              accent: accent,
                                              onTap: () =>
                                                  showAccessoryDetailSheetForAccessory(
                                                context: context,
                                                accessory: a,
                                                onMarkVerified: () {
                                                  ref
                                                      .read(
                                                          uniformProfileProvider
                                                              .notifier)
                                                      .setDressAccessoryChecked(
                                                          dressId, a.id,
                                                          checked: true);
                                                },
                                              ),
                                              onToggle: () => ref
                                                  .read(uniformProfileProvider
                                                      .notifier)
                                                  .toggleDressAccessory(
                                                      dressId, a.id),
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (split.optional.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        _SectionHeader(
                                          label: l.wardrobeOptionalChip,
                                          accent: AppColors.inkSubtle,
                                        ),
                                        const SizedBox(height: 10),
                                        ...split.optional.map(
                                          (a) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: _AccessoryRow(
                                              accessory: a,
                                              dressId: dressId,
                                              checked: checked.contains(a.id),
                                              mandatory: false,
                                              accent: accent,
                                              onTap: () =>
                                                  showAccessoryDetailSheetForAccessory(
                                                context: context,
                                                accessory: a,
                                                onMarkVerified: () {
                                                  ref
                                                      .read(
                                                          uniformProfileProvider
                                                              .notifier)
                                                      .setDressAccessoryChecked(
                                                          dressId, a.id,
                                                          checked: true);
                                                },
                                              ),
                                              onToggle: () => ref
                                                  .read(uniformProfileProvider
                                                      .notifier)
                                                  .toggleDressAccessory(
                                                      dressId, a.id),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // ── Build button (sticky bottom) ───────────────────
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _BuildButton(
                              allMandatoryChecked: allMandatoryChecked,
                              accent: accent,
                              onTap: () => _onBuildTapped(
                                  context, allMandatoryChecked),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onBuildTapped(BuildContext context, bool allMandatoryChecked) {
    log('DressAccessoriesScreen._onBuildTapped: allMandatoryChecked=$allMandatoryChecked',
        name: 'dress_accessories');
    if (allMandatoryChecked) {
      context.push('${Routes.generating}?dress=${dress.wireName}');
    } else {
      _showIncompleteDialog(context);
    }
  }

  void _showIncompleteDialog(BuildContext context) {
    final l = context.l10n;
    final accent = context.branchTheme.bright;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        title: Text(
          l.dressAccessoriesDialogTitle,
          style: AppTextStyles.bodyStrong(color: AppColors.ink),
        ),
        content: Text(
          l.dressAccessoriesDialogBody,
          style: AppTextStyles.body(
            color: AppColors.inkMuted,
            fontSize: 13,
          ).copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.dressAccessoriesDialogClose,
              style: AppTextStyles.body(
                color: AppColors.inkMuted,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(
                  '${Routes.generating}?dress=${dress.wireName}');
            },
            child: Text(
              l.dressAccessoriesDialogBuild,
              style: AppTextStyles.bodyStrong(color: accent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verified progress card (mandatory count)
// ---------------------------------------------------------------------------

class _VerifiedCard extends StatelessWidget {
  const _VerifiedCard({
    required this.checked,
    required this.total,
    required this.accent,
  });

  final int checked;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final progress = total == 0 ? 0.0 : checked / total;
    final allDone = total > 0 && checked == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Text(
            l.checklistVerified,
            style: AppTextStyles.mono(
              fontSize: 9,
              color: AppColors.inkMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    AlwaysStoppedAnimation(allDone ? AppColors.ok : accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(TextSpan(children: [
            TextSpan(
              text: '$checked',
              style: AppTextStyles.bodyStrong(
                color: allDone ? AppColors.ok : AppColors.ink,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: ' / $total',
              style: AppTextStyles.body(
                color: AppColors.inkSubtle,
                fontSize: 11,
              ),
            ),
          ])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header with accent bar
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.mono(
            fontSize: 10,
            color: accent,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Accessory row — CheckCard + mandatory/optional chip
// ---------------------------------------------------------------------------

class _AccessoryRow extends StatelessWidget {
  const _AccessoryRow({
    required this.accessory,
    required this.dressId,
    required this.checked,
    required this.mandatory,
    required this.accent,
    required this.onTap,
    required this.onToggle,
  });

  final Accessory accessory;
  final String dressId;
  final bool checked;
  final bool mandatory;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final icon = iconForAccessoryCategory(accessory.category);
    final chipLabel =
        mandatory ? l.wardrobeMandatoryChip : l.wardrobeOptionalChip;
    final chipAccentColor = mandatory ? accent : AppColors.inkSubtle;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        CheckCard(
          title: accessory.displayName.isEmpty
              ? accessory.id
              : accessory.displayName,
          subtitle: l.checklistTapToView,
          icon: icon,
          checked: checked,
          onTap: onTap,
          onToggle: onToggle,
        ),
        Positioned(
          top: 7,
          right: 12,
          child: Text(
            chipLabel.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
              color: chipAccentColor,
              letterSpacing: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (pending doctrine)
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.inkMuted, size: 28),
          const SizedBox(height: 12),
          Text(
            l.wardrobeEmptyDress,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyStrong(color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            l.wardrobeEmptyPendingDoctrine,
            textAlign: TextAlign.center,
            style: AppTextStyles.mono(
              fontSize: 10.5,
              color: AppColors.inkMuted,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixed bottom build button
// ---------------------------------------------------------------------------

class _BuildButton extends StatelessWidget {
  const _BuildButton({
    required this.allMandatoryChecked,
    required this.accent,
    required this.onTap,
  });

  final bool allMandatoryChecked;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF0B0D0E), Color(0x000B0D0E)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        24 + mq.viewPadding.bottom,
      ),
      child: PrimaryButton(
        label: l.dressAccessoriesBuildBtn,
        gradient: allMandatoryChecked,
        accentColor: accent,
        trailingIcon: Icon(
          allMandatoryChecked
              ? Icons.arrow_forward
              : Icons.warning_amber_rounded,
          size: 16,
          color: allMandatoryChecked
              ? Colors.white
              : AppColors.warn,
        ),
        onPressed: onTap,
      ),
    );
  }
}
