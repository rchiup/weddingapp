import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import 'foto_model.dart';
import 'fotos_fullscreen_screen.dart';
import 'fotos_provider.dart';
import 'fotos_repository.dart';

/// Tile de foto con recorte, "Subido por", like count vía API y apertura a pantalla completa
class FotosImageTile extends StatefulWidget {
  final FotoModel photo;
  final String eventId;

  const FotosImageTile({super.key, required this.photo, required this.eventId});

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
    final userName = userContext.userName ?? 'Invitado';
    final uploadedByName = widget.photo.uploadedBy == userId
        ? (userName != 'Invitado' ? userName : 'Tú')
        : (widget.photo.uploadedByName.isNotEmpty
            ? widget.photo.uploadedByName
            : 'Invitado');

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
                aspectRatio: 1,
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
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Subido por: $uploadedByName',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 14, color: AppColors.textPrimary.withOpacity(0.45)),
              const SizedBox(width: 4),
              FutureBuilder<({int count, bool userLiked})?>(
                future: _likesFuture,
                builder: (_, snap) {
                  final text = snap.connectionState == ConnectionState.waiting
                      ? '—'
                      : '${snap.data?.count ?? 0}';
                  return Text(text, style: AppTextStyles.subtitle.copyWith(fontSize: 12));
                },
              ),
              const SizedBox(width: AppSpacing.x1_5),
              Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textPrimary.withOpacity(0.45)),
              const SizedBox(width: 4),
              FutureBuilder<int>(
                future: _commentsCountFuture,
                builder: (_, snap) {
                  final text = snap.connectionState == ConnectionState.waiting
                      ? '—'
                      : '${snap.data ?? 0}';
                  return Text(text, style: AppTextStyles.subtitle.copyWith(fontSize: 12));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
