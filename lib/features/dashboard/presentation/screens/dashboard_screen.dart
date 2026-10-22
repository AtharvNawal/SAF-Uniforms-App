import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/saf_crest_logo.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../tabs/gallery_tab.dart';
import '../tabs/home_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/wardrobe_tab.dart';
import '../widgets/settings_sheet.dart';

enum DashTab { home, wardrobe, gallery, profile }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashTab _tab = DashTab.home;

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final mq = MediaQuery.of(context);
    final profile = ref.watch(uniformProfileProvider);
    final dressStates = {
      for (final dc in DressCode.values)
        dc: profile.generatedDresses.containsKey(dc.requirementDocId)
            ? 'ready'
            : 'idle',
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(
            accentColor: branchTheme.bright,
            opacity: 0.25,
            gradientCenter: const Alignment(0, -1),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _AppBar(onOpenSettings: () => showSettingsSheet(context)),
                Expanded(
                  child: IndexedStack(
                    index: _tab.index,
                    children: [
                      HomeTab(
                        dressStates: dressStates,
                        onOpenDress: (d) {
                          // The dress picked here is the one the 3D figure
                          // and the AR Scanner show / check.
                          if (profile.dressCode != d) {
                            log(
                              'active dress ${profile.dressCode.wireName} -> ${d.wireName}',
                              name: 'dashboard',
                            );
                            ref
                                .read(uniformProfileProvider.notifier)
                                .setDressCode(d);
                          }
                          if (dressStates[d] == 'ready') {
                            context.go(Routes.ghostModel);
                          } else {
                            context.push(
                              '${Routes.dressAccessories}?dress=${d.wireName}',
                            );
                          }
                        },
                        onSetup: () => context.go(Routes.config),
                      ),
                      const WardrobeTab(),
                      const GalleryTab(),
                      ProfileTab(onUpdate: () => context.go(Routes.rebuilding)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              tab: _tab,
              onChange: (t) => setState(() => _tab = t),
              bottomInset: mq.viewPadding.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBar extends ConsumerWidget {
  const _AppBar({required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final branch = ref.watch(currentBranchProvider);
    final profile = ref.watch(uniformProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final accent = context.branchTheme.bright;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.25), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const SafCrestLogo(size: 33),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName
                      : l.commonSoldier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong(
                    color: AppColors.ink,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${branch.label(l)} · ${profile.rank.code}',
                  style: AppTextStyles.mono(
                    fontSize: 9,
                    color: accent,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .set(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.settings_outlined, onTap: onOpenSettings),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tab,
    required this.onChange,
    required this.bottomInset,
  });
  final DashTab tab;
  final ValueChanged<DashTab> onChange;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = context.branchTheme.bright;
    final tabs = [
      (DashTab.home, l.navHome, Icons.home_outlined),
      (DashTab.wardrobe, l.navWardrobe, Icons.checkroom_outlined),
      (DashTab.gallery, l.navGallery, Icons.photo_library_outlined),
      (DashTab.profile, l.navProfile, Icons.person_outline),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xF80B0D0E), Color(0x000B0D0E)],
          stops: [0.6, 1.0],
        ),
        border: Border(
          top: BorderSide(color: accent.withValues(alpha: 0.25), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, 4, 8, 8 + bottomInset),
      child: Row(
        children: [
          for (final t in tabs)
            Expanded(
              child: _NavItem(
                label: t.$2,
                icon: t.$3,
                active: tab == t.$1,
                accent: accent,
                onTap: () => onChange(t.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    color: active ? accent : AppColors.inkMuted,
                    size: 20,
                  ),
                  if (active)
                    Positioned(
                      top: -8,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          boxShadow: [BoxShadow(color: accent, blurRadius: 8)],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.mono(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? accent : AppColors.inkMuted,
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

/// Helper extension for AppLocalizations dress code/code/name lookups
/// (also used by the Home + Wardrobe tabs).
String dressCodeLabel(AppLocalizations l, DressCode d) => switch (d) {
  DressCode.no1 => l.dressNo1Code,
  DressCode.no2 => l.dressNo2Code,
  DressCode.no3 => l.dressNo3Code,
  DressCode.no4 => l.dressNo4Code,
  DressCode.no5 => l.dressNo5Code,
};

String dressNameLabel(AppLocalizations l, DressCode d) => switch (d) {
  DressCode.no1 => l.dressNo1Name,
  DressCode.no2 => l.dressNo2Name,
  DressCode.no3 => l.dressNo3Name,
  DressCode.no4 => l.dressNo4Name,
  DressCode.no5 => l.dressNo5Name,
};

String dressTagLabel(AppLocalizations l, DressCode d) => switch (d) {
  DressCode.no1 => l.dressNo1Tag,
  DressCode.no2 => l.dressNo2Tag,
  DressCode.no3 => l.dressNo3Tag,
  DressCode.no4 => l.dressNo4Tag,
  DressCode.no5 => l.dressNo5Tag,
};
