import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.accent = false,
    this.accentColor,
    this.icon,
  });

  final String label;
  final bool accent;
  final Color? accentColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ac = accentColor ?? Theme.of(context).colorScheme.primary;
    final bg = accent ? ac.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.06);
    final fg = accent ? AppColors.ink : AppColors.inkMuted;
    final borderColor = accent
        ? ac.withValues(alpha: 0.5)
        : AppColors.line;

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: 12),
              child: icon!,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: AppTextStyles.mono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
