import 'package:flutter/material.dart';

import '../app_colors.dart';

class TopoBackground extends StatelessWidget {
  const TopoBackground({
    super.key,
    this.accentColor,
    this.opacity = 0.35,
    this.gradientCenter = const Alignment(0, -0.4),
  });

  final Color? accentColor;
  final double opacity;
  final Alignment gradientCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.charcoal),
        if (accentColor != null)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: gradientCenter,
                  radius: 0.85,
                  colors: [accentColor!.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
