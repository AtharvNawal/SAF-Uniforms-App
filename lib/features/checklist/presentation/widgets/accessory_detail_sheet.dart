import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../profile/domain/entities/accessory.dart';
import '../../../profile/domain/entities/branch_id.dart';
import '../../../profile/domain/entities/dress_code.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../domain/services/accessory_presentation.dart';
import '../models/accessory_item.dart';
import 'accessory_remote_image.dart';

Future<void> showAccessoryDetailSheet({
  required BuildContext context,
  required AccessoryItem item,
  required VoidCallback onMarkVerified,
}) {
  return _showSheet(
    context: context,
    title: item.title,
    body: item.body,
    reference: item.reference,
    mono: item.mono,
    icon: item.icon,
    zoneKey: item.id,
    imageUrl: '',
    placementDiagramUrl: '',
    onMarkVerified: onMarkVerified,
  );
}

/// Variant of [showAccessoryDetailSheet] that takes a live [Accessory]
/// (sourced from the Firestore-backed accessory_library). Visually
/// identical — only the data binding changes.
///
/// [dress] is the dress the item is being viewed for (null in the
/// cross-dress "All Accessories" list). With it, the sheet shows that
/// dress's pictures (e.g. the No.4 name tape on No.4 camo, per [branch])
/// and its doctrine text instead of the shared No.3 ones.
Future<void> showAccessoryDetailSheetForAccessory({
  required BuildContext context,
  required Accessory accessory,
  required VoidCallback onMarkVerified,
  required Gender gender,
  DressCode? dress,
  BranchId? branch,
}) {
  final view = _accessoryView(
    accessory,
    gender: gender,
    dress: dress,
    branch: branch,
  );
  final images = accessoryImagesFor(accessory, dress: dress, branch: branch);
  log(
    'open: id=${accessory.id} dress=${dress?.wireName} '
    'branch=${branch?.wireName} '
    'dressImage=${images.imageUrl != accessory.imageUrl} '
    'dressPlacement=${images.placementDiagramUrl != accessory.placementDiagramUrl}',
    name: 'checklist.detail_sheet',
    level: 500,
  );
  return _showSheet(
    context: context,
    title: view.title,
    body: view.body,
    reference: view.reference,
    mono: view.mono,
    icon: view.icon,
    zoneKey: view.zoneKey,
    imageUrl: images.imageUrl,
    placementDiagramUrl: images.placementDiagramUrl,
    onMarkVerified: onMarkVerified,
  );
}

Future<void> _showSheet({
  required BuildContext context,
  required String title,
  required String body,
  required String reference,
  required String mono,
  required IconData icon,
  required String zoneKey,
  required String imageUrl,
  required String placementDiagramUrl,
  required VoidCallback onMarkVerified,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final l = ctx.l10n;
      final accent = ctx.branchTheme.bright;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: title,
            eyebrow: l.checklistVerbatimManual,
            icon: Icon(icon),
            onClose: () => Navigator.of(ctx).pop(),
          ),
          const SizedBox(height: 14),
          if (imageUrl.isNotEmpty) ...[
            AccessoryRemoteImage(
              url: imageUrl,
              caption: 'ACCESSORY',
              icon: icon,
              accent: accent,
            ),
            const SizedBox(height: 12),
          ],
          if (placementDiagramUrl.isNotEmpty) ...[
            AccessoryRemoteImage(
              url: placementDiagramUrl,
              caption: 'PLACEMENT',
              icon: icon,
              accent: accent,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.line, width: 1),
            ),
            child: Text(
              body,
              style: AppTextStyles.body(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 13.5,
              ).copyWith(height: 1.55),
            ),
          ),
          const SizedBox(height: 14),
          // Custom-painted torso fallback. Useful for accessories whose
          // real placement diagram has not been uploaded yet (legacy
          // No.1/2/4/5 entries) — collapses cleanly once every entry has
          // a real diagram URL.
          if (placementDiagramUrl.isEmpty) ...[
            _PlacementDiagram(
              zoneKey: zoneKey,
              reference: reference,
              mono: mono,
              accent: accent,
            ),
            const SizedBox(height: 14),
          ],
          PrimaryButton(
            label: l.commonGotIt,
            gradient: true,
            accentColor: ctx.branchTheme.accent,
            icon: const Icon(Icons.check, size: 16),
            onPressed: () {
              Navigator.of(ctx).pop();
              onMarkVerified();
            },
          ),
        ],
      );
    },
  );
}

class _AccessoryView {
  const _AccessoryView({
    required this.title,
    required this.body,
    required this.reference,
    required this.mono,
    required this.icon,
    required this.zoneKey,
  });
  final String title;
  final String body;
  final String reference;
  final String mono;
  final IconData icon;
  final String zoneKey;
}

_AccessoryView _accessoryView(
  Accessory a, {
  required Gender gender,
  DressCode? dress,
  BranchId? branch,
}) {
  final category = a.category;
  final body = accessoryDoctrineText(
        a,
        gender: gender,
        dress: dress,
        branch: branch,
      ) ??
      'Refer to branch doctrine for exact placement of this accessory.';
  final eyebrow = (category ?? 'accessory')
      .replaceAll('_', ' ')
      .toUpperCase();
  return _AccessoryView(
    title: a.displayName.isEmpty ? a.id : a.displayName,
    body: body,
    reference: eyebrow,
    mono: a.id,
    icon: iconForAccessoryCategory(category),
    zoneKey: zoneForCategory(category),
  );
}

IconData iconForAccessoryCategory(String? category) {
  if (category == null) return Icons.shield_outlined;
  if (category.startsWith('headdress')) return Icons.military_tech;
  if (category.startsWith('cap_badge')) return Icons.star_border;
  if (category.startsWith('cap_embellishment')) return Icons.workspace_premium;
  if (category.startsWith('sleeve_rank') ||
      category == 'sleeve_rank_specialist' ||
      category == 'sleeve_rank_enlistee') {
    return Icons.format_align_left;
  }
  if (category == 'epaulette') return Icons.label_outline;
  if (category == 'gorgette') return Icons.style_outlined;
  if (category == 'lanyard') return Icons.airline_stops;
  if (category == 'arms_badge') return Icons.shield_outlined;
  if (category == 'vocation_badge') return Icons.engineering_outlined;
  if (category == 'name_tag') return Icons.badge_outlined;
  if (category == 'belt') return Icons.horizontal_rule;
  if (category == 'footwear') return Icons.directions_walk;
  if (category == 'socks') return Icons.water_drop_outlined;
  if (category == 'medal_ribbons') return Icons.workspace_premium_outlined;
  if (category == 'saf_badge') return Icons.verified_outlined;
  if (category == 'foreign_badge') return Icons.public;
  if (category.startsWith('skill')) return Icons.fitness_center;
  return Icons.shield_outlined;
}

String zoneForCategory(String? category) {
  if (category == null) return 'badges';
  if (category.startsWith('headdress')) return 'collar';
  if (category == 'name_tag') return 'name';
  if (category == 'lanyard') return 'lanyard';
  if (category == 'belt') return 'belt';
  if (category == 'medal_ribbons') return 'medals';
  return 'badges';
}

class _PlacementDiagram extends StatelessWidget {
  const _PlacementDiagram({
    required this.zoneKey,
    required this.reference,
    required this.mono,
    required this.accent,
  });
  final String zoneKey;
  final String reference;
  final String mono;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 3,
      child: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.line, width: 1),
            ),
            child: CustomPaint(
              painter: _DiagramPainter(zoneKey: zoneKey, accent: accent),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: AppChip(
              label: 'Reference · $reference',
              accent: true,
              accentColor: accent,
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Text(
              mono,
              style: AppTextStyles.mono(
                fontSize: 10,
                color: accent,
                letterSpacing: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  _DiagramPainter({required this.zoneKey, required this.accent});
  final String zoneKey;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Torso outline
    final torso = Path()
      ..moveTo(w * 0.30, h * 0.07)
      ..lineTo(w * 0.70, h * 0.07)
      ..lineTo(w * 0.78, h * 0.93)
      ..lineTo(w * 0.22, h * 0.93)
      ..close();
    canvas.drawPath(torso, outline);

    // Pockets
    canvas.drawRect(Rect.fromLTRB(w * 0.25, h * 0.42, w * 0.42, h * 0.65), outline);
    canvas.drawRect(Rect.fromLTRB(w * 0.58, h * 0.42, w * 0.75, h * 0.65), outline);

    // Highlight
    final highlight = Paint()
      ..color = accent
      ..strokeWidth = 1.4;
    if (zoneKey == 'collar') {
      canvas.drawLine(Offset(w * 0.42, h * 0.10), Offset(w * 0.42, h * 0.22), highlight);
      canvas.drawCircle(Offset(w * 0.42, h * 0.22), 3, Paint()..color = accent);
    } else if (zoneKey == 'badges') {
      canvas.drawLine(Offset(w * 0.26, h * 0.34), Offset(w * 0.41, h * 0.34), highlight);
    } else if (zoneKey == 'medals') {
      for (var i = 0; i < 3; i++) {
        canvas.drawRect(
          Rect.fromLTWH(w * 0.26 + i * w * 0.05, h * 0.36, w * 0.04, h * 0.04),
          Paint()..color = accent,
        );
      }
    } else if (zoneKey == 'name') {
      canvas.drawRect(Rect.fromLTWH(w * 0.59, h * 0.34, w * 0.16, h * 0.04), Paint()..color = accent);
    } else if (zoneKey == 'lanyard') {
      final p = Path()
        ..moveTo(w * 0.71, h * 0.08)
        ..quadraticBezierTo(w * 0.62, h * 0.28, w * 0.54, h * 0.55);
      canvas.drawPath(p, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 1.4);
    } else if (zoneKey == 'belt') {
      canvas.drawRect(
        Rect.fromLTWH(w * 0.26, h * 0.83, w * 0.50, h * 0.06),
        Paint()..color = accent.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter old) =>
      old.zoneKey != zoneKey || old.accent != accent;
}
