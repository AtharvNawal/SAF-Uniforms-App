import 'package:flutter/material.dart';

import '../../../features/profile/domain/entities/dress_code.dart';
import '../app_colors.dart';

class DressMiniPreview extends StatelessWidget {
  const DressMiniPreview({
    super.key,
    required this.dress,
    this.size = 80,
    this.accent,
  });

  final DressCode dress;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ac = accent ?? Theme.of(context).colorScheme.primary;
    final bright = HSLColor.fromColor(ac).withLightness(0.55).toColor();

    return SizedBox(
      width: size,
      height: size * 1.25,
      child: CustomPaint(
        painter: _DressPainter(dress: dress, accent: bright),
      ),
    );
  }
}

class _DressPainter extends CustomPainter {
  _DressPainter({required this.dress, required this.accent});
  final DressCode dress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final palette = _paletteFor(dress);
    final body = palette.body;
    final stroke = palette.stroke;

    final scaleX = size.width / 80;
    final scaleY = size.height / 100;
    Offset p(double x, double y) => Offset(x * scaleX, y * scaleY);

    // Head
    final headPaint = Paint()..color = body.withValues(alpha: 0.8);
    canvas.drawCircle(p(40, 20), 9 * scaleX, headPaint);

    // Headdress hint for No.1 and No.5
    if (dress == DressCode.no1) {
      canvas.drawOval(
        Rect.fromCenter(center: p(40, 14), width: 24 * scaleX, height: 10 * scaleY),
        Paint()
          ..color = body
          ..style = PaintingStyle.fill,
      );
    } else if (dress == DressCode.no5) {
      final cap = Path()
        ..moveTo(p(28, 20).dx, p(28, 20).dy)
        ..quadraticBezierTo(p(40, 8).dx, p(40, 8).dy, p(52, 20).dx, p(52, 20).dy)
        ..lineTo(p(52, 24).dx, p(52, 24).dy)
        ..lineTo(p(28, 24).dx, p(28, 24).dy)
        ..close();
      canvas.drawPath(cap, Paint()..color = body);
    }

    // Torso
    final torso = Path()
      ..moveTo(p(22, 36).dx, p(22, 36).dy)
      ..lineTo(p(58, 36).dx, p(58, 36).dy)
      ..lineTo(p(62, 72).dx, p(62, 72).dy)
      ..lineTo(p(18, 72).dx, p(18, 72).dy)
      ..close();
    canvas.drawPath(torso, Paint()..color = body.withValues(alpha: 0.85));
    canvas.drawPath(
      torso,
      Paint()
        ..color = stroke
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );

    // Center seam
    canvas.drawLine(
      p(40, 36),
      p(40, 72),
      Paint()
        ..color = stroke.withValues(alpha: 0.6)
        ..strokeWidth = 0.6,
    );

    // Pockets
    final pocketPaint = Paint()
      ..color = stroke.withValues(alpha: 0.7)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(p(26, 46).dx, p(26, 46).dy, 10 * scaleX, 8 * scaleY),
      pocketPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(p(44, 46).dx, p(44, 46).dy, 10 * scaleX, 8 * scaleY),
      pocketPaint,
    );

    // Medals
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(p(26 + i * 4.0, 42).dx, p(0, 42).dy, 3 * scaleX, 2 * scaleY),
        Paint()..color = accent,
      );
    }

    // Belt
    canvas.drawRect(
      Rect.fromLTWH(p(18, 72).dx, p(0, 72).dy, 44 * scaleX, 3 * scaleY),
      Paint()..color = accent.withValues(alpha: 0.5),
    );

    // Legs
    final left = Path()
      ..moveTo(p(22, 75).dx, p(22, 75).dy)
      ..lineTo(p(38, 75).dx, p(38, 75).dy)
      ..lineTo(p(36, 96).dx, p(36, 96).dy)
      ..lineTo(p(26, 96).dx, p(26, 96).dy)
      ..close();
    final right = Path()
      ..moveTo(p(42, 75).dx, p(42, 75).dy)
      ..lineTo(p(58, 75).dx, p(58, 75).dy)
      ..lineTo(p(54, 96).dx, p(54, 96).dy)
      ..lineTo(p(44, 96).dx, p(44, 96).dy)
      ..close();
    final legPaint = Paint()..color = body.withValues(alpha: 0.6);
    canvas.drawPath(left, legPaint);
    canvas.drawPath(right, legPaint);
  }

  _Palette _paletteFor(DressCode d) {
    switch (d) {
      case DressCode.no1:
        return const _Palette(
          body: Color(0xFFF4F4F0),
          stroke: Color(0x73000000),
        );
      case DressCode.no2:
        return const _Palette(
          body: Color(0xFF1A1D22),
          stroke: Color(0x66FFFFFF),
        );
      case DressCode.no3:
        return _Palette(body: AppColors.ink.withValues(alpha: 0.18), stroke: const Color(0x80FFFFFF));
      case DressCode.no4:
        return const _Palette(
          body: Color(0xFF3A4434),
          stroke: Color(0x73FFFFFF),
        );
      case DressCode.no5:
        return const _Palette(
          body: Color(0xFF2A3A25),
          stroke: Color(0x80FFFFFF),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _DressPainter oldDelegate) =>
      oldDelegate.dress != dress || oldDelegate.accent != accent;
}

class _Palette {
  const _Palette({required this.body, required this.stroke});
  final Color body;
  final Color stroke;
}
