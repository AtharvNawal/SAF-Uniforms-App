import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D20) : AppColors.surface2,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.lineStrong : AppColors.lineLightStrong,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(child: builder(ctx)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.icon,
    this.onClose,
  });

  final String title;
  final String? eyebrow;
  final Widget? icon;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: accent, width: 1),
            ),
            child: IconTheme(
              data: IconThemeData(color: accent, size: 22),
              child: icon!,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? AppColors.ink : AppColors.inkDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          Material(
            color: Colors.white.withValues(alpha: 0.06),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onClose,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}
