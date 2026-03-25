import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import 'foto_model.dart';
import 'fotos_fullscreen_pager_screen.dart';
import 'fotos_fullscreen_screen.dart';
import 'fotos_provider.dart';
import 'fotos_repository.dart';

/// Cuadrícula compacta vs tarjeta ancha tipo feed.
enum FotosGalleryTileLayout { grid, feed }

/// Tile de foto con recorte, "Subido por", like count vía API y apertura a pantalla completa
class FotosImageTile extends StatefulWidget {
  final FotoModel photo;
  final String eventId;
  final FotosGalleryTileLayout layout;
  final int index;
  final List<FotoModel>? photos;

  const FotosImageTile({
    super.key,
    required this.photo,
    required this.eventId,
    this.layout = FotosGalleryTileLayout.grid,
    this.index = 0,
    this.photos,
  });

  @override
  State<FotosImageTile> createState() => _FotosImageTileState();
}

class _FotosImageTileState extends State<FotosImageTile> {
  Future<({int count, bool userLiked})?>? _likesFuture;
  Future<int>? _commentsCountFuture;
  final FotosRepository _repo = FotosRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_likesFuture == null && widget.photo.id.isNotEmpty) {
      final userId = context.read<UserContextProvider>().userId ?? '';
      _likesFuture = _repo.getPhotoLikes(widget.photo.id, userId);
    }
    if (_commentsCountFuture == null && widget.photo.id.isNotEmpty) {
      _commentsCountFuture = _repo
          .getPhotoCommentsCount(widget.photo.id)
          .then((value) => value ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final userId = userContext.userId ?? '';
    final fallbackName = userContext.isAdmin ? 'Novios' : 'Invitado';
    final userName = userContext.isAdmin
        ? 'Novios'
        : (userContext.userName ?? 'Invitado');
    final uploadedByName = widget.photo.uploadedBy == userId
        ? userName
        : (widget.photo.uploadedByName.isNotEmpty
            ? widget.photo.uploadedByName
            : fallbackName);

    final isGrid = widget.layout == FotosGalleryTileLayout.grid;

    Widget metricsPills() {
      return FutureBuilder<({int count, bool userLiked})?>(
        future: _likesFuture,
        builder: (_, likeSnap) {
          return FutureBuilder<int>(
            future: _commentsCountFuture,
            builder: (_, comSnap) {
              final likes = likeSnap.connectionState == ConnectionState.waiting
                  ? '—'
                  : '${likeSnap.data?.count ?? 0}';
              final com = comSnap.connectionState == ConnectionState.waiting
                  ? '—'
                  : '${comSnap.data ?? 0}';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _pill(Icons.favorite_border, likes),
                  const SizedBox(width: 6),
                  _pill(Icons.chat_bubble_outline, com),
                ],
              );
            },
          );
        },
      );
    }

    return GestureDetector(
      onTap: () async {
        final list = widget.photos;
        final usePager = list != null && list.length > 1;
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => usePager
                ? FotosFullscreenPagerScreen(
                    photos: list,
                    initialIndex: widget.index,
                    eventId: widget.eventId,
                  )
                : FotosFullscreenScreen(
                    photo: widget.photo,
                    eventId: widget.eventId,
                  ),
          ),
        );
        if (!mounted) return;
        if (deleted == true) {
          final viewerId = context.read<UserContextProvider>().userId ?? '';
          final includePrivate = context.read<UserContextProvider>().isAdmin;
          context.read<FotosProvider>().refresh(
                widget.eventId,
                viewerId: viewerId,
                includePrivate: includePrivate,
              );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: AppRadii.galleryTile,
            child: AspectRatio(
              aspectRatio: widget.layout == FotosGalleryTileLayout.feed ? 4 / 5 : 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.border,
                    child: Image.network(
                      widget.photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.galleryUpload,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
                  if (isGrid)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: metricsPills(),
                    ),
                  if (widget.photo.visibility.toLowerCase() == 'novios')
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.lock, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isGrid) ...[
            SizedBox(height: widget.layout == FotosGalleryTileLayout.feed ? AppSpacing.x1_5 : AppSpacing.x1),
            Text(
              'Subido por: $uploadedByName',
              style: TextStyle(
                fontSize: widget.layout == FotosGalleryTileLayout.feed ? 13 : 11,
                color: Colors.grey.shade700,
                fontWeight: widget.layout == FotosGalleryTileLayout.feed ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: widget.layout == FotosGalleryTileLayout.feed ? 18 : 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                FutureBuilder<({int count, bool userLiked})?>(
                  future: _likesFuture,
                  builder: (_, snap) {
                    final text = snap.connectionState == ConnectionState.waiting
                        ? '—'
                        : '${snap.data?.count ?? 0}';
                    return Text(
                      text,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: widget.layout == FotosGalleryTileLayout.feed ? 14 : 12,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.x1_5),
                Icon(
                  Icons.chat_bubble_outline,
                  size: widget.layout == FotosGalleryTileLayout.feed ? 18 : 14,
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                FutureBuilder<int>(
                  future: _commentsCountFuture,
                  builder: (_, snap) {
                    final text = snap.connectionState == ConnectionState.waiting
                        ? '—'
                        : '${snap.data ?? 0}';
                    return Text(
                      text,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: widget.layout == FotosGalleryTileLayout.feed ? 14 : 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
