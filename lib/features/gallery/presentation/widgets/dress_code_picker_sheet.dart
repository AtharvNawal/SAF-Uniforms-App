import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/dress_code.dart';

/// Returns:
/// - the chosen dress-code wireName (e.g. `"No3"`) if the user picked one,
/// - the empty string `""` if the user picked "None",
/// - `null` if the sheet was dismissed without confirming.
Future<String?> showDressCodePickerSheet(
  BuildContext context, {
  required String preselected,
}) {
  return showAppBottomSheet<String?>(
    context: context,
    builder: (ctx) => _DressCodePickerSheet(preselected: preselected),
  );
}

class _DressCodePickerSheet extends StatefulWidget {
  const _DressCodePickerSheet({required this.preselected});
  final String preselected;

  @override
  State<_DressCodePickerSheet> createState() => _DressCodePickerSheetState();
}

class _DressCodePickerSheetState extends State<_DressCodePickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accent = context.branchTheme.bright;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
          child: Text(l.galleryDressCodeTag,
              style: AppTextStyles.bodyStrong(fontSize: 15)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          child: Text(
            'Tap a dress code to tag this photo, or remove the tag.',
            style: AppTextStyles.body(
                color: AppColors.inkMuted, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: 'None',
                active: _selected.isEmpty,
                accentColor: accent,
                onTap: () => setState(() => _selected = ''),
              ),
              ...DressCode.values.map((dc) => _Pill(
                    label: dc.wireName,
                    active: _selected == dc.wireName,
                    accentColor: accent,
                    onTap: () => setState(() => _selected = dc.wireName),
                  )),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              18, 16, 18, MediaQuery.of(context).padding.bottom + 16),
          child: PrimaryButton(
            label: 'Confirm',
            height: 46,
            gradient: true,
            accentColor: accent,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? accentColor.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          border: Border.all(
            color: active ? accentColor : AppColors.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Icon(Icons.check_rounded, size: 13, color: accentColor),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: AppTextStyles.mono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.ink : AppColors.inkMuted,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
