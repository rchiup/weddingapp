import 'dart:ui' show ImageFilter;

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
  bool _hover = false;

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

    final tile = GestureDetector(
      onTap: () async {
        if (widget.photo.isVideo) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vista previa de video próximamente.')),
          );
          return;
        }
        final list = widget.photos;
        final usePager = list != null && list.length > 1;
        final uc = context.read<UserContextProvider>();
        final viewerId = uc.userId ?? '';
        final includePrivate = uc.isAdmin;
        final provider = context.read<FotosProvider>();
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
          provider.refresh(
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
          AnimatedScale(
            scale: _hover ? (isGrid ? 1.03 : 1.02) : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: AppRadii.galleryTile,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _hover ? 0.14 : 0.10),
                    blurRadius: _hover ? (isGrid ? 22 : 18) : 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadii.galleryTile,
                child: AspectRatio(
                  aspectRatio: widget.layout == FotosGalleryTileLayout.feed ? 4 / 5 : 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: AppColors.border,
                        child: widget.photo.isVideo
                            ? _videoPlaceholder()
                            : Image.network(
                                widget.photo.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                                frameBuilder: (context, child, frame, wasSync) {
                                  if (wasSync) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: child,
                                  );
                                },
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const SizedBox.expand();
                                },
                              ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isGrid)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: metricsPills(),
                        ),
                      if (widget.photo.visibility.toLowerCase() == 'novios')
                        Positioned(
                          top: 12,
                          right: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.photo.isVideo)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _pill(Icons.videocam_outlined, 'Video'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isGrid) ...[
            SizedBox(height: widget.layout == FotosGalleryTileLayout.feed ? AppSpacing.x1_5 : AppSpacing.x1),
            Text(
              'Subido por: $uploadedByName',
              style: TextStyle(
                fontSize: widget.layout == FotosGalleryTileLayout.feed ? 13 : 11,
                color: AppColors.textMuted,
                fontWeight: widget.layout == FotosGalleryTileLayout.feed ? FontWeight.w600 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            FutureBuilder<({int count, bool userLiked})?>(
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
                      children: [
                        _pill(Icons.favorite_border, likes),
                        const SizedBox(width: 8),
                        _pill(Icons.chat_bubble_outline, com),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: tile,
    );
  }

  Widget _pill(IconData icon, String value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFF1F232A),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 44,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(height: 8),
          Text(
            'Video',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
