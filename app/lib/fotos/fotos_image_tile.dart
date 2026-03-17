import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'foto_model.dart';
import 'fotos_fullscreen_screen.dart';
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
        : 'Invitado';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FotosFullscreenScreen(
              photo: widget.photo,
              eventId: widget.eventId,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
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
            ),
          ),
          const SizedBox(height: 4),
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
              const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
              const SizedBox(width: 2),
              FutureBuilder<({int count, bool userLiked})?>(
                future: _likesFuture,
                builder: (_, snap) {
                  final text = snap.connectionState == ConnectionState.waiting
                      ? '—'
                      : '${snap.data?.count ?? 0}';
                  return Text(text, style: const TextStyle(fontSize: 12));
                },
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chat_bubble_outline,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 2),
              FutureBuilder<int>(
                future: _commentsCountFuture,
                builder: (_, snap) {
                  final text = snap.connectionState == ConnectionState.waiting
                      ? '—'
                      : '${snap.data ?? 0}';
                  return Text(text, style: const TextStyle(fontSize: 12));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
