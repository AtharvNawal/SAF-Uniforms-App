import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.height = AppSpacing.buttonHeight,
    this.gradient = false,
    this.accentColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool expand;
  final double height;
  final bool gradient;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = accentColor ?? theme.colorScheme.primary;
    final bright = HSLColor.fromColor(ac).withLightness(0.55).toColor();
    final fg = AppColors.bg;
    final disabled = onPressed == null;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      gradient: gradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ac, bright],
            )
          : null,
      color: gradient
          ? null
          : disabled
              ? Colors.white.withValues(alpha: 0.08)
              : bright,
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: gradient ? Colors.white : fg, size: 16),
              child: icon!,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.button(
                color: gradient
                    ? Colors.white
                    : disabled
                        ? Colors.white.withValues(alpha: 0.3)
                        : fg,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            IconTheme(
              data: IconThemeData(color: gradient ? Colors.white : fg, size: 16),
              child: trailingIcon!,
            ),
          ],
        ],
      ),
    );

    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: height,
          decoration: decoration,
          child: content,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.height = AppSpacing.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.lineStrong, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 16),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class IconChipButton extends StatelessWidget {
  const IconChipButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = AppSpacing.iconBtn,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 16),
            child: icon,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}
