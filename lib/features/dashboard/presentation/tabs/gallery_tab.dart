import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_bottom_sheet.dart';
import '../../../../core/design/widgets/app_buttons.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/l10n_extensions.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../../gallery/domain/entities/gallery_photo.dart';
import '../../../gallery/presentation/providers/gallery_providers.dart';
import '../../../gallery/presentation/widgets/dress_code_picker_sheet.dart';

class GalleryTab extends ConsumerStatefulWidget {
  const GalleryTab({super.key});

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab> {
  // null = show all; non-null = filter by dress code
  String? _filterDressCode;

  // ─── Upload ──────────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    developer.log('GalleryTab: upload tapped',
        name: 'gallery.tab', level: 800);

    // Pick image from camera
    const source = ImageSource.camera;

    // Step 2: pick image
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;

    developer.log('GalleryTab: picked path=${picked.path}',
        name: 'gallery.tab', level: 800);
    final bytes = await picked.readAsBytes();

    // Step 3: upload (untagged). Dress-code tagging is a separate
    // post-upload action from the grid long-press menu or the viewer.
    final result =
        await ref.read(galleryUploadProvider.notifier).upload(imageBytes: bytes);

    if (!mounted) return;
    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.galleryUploadFailed,
            style: AppTextStyles.body(fontSize: 13),
          ),
          backgroundColor: AppColors.charcoal3,
        ),
      );
    }
  }

  // ─── Long-press action sheet (Tag / Delete) ──────────────────────────────

  Future<void> _showActionSheet(GalleryPhoto photo) async {
    final l = context.l10n;
    final action = await showAppBottomSheet<_TileAction>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.label_outline_rounded,
                color: Colors.white),
            title: Text(
              photo.dressCode.isEmpty
                  ? 'Tag dress code'
                  : 'Change dress code (${photo.dressCode})',
              style: AppTextStyles.body(fontSize: 14),
            ),
            onTap: () => Navigator.of(ctx).pop(_TileAction.tag),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: AppColors.err),
            title: Text(l.galleryDeleteTitle.replaceAll('?', ''),
                style: AppTextStyles.body(fontSize: 14, color: AppColors.err)),
            onTap: () => Navigator.of(ctx).pop(_TileAction.delete),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case _TileAction.tag:
        await _handleTag(photo);
      case _TileAction.delete:
        await _confirmDelete(photo);
    }
  }

  // ─── Tag (post-upload) ───────────────────────────────────────────────────

  Future<void> _handleTag(GalleryPhoto photo) async {
    final picked = await showDressCodePickerSheet(
      context,
      preselected: photo.dressCode,
    );
    if (picked == null || !mounted) return;
    if (picked == photo.dressCode) return; // no-op

    developer.log(
        'GalleryTab: tag id=${photo.id} dressCode=$picked',
        name: 'gallery.tab',
        level: 800);
    final result = await ref
        .read(galleryRepositoryProvider)
        .updateMetadata(photoId: photo.id, dressCode: picked);

    if (!mounted) return;
    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update tag.',
              style: AppTextStyles.body(fontSize: 13)),
          backgroundColor: AppColors.charcoal3,
        ),
      );
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(GalleryPhoto photo) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(l.galleryDeleteTitle, style: AppTextStyles.bodyStrong()),
        content: Text(l.galleryDeleteBody,
            style: AppTextStyles.body(color: AppColors.inkMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.body(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.galleryDeleteConfirm,
                style: AppTextStyles.body(color: AppColors.err)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    developer.log('GalleryTab: delete id=${photo.id}',
        name: 'gallery.tab', level: 800);
    final result =
        await ref.read(galleryDeleteProvider.notifier).delete(photo.id);

    if (!mounted) return;
    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed. Please try again.',
              style: AppTextStyles.body(fontSize: 13)),
          backgroundColor: AppColors.charcoal3,
        ),
      );
    }
  }

  // ─── Viewer ───────────────────────────────────────────────────────────────

  void _openViewer(List<GalleryPhoto> photos, int index) {
    context.push(
      Routes.galleryViewer,
      extra: (photos: photos, initialIndex: index),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = context.branchTheme.bright;
    final asyncPhotos = ref.watch(galleryPhotosProvider);
    final uploadProgress = ref.watch(galleryUploadProvider);
    final deletingId = ref.watch(galleryDeleteProvider);

    return asyncPhotos.when(
      loading: () => _buildShimmerGrid(context, accent, uploadProgress),
      error: (e, _) => Center(
        child: Text(
          'Could not load photos.',
          style: AppTextStyles.body(color: AppColors.inkMuted),
        ),
      ),
      data: (allPhotos) {
        final photos = _filterDressCode == null
            ? allPhotos
            : allPhotos
                .where((p) => p.dressCode == _filterDressCode)
                .toList(growable: false);

        // Collect distinct dress codes present in uploaded photos
        final dressCodesInUse = {
          for (final p in allPhotos)
            if (p.dressCode.isNotEmpty) p.dressCode,
        };

        return CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: _buildHeader(context, accent, allPhotos.length,
                    isUploading: uploadProgress != null),
              ),
            ),

            // Prominent upload banner (only while uploading)
            if (uploadProgress != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                  child: _UploadBanner(
                      progress: uploadProgress, accent: accent),
                ),
              ),

            // Filter chip bar (only when there are dress-coded photos)
            if (dressCodesInUse.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildFilterBar(dressCodesInUse, accent),
              ),

            // Empty state
            if (photos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, accent,
                    isUploading: uploadProgress != null),
              )
            else
              // Photo grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _PhotoTile(
                      photo: photos[i],
                      accent: accent,
                      isDeleting: deletingId == photos[i].id,
                      onTap: () => _openViewer(photos, i),
                      onLongPress: () => _showActionSheet(photos[i]),
                    ),
                    childCount: photos.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color accent,
    int totalCount, {
    required bool isUploading,
  }) {
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.galleryEyebrow, style: AppTextStyles.eyebrow()),
              const SizedBox(height: 4),
              Text(l.galleryTitle,
                  style: AppTextStyles.title(fontSize: 24)),
              if (totalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l.galleryPhotoCount(totalCount),
                    style: AppTextStyles.body(
                        color: AppColors.inkSubtle, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        // Upload button — disables itself + shows a spinner while busy
        Opacity(
          opacity: isUploading ? 0.55 : 1,
          child: GestureDetector(
            onTap: isUploading ? null : _handleUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: accent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUploading)
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.upload_rounded,
                        color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    l.galleryUpload,
                    style: AppTextStyles.bodyStrong(
                        color: AppColors.ink, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(Set<String> dressCodes, Color accent) {
    final l = context.l10n;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
        children: [
          _FilterPill(
            label: l.galleryFilterAll,
            active: _filterDressCode == null,
            accent: accent,
            onTap: () => setState(() => _filterDressCode = null),
          ),
          ...dressCodes.map((dc) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _FilterPill(
                  label: dc,
                  active: _filterDressCode == dc,
                  accent: accent,
                  onTap: () => setState(() => _filterDressCode = dc),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color accent,
      {required bool isUploading}) {
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: isUploading
                ? Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: accent,
                      ),
                    ),
                  )
                : Icon(Icons.photo_outlined,
                    color: AppColors.inkSubtle, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            isUploading ? 'Uploading photo…' : l.galleryEmptyTitle,
            style:
                AppTextStyles.bodyStrong(color: AppColors.ink, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            isUploading
                ? 'Your first photo will appear here in a moment.'
                : l.galleryEmptyBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              color: AppColors.inkSubtle,
              fontSize: 13,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 20),
          if (!isUploading)
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: l.galleryUploadCta,
                height: 46,
                gradient: true,
                accentColor: accent,
                icon: const Icon(Icons.upload_rounded, size: 14),
                onPressed: _handleUpload,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(
      BuildContext context, Color accent, double? uploadProgress) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: _buildHeader(context, accent, 0,
                isUploading: uploadProgress != null),
          ),
        ),
        if (uploadProgress != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
              child: _UploadBanner(progress: uploadProgress, accent: accent),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const _ShimmerTile(),
              childCount: 9,
            ),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}

enum _TileAction { tag, delete }

// ─── Private widgets ──────────────────────────────────────────────────────────

class _UploadBanner extends StatelessWidget {
  const _UploadBanner({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.galleryUploadProgress(pct),
                  style: AppTextStyles.bodyStrong(
                      color: AppColors.ink, fontSize: 13),
                ),
              ),
              Text(
                '$pct%',
                style: AppTextStyles.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.accent,
    required this.isDeleting,
    required this.onTap,
    required this.onLongPress,
  });

  final GalleryPhoto photo;
  final Color accent;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'gallery_photo_${photo.id}',
            child: CachedNetworkImage(
              imageUrl: photo.thumbnailUrl.isNotEmpty
                  ? photo.thumbnailUrl
                  : photo.url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.charcoal3),
              errorWidget: (_, _, _) => Container(
                color: AppColors.charcoal3,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.inkSubtle, size: 22),
              ),
            ),
          ),
          if (isDeleting)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (photo.dressCode.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 4,
              child: AppChip(
                label: photo.dressCode,
                accent: true,
                accentColor: accent,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? accent : AppColors.lineStrong,
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.mono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.ink : AppColors.inkMuted,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.04 + _anim.value * 0.05),
              Colors.white.withValues(alpha: 0.08 + _anim.value * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
