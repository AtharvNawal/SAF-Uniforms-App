import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/rank.dart';
import '../../../profile/presentation/providers/uniform_provider.dart';
import '../../data/capture_quality_gate.dart';
import '../../data/device_tilt.dart';
import '../../data/live_pose_guide.dart';
import '../../domain/entities/cv_inspection_result.dart';
import '../../domain/entities/uniform_check_result.dart';
import '../../domain/supported_uniforms.dart';
import '../providers/cv_service_inspection_provider.dart';
import '../providers/uniform_check_provider.dart';
// Phase-1 `checkUniformCompliance` (Node/Anthropic) path stays disabled —
// the default capture now uses `cv-service`'s Anthropic-free
// `/check_uniform` geometry endpoint (see `_capture`). The old provider
// in `uniform_compliance_provider.dart` is commented out in full.
// import '../providers/uniform_compliance_provider.dart';
import '../utils/capture_error_message.dart';
import '../widgets/cv_server_settings.dart';

const String _tag = 'arScanner.screen';

enum _ArPhase { aligning, aligned, analyzing, scorecard, cvScorecard, failed }

/// Maps the app's [Rank] enum to the `rank_tier` condition values
/// `cv-service/rules/army_no3_male.json` filters on (see
/// `rules/rule_engine.py`'s `_condition_matches`). Lives here rather
/// than on [Rank] itself since it's specific to this one dev
/// integration point, not a general-purpose rank concept.
String _rankTierWireValue(Rank rank) {
  switch (rank) {
    case Rank.rec:
    case Rank.pte:
    case Rank.lcp:
    case Rank.cpl:
    case Rank.cfc:
      return 'enlistee';
    case Rank.threeSg:
    case Rank.twoSg:
    case Rank.oneSg:
    case Rank.ssg:
    case Rank.msg:
      return 'specialist';
    case Rank.oct:
      return 'officer_cadet_and_mxt_trainee';
    case Rank.col:
      return 'col_me7';
    case Rank.bg:
    case Rank.mg:
    case Rank.ltg:
      return 'bg_me8_and_above';
    case Rank.threeWo:
    case Rank.twoWo:
    case Rank.oneWo:
    case Rank.mwo:
    case Rank.swo:
    case Rank.cwo:
    case Rank.twoLt:
    case Rank.lta:
    case Rank.cpt:
    case Rank.maj:
    case Rank.ltc:
    case Rank.sltc:
      return 'sltc_me6_and_below';
  }
}

/// `body_type` form field — the geometry/anchor set the solver uses.
String _bodyTypeWireValue(Gender g) => switch (g) {
  Gender.male => 'male',
  Gender.female => 'female',
  Gender.maternity => 'female_maternity',
};

class ARScannerScreen extends ConsumerStatefulWidget {
  const ARScannerScreen({super.key});

  @override
  ConsumerState<ARScannerScreen> createState() => _ARScannerScreenState();
}

class _ARScannerScreenState extends ConsumerState<ARScannerScreen>
    with WidgetsBindingObserver {
  _ArPhase _phase = _ArPhase.aligning;

  /// D15 — live capture guidance: ML Kit pose on the camera stream decides
  /// when the shot meets the capture protocol (replaces a fixed 1.8 s
  /// "aligned" timer that unlocked capture regardless of framing). See
  /// `live_pose_guide.dart` and
  /// `ChangeRequest/2026-09-28_accuracy-program-no-real-data.md`.
  final LivePoseGuide _guide = LivePoseGuide();
  CaptureHint _hint = CaptureHint.noPerson;

  /// Set when the live guide produced no result within
  /// [_guideWatchdogDelay] of the preview starting (ML Kit unsupported on
  /// this device / simulator): capture is unlocked so the user is never
  /// stuck, and the post-capture [CaptureQualityGate] still applies.
  bool _guideUnavailable = false;
  bool _guideSeenFrame = false;
  Timer? _guideWatchdog;
  static const Duration _guideWatchdogDelay = Duration(seconds: 4);

  /// D16 — phone pitch/roll for the guidance and the server's camera solve.
  final DeviceTilt _tilt = DeviceTilt();

  /// D17 — frames per capture, combined server-side by per-item majority.
  static const int _burstFrames = 3;

  /// True while the in-flight check is the Phase-2 `cv-service` path
  /// rather than the default Phase-1 (`checkUniformCompliance`) path —
  /// disambiguates which of the two `ref.listen` blocks below should
  /// react to its provider settling. Reached via long-press on the
  /// capture button; see `_ScanningPhase.onCaptureDev`.
  bool _usingCvService = false;

  /// The actual thrown error behind the current `_ArPhase.failed`
  /// state — `_FailedPhase` inspects this to show an accurate message
  /// instead of a one-size-fits-all "check your connection" (see
  /// `ChangeRequest/2026-08-11_ar-scanner-live-camera-and-error-messaging.md`).
  Object? _lastError;

  /// Live in-app camera preview — replaces the prior `image_picker`
  /// OS-camera hand-off. `null` while initializing or on failure
  /// (permission denied, no hardware — e.g. a simulator); `_ScanningPhase`
  /// falls back to a placeholder in either case.
  CameraController? _cameraController;
  bool _cameraUnavailable = false;

  /// Milestone 1's client-side half — see `capture_quality_gate.dart`
  /// for why this runs on the already-captured photo rather than mid-shutter.
  /// One instance for the screen's lifetime; ML Kit's detector holds
  /// native resources that must be explicitly closed.
  final CaptureQualityGate _captureGate = CaptureQualityGate();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tilt.start();
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _guideWatchdog?.cancel();
    unawaited(_guide.close());
    unawaited(_tilt.stop());
    _captureGate.close();
    unawaited(_cameraController?.dispose());
    super.dispose();
  }

  /// The `camera` package's own documented pattern: release the camera
  /// while backgrounded (avoids holding the hardware, and Android
  /// camera-in-use conflicts with other apps), reacquire on resume.
  /// This is the first `WidgetsBindingObserver` in this codebase —
  /// scoped tightly to camera resource management, not general app
  /// state restoration (that's `Routes.restorable`, a separate concern).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(controller.dispose());
      setState(() => _cameraController = null);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initCamera());
    }
  }

  Future<void> _initCamera() async {
    developer.log('initCamera: start', name: _tag, level: 800);
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        // Single-plane formats ML Kit accepts directly from the stream.
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraUnavailable = false;
      });
      developer.log('initCamera: ready', name: _tag, level: 800);
      unawaited(_startGuide());
    } catch (e, st) {
      developer.log(
        'initCamera: failed',
        name: _tag,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      if (mounted) setState(() => _cameraUnavailable = true);
    }
  }

  /// Starts live pose guidance on the camera stream. Safe to call again
  /// (no-op while already streaming).
  Future<void> _startGuide() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    developer.log('startGuide', name: _tag, level: 800);
    _guide.reset();
    _guideSeenFrame = false;
    _guideWatchdog?.cancel();
    _guideWatchdog = Timer(_guideWatchdogDelay, () {
      if (!mounted || _guideSeenFrame) return;
      developer.log(
        'startGuide: no guide result — unlocking capture',
        name: _tag,
        level: 900,
      );
      setState(() {
        _guideUnavailable = true;
        if (_phase == _ArPhase.aligning) _phase = _ArPhase.aligned;
      });
    });
    try {
      await controller.startImageStream((image) async {
        final hint = await _guide.process(
          image,
          controller.description,
          controller.value.deviceOrientation,
          pitchDeg: _tilt.pitchDeg,
          rollDeg: _tilt.rollDeg,
        );
        if (hint == null || !mounted) return;
        _guideSeenFrame = true;
        if (_phase != _ArPhase.aligning && _phase != _ArPhase.aligned) return;
        final next = hint == CaptureHint.ready
            ? _ArPhase.aligned
            : _ArPhase.aligning;
        if (hint != _hint || next != _phase || _guideUnavailable) {
          setState(() {
            _hint = hint;
            _phase = next;
            _guideUnavailable = false;
          });
        }
      });
    } catch (e, st) {
      developer.log(
        'startGuide: stream failed',
        name: _tag,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      if (mounted) {
        setState(() {
          _guideUnavailable = true;
          if (_phase == _ArPhase.aligning) _phase = _ArPhase.aligned;
        });
      }
    }
  }

  /// The camera can't take a still while streaming frames on every
  /// platform — stop the guide first.
  Future<void> _stopGuide() async {
    _guideWatchdog?.cancel();
    final controller = _cameraController;
    if (controller == null || !controller.value.isStreamingImages) return;
    try {
      await controller.stopImageStream();
    } catch (e, st) {
      developer.log(
        'stopGuide: failed',
        name: _tag,
        error: e,
        stackTrace: st,
        level: 1000,
      );
    }
  }

  /// D17 — [_burstFrames] stills a moment apart. The first is run through
  /// the on-device [CaptureQualityGate]; `null` means nothing to send.
  Future<List<Uint8List>?> _takeBurst() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      developer.log('takeBurst: camera not ready', name: _tag, level: 900);
      return null;
    }
    await _stopGuide();
    final frames = <XFile>[];
    for (var i = 0; i < _burstFrames; i++) {
      try {
        frames.add(await controller.takePicture());
      } catch (e, st) {
        developer.log(
          'takeBurst: frame $i failed',
          name: _tag,
          error: e,
          stackTrace: st,
          level: 1000,
        );
        break;
      }
      if (i < _burstFrames - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }
    developer.log('takeBurst: ${frames.length} frames', name: _tag, level: 800);
    if (!mounted) return null;
    if (frames.isEmpty ||
        !await _passesCaptureGate(frames.first.path) ||
        !mounted) {
      unawaited(_startGuide());
      return null;
    }
    return Future.wait(frames.map((f) => f.readAsBytes()));
  }

  /// Returns `false` (and shows a SnackBar explaining why) when the
  /// photo fails the on-device capture-quality gate. Callers should
  /// bail out without transitioning to the analyzing phase.
  Future<bool> _passesCaptureGate(String imagePath) async {
    final result = await _captureGate.evaluate(imagePath);
    if (result.accepted || !mounted) return true;

    final message = switch (result.issue) {
      CaptureQualityIssue.noPersonDetected =>
        'No person detected — make sure you\'re fully in frame.',
      CaptureQualityIssue.torsoNotVisible =>
        'Torso not clearly visible — step back so your shoulders and waist are both in frame.',
      CaptureQualityIssue.shouldersNotLevel =>
        'Camera looks tilted — hold the phone level and face the camera directly.',
      CaptureQualityIssue.none => '',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
    return false;
  }

  /// Shared by [_capture] and [_captureCvService] — both now capture
  /// from the same live in-app preview (`_cameraController`), differing
  /// only in which backend the resulting bytes go to. Returns `null`
  /// (nothing left to do — either not ready, capture failed, or the
  /// photo didn't pass the quality gate) or the captured JPEG bytes.
  Future<Uint8List?> _takePhoto({required String logTag}) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      developer.log('$logTag: camera not ready', name: _tag, level: 900);
      return null;
    }
    await _stopGuide();
    XFile picked;
    try {
      picked = await controller.takePicture();
    } catch (e, st) {
      developer.log(
        '$logTag: takePicture failed',
        name: _tag,
        error: e,
        stackTrace: st,
        level: 1000,
      );
      return null;
    }
    if (!mounted) return null;

    if (!await _passesCaptureGate(picked.path) || !mounted) {
      unawaited(_startGuide());
      return null;
    }

    return picked.readAsBytes();
  }

  /// Default capture path — runs a real geometry/pixel compliance check
  /// via `cv-service`'s Anthropic-free `POST /check_uniform`
  /// (`UniformCheckController`). The `_ArPhase` transition happens in the
  /// `ref.listen` block in [build] once the provider settles. Needs a
  /// reachable `cv-service` (`kCvServiceBaseUrl`) — an unreachable one
  /// lands on `_ArPhase.failed` with an explicit message.
  Future<void> _capture() async {
    developer.log('capture: start', name: _tag, level: 800);
    final photos = await _takeBurst();
    if (photos == null || !mounted) return;

    final profile = ref.read(uniformProfileProvider);
    // The dress chosen on the dashboard (profile's active dress).
    final dress = profile.dressCode;
    final gravity = _tilt.gravityUpCamera;
    developer.log(
      'capture: uniform=${uniformTypeFor(profile.branch, dress, profile.gender)}',
      name: _tag,
    );
    setState(() {
      _usingCvService = false;
      _phase = _ArPhase.analyzing;
    });
    await ref
        .read(uniformCheckControllerProvider.notifier)
        .check(
          photos: photos,
          uniformType: uniformTypeFor(profile.branch, dress, profile.gender),
          rankTier: _rankTierWireValue(profile.rank),
          gender: uniformGenderWireValue(profile.gender),
          isSikh: profile.isSikh,
          medalRowCount: profile.medalRowCount,
          bodyType: _bodyTypeWireValue(profile.gender),
          wearerName: profile.fullName,
          heightCm: profile.heightCm > 0 ? profile.heightCm : null,
          gravityUpCamera: gravity,
        );
  }

  /// Dev-only entry point into the Phase-2 `cv-service` pipeline
  /// (real pose/PnP geometry + a vision-language stand-in for the
  /// not-yet-trained accessory detector — see `cv-service/README.md`).
  /// Reached by long-pressing the capture button rather than the
  /// default tap, so it never disturbs the shipped Phase-1 flow.
  /// Requires `cv-service` running locally (`uvicorn api.main:app`).
  Future<void> _captureCvService() async {
    developer.log('captureCvService: start', name: _tag, level: 800);
    final bytes = await _takePhoto(logTag: 'captureCvService');
    if (bytes == null || !mounted) return;

    final profile = ref.read(uniformProfileProvider);
    setState(() {
      _usingCvService = true;
      _phase = _ArPhase.analyzing;
    });
    await ref
        .read(cvServiceInspectionControllerProvider.notifier)
        .inspect(
          photoBytes: bytes,
          rankTier: _rankTierWireValue(profile.rank),
          gender: profile.gender.wireName,
          isSikh: profile.isSikh,
          medalRowCount: profile.medalRowCount,
        );
  }

  void _rescan() {
    ref.read(uniformCheckControllerProvider.notifier).reset();
    ref.read(cvServiceInspectionControllerProvider.notifier).reset();
    setState(() {
      _usingCvService = false;
      _phase = _ArPhase.aligning;
      _hint = CaptureHint.noPerson;
      _guideUnavailable = false;
    });
    unawaited(_startGuide());
  }

  @override
  Widget build(BuildContext context) {
    // Default capture path — the real `cv-service` /check_uniform result.
    ref.listen<AsyncValue<UniformCheckResult?>>(
      uniformCheckControllerProvider,
      (previous, next) {
        if (!mounted || _phase != _ArPhase.analyzing || _usingCvService) {
          return;
        }
        next.when(
          data: (result) {
            if (result != null) setState(() => _phase = _ArPhase.scorecard);
          },
          loading: () {},
          error: (e, st) => setState(() {
            _lastError = e;
            _phase = _ArPhase.failed;
          }),
        );
      },
    );
    ref.listen<AsyncValue<CvInspectionResult?>>(
      cvServiceInspectionControllerProvider,
      (previous, next) {
        if (!mounted || _phase != _ArPhase.analyzing || !_usingCvService) {
          return;
        }
        next.when(
          data: (result) {
            if (result != null) setState(() => _phase = _ArPhase.cvScorecard);
          },
          loading: () {},
          error: (e, st) => setState(() {
            _lastError = e;
            _phase = _ArPhase.failed;
          }),
        );
      },
    );

    switch (_phase) {
      case _ArPhase.scorecard:
        final result = ref.watch(uniformCheckControllerProvider).value;
        if (result == null) {
          return _AnalyzingPhase(onClose: () => context.go(Routes.ghostModel));
        }
        return _RealScorecard(result: result, onRescan: _rescan);
      case _ArPhase.cvScorecard:
        final result = ref.watch(cvServiceInspectionControllerProvider).value;
        if (result == null) {
          return _AnalyzingPhase(onClose: () => context.go(Routes.ghostModel));
        }
        return _CvScorecard(result: result, onRescan: _rescan);
      case _ArPhase.analyzing:
        return _AnalyzingPhase(onClose: () => context.go(Routes.ghostModel));
      case _ArPhase.failed:
        return _FailedPhase(
          error: _lastError,
          onRetry: _rescan,
          onClose: () => context.go(Routes.ghostModel),
        );
      case _ArPhase.aligning:
      case _ArPhase.aligned:
        final profile = ref.watch(uniformProfileProvider);
        final l = context.l10n;
        final dress = profile.dressCode;
        String uniformLabel(BranchId b, DressCode d, Gender g) =>
            '${b.label(l)} ${d.code(l)} (${g.label(l)})';
        final supported = isCheckableUniform(
          profile.branch,
          dress,
          profile.gender,
        );
        return _ScanningPhase(
          onChooseUniform: () => context.go(Routes.dashboard),
          unsupportedTitle: supported
              ? null
              : l.arUnsupportedTitle(
                  uniformLabel(profile.branch, dress, profile.gender),
                ),
          unsupportedSub: l.arUnsupportedSub(
            checkableUniforms()
                .map((u) => uniformLabel(u.branch, u.dress, u.gender))
                .join(', '),
          ),
          aligned: _phase == _ArPhase.aligned,
          hint: _hint,
          guideUnavailable: _guideUnavailable,
          cameraController: _cameraController,
          cameraUnavailable: _cameraUnavailable,
          onCapture: _capture,
          onCaptureDev: _captureCvService,
          onClose: () => context.go(Routes.ghostModel),
        );
    }
  }
}

class _ScanningPhase extends StatelessWidget {
  const _ScanningPhase({
    required this.onChooseUniform,
    required this.unsupportedTitle,
    required this.unsupportedSub,
    required this.aligned,
    required this.hint,
    required this.guideUnavailable,
    required this.cameraController,
    required this.cameraUnavailable,
    required this.onCapture,
    required this.onCaptureDev,
    required this.onClose,
  });
  final bool aligned;

  /// Back to the dashboard, where the uniform (No.1–No.5) is chosen.
  final VoidCallback onChooseUniform;

  /// Non-null when cv-service can't check this branch / dress / gender yet;
  /// capture is then disabled so no photo is uploaded for a sure 422.
  final String? unsupportedTitle;
  final String unsupportedSub;

  /// Live guidance: what to fix next ([CaptureHint.ready] once aligned).
  final CaptureHint hint;
  final bool guideUnavailable;

  /// Live in-app preview — `null` while initializing (falls back to the
  /// dark-gradient placeholder) or after [cameraUnavailable] (permission
  /// denied / no hardware, e.g. a simulator).
  final CameraController? cameraController;
  final bool cameraUnavailable;
  final VoidCallback onCapture;

  /// Long-press alternative to [onCapture] — routes through the
  /// Phase-2 `cv-service` pipeline instead of the shipped Phase-1
  /// path. See `_ARScannerScreenState._captureCvService`.
  final VoidCallback onCaptureDev;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    final controller = cameraController;
    final previewReady = controller != null && controller.value.isInitialized;
    final canCapture = aligned && previewReady && unsupportedTitle == null;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (previewReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              ),
            )
          else
            // Dark-gradient placeholder — shown while the camera
            // initializes, or in place of a live feed entirely when
            // [cameraUnavailable] (permission denied / no hardware).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    branchTheme.bright.withValues(alpha: 0.10),
                    Colors.black,
                  ],
                ),
              ),
            ),
          if (cameraUnavailable)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off_outlined,
                      color: AppColors.warn,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.arErrorCameraTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyStrong(
                        color: AppColors.ink,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.arErrorCameraSub,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Corner brackets
          const Positioned.fill(child: _CornerBrackets()),
          // Ghost figure overlay
          Center(
            child: SizedBox(
              width: 200,
              height: 380,
              child: Opacity(
                opacity: 0.5,
                child: CustomPaint(
                  painter: _GhostOverlayPainter(
                    accent: aligned ? AppColors.ok : AppColors.warn,
                  ),
                ),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(icon: Icons.close, onTap: onClose),
                AppChip(
                  label: l.arLive,
                  accent: true,
                  accentColor: AppColors.err,
                  icon: const Icon(Icons.fiber_manual_record),
                ),
                _CircleBtn(icon: Icons.info_outline, onTap: () {}),
              ],
            ),
          ),
          // "Can't be checked yet" notice — the uniform is chosen on the
          // dashboard, so the card links back there.
          if (unsupportedTitle != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 68,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.err.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.err, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block, color: AppColors.err, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            unsupportedTitle!,
                            style: AppTextStyles.bodyStrong(
                              color: AppColors.ink,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unsupportedSub,
                            style: AppTextStyles.body(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: onChooseUniform,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                            ),
                            child: Text(
                              l.arChooseUniform,
                              style: AppTextStyles.bodyStrong(
                                color: AppColors.ink,
                                fontSize: 13,
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
          // Status banner
          Positioned(
            bottom: 140 + MediaQuery.of(context).viewPadding.bottom,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (aligned ? AppColors.ok : AppColors.warn).withValues(
                  alpha: 0.18,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: aligned ? AppColors.ok : AppColors.warn,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    aligned ? Icons.check_circle_outline : Icons.adjust,
                    color: aligned ? AppColors.ok : AppColors.warn,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          aligned ? l.arAlignedTitle : l.arAligning,
                          style: AppTextStyles.bodyStrong(
                            color: AppColors.ink,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          aligned
                              ? (guideUnavailable
                                    ? l.arHintUnavailable
                                    : l.arAlignedSub)
                              : _hintText(l, hint),
                          style: AppTextStyles.body(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Capture button
          Positioned(
            bottom: 32 + MediaQuery.of(context).viewPadding.bottom,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: canCapture ? onCapture : null,
                onLongPress: canCapture ? onCaptureDev : null,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canCapture
                        ? AppColors.ok
                        : Colors.white.withValues(alpha: 0.10),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: canCapture
                        ? [
                            BoxShadow(
                              color: AppColors.ok.withValues(alpha: 0.6),
                              blurRadius: 24,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
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

/// Shown while the `/check_uniform` geometry pass is in flight.
class _AnalyzingPhase extends StatelessWidget {
  const _AnalyzingPhase({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  branchTheme.bright.withValues(alpha: 0.14),
                  Colors.black,
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _CircleBtn(icon: Icons.close, onTap: onClose),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(branchTheme.bright),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.arAnalyzing,
                  style: AppTextStyles.bodyStrong(
                    color: AppColors.ink,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.arAnalyzingSub,
                  style: AppTextStyles.body(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.5,
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

/// Shown when the compliance check call fails — see
/// [_describeCaptureError] for how the message is chosen; never shows
/// the raw exception to the user.
class _FailedPhase extends StatelessWidget {
  const _FailedPhase({
    required this.error,
    required this.onRetry,
    required this.onClose,
  });
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final branchTheme = context.branchTheme;
    final (title, subtitle) = describeCaptureError(error, l);
    final detail = captureErrorDetail(error);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: _CircleBtn(icon: Icons.close, onTap: onClose),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.err,
                    size: 40,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyStrong(
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.5,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      detail,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.mono(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: l.arRetry,
                    gradient: true,
                    accentColor: branchTheme.accent,
                    icon: const Icon(Icons.refresh, size: 14),
                    onPressed: onRetry,
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 10),
                    // Couldn't reach cv-service: let the user fix the
                    // address (or switch to USB) right here, then retry.
                    GhostButton(
                      label: l.arServerSettings,
                      icon: const Icon(Icons.settings_ethernet, size: 14),
                      onPressed: () => showAppBottomSheet<void>(
                        context: context,
                        builder: (_) => const CvServerSettings(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();
  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(alpha: 0.6);
    return Stack(
      children: [
        Positioned(
          top: 70,
          left: 24,
          child: _bracket(color, Alignment.topLeft),
        ),
        Positioned(
          top: 70,
          right: 24,
          child: _bracket(color, Alignment.topRight),
        ),
        Positioned(
          bottom: 220,
          left: 24,
          child: _bracket(color, Alignment.bottomLeft),
        ),
        Positioned(
          bottom: 220,
          right: 24,
          child: _bracket(color, Alignment.bottomRight),
        ),
      ],
    );
  }

  Widget _bracket(Color color, Alignment a) {
    final stroke = Border(
      top: a.y < 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      bottom: a.y > 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      left: a.x < 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
      right: a.x > 0 ? BorderSide(color: color, width: 2) : BorderSide.none,
    );
    return SizedBox(
      width: 30,
      height: 30,
      child: DecoratedBox(decoration: BoxDecoration(border: stroke)),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _GhostOverlayPainter extends CustomPainter {
  _GhostOverlayPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.10), w * 0.10, paint);
    canvas.drawRect(
      Rect.fromLTRB(w * 0.30, h * 0.20, w * 0.70, h * 0.55),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.30, h * 0.55, w * 0.49, h * 0.95),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.51, h * 0.55, w * 0.70, h * 0.95),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostOverlayPainter old) =>
      old.accent != accent;
}

/// Renders the real `cv-service` `/check_uniform` geometry result — the
/// default capture path. Every number here comes from the pixel-space
/// pipeline (pose → PnP camera solve → segmentation → doctrine tolerance
/// check); nothing is fabricated. Reuses [_ScoreRing] / [_IssueCard] /
/// [_PassCard] / [_MetaTile] for visual continuity with [_CvScorecard].
class _RealScorecard extends StatelessWidget {
  const _RealScorecard({required this.result, required this.onRescan});
  final UniformCheckResult result;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final identityFailed =
        result.overallStatus == 'INVALID_ATTIRE' ||
        result.overallStatus == 'WRONG_UNIFORM' ||
        result.overallStatus == 'UNABLE_TO_VERIFY';
    final score = result.overallScore.round();
    final color = result.passed
        ? AppColors.ok
        : identityFailed
        ? AppColors.err
        : result.incomplete || score >= 70
        ? AppColors.warn
        : AppColors.err;
    final issues = result.issues;
    final passes = result.passes;
    final couldNotCheck = result.couldNotCheck;
    final checkByEye = result.checkByEye;
    final overlay = _decodeOverlay(result.debugImageBase64);

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppChip(
                      label: 'COMPLIANCE CHECK',
                      accent: true,
                      accentColor: branchTheme.bright,
                    ),
                    Text(
                      result.passed
                          ? 'PASS'
                          : result.incomplete
                          ? 'INCOMPLETE'
                          : 'FAIL',
                      style: AppTextStyles.mono(
                        fontSize: 11,
                        color: color,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: _ScoreRing(score: score, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      identityFailed
                          ? 'Not assessed — ${_identityMessage(result.overallStatus)}'
                          : _summaryLine(result),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                    if (result.focalSource == 'assumed') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Camera lens info was missing from the photo — distances are less precise.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          color: AppColors.warn,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    if (overlay != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Image.memory(
                          overlay,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Where each item should be vs. where it was found',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          color: AppColors.inkSubtle,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (!result.personDetected ||
                        !result.imageQualityUsable) ...[
                      const SizedBox(height: 8),
                      Text(
                        !result.personDetected
                            ? 'No person was clearly detected — result may be unreliable.'
                            : 'Photo quality was low — result may be unreliable.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          color: AppColors.warn,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    if (identityFailed) ...[
                      const SizedBox(height: 16),
                      _IssueCard(
                        title: _identityLabel(result.overallStatus),
                        body:
                            'Accessory checks were skipped because SAF uniform identity was not verified.',
                        color: AppColors.err,
                        icon: Icons.block_outlined,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!identityFailed && issues.isNotEmpty) ...[
                      Text(
                        '${issues.length} ISSUE(S)',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.warn,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in issues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IssueCard(
                            title:
                                '${_prettyName(item.name)} — ${_statusLabel(item.status)}',
                            body: _accessoryBody(item),
                            color:
                                item.status ==
                                    UniformCheckStatus.slightlyMisaligned
                                ? AppColors.warn
                                : AppColors.err,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (!identityFailed && passes.isNotEmpty) ...[
                      Text(
                        '${passes.length} CORRECT',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.ok,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in passes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PassCard(
                            label: _prettyName(item.name),
                            body: _accessoryBody(item),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (!identityFailed && couldNotCheck.isNotEmpty) ...[
                      Text(
                        '${couldNotCheck.length} COULD NOT CHECK — A RETAKE MAY HELP',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.inkMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in couldNotCheck)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IssueCard(
                            title: _prettyName(item.name),
                            body: _accessoryBody(item),
                            color: AppColors.inkMuted,
                            icon: Icons.help_outline,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (!identityFailed && checkByEye.isNotEmpty) ...[
                      Text(
                        '${checkByEye.length} CHECK BY EYE',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.inkMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Not measured automatically yet — compare with the doctrine diagram.',
                        style: AppTextStyles.body(
                          color: AppColors.inkSubtle,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in checkByEye)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _IssueCard(
                            title: _prettyName(item.name),
                            body: _accessoryBody(item),
                            color: AppColors.inkSubtle,
                            icon: Icons.visibility_outlined,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (identityFailed)
                      Text(
                        'UNIFORM IDENTITY GATE',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.mono(
                          fontSize: 10,
                          color: AppColors.inkSubtle,
                          letterSpacing: 1.4,
                        ),
                      ),
                    if (!identityFailed)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        childAspectRatio: 1.7,
                        children: [
                          _MetaTile(
                            label: 'REQUIRED',
                            value: '${result.summary.requiredAccessories}',
                          ),
                          _MetaTile(
                            label: 'PERSON',
                            value:
                                '${(result.personConfidence * 100).round()}%',
                          ),
                          if (result.burstFrames != null)
                            _MetaTile(
                              label: 'FRAMES',
                              value:
                                  '${result.burstUsableFrames ?? 0}/${result.burstFrames}',
                            )
                          else
                            _MetaTile(
                              label: 'IMG QUALITY',
                              value:
                                  '${(result.imageQualityConfidence * 100).round()}%',
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
                  top: 4,
                ),
                child: GhostButton(
                  label: 'Rescan',
                  icon: const Icon(Icons.refresh, size: 14),
                  onPressed: onRescan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hintText(AppLocalizations l, CaptureHint hint) => switch (hint) {
  CaptureHint.noPerson => l.arHintNoPerson,
  CaptureHint.notFullBody => l.arHintNotFullBody,
  CaptureHint.tooFar => l.arHintTooFar,
  CaptureHint.tooClose => l.arHintTooClose,
  CaptureHint.notCentered => l.arHintNotCentered,
  CaptureHint.facingAway => l.arHintFacingAway,
  CaptureHint.turnedSideways => l.arHintTurnedSideways,
  CaptureHint.armsRaised => l.arHintArmsRaised,
  CaptureHint.phoneTilted => l.arHintPhoneTilted,
  CaptureHint.holdStill => l.arHintHoldStill,
  CaptureHint.ready => l.arAlignedSub,
};

String _summaryLine(UniformCheckResult r) {
  final s = r.summary;
  if (s.requiredAccessories == 0) {
    return 'No doctrine rules resolved for this profile.';
  }

  final line =
      '${s.correct} of ${s.requiredAccessories} required items correct · '
      '${s.incorrect} off · ${s.slightlyMisaligned} slightly off · '
      '${s.missing} missing · ${s.uncertain} unverified.';
  if (r.incomplete) {
    return 'Too few items could be checked from this photo to give a result. '
        'Retake front-facing with your full body in frame.\n$line';
  }
  return line;
}

String _identityLabel(String status) => switch (status) {
  'INVALID_ATTIRE' => 'INVALID ATTIRE',
  'WRONG_UNIFORM' => 'WRONG UNIFORM',
  _ => 'UNABLE TO VERIFY UNIFORM',
};

String _identityMessage(String status) => switch (status) {
  'INVALID_ATTIRE' => 'No SAF uniform was detected.',
  'WRONG_UNIFORM' => 'The detected uniform does not match your selection.',
  _ =>
    'The photograph does not provide enough evidence to identify the uniform.',
};

/// The instruction first — what to do, in cm and the wearer's own
/// left/right — then how solid the call is and the doctrine reference.
/// Falls back to the technical message for older service versions.
String _accessoryBody(UniformCheckAccessory a) {
  final parts = <String>[];
  parts.add(
    'Presence: ${a.present == null
        ? 'not determined'
        : a.present!
        ? 'present'
        : 'missing'} · '
    'Placement: ${a.positionCorrect == null
        ? 'not determined'
        : a.positionCorrect!
        ? 'correct'
        : 'not within tolerance'}',
  );
  final instruction = a.instruction;
  if (instruction.isNotEmpty) {
    final colon = instruction.indexOf(': ');
    parts.add(colon >= 0 ? instruction.substring(colon + 2) : instruction);
  } else if (a.message.isNotEmpty) {
    parts.add(a.message);
  } else if (!a.checkable) {
    parts.add(
      'Not measured automatically yet — compare with the doctrine diagram.',
    );
  } else if (a.status == UniformCheckStatus.correct) {
    parts.add('Detected within the doctrine tolerance.');
  } else if (a.status == UniformCheckStatus.uncertain) {
    parts.add(
      'The image did not provide enough evidence for a reliable verdict.',
    );
  }
  if (a.confidence != null) {
    parts.add('Confidence: ${(a.confidence! * 100).round()}%.');
  }
  if (a.visibility.isNotEmpty) {
    parts.add('Visibility: ${a.visibility.toLowerCase()}.');
  }
  if (a.errorMagnitudePx != null) {
    parts.add('Measured offset: ${a.errorMagnitudePx!.toStringAsFixed(1)} px.');
  }
  if (a.frameAgreement != null) parts.add('${a.frameAgreement} frames agree.');
  if (a.detectionSource != null) {
    parts.add('Detection: ${a.detectionSource!.replaceAll('_', ' ')}.');
  }
  if (a.doctrineRef.isNotEmpty) parts.add('Ref: ${a.doctrineRef}');
  return parts.join('\n');
}

Uint8List? _decodeOverlay(String? base64Image) {
  if (base64Image == null || base64Image.isEmpty) return null;
  try {
    return base64Decode(base64Image);
  } catch (e, st) {
    developer.log(
      'decodeOverlay: failed',
      name: _tag,
      error: e,
      stackTrace: st,
      level: 1000,
    );
    return null;
  }
}

String _statusLabel(UniformCheckStatus s) => switch (s) {
  UniformCheckStatus.correct => 'correct',
  UniformCheckStatus.slightlyMisaligned => 'slightly misaligned',
  UniformCheckStatus.incorrect => 'incorrect position',
  UniformCheckStatus.missing => 'missing',
  UniformCheckStatus.uncertain => 'unverified',
};

String _prettyName(String raw) => raw
    .split(RegExp(r'[_\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: AppTextStyles.title(color: AppColors.ink, fontSize: 30),
              ),
              const SizedBox(height: 4),
              Text(
                l.arCompliance,
                style: AppTextStyles.mono(
                  fontSize: 9.5,
                  color: AppColors.inkSubtle,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.body,
    this.color = AppColors.err,
    this.icon = Icons.error_outline,
  });
  final String title;
  final String body;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong(
                    color: AppColors.ink,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.body(
                    color: AppColors.inkMuted,
                    fontSize: 12,
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

class _PassCard extends StatelessWidget {
  const _PassCard({required this.label, required this.body});
  final String label;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ok.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(
          color: AppColors.ok.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ok,
            ),
            child: const Icon(Icons.check, color: AppColors.bg, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyStrong(
                    color: AppColors.ink,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.body(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.mono(
              fontSize: 9,
              color: AppColors.inkSubtle,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong(color: AppColors.ink, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Renders a Phase-2 `cv-service` [CvInspectionResult] — reached only
/// via the long-press dev entry point (`_ScanningPhase.onCaptureDev`),
/// never the default tap. Deliberately labelled "PHASE 2 (DEV)" rather
/// than styled to look like the shipped [_Scorecard], since the
/// underlying accessory identification is a vision-language judgment
/// standing in for a not-yet-trained detector — see
/// `cv-service/README.md`. Renders the extra fields the Phase-1 shape
/// doesn't have: per-region subscores, the annotated crop-box image,
/// and camera-pose diagnostics.
class _CvScorecard extends StatelessWidget {
  const _CvScorecard({required this.result, required this.onRescan});
  final CvInspectionResult result;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final branchTheme = context.branchTheme;
    final score = result.overallScore.round();
    final color = score >= 90
        ? AppColors.ok
        : score >= 70
        ? AppColors.warn
        : AppColors.err;
    final subscoreEntries = <String, double?>{
      'HEADWEAR': result.subscores.headwear,
      'CHEST': result.subscores.chest,
      'COLLAR': result.subscores.collar,
      'SLEEVES': result.subscores.sleeves,
      'WAIST': result.subscores.waist,
      'LOWER BODY': result.subscores.lowerBody,
      'FOOTWEAR': result.subscores.footwear,
      'APPEARANCE': result.subscores.appearance,
    }..removeWhere((_, v) => v == null);

    Uint8List? annotatedBytes;
    if (result.annotatedImageBase64 != null) {
      try {
        annotatedBytes = base64Decode(result.annotatedImageBase64!);
      } catch (_) {
        annotatedBytes = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppChip(
                      label: 'PHASE 2 · DEV',
                      accent: true,
                      accentColor: branchTheme.bright,
                    ),
                    Text(
                      result.status,
                      style: AppTextStyles.mono(
                        fontSize: 10.5,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: _ScoreRing(score: score, color: color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Real pose + camera-pose geometry; item identification '
                      'is a vision-language judgment, not a trained detector.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                      ),
                    ),
                    if (annotatedBytes != null) ...[
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Image.memory(
                          annotatedBytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (subscoreEntries.isNotEmpty) ...[
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        childAspectRatio: 1.5,
                        children: [
                          for (final entry in subscoreEntries.entries)
                            _MetaTile(
                              label: entry.key,
                              value: '${entry.value!.round()}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (result.issues.isNotEmpty) ...[
                      Text(
                        '${result.issues.length} ISSUE(S)',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.warn,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final issue in result.issues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IssueCard(
                            title: '${issue.item} — ${issue.problem.wireName}',
                            body: issue.note.isNotEmpty
                                ? issue.note
                                : issue.doctrineRef,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (result.uncertain.isNotEmpty) ...[
                      Text(
                        '${result.uncertain.length} UNCERTAIN',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.inkMuted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in result.uncertain)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IssueCard(
                            title: item.item,
                            body: item.reason,
                            color: AppColors.inkMuted,
                            icon: Icons.help_outline,
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (result.geometricVerdicts.isNotEmpty) ...[
                      Text(
                        'GEOMETRIC VERDICTS (${result.geometricVerdicts.length})',
                        style: AppTextStyles.bodyStrong(
                          color: AppColors.ink,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Doctrine tolerance vs. detected segment position — '
                        'not the vision-language judgment above.',
                        style: AppTextStyles.body(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final verdict in result.geometricVerdicts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IssueCard(
                            title:
                                '${verdict.accessory} — ${verdict.status.wireName}',
                            body: verdict.doctrineRef.isNotEmpty
                                ? '${verdict.reason}\n${verdict.doctrineRef}'
                                : verdict.reason,
                            color: _geometricVerdictColor(verdict.status),
                            icon: _geometricVerdictIcon(verdict.status),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.7,
                      children: [
                        _MetaTile(
                          label: 'ITEMS',
                          value: '${result.itemsEvaluated}',
                        ),
                        _MetaTile(
                          label: 'REPROJ. ERR',
                          value:
                              '${result.cameraDiagnostics.reprojectionErrorPx.round()}px',
                        ),
                        _MetaTile(
                          label: 'CORR. PTS',
                          value:
                              '${result.cameraDiagnostics.correspondenceCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
                  top: 4,
                ),
                child: GhostButton(
                  label: 'Rescan',
                  icon: const Icon(Icons.refresh, size: 14),
                  onPressed: onRescan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color/icon per [GeometricVerdictStatus] for the "GEOMETRIC VERDICTS"
/// section — `pass` reuses the same green as the vision-crop path's
/// "present", `fail`/`missing` reuse the same red as its issues,
/// `unverifiable` reuses the same muted grey/help-icon styling already
/// used for the vision-crop path's "uncertain" items, so the two
/// judgment mechanisms read as visually related without being merged.
Color _geometricVerdictColor(GeometricVerdictStatus status) {
  switch (status) {
    case GeometricVerdictStatus.pass_:
      return AppColors.ok;
    case GeometricVerdictStatus.fail:
    case GeometricVerdictStatus.missing:
      return AppColors.err;
    case GeometricVerdictStatus.unverifiable:
      return AppColors.inkMuted;
  }
}

IconData _geometricVerdictIcon(GeometricVerdictStatus status) {
  switch (status) {
    case GeometricVerdictStatus.pass_:
      return Icons.check_circle_outline;
    case GeometricVerdictStatus.fail:
    case GeometricVerdictStatus.missing:
      return Icons.error_outline;
    case GeometricVerdictStatus.unverifiable:
      return Icons.help_outline;
  }
}
