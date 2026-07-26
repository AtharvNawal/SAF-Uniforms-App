import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_text_styles.dart';

class CheckCard extends StatelessWidget {
  const CheckCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.checked,
    required this.onTap,
    required this.onToggle,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  /// Optional accessory thumbnail. When non-empty, renders inside the
  /// 56×56 thumb slot in place of [icon]; the icon stays as the
  /// loading placeholder and error fallback so the row never goes blank.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final bright = HSLColor.fromColor(accent).withLightness(0.55).toColor();

    final bg = checked
        ? AppColors.ok.withValues(alpha: 0.08)
        : (isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface2);
    final borderColor = checked
        ? AppColors.ok.withValues(alpha: 0.6)
        : (isDark ? AppColors.line : AppColors.lineLight);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              _Thumb(icon: icon, color: bright, imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong(
                        color: isDark ? AppColors.ink : AppColors.inkDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.mono(
                        fontSize: 10.5,
                        color: AppColors.inkMuted,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: checked ? AppColors.ok : Colors.transparent,
                    border: checked
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 16, color: AppColors.bg)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.icon,
    required this.color,
    this.imageUrl,
  });
  final IconData icon;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final iconFallback = Icon(icon, size: 22, color: color);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: 56,
              height: 56,
              placeholder: (_, _) => Center(child: iconFallback),
              errorWidget: (_, _, _) => Center(child: iconFallback),
            )
          : iconFallback,
    );
  }
}
