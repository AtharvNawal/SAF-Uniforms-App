import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_text_styles.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppSpacing.radiusLg,
    this.borderColor,
    this.background,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = background ??
        (isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface2);
    final border = borderColor ??
        (isDark ? AppColors.line : AppColors.lineLight);

    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      child: child,
    );

    if (onTap == null) return inner;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: inner,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.eyebrow,
  });

  final String title;
  final String? eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final dividerColor = isDark ? AppColors.line : AppColors.lineLight;
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface2;
    final border = isDark ? AppColors.line : AppColors.lineLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
            ),
            child: Row(
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!, style: AppTextStyles.eyebrow(color: accent)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong(
                      color: isDark ? AppColors.ink : AppColors.inkDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
