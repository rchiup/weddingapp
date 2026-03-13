import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'foto_model.dart';
import 'fotos_social_service.dart';

/// Vista de foto en grande con likes y comentarios
class FotosFullscreenScreen extends StatefulWidget {
  final FotoModel photo;
  final String eventId;

  const FotosFullscreenScreen({super.key, required this.photo, required this.eventId});

  @override
  State<FotosFullscreenScreen> createState() => _FotosFullscreenScreenState();
}

class _FotosFullscreenScreenState extends State<FotosFullscreenScreen> {
  final FotosSocialService _socialService = FotosSocialService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final userId = userContext.userId ?? '';
    final userName = userContext.userName ?? 'Invitado';
    final uploadedByName = widget.photo.uploadedBy == userId
        ? (userName != 'Invitado' ? userName : 'Tú')
        : 'Invitado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.photo.url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Subido por: $uploadedByName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StreamBuilder<int>(
                        stream: _socialService.watchLikeCount(widget.eventId, widget.photo.id),
                        builder: (_, countSnap) {
                          final count = countSnap.data ?? 0;
                          return FutureBuilder<bool>(
                            future: _socialService.isLikedBy(
                              widget.eventId,
                              widget.photo.id,
                              userId,
                            ),
                            builder: (_, likeSnap) {
                              final isLiked = likeSnap.data ?? false;
                              return IconButton(
                                onPressed: () async {
                                  await _socialService.toggleLike(
                                    eventId: widget.eventId,
                                    photoId: widget.photo.id,
                                    userId: userId,
                                    name: userName,
                                  );
                                  if (mounted) setState(() {});
                                },
                                icon: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                ),
                                label: Text('$count'),
                              );
                            },
                          );
                        },
                      ),
                      const Text(' likes'),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    '💬 Comentarios',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final msg = _commentController.text.trim();
                          if (msg.isEmpty) return;
                          await _socialService.addComment(
                            eventId: widget.eventId,
                            photoId: widget.photo.id,
                            name: userName,
                            message: msg,
                          );
                          _commentController.clear();
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _socialService.watchComments(
                widget.eventId,
                widget.photo.id,
              ),
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin comentarios',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final ts = c['timestamp'];
                    DateTime? dt;
                    if (ts != null) {
                      if (ts is Timestamp) dt = ts.toDate();
                      else if (ts is DateTime) dt = ts;
                    }
                    final dateStr = dt != null
                        ? '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                        : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c['name'] ?? 'Invitado'} · $dateStr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text('${c['message'] ?? ''}'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
