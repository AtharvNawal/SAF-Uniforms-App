import 'package:flutter/material.dart';

import '../../theme/saf_crest_theme.dart';

/// Heraldic backdrop reserved for the SAF Crest theme.
///
/// Same line geometry as the default `TopoBackground` (horizontal
/// triangle-wave sweeps at increasing amplitude down the screen), but
/// rendered in **gold on deep navy** so the surface still reads as the
/// crest's signature palette.
class SafCrestBackground extends StatelessWidget {
  const SafCrestBackground({
    super.key,
    this.opacity = 0.32,
    this.gradientCenter = const Alignment(0, -0.4),
  });

  /// Opacity of the gold topo-line overlay. Kept slightly lower than
  /// `TopoBackground`'s default so foreground content stays legible
  /// against the darker navy base.
  final double opacity;

  /// Anchor of the gold radial halo above the topo lines.
  final Alignment gradientCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep-navy radial base — lighter near the gradient center,
        // darker at the edges.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                Color(0xFF15154A),
                Color(0xFF0A0A1F),
              ],
            ),
          ),
        ),

        // Topo line overlay intentionally hidden for now — restore by
        // re-enabling this `IgnorePointer` block:
        //
        //   IgnorePointer(
        //     child: Opacity(
        //       opacity: opacity,
        //       child: CustomPaint(painter: _GoldTopoPainter()),
        //     ),
        //   ),

        // Gold radial halo — soft, anchored above center.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: gradientCenter,
                radius: 0.85,
                colors: [
                  safCrestGold.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _GoldTopoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = safCrestGold.withValues(alpha: 0.55)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Stylized topographic lines: horizontal sinusoidal sweeps at
    // decreasing y. Identical formula to `TopoBackground._TopoPainter`
    // so the line shape is preserved across themes.
    const lines = 14;
    for (var i = 0; i < lines; i++) {
      final y = h * (0.15 + (i / lines) * 0.85);
      final amp = 8.0 + i * 1.5;
      final wavelength = w / 2;
      final path = Path()..moveTo(-20, y);
      for (double x = 0; x <= w + 20; x += 8) {
        final dy = amp *
            (1 - 2 * ((x / wavelength) - (x / wavelength).floor()).abs()) /
            2;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
