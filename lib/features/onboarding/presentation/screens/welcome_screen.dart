import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/saf_crest_logo.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/app_bootstrap_provider.dart';

const String _tag = 'welcome';

/// Minimum time the Welcome screen stays visible, even if bootstrap
/// finishes faster. Keeps the brand moment consistent across cold
/// starts that hit a warm cache vs. cold storage.
const Duration _minDisplay = Duration(milliseconds: 1500);

/// Hard cap on the new-user wait. If bootstrap is still loading
/// after this, treat the user as new and reveal the CTA so they're
/// never stuck behind a hung network.
const Duration _bootstrapTimeout = Duration(seconds: 8);

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _minDisplayElapsed = false;
  bool _timedOut = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    AppLog.i('initState — starting min-display + timeout timers', tag: _tag);
    unawaited(
      Future<void>.delayed(_minDisplay).then((_) {
        if (!mounted) return;
        setState(() => _minDisplayElapsed = true);
      }),
    );
    unawaited(
      Future<void>.delayed(_bootstrapTimeout).then((_) {
        if (!mounted) return;
        setState(() => _timedOut = true);
      }),
    );
  }

  /// Returns a returning user to the screen they were on (per the
  /// last-persisted, allowlist-validated route) instead of always
  /// `/dashboard` — see `Routes.restorable` and
  /// `ChangeRequest/2026-08-11_capture-flow-state-loss-fix.md`.
  Future<void> _navigateToLastRoute() async {
    final lastRoute =
        await ref.read(localStorageServiceProvider).readLastRoute();
    final target = Routes.resolveRestoreTarget(lastRoute);
    AppLog.i('navigating to $target (returning user)', tag: _tag);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final bootstrap = ref.watch(appBootstrapProvider);

    final ready = _minDisplayElapsed &&
        (bootstrap.hasValue || bootstrap.hasError || _timedOut);
    final outcome =
        bootstrap.asData?.value ?? BootstrapOutcome.newUser; // fallback on err/timeout

    if (ready && !_didNavigate && outcome == BootstrapOutcome.returningUser) {
      _didNavigate = true;
      unawaited(_navigateToLastRoute());
    }


    final showCta = ready && outcome == BootstrapOutcome.newUser;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ThemeBackground(accentColor: branchTheme.bright),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.vertical -
                            120,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 36),
                          const SafCrestLogo(size: 132, withGlow: true),
                          const SizedBox(height: 32),
                          Text(
                            l.welcomeEyebrow,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.eyebrow(),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              '${l.welcomeTitleLine1}\n${l.welcomeTitleLine2}',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title(fontSize: 34),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              l.welcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    24 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: showCta
                      ? PrimaryButton(
                          label: l.welcomeGetStarted,
                          gradient: true,
                          accentColor: branchTheme.accent,
                          trailingIcon:
                              const Icon(Icons.arrow_forward, size: 16),
                          onPressed: () => context.go(Routes.config),
                        )
                      : _BootstrapProgressStrip(
                          color: branchTheme.bright,
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

/// Thin linear progress bar shown in the CTA slot while bootstrap runs.
/// Sized to roughly match the height of the `PrimaryButton` so the
/// layout doesn't jump when the CTA is revealed.
class _BootstrapProgressStrip extends StatelessWidget {
  const _BootstrapProgressStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }
}
