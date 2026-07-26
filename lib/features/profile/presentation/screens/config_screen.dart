import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_field.dart';
import '../../../../core/design/widgets/badge_pill.dart';
import '../../../../core/design/widgets/pill_toggle.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/branch_id.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/rank.dart';
import '../providers/uniform_provider.dart';

const String _tag = 'config.screen';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  int _step = 0;
  bool _loading = false;
  final TextEditingController _nameCtrl = TextEditingController();
  static const int _stepCount = 4;

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

  void _next() {
    if (_loading) return;
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      // Fire-and-forget: the completion handler navigates when done.
      // ignore: discarded_futures
      _completeConfiguration();
    }
  }

  /// Waits for the background `kickoffAuthFlow` to set a live session.
  /// Returns null only on a 30-second network timeout.
  Future<AuthSession?> _awaitAuthSession() async {
    AppLog.i('awaitAuthSession: checking authSessionProvider...', tag: _tag);
    AuthSession? session = ref.read(authSessionProvider);
    if (session != null) {
      AppLog.i(
        'awaitAuthSession: session already set  uid=${session.uid}',
        tag: _tag,
      );
      return session;
    }

    AppLog.i(
      'awaitAuthSession: session is NULL — subscribing and waiting up to 30s '
      'for kickoffAuthFlow to complete',
      tag: _tag,
    );

    final completer = Completer<AuthSession?>();
    final sub = ref.listenManual<AuthSession?>(
      authSessionProvider,
      (prev, next) {
        AppLog.i(
          'awaitAuthSession: provider changed  '
          'prev=${prev?.uid ?? "null"}  next=${next?.uid ?? "null"}',
          tag: _tag,
        );
        if (next != null && !completer.isCompleted) completer.complete(next);
      },
    );
    try {
      final result =
          await completer.future.timeout(const Duration(seconds: 30));
      AppLog.i('awaitAuthSession: RESOLVED  uid=${result?.uid}', tag: _tag);
      return result;
    } on TimeoutException {
      AppLog.e(
        'awaitAuthSession: TIMED OUT after 30s — '
        'kickoffAuthFlow never set the session. '
        'Check [I/bootstrap] and [E/auth.registry] logs above for the root cause.',
        tag: _tag,
      );
      return null;
    } finally {
      sub.close();
    }
  }

  Future<void> _completeConfiguration() async {
    AppLog.i(
      'completeConfiguration: START — Build Ghost Model pressed',
      tag: _tag,
    );
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // 1. Wait for background auth to complete.
      AppLog.i('completeConfiguration: STEP 1 — awaiting auth session', tag: _tag);
      final session = await _awaitAuthSession();
      if (session == null) {
        AppLog.e(
          'completeConfiguration: STEP 1 FAILED — no session after 30s. '
          'Navigating to dashboard (router will redirect to Welcome). '
          'See [E/bootstrap] logs for root cause.',
          tag: _tag,
        );
        if (mounted) context.go(Routes.dashboard);
        return;
      }
      AppLog.i(
        'completeConfiguration: STEP 1 OK  '
        'uid=${session.uid}  deviceId=${session.deviceId}',
        tag: _tag,
      );

      // 2. Flush profile — uid is now known so the write will land.
      AppLog.i(
        'completeConfiguration: STEP 2 — persisting profile to '
        'users/${session.uid}/profile/current',
        tag: _tag,
      );
      await ref.read(uniformProfileProvider.notifier).persist();
      AppLog.i('completeConfiguration: STEP 2 OK — profile written', tag: _tag);

      // 3. Mark device registration complete (best-effort).
      AppLog.i(
        'completeConfiguration: STEP 3 — markProfileComplete  '
        'deviceId=${session.deviceId}',
        tag: _tag,
      );
      try {
        await ref
            .read(deviceRegistryServiceProvider)
            .markProfileComplete(session.deviceId);
        AppLog.i('completeConfiguration: STEP 3 OK', tag: _tag);
      } catch (e, st) {
        AppLog.w(
          'completeConfiguration: STEP 3 WARN — markProfileComplete failed (non-fatal)',
          tag: _tag,
          error: e,
          st: st,
        );
      }

      // 4. Persist the completion flag for cold-start routing.
      AppLog.i(
        'completeConfiguration: STEP 4 — writing profileComplete=true to local storage',
        tag: _tag,
      );
      await ref.read(localStorageServiceProvider).writeProfileComplete(true);
      AppLog.i('completeConfiguration: STEP 4 OK', tag: _tag);

      // 5. Flip the in-memory session so the router allows /dashboard.
      AppLog.i(
        'completeConfiguration: STEP 5 — setting authSession profileComplete=true',
        tag: _tag,
      );
      ref.read(authSessionProvider.notifier).set(
            session.copyWith(profileComplete: true),
          );
      AppLog.i(
        'completeConfiguration: STEP 5 OK — router refresh triggered',
        tag: _tag,
      );

      AppLog.i(
        'completeConfiguration: ALL DONE — navigating to /dashboard',
        tag: _tag,
      );
    } catch (e, st) {
      AppLog.e(
        'completeConfiguration: UNEXPECTED ERROR',
        tag: _tag,
        error: e,
        st: st,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    context.go(Routes.dashboard);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.go(Routes.dashboard);
    }
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

  String _stepLabel(AppLocalizations l, int s) => switch (s) {
        0 => l.configStep01,
        1 => l.configStep02,
        2 => l.configStep03,
        3 => l.configStep04,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final profile = ref.watch(uniformProfileProvider);

    ref.listen<String>(
      uniformProfileProvider.select((p) => p.fullName),
      (prev, next) {
        if (_nameCtrl.text != next) _nameCtrl.text = next;
      },
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: branchTheme.bright),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  step: _step,
                  back: _back,
                  l: l,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Stepper(step: _step, total: _stepCount, accent: branchTheme.bright),
                        const SizedBox(height: 22),
                        Text(
                          '${l.configHeaderConfiguration} · ${_stepLabel(l, _step)}',
                          style: AppTextStyles.eyebrow(),
                        ),
                        const SizedBox(height: 8),
                        if (_step == 0) _Step1(profile: profile),
                        if (_step == 1) _Step2(profile: profile),
                        if (_step == 2)
                          _Step3(
                            profile: profile,
                            vocation: profile.vocation,
                            onVocation: (v) => ref
                                .read(uniformProfileProvider.notifier)
                                .setVocation(v),
                            nameCtrl: _nameCtrl,
                          ),
                        if (_step == 3)
                          _Step4(
                            medalRows: profile.medalRowCount,
                            badges: profile.selectedBadgeIds,
                            badgeDefs: _badgeDefs,
                            badgeName: _badgeName,
                            onMedalRows: (v) => ref
                                .read(uniformProfileProvider.notifier)
                                .setMedalRowCount(v),
                            onToggle: (id) => ref
                                .read(uniformProfileProvider.notifier)
                                .toggleBadge(id),
                            isDisabled: (id) =>
                                _isBadgeDisabled(profile.selectedBadgeIds, id),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  colors: [
                    Color(0xFF0B0D0E),
                    Color(0x000B0D0E),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                22,
                14,
                22,
                24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: PrimaryButton(
                label: _step < _stepCount - 1 ? l.commonContinue : l.configBuildGhost,
                gradient: true,
                accentColor: branchTheme.accent,
                trailingIcon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward, size: 16),
                onPressed: _loading ? null : _next,
              ),
            ),
          ),
        ],
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

class _Header extends StatelessWidget {
  const _Header({required this.step, required this.back, required this.l});
  final int step;
  final VoidCallback back;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            BackButton(
              color: Colors.white,
              onPressed: back,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.only(top: 8, right: 8, bottom: 8),
                ),
              ),
            ),
            const Spacer(),
            Text(
              l.configStepFormat(
                (step + 1).toString().padLeft(2, '0'),
                '04',
              ),
              style: AppTextStyles.mono(
                fontSize: 10.5,
                color: AppColors.inkMuted,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.total, required this.accent});
  final int step;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: List.generate(total, (i) {
          final state = i < step
              ? 'done'
              : i == step
                  ? 'active'
                  : 'pending';
          final color = state == 'pending'
              ? Colors.white.withValues(alpha: 0.1)
              : accent;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: state == 'active'
                      ? [BoxShadow(color: accent, blurRadius: 12, spreadRadius: 0)]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Step1 extends ConsumerWidget {
  const _Step1({required this.profile});
  final dynamic profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final notifier = ref.read(uniformProfileProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.configStep1Title, style: AppTextStyles.title(fontSize: 26)),
        const SizedBox(height: 6),
        Text(l.configStep1Subtitle, style: AppTextStyles.subtitle()),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: () {
            // Keep card height fixed at 104 dp regardless of screen width.
            // hPadding: 22*2 from parent scroll view; hSpacing: crossAxisSpacing.
            const double hPadding = 44.0;
            const double hSpacing = 10.0;
            const double targetCardHeight = 104.0;
            final double cardWidth =
                (MediaQuery.of(context).size.width - hPadding - hSpacing) / 2;
            return cardWidth / targetCardHeight;
          }(),
          children: [
            for (final b in BranchId.values)
              _ServiceCard(
                branch: b,
                selected: profile.branch == b,
                onTap: () => notifier.setBranch(b),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.configStep1WhyTitle, style: AppTextStyles.eyebrow()),
              const SizedBox(height: 6),
              Text(
                l.configStep1WhyBody,
                style: AppTextStyles.body(
                  color: Colors.white.withValues(alpha: 0.7),
                ).copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });
  final BranchId branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ServicePalette.of(branch);
    final l = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? palette.bright.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: selected ? palette.bright : AppColors.line,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [palette.primary, palette.bright],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check, color: palette.bright, size: 18),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(branch.label(l),
                      style: AppTextStyles.bodyStrong(color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    '${palette.collarRule} · ${ServicePalette.tagOf(branch)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      fontSize: 9.5,
                      color: AppColors.inkMuted,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step2 extends ConsumerWidget {
  const _Step2({required this.profile});
  final dynamic profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final notifier = ref.read(uniformProfileProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.configStep2Title, style: AppTextStyles.title(fontSize: 26)),
        const SizedBox(height: 6),
        Text(l.configStep2Subtitle, style: AppTextStyles.subtitle()),
        const SizedBox(height: 22),
        FieldLabel(l.configStandardSikh),
        PillToggle<bool>(
          value: profile.isSikh,
          onChanged: (v) => notifier.setSikh(v),
          options: [
            PillToggleOption(value: false, label: l.configStandard),
            PillToggleOption(value: true, label: l.configSikhPersonnel),
          ],
        ),
        const SizedBox(height: 22),
        FieldLabel(l.configSexBuild),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
          children: [
            _IdTile(
              label: l.configIdentityMen,
              icon: Icons.man,
              selected: profile.gender == Gender.male,
              onTap: () => notifier.setGender(Gender.male),
            ),
            _IdTile(
              label: l.configIdentityLadies,
              icon: Icons.woman,
              selected: profile.gender == Gender.female,
              onTap: () => notifier.setGender(Gender.female),
            ),
            _IdTile(
              label: l.configIdentityMaternity,
              icon: Icons.pregnant_woman,
              selected: profile.gender == Gender.maternity,
              onTap: () => notifier.setGender(Gender.maternity),
            ),
          ],
        ),
        if (profile.isSikh) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x2E7A1E1E),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0x66B42828), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.configSikhRuleEyebrow,
                    style: AppTextStyles.eyebrow(color: const Color(0xFFE8A8A8))),
                const SizedBox(height: 6),
                Text(
                  l.configSikhRuleBody,
                  style: AppTextStyles.body(
                    color: Colors.white.withValues(alpha: 0.85),
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IdTile extends StatelessWidget {
  const _IdTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final bright = HSLColor.fromColor(accent).withLightness(0.55).toColor();
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? bright.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? bright : AppColors.line,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTextStyles.body(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step3 extends ConsumerWidget {
  const _Step3({
    required this.profile,
    required this.vocation,
    required this.onVocation,
    required this.nameCtrl,
  });
  final dynamic profile;
  final String vocation;
  final ValueChanged<String> onVocation;
  final TextEditingController nameCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final notifier = ref.read(uniformProfileProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.configStep3Title, style: AppTextStyles.title(fontSize: 26)),
        const SizedBox(height: 6),
        Text(l.configStep3Subtitle, style: AppTextStyles.subtitle()),
        const SizedBox(height: 24),
        FieldLabel(l.configFieldRank),
        AppDropdown<Rank>(
          value: profile.rank,
          items: Rank.values,
          itemLabel: (r) => r.code,
          onChanged: (v) {
            if (v != null) notifier.setRank(v);
          },
        ),
        const SizedBox(height: 16),
        FieldLabel(l.configFieldVocation),
        AppDropdown<String>(
          value: vocation,
          items: const ['Infantry', 'Armour', 'Artillery', 'Signals', 'Engineers', 'Logistics'],
          itemLabel: (s) => s,
          onChanged: (v) {
            if (v != null) onVocation(v);
          },
        ),
        const SizedBox(height: 16),
        FieldLabel(l.configFieldName),
        AppTextField(
          controller: nameCtrl,
          placeholder: l.configNamePlaceholder,
          onChanged: notifier.setFullName,
        ),
      ],
    );
  }
}

class _Step4 extends StatelessWidget {
  const _Step4({
    required this.medalRows,
    required this.badges,
    required this.badgeDefs,
    required this.badgeName,
    required this.onMedalRows,
    required this.onToggle,
    required this.isDisabled,
  });
  final int medalRows;
  final Set<String> badges;
  final List<_BadgeDef> badgeDefs;
  final String Function(AppLocalizations, String) badgeName;
  final ValueChanged<int> onMedalRows;
  final void Function(String) onToggle;
  final bool Function(String) isDisabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.configStep4Title, style: AppTextStyles.title(fontSize: 26)),
        const SizedBox(height: 6),
        Text(l.configStep4Subtitle, style: AppTextStyles.subtitle()),
        const SizedBox(height: 22),
        FieldLabel(l.configMedalRows(medalRows)),
        Row(
          children: [
            _StepperBtn(
              icon: Icons.remove,
              onTap: () => onMedalRows((medalRows - 1).clamp(0, 10)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: List.generate(10, (i) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: i < medalRows
                              ? branchTheme.bright
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 10),
            _StepperBtn(
              icon: Icons.add,
              onTap: () => onMedalRows((medalRows + 1).clamp(0, 10)),
            ),
          ],
        ),
        if (medalRows >= 3) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: branchTheme.bright.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
              border: Border.all(
                color: branchTheme.bright.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: branchTheme.bright, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.configAutoRuleApplied,
                    style: AppTextStyles.body(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ).copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        FieldLabel(l.configBadgesLabel),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in badgeDefs)
              BadgePill(
                label: badgeName(l, b.id),
                active: badges.contains(b.id),
                disabled: isDisabled(b.id),
                onTap: () => onToggle(b.id),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(l.configBadgesExclusion,
            style: AppTextStyles.mono(
              fontSize: 10.5,
              color: AppColors.inkMuted,
              letterSpacing: 1.4,
            )),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.lineStrong, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
