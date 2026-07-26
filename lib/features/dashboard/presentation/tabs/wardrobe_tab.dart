import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/design/widgets/check_card.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../checklist/domain/entities/dress_requirement.dart';
import '../../../checklist/presentation/providers/dress_accessories_provider.dart';
import '../../../checklist/presentation/providers/dress_requirements_provider.dart';
import '../../../checklist/presentation/widgets/accessory_detail_sheet.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

class WardrobeTab extends ConsumerStatefulWidget {
  const WardrobeTab({super.key});

  @override
  ConsumerState<WardrobeTab> createState() => _WardrobeTabState();
}

class _WardrobeTabState extends ConsumerState<WardrobeTab> {
  WardrobeFilter _filter = const AllAccessoriesFilter();

  @override
  Widget build(BuildContext context) {
    final accent = context.branchTheme.bright;
    final progress = ref.watch(wardrobeProgressProvider(_filter));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterTrigger(
            filter: _filter,
            accent: accent,
            onTap: () => _openFilterSheet(context),
          ),
          const SizedBox(height: 14),
          _VerifiedCard(
            checked: progress.checked,
            total: progress.total,
            accent: accent,
          ),
          const SizedBox(height: 14),
          Expanded(child: _AccessoryList(filter: _filter)),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final l = context.l10n;
    final dresses = ref.read(dressRequirementsAllProvider).value ??
        const <DressRequirement>[];
    final sortedDresses = [...dresses]..sort((a, b) => a.id.compareTo(b.id));
    final selected = await showAppBottomSheet<WardrobeFilter>(
      context: context,
      builder: (ctx) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                l.checklistDressCode.toUpperCase(),
                style: AppTextStyles.mono(
                  fontSize: 10.5,
                  color: AppColors.inkMuted,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            _FilterOptionRow(
              chip: l.wardrobeFilterAllChip,
              title: l.checklistDressAll,
              subtitle: l.checklistDressAllDesc,
              selected: _filter is AllAccessoriesFilter,
              onTap: () => Navigator.of(ctx).pop(const AllAccessoriesFilter()),
            ),
            for (final d in sortedDresses) ...[
              const SizedBox(height: 8),
              _FilterOptionRow(
                chip: _shortCodeFromDressId(d.id, l),
                title: d.dressName,
                subtitle: l.wardrobeFilterDressSubtitle(d.dressName),
                selected: _filter is SingleDressFilter &&
                    (_filter as SingleDressFilter).dressId == d.id,
                onTap: () =>
                    Navigator.of(ctx).pop(SingleDressFilter(d.id)),
              ),
            ],
          ],
        );
      },
    );
    if (selected != null && selected != _filter) {
      setState(() => _filter = selected);
    }
  }
}

DressCode? _safeDressCodeFromRequirementId(String dressId) {
  // Doc ids are 'no_1_dress_requirements' .. 'no_5_dress_requirements'.
  switch (dressId) {
    case 'no_1_dress_requirements':
      return DressCode.no1;
    case 'no_2_dress_requirements':
      return DressCode.no2;
    case 'no_3_dress_requirements':
      return DressCode.no3;
    case 'no_4_dress_requirements':
      return DressCode.no4;
    case 'no_5_dress_requirements':
      return DressCode.no5;
  }
  return null;
}

String _shortCodeFromDressId(String dressId, AppLocalizations l) {
  final code = _safeDressCodeFromRequirementId(dressId);
  return code?.code(l) ?? dressId.toUpperCase();
}

class _FilterTrigger extends StatelessWidget {
  const _FilterTrigger({
    required this.filter,
    required this.accent,
    required this.onTap,
  });

  final WardrobeFilter filter;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Consumer(
      builder: (ctx, ref, _) {
        String chipLabel;
        String title;
        String subtitle;
        switch (filter) {
          case AllAccessoriesFilter():
            chipLabel = l.wardrobeFilterAllChip;
            title = l.checklistDressAll;
            subtitle = l.checklistDressAllDesc;
          case SingleDressFilter(:final dressId):
            chipLabel = _shortCodeFromDressId(dressId, l);
            final asyncDresses = ref.watch(dressRequirementsAllProvider);
            final match = asyncDresses.value?.where((d) => d.id == dressId);
            final name =
                (match != null && match.isNotEmpty) ? match.first.dressName : dressId;
            title = name;
            subtitle = l.wardrobeFilterDressSubtitle(name);
        }
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.line, width: 1),
              ),
              child: Row(
                children: [
                  AppChip(label: chipLabel, accent: true, accentColor: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong(color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.mono(
                            fontSize: 10.5,
                            color: AppColors.inkMuted,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white70, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterOptionRow extends StatelessWidget {
  const _FilterOptionRow({
    required this.chip,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String chip;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.branchTheme.bright;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.6) : AppColors.line,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AppChip(label: chip, accent: true, accentColor: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong(color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.mono(
                        fontSize: 10.5,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final progressValue = total == 0 ? 0.0 : checked / total;
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
                value: progressValue.clamp(0.0, 1.0),
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

class _AccessoryList extends ConsumerWidget {
  const _AccessoryList({required this.filter});

  final WardrobeFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (filter) {
      case AllAccessoriesFilter():
        final asyncCombined = ref.watch(allDressesAccessoriesCombinedProvider);
        return asyncCombined.when(
          data: (list) {
            if (list.isEmpty) return const _EmptyDressState();
            return _AllAccessoriesList(items: list);
          },
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString()),
        );
      case SingleDressFilter(:final dressId):
        final asyncSplit = ref.watch(dressAccessoriesByIdProvider(dressId));
        return asyncSplit.when(
          data: (split) {
            if (split.mandatory.isEmpty && split.optional.isEmpty) {
              return const _EmptyDressState();
            }
            return _SingleDressAccessoryList(
              dressId: dressId,
              mandatory: split.mandatory,
              optional: split.optional,
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(message: e.toString()),
        );
    }
  }
}

class _SingleDressAccessoryList extends ConsumerWidget {
  const _SingleDressAccessoryList({
    required this.dressId,
    required this.mandatory,
    required this.optional,
  });

  final String dressId;
  final List<Accessory> mandatory;
  final List<Accessory> optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accent = context.branchTheme.bright;
    final checks =
        ref.watch(uniformProfileProvider).dressAccessoryChecks[dressId] ??
            const <String>{};

    final entries = <_RowEntry>[
      for (final a in mandatory)
        _RowEntry(accessory: a, label: l.wardrobeMandatoryChip, mandatory: true),
      for (final a in optional)
        _RowEntry(accessory: a, label: l.wardrobeOptionalChip, mandatory: false),
    ];

    return ListView.separated(
      itemCount: entries.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final acc = entry.accessory;
        final checked = checks.contains(acc.id);
        return _AccessoryRow(
          accessory: acc,
          checked: checked,
          mandatoryLabel: entry.label,
          mandatory: entry.mandatory,
          accent: accent,
          onTap: () => showAccessoryDetailSheetForAccessory(
            context: context,
            accessory: acc,
            onMarkVerified: () {
              ref
                  .read(uniformProfileProvider.notifier)
                  .setDressAccessoryChecked(dressId, acc.id, checked: true);
            },
          ),
          onToggle: () {
            ref
                .read(uniformProfileProvider.notifier)
                .toggleDressAccessory(dressId, acc.id);
          },
        );
      },
    );
  }
}

class _AllAccessoriesList extends ConsumerWidget {
  const _AllAccessoriesList({required this.items});

  final List<Accessory> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.branchTheme.bright;
    final profile = ref.watch(uniformProfileProvider);
    final asyncIndex = ref.watch(accessoryDressIndexProvider);
    final index = asyncIndex.value ?? const <String, Set<String>>{};

    bool isChecked(Accessory a) {
      final dressIds = index[a.id] ?? const <String>{};
      for (final dId in dressIds) {
        if ((profile.dressAccessoryChecks[dId] ?? const <String>{})
            .contains(a.id)) {
          return true;
        }
      }
      return false;
    }

    return ListView.separated(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final acc = items[i];
        final checked = isChecked(acc);
        return _AccessoryRow(
          accessory: acc,
          checked: checked,
          mandatoryLabel: null,
          mandatory: false,
          accent: accent,
          onTap: () => showAccessoryDetailSheetForAccessory(
            context: context,
            accessory: acc,
            onMarkVerified: () =>
                _setAcrossAllDresses(ref, acc.id, index, true),
          ),
          onToggle: () => _setAcrossAllDresses(ref, acc.id, index, !checked),
        );
      },
    );
  }

  void _setAcrossAllDresses(
    WidgetRef ref,
    String accessoryId,
    Map<String, Set<String>> index,
    bool checked,
  ) {
    final notifier = ref.read(uniformProfileProvider.notifier);
    final dressIds = index[accessoryId] ?? const <String>{};
    if (dressIds.isEmpty) return;
    for (final dId in dressIds) {
      notifier.setDressAccessoryChecked(dId, accessoryId, checked: checked);
    }
  }
}

class _RowEntry {
  const _RowEntry({
    required this.accessory,
    required this.label,
    required this.mandatory,
  });
  final Accessory accessory;
  final String label;
  final bool mandatory;
}

class _AccessoryRow extends StatelessWidget {
  const _AccessoryRow({
    required this.accessory,
    required this.checked,
    required this.mandatoryLabel,
    required this.mandatory,
    required this.accent,
    required this.onTap,
    required this.onToggle,
  });

  final Accessory accessory;
  final bool checked;
  final String? mandatoryLabel;
  final bool mandatory;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final icon = iconForAccessoryCategory(accessory.category);
    final card = CheckCard(
      title: accessory.displayName.isEmpty ? accessory.id : accessory.displayName,
      subtitle: l.checklistTapToView,
      icon: icon,
      imageUrl: accessory.imageUrl,
      checked: checked,
      onTap: onTap,
      onToggle: onToggle,
    );
    if (mandatoryLabel == null) return card;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        card,
        Positioned(
          top: 7,
          right: 12,
          child: Text(
            mandatoryLabel!.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 6.5,
              fontWeight: FontWeight.w600,
              color: mandatory ? accent : AppColors.inkSubtle,
              letterSpacing: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDressState extends StatelessWidget {
  const _EmptyDressState();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
        ),
      ),
    );
  }
}
