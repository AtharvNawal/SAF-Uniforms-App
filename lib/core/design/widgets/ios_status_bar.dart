import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_text_styles.dart';

class IOSStatusBar extends StatelessWidget {
  const IOSStatusBar({super.key, this.dark = true});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.ink : AppColors.inkDark;
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top > 0 ? mq.padding.top : 18.0;
    return SizedBox(
      height: 28 + topPad,
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, topPad - 4, 22, 4),
        child: Row(
          children: [
            Text(
              '9:41',
              style: AppTextStyles.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            // Signal bars
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 3,
                    height: 4 + i * 2.0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 6),
            // Wifi (small triangle of arcs)
            Icon(Icons.wifi, size: 14, color: color),
            const SizedBox(width: 6),
            // Battery
            _BatteryGlyph(color: color),
          ],
        ),
      ),
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 12,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.55), width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Positioned(
            left: 1.5,
            top: 1.5,
            bottom: 1.5,
            child: FractionallySizedBox(
              widthFactor: 0.85,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            top: 4,
            child: Container(
              width: 2,
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
