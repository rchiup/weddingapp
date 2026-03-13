import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'foto_model.dart';
import 'fotos_fullscreen_screen.dart';
import 'fotos_social_service.dart';

/// Tile de foto con recorte, "Subido por", likes/comentarios y apertura a pantalla completa
class FotosImageTile extends StatelessWidget {
  final FotoModel photo;
  final String eventId;

  const FotosImageTile({super.key, required this.photo, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final userId = userContext.userId ?? '';
    final userName = userContext.userName ?? 'Invitado';
    final uploadedByName = photo.uploadedBy == userId
        ? (userName != 'Invitado' ? userName : 'Tú')
        : 'Invitado';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FotosFullscreenScreen(
              photo: photo,
              eventId: eventId,
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
                photo.url,
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
              StreamBuilder<int>(
                stream: FotosSocialService().watchLikeCount(eventId, photo.id),
                builder: (_, snap) => Text(
                  '${snap.data ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
