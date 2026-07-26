import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/theme_background.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../providers/generated_dress_provider.dart';
import '../providers/model_generation_controller.dart';

enum _GhostView { front }

/// Theta orbit for the ModelViewer when the user is on the front view.
/// Radius is intentionally pulled back so the figure sits well inside the
/// viewport on small phones (taller models would otherwise overflow).
const String _frontOrbit = '0deg 90deg 4m';

/// Theta orbit for the back view — same height + radius, just spun
/// 180° around the figure.
const String _backOrbit = '180deg 90deg 4m';

class GhostScreen extends ConsumerStatefulWidget {
  const GhostScreen({super.key});

  @override
  ConsumerState<GhostScreen> createState() => _GhostScreenState();
}

class _GhostScreenState extends ConsumerState<GhostScreen> {
  final _GhostView _view = _GhostView.front;

  @override
  void initState() {
    super.initState();
    // Kick off generation / refresh after the first frame so listeners
    // observe the optimistic in-flight state immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dress = ref.read(uniformProfileProvider).dressCode;
      // ignore: discarded_futures
      ref
          .read(modelGenerationControllerProvider.notifier)
          .ensureFresh(dress);
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final l = context.l10n;
    final profile = ref.watch(uniformProfileProvider);
    final status = ref.watch(modelStatusProvider(profile.dressCode));

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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(
                            color: Colors.white,
                            onPressed: () => context.go(Routes.dashboard),
                            style: const ButtonStyle(
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.only(top: 8, right: 8, bottom: 8),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${profile.branch.label(l)} · ${profile.rank.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  // Ghost figure viewport
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: 320 / 580,
                          child: _GhostFigureView(
                            view: _view,
                            accent: branchTheme.bright,
                            dress: profile.dressCode,
                          ),
                        ),
                        if (status == ModelStatus.stale || status == ModelStatus.generating)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _RegeneratingBadge(accent: branchTheme.bright),
                          ),
                      ],
                    ),
                  ),
                  // Footer
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 18 + MediaQuery.of(context).viewPadding.bottom,
                      top: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GhostButton(
                            label: l.ghostStartArScan,
                            icon: const Icon(Icons.crop_free, size: 16),
                            onPressed: () => context.go(Routes.ar),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: l.ghostStartWearing,
                            gradient: true,
                            accentColor: branchTheme.accent,
                            icon: const Icon(Icons.checkroom, size: 16),
                            onPressed: () => context.go(Routes.wearing),
                          ),
                        ),
                      ],
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

/// Renders the active dress for the current profile. Picks between the
/// real `ModelViewer`, an in-flight progress card, a CTA card (no model
/// yet), or a failure card with retry.
class _GhostFigureView extends ConsumerWidget {
  const _GhostFigureView({
    required this.view,
    required this.accent,
    required this.dress,
  });
  final _GhostView view;
  final Color accent;
  final DressCode dress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(modelStatusProvider(dress));
    final entry = ref.watch(generatedDressProvider(dress));

    // Stale and ready both render the cached GLB. For stale, the status
    // badge in the parent indicates the background regen.
    if ((status == ModelStatus.ready || status == ModelStatus.stale) &&
        entry?.modelUrl != null) {
      return _GlbViewer(
        url: entry!.modelUrl!,
        view: view,
        accent: accent,
      );
    }

    if (status == ModelStatus.generating) {
      return _GeneratingCard(accent: accent);
    }

    if (status == ModelStatus.failed) {
      return _FailedCard(
        accent: accent,
        message: entry?.error ?? '',
        onRetry: () {
          // ignore: discarded_futures
          ref
              .read(modelGenerationControllerProvider.notifier)
              .generate(dress);
        },
      );
    }

    return _NeedsGenerationCard(
      accent: accent,
      onGenerate: () {
        // ignore: discarded_futures
        ref
            .read(modelGenerationControllerProvider.notifier)
            .generate(dress);
      },
    );
  }
}

class _GlbViewer extends StatefulWidget {
  const _GlbViewer({
    required this.url,
    required this.view,
    required this.accent,
  });
  final String url;
  final _GhostView view;
  final Color accent;

  @override
  State<_GlbViewer> createState() => _GlbViewerState();
}

class _GlbViewerState extends State<_GlbViewer> {
  bool _loaded = false;

  void _markLoaded() {
    if (mounted && !_loaded) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final orbit = widget.view == _GhostView.front ? _frontOrbit : _backOrbit;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ModelViewer(
            src: widget.url,
            alt: 'Personalised SAF uniform 3D model',
            cameraControls: true,
            autoRotate: false,
            cameraOrbit: orbit,
            fieldOfView: '30deg',
            exposure: 1.0,
            shadowIntensity: 1.0,
            ar: true,
            arModes: const ['webxr', 'scene-viewer', 'quick-look'],
            loading: Loading.lazy,
            backgroundColor: const Color(0x00000000),
            // relatedJs is embedded in the generated HTML page after the
            // model-viewer element, so querySelector is always non-null here.
            // model-viewer fires its own 'load' event once the GLB is fully
            // parsed and rendered — distinct from the WebView page-load.
            relatedJs:
                "var mv=document.querySelector('model-viewer');"
                "if(mv){"
                "  if(mv.loaded){ModelViewerChannel.postMessage('ok');}"
                "  else{mv.addEventListener('load',()=>ModelViewerChannel.postMessage('ok'));}"
                "}",
            javascriptChannels: {
              JavascriptChannel(
                'ModelViewerChannel',
                onMessageReceived: (_) => _markLoaded(),
              ),
            },
          ),
          // Fades out once the 3D model signals it has finished loading.
          IgnorePointer(
            ignoring: _loaded,
            child: AnimatedOpacity(
              opacity: _loaded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.accent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GENERATING 3D MODEL',
            style: AppTextStyles.mono(
              fontSize: 11,
              color: AppColors.ink,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Composing body, uniform & accessories',
            style: AppTextStyles.body(
              color: AppColors.inkSubtle,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsGenerationCard extends StatelessWidget {
  const _NeedsGenerationCard({
    required this.accent,
    required this.onGenerate,
  });
  final Color accent;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.accessibility_new, color: accent, size: 56),
          const SizedBox(height: 16),
          Text(
            'YOUR 3D MODEL',
            style: AppTextStyles.mono(
              fontSize: 11,
              color: AppColors.ink,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build a personalised 3D figure for the current dress, branch & rank.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              color: AppColors.inkSubtle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Generate',
            accentColor: accent,
            onPressed: onGenerate,
          ),
        ],
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard({
    required this.accent,
    required this.message,
    required this.onRetry,
  });
  final Color accent;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            'GENERATION FAILED',
            style: AppTextStyles.mono(
              fontSize: 11,
              color: AppColors.ink,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.inkSubtle, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          GhostButton(
            label: 'Retry',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _RegeneratingBadge extends StatelessWidget {
  const _RegeneratingBadge({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'REGENERATING',
            style: AppTextStyles.mono(
              fontSize: 9,
              color: AppColors.ink,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

