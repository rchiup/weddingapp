import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import 'foto_model.dart';
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

  const FotosImageTile({
    super.key,
    required this.photo,
    required this.eventId,
    this.layout = FotosGalleryTileLayout.grid,
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

    return GestureDetector(
      onTap: () async {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => FotosFullscreenScreen(
              photo: widget.photo,
              eventId: widget.eventId,
            ),
          ),
        );
        if (!mounted) return;
        if (deleted == true) {
          // Recargar el grid para que desaparezca al instante.
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.card,
              boxShadow: AppShadows.soft,
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: AppRadii.card,
              child: AspectRatio(
                aspectRatio: widget.layout == FotosGalleryTileLayout.feed ? 4 / 5 : 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                    if (widget.photo.visibility.toLowerCase() == 'novios')
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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
                color: AppColors.textPrimary.withOpacity(0.45),
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
                color: AppColors.textPrimary.withOpacity(0.45),
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
      ),
    );
  }
}
