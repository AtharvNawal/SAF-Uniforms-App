import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/design/widgets/saf_crest_logo.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/theme/theme_accent.dart';
import '../../../../core/theme/theme_accent_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) => _SettingsSheetBody(),
    ),
  );
}

class _SettingsSheetBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final branch = ref.watch(currentBranchProvider);
    final accent = ref.watch(themeAccentProvider);
    final isSafCrest = accent is SafCrest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsAppearance, style: AppTextStyles.eyebrow()),
                  const SizedBox(height: 4),
                  Text(l.settingsTheme, style: AppTextStyles.title(fontSize: 18)),
                ],
              ),
            ),
            Material(
              color: Colors.white.withValues(alpha: 0.06),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(l.settingsMode.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 11,
              color: AppColors.inkMuted,
              letterSpacing: 1.5,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final entry in [
              (ThemeMode.system, l.settingsSystem, Icons.devices),
              (ThemeMode.light, l.settingsLight, Icons.light_mode),
              (ThemeMode.dark, l.settingsDark, Icons.dark_mode),
            ])
              Expanded(
                child: _ModeTile(
                  label: entry.$2,
                  icon: entry.$3,
                  active: themeMode == entry.$1,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(entry.$1),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l.settingsAccent.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 11,
              color: AppColors.inkMuted,
              letterSpacing: 1.5,
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final b in BranchId.values)
              Expanded(
                child: _AccentTile(
                  branch: b,
                  // Branch tile is "active" only when following the user's
                  // service AND that service matches this tile. Selecting
                  // SAF Crest takes all 4 branch tiles into the inactive
                  // state, even though the underlying profile branch is
                  // still set to one of them.
                  active: !isSafCrest && branch == b,
                  onTap: () {
                    // Picking a service implicitly reverts the override —
                    // a user who picked SAF Crest then taps Army gets
                    // their normal Army-themed UI back.
                    ref
                        .read(themeAccentProvider.notifier)
                        .set(const FollowBranch());
                    ref.read(uniformProfileProvider.notifier).setBranch(b);
                  },
                ),
              ),
            Expanded(
              child: _SafCrestAccentTile(
                active: isSafCrest,
                // SAF Crest does NOT touch the profile branch — it is a
                // visual override only, so the user's selected service
                // continues to drive Firestore data and AR ghost models.
                onTap: () => ref
                    .read(themeAccentProvider.notifier)
                    .set(const SafCrest()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.branchTheme.bright;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: active ? accent : AppColors.line,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: active ? Colors.white : AppColors.inkMuted, size: 18),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.body(
                    color: active ? Colors.white : AppColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentTile extends StatelessWidget {
  const _AccentTile({
    required this.branch,
    required this.active,
    required this.onTap,
  });
  final BranchId branch;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ServicePalette.of(branch);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? palette.bright.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: active ? palette.bright : AppColors.line,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.primary, palette.bright],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  branch.label(l),
                  style: AppTextStyles.body(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SafCrestAccentTile extends StatelessWidget {
  const _SafCrestAccentTile({
    required this.active,
    required this.onTap,
  });
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Pin the highlight color to the crest navy regardless of the
    // current branch theme — the tile must read the same whichever
    // service the user picked.
    const accent = Color(0xFF1A3A99);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: active ? accent : AppColors.line,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const SafCrestLogo(size: 26),
                const SizedBox(height: 6),
                Text(
                  l.themeAccentSafCrest,
                  style: AppTextStyles.body(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
