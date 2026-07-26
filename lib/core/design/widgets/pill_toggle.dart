import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_text_styles.dart';

class PillToggleOption<T> {
  const PillToggleOption({required this.value, required this.label});
  final T value;
  final String label;
}

class PillToggle<T> extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 38,
  });

  final List<PillToggleOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bright = HSLColor.fromColor(accent).withLightness(0.55).toColor();

    final outerBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface2;
    final outerBorder = isDark ? AppColors.line : AppColors.lineLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: outerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: outerBorder, width: 1),
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: _PillButton(
                label: opt.label,
                active: opt.value == value,
                accentBg: bright,
                height: height,
                onTap: () => onChanged(opt.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.active,
    required this.accentBg,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accentBg;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? accentBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.dmSans(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.bg : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
