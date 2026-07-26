import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_text_styles.dart';
import '../../../../core/design/widgets/app_chip.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/branch_theme_extension.dart';
import '../../domain/entities/gallery_photo.dart';
import '../providers/gallery_providers.dart';
import '../widgets/dress_code_picker_sheet.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  final List<GalleryPhoto> photos;
  final int initialIndex;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  // Mutable copy so tag updates reflect immediately in the viewer.
  // Firestore is the source of truth — the grid will pick up the same
  // change via its real-time stream.
  late List<GalleryPhoto> _photos;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _photos = List<GalleryPhoto>.of(widget.photos);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GalleryPhoto get _currentPhoto => _photos[_currentIndex];

  Future<void> _handleShare() async {
    developer.log('PhotoViewer: share id=${_currentPhoto.id}',
        name: 'gallery.viewer', level: 800);
    try {
      await SharePlus.instance.share(
        ShareParams(
          uri: Uri.parse(_currentPhoto.url),
          subject: 'SAF Uniform Photo',
        ),
      );
    } catch (e, st) {
      developer.log('PhotoViewer: share failed',
          name: 'gallery.viewer', error: e, stackTrace: st, level: 1000);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not share this photo.',
              style: AppTextStyles.body(fontSize: 13),
            ),
            backgroundColor: AppColors.charcoal3,
          ),
        );
      }
    }
  }

  Future<void> _handleTag() async {
    final photo = _currentPhoto;
    final picked = await showDressCodePickerSheet(
      context,
      preselected: photo.dressCode,
    );
    if (picked == null || !mounted) return;
    if (picked == photo.dressCode) return; // no change

    developer.log('PhotoViewer: tag id=${photo.id} dressCode=$picked',
        name: 'gallery.viewer', level: 800);
    final result = await ref
        .read(galleryRepositoryProvider)
        .updateMetadata(photoId: photo.id, dressCode: picked);

    if (!mounted) return;
    if (result is Ok) {
      setState(() {
        _photos[_currentIndex] = photo.copyWith(dressCode: picked);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update tag.',
              style: AppTextStyles.body(fontSize: 13)),
          backgroundColor: AppColors.charcoal3,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoal2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text('Delete photo?', style: AppTextStyles.bodyStrong()),
        content: Text(
          'This cannot be undone.',
          style: AppTextStyles.body(color: AppColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.body(color: AppColors.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppTextStyles.body(color: AppColors.err)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    developer.log('PhotoViewer: delete id=${_currentPhoto.id}',
        name: 'gallery.viewer', level: 800);
    final result = await ref
        .read(galleryDeleteProvider.notifier)
        .delete(_currentPhoto.id);

    if (!mounted) return;
    if (result is Ok) {
      GoRouter.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed. Please try again.',
              style: AppTextStyles.body(fontSize: 13)),
          backgroundColor: AppColors.charcoal3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.branchTheme.bright;
    final isDeleting =
        ref.watch(galleryDeleteProvider) == _currentPhoto.id;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.55),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currentIndex + 1} / ${_photos.length}',
              style: AppTextStyles.bodyStrong(fontSize: 14),
            ),
            if (_currentPhoto.dressCode.isNotEmpty)
              Text(
                _currentPhoto.dressCode,
                style: AppTextStyles.body(
                    color: AppColors.inkMuted, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentPhoto.dressCode.isEmpty
                  ? Icons.label_outline_rounded
                  : Icons.label_rounded,
              color: _currentPhoto.dressCode.isEmpty
                  ? Colors.white
                  : accent,
              size: 22,
            ),
            tooltip: 'Tag dress code',
            onPressed: _handleTag,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined,
                color: Colors.white, size: 22),
            tooltip: 'Share',
            onPressed: _handleShare,
          ),
          if (isDeleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppColors.err, size: 22),
              tooltip: 'Delete',
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: _photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        builder: (ctx, i) {
          final photo = _photos[i];
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(photo.url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'gallery_photo_${photo.id}',
            ),
          );
        },
        loadingBuilder: (_, _) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
      bottomNavigationBar: _currentPhoto.dressCode.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(18, 10, 18,
                  MediaQuery.of(context).padding.bottom + 10),
              color: Colors.black.withValues(alpha: 0.55),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_outline_rounded, color: accent, size: 14),
                  const SizedBox(width: 6),
                  AppChip(
                    label: _currentPhoto.dressCode,
                    accent: true,
                    accentColor: accent,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
