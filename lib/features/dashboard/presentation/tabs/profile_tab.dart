import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_card.dart';
import '../../../../core/design/widgets/app_field.dart';
import '../../../../core/design/widgets/badge_pill.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/rank.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key, required this.onUpdate});
  final VoidCallback onUpdate;

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final TextEditingController _nameCtrl = TextEditingController();

  static const List<_BadgeDef> _badgeDefs = [
    _BadgeDef('ippt', 'badgeIppt', []),
    _BadgeDef('marksman', 'badgeMarksmanship', ['sniper', 'fitness']),
    _BadgeDef('sniper', 'badgeSniper', ['marksman', 'fitness']),
    _BadgeDef('fitness', 'badgeFitness', ['marksman', 'sniper']),
    _BadgeDef('airborne', 'badgeAirborne', []),
    _BadgeDef('dive', 'badgeDive', []),
    _BadgeDef('pilot', 'badgePilot', []),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = ref.read(uniformProfileProvider).fullName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool _isBadgeDisabled(Set<String> selected, String id) {
    if (selected.contains(id)) return false;
    final def = _badgeDefs.firstWhere((b) => b.id == id);
    return def.exclusiveWith.any(selected.contains);
  }

  String _badgeName(AppLocalizations l, String id) => switch (id) {
        'ippt' => l.badgeIppt,
        'marksman' => l.badgeMarksmanship,
        'sniper' => l.badgeSniper,
        'fitness' => l.badgeFitness,
        'airborne' => l.badgeAirborne,
        'dive' => l.badgeDive,
        'pilot' => l.badgePilot,
        _ => id,
      };

  void _onUpdateTap() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(ctx.l10n.profileRebuildTitle,
            style: AppTextStyles.title(fontSize: 17)),
        content: Text(ctx.l10n.profileRebuildBody, style: AppTextStyles.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel,
                style: AppTextStyles.body(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onUpdate();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.branchTheme.bright,
            ),
            child: Text(ctx.l10n.profileRebuildConfirm,
                style: AppTextStyles.bodyStrong(color: AppColors.bg)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(uniformProfileProvider);
    final notifier = ref.read(uniformProfileProvider.notifier);
    final branchTheme = context.branchTheme;

    ref.listen<String>(
      uniformProfileProvider.select((p) => p.fullName),
      (prev, next) {
        if (_nameCtrl.text != next) _nameCtrl.text = next;
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
      children: [
        // Avatar header
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [branchTheme.primary, branchTheme.bright],
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              alignment: Alignment.center,
              child: Text(
                profile.fullName.isEmpty
                    ? 'SO'
                    : profile.fullName[0].toUpperCase(),
                style: AppTextStyles.title(color: AppColors.ink, fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${profile.rank.code} · ${profile.branch.label(l)}',
                    style: AppTextStyles.mono(
                      fontSize: 9.5,
                      color: context.branchTheme.bright,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _nameCtrl,
                    placeholder: l.profileFullName,
                    height: 38,
                    onChanged: notifier.setFullName,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          eyebrow: '01',
          title: l.profileSection1,
          children: [
            _Label(l.profileFieldBranch),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BranchId.values.map((b) {
                final active = profile.branch == b;
                final accent = context.branchTheme.bright;
                return _Pill(
                  label: b.label(l),
                  active: active,
                  accent: accent,
                  onTap: () => notifier.setBranch(b),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          eyebrow: '02',
          title: l.profileSection2,
          children: [
            _Label(l.profileFieldBuild),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(
                  label: l.configIdentityMen,
                  active: profile.gender == Gender.male,
                  accent: context.branchTheme.bright,
                  onTap: () => notifier.setGender(Gender.male),
                ),
                _Pill(
                  label: l.configIdentityLadies,
                  active: profile.gender == Gender.female,
                  accent: context.branchTheme.bright,
                  onTap: () => notifier.setGender(Gender.female),
                ),
                _Pill(
                  label: l.configIdentityMaternity,
                  active: profile.gender == Gender.maternity,
                  accent: context.branchTheme.bright,
                  onTap: () => notifier.setGender(Gender.maternity),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.profileSikhToggle,
                    style: AppTextStyles.body(color: AppColors.ink, fontSize: 13.5),
                  ),
                ),
                _Switch(
                  value: profile.isSikh,
                  onChanged: notifier.setSikh,
                  accent: context.branchTheme.bright,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          eyebrow: '03',
          title: l.profileSection3,
          children: [
            _Label(l.profileFieldRank),
            AppDropdown<Rank>(
              value: profile.rank,
              items: Rank.values,
              itemLabel: (r) => r.code,
              onChanged: (v) {
                if (v != null) notifier.setRank(v);
              },
            ),
            _Label(l.profileFieldVocation),
            AppDropdown<String>(
              value: profile.vocation,
              items: const ['Infantry', 'Armour', 'Artillery', 'Signals', 'Engineers', 'Logistics'],
              itemLabel: (s) => s,
              onChanged: (v) {
                if (v != null) notifier.setVocation(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          eyebrow: '04',
          title: l.profileSection4,
          children: [
            _Label(l.profileFieldMedalRows),
            _MedalStepper(
              value: profile.medalRowCount,
              onChanged: notifier.setMedalRowCount,
              label: l.profileMedalRowsLabel,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          eyebrow: '05',
          title: l.profileSection5,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final b in _badgeDefs)
                  BadgePill(
                    label: _badgeName(l, b.id),
                    active: profile.selectedBadgeIds.contains(b.id),
                    disabled:
                        _isBadgeDisabled(profile.selectedBadgeIds, b.id),
                    onTap: () => notifier.toggleBadge(b.id),
                  ),
              ],
            ),
            Text(
              l.profileBadgesNote,
              style: AppTextStyles.mono(
                fontSize: 9.5,
                color: AppColors.inkSubtle,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: l.profileUpdateRebuild,
          gradient: true,
          accentColor: context.branchTheme.accent,
          height: 54,
          icon: const Icon(Icons.upload_file, size: 16),
          onPressed: _onUpdateTap,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.mono(
          fontSize: 11,
          color: AppColors.inkMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? accent : AppColors.line,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.body(
              color: active ? AppColors.ink : AppColors.inkMuted,
              fontSize: 12.5,
            ).copyWith(fontWeight: active ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.value,
    required this.onChanged,
    required this.accent,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? accent : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              top: 3,
              left: value ? 21 : 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? AppColors.bg : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalStepper extends StatelessWidget {
  const _MedalStepper({
    required this.value,
    required this.onChanged,
    required this.label,
  });
  final int value;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove, onTap: () => onChanged((value - 1).clamp(0, 10))),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line, width: 1),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: AppTextStyles.mono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTextStyles.mono(
                    fontSize: 10,
                    color: AppColors.inkSubtle,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _StepBtn(icon: Icons.add, onTap: () => onChanged((value + 1).clamp(0, 10))),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
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

class _BadgeDef {
  const _BadgeDef(this.id, this.l10nKey, this.exclusiveWith);
  final String id;
  final String l10nKey;
  final List<String> exclusiveWith;
}
