import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/widgets/app_chip.dart';

/// Renders a Firebase-Storage-hosted accessory image with a small
/// caption chip. Keeps the icon as both the loading placeholder and the
/// error fallback so the slot never goes blank, even on cold open or
/// network hiccup.
class AccessoryRemoteImage extends StatelessWidget {
  const AccessoryRemoteImage({
    super.key,
    required this.url,
    required this.caption,
    required this.icon,
    required this.accent,
  });
  final String url;
  final String caption;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: AppColors.line, width: 1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => Center(
                    child: Icon(
                      icon,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  errorWidget: (_, _, _) => Center(
                    child: Icon(
                      icon,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: AppChip(
              label: caption,
              accent: true,
              accentColor: accent,
            ),
          ),
        ],
      ),
    );
  }
}
