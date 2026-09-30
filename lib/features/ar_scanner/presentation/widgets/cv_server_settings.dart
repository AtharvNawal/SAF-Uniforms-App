import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_field.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/cv_service_health.dart';
import '../providers/cv_service_url_provider.dart';

const String _tag = 'arScanner.cvServerSettings';

/// Edit + test the AR Scanner's analysis-server (`cv-service`) address on
/// the phone: free-text address, a one-tap USB-cable preset
/// ([kCvServiceUsbUrl], used with `adb reverse`), reset to the compiled-in
/// default, and a "Test connection" probe of `GET /health` that shows the
/// exact answer or network error. Used in the Settings sheet and from the
/// scanner's "Connection problem" screen.
class CvServerSettings extends ConsumerStatefulWidget {
  const CvServerSettings({super.key});

  @override
  ConsumerState<CvServerSettings> createState() => _CvServerSettingsState();
}

class _CvServerSettingsState extends ConsumerState<CvServerSettings> {
  late final TextEditingController _ctrl =
      TextEditingController(text: ref.read(cvServiceUrlProvider));
  bool _testing = false;
  CvServiceHealth? _result;
  String? _message;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save(String input) async {
    final url = await ref.read(cvServiceUrlProvider.notifier).set(input);
    if (!mounted) return;
    setState(() {
      _message = url == null ? context.l10n.cvServerInvalid : context.l10n.cvServerSaved;
      _result = null;
      if (url != null) _ctrl.text = url;
    });
    if (url != null) await _test();
  }

  Future<void> _reset() async {
    await ref.read(cvServiceUrlProvider.notifier).reset();
    if (!mounted) return;
    setState(() {
      _ctrl.text = ref.read(cvServiceUrlProvider);
      _message = null;
      _result = null;
    });
    await _test();
  }

  Future<void> _test() async {
    final url = ref.read(cvServiceUrlProvider);
    AppLog.i('test $url', tag: _tag);
    setState(() => _testing = true);
    final result = await CvServiceHealth.check(url);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = ref.watch(cvServiceUrlProvider);
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(l.cvServerTitle),
        Text(l.cvServerHint, style: AppTextStyles.body(color: AppColors.inkSubtle, fontSize: 11.5)),
        const SizedBox(height: 8),
        AppTextField(
          controller: _ctrl,
          placeholder: 'http://192.168.1.x:8001',
          height: 40,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 4),
        Text(current, style: AppTextStyles.mono(fontSize: 10, color: AppColors.inkSubtle)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GhostButton(label: l.cvServerSave, onPressed: () => _save(_ctrl.text)),
            GhostButton(label: l.cvServerUsb, icon: const Icon(Icons.usb, size: 14), onPressed: () => _save(kCvServiceUsbUrl)),
            GhostButton(label: l.cvServerReset, onPressed: _reset),
            GhostButton(
              label: _testing ? l.cvServerTesting : l.cvServerTest,
              icon: const Icon(Icons.wifi_tethering, size: 14),
              onPressed: _testing ? null : _test,
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(_message!, style: AppTextStyles.body(color: AppColors.inkMuted, fontSize: 12)),
        ],
        if (result != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(result.ok ? Icons.check_circle_outline : Icons.error_outline,
                  size: 16, color: result.ok ? AppColors.ok : AppColors.err),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  '${result.ok ? l.cvServerOk : l.cvServerFail}\n${result.detail}',
                  style: AppTextStyles.mono(fontSize: 10.5, color: result.ok ? AppColors.ok : AppColors.err),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(l.cvServerUsbHelp, style: AppTextStyles.body(color: AppColors.inkSubtle, fontSize: 11)),
      ],
    );
  }
}
