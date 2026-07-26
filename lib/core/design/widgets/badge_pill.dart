import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class BadgePill extends StatelessWidget {
  const BadgePill({
    super.key,
    required this.label,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bright = HSLColor.fromColor(accent).withLightness(0.55).toColor();

    final bg = active
        ? bright.withValues(alpha: 0.22)
        : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface2);
    final borderColor = active
        ? bright
        : (isDark ? AppColors.line : AppColors.lineLight);
    final fg = active
        ? (isDark ? AppColors.ink : AppColors.inkDark)
        : (isDark ? AppColors.inkMuted : AppColors.mutedLight);

    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check : Icons.add,
                  size: 14,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.body(color: fg, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
