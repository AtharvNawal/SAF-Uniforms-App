import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/check_card.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../models/accessory_item.dart';
import '../widgets/accessory_detail_sheet.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final items = AccessoryItem.all(l);
    final total = items.length;
    final done = items.where((a) => _checked.contains(a.id)).length;
    final allDone = done == total;

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
                          onPressed: () => context.go(Routes.dashboard),
                          style: const ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.only(top: 8, right: 8, bottom: 8),
                            ),
                          ),
                        ),
                        Text(
                          '$done / $total',
                          style: AppTextStyles.mono(
                            fontSize: 10.5,
                            color: AppColors.inkMuted,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress card
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.line, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l.checklistVerified,
                                style: AppTextStyles.mono(
                                  fontSize: 10,
                                  color: AppColors.inkMuted,
                                  letterSpacing: 1.8,
                                )),
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: '$done',
                                  style: AppTextStyles.bodyStrong(
                                    color: AppColors.ink,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / $total',
                                  style: AppTextStyles.body(
                                    color: AppColors.inkSubtle,
                                    fontSize: 13,
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation(branchTheme.bright),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      padding: const EdgeInsets.only(bottom: 110),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final accent = context.branchTheme.bright;
                        final card = CheckCard(
                          title: item.title,
                          subtitle: _checked.contains(item.id)
                              ? '${l.checklistVerifiedPrefix} ${l.checklistTapToView}'
                              : l.checklistTapToView,
                          icon: item.icon,
                          checked: _checked.contains(item.id),
                          onTap: () => showAccessoryDetailSheet(
                            context: context,
                            item: item,
                            onMarkVerified: () => setState(() => _checked.add(item.id)),
                          ),
                          onToggle: () => setState(() {
                            if (_checked.contains(item.id)) {
                              _checked.remove(item.id);
                            } else {
                              _checked.add(item.id);
                            }
                          }),
                        );
                        return Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            card,
                            Positioned(
                              top: 7,
                              right: 12,
                              child: Text(
                                l.wardrobeMandatoryChip.toUpperCase(),
                                style: AppTextStyles.mono(
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                  letterSpacing: 1.7,
                                ),
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
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: PrimaryButton(
                label: allDone
                    ? l.checklistAllVerified
                    : l.checklistVerifyMore(total - done),
                gradient: allDone,
                accentColor: branchTheme.accent,
                icon: allDone ? const Icon(Icons.check, size: 16) : null,
                onPressed: allDone ? () => context.go(Routes.ghostModel) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
