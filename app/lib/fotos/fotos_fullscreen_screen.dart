import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'foto_model.dart';
import 'fotos_repository.dart';
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
  final FotosRepository _fotosRepository = FotosRepository();
  final TextEditingController _commentController = TextEditingController();
  int? _initialLikeCount;
  bool? _initialIsLiked;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  bool _showDoubleTapHeart = false;

  @override
  void initState() {
    super.initState();
    _loadInitialLikes();
    _loadComments();
  }

  /// Carga likes desde la API (backend lee gallery/{photoId}/likes). Sin Firestore.
  Future<void> _loadInitialLikes() async {
    final photoId = widget.photo.id;
    if (photoId.isEmpty) return;
    final userId = context.read<UserContextProvider>().userId ?? '';
    if (!mounted) return;
    final result = await _fotosRepository.getPhotoLikes(photoId, userId);
    if (result != null && mounted) {
      setState(() {
        _initialLikeCount = result.count;
        _initialIsLiked = result.userLiked;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    final items = await _fotosRepository.getPhotoComments(widget.photo.id);
    if (mounted) {
      setState(() {
        _comments = items;
        _loadingComments = false;
      });
    }
  }

  Future<void> _submitComment({
    required String userId,
    required String userName,
  }) async {
    final msg = _commentController.text.trim();
    if (msg.isEmpty) return;
    if (userId.isEmpty || widget.photo.id.isEmpty) return;

    await _fotosRepository.addPhotoComment(
      photoId: widget.photo.id,
      userId: userId,
      name: userName,
      message: msg,
    );
    _commentController.clear();
    if (!mounted) return;
    setState(() {
      _comments.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'name': userName,
        'message': msg,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> _toggleLike({
    required String userId,
    required String userName,
  }) async {
    if (widget.photo.id.isEmpty || userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo dar like.'),
          ),
        );
      }
      return;
    }
    // Optimista: actualiza UI al instante, luego sincroniza con API
    final wasLiked = _initialIsLiked ?? false;
    final wasCount = _initialLikeCount;
    setState(() {
      _initialIsLiked = !wasLiked;
      _initialLikeCount = (wasCount ?? 0) + (wasLiked ? -1 : 1);
    });

    final result =
        await _fotosRepository.togglePhotoLike(widget.photo.id, userId, userName);
    if (result != null && mounted) {
      setState(() {
        _initialLikeCount = result.count;
        _initialIsLiked = result.liked;
      });
      return;
    }

    // Si falló la API, revertimos
    if (mounted) {
      setState(() {
        _initialIsLiked = wasLiked;
        _initialLikeCount = wasCount;
      });
    }
  }

  Future<void> _playHeartPop() async {
    if (!mounted) return;
    setState(() => _showDoubleTapHeart = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() => _showDoubleTapHeart = false);
  }

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
        : (widget.photo.uploadedByName.isNotEmpty
            ? widget.photo.uploadedByName
            : 'Invitado');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto'),
        actions: [
          if (userContext.isAdmin)
            IconButton(
              tooltip: 'Eliminar foto',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar foto'),
                    content: const Text('¿Seguro que quieres borrar esta foto?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
                try {
                  await _fotosRepository.deletePhoto(widget.photo.id);
                  if (!mounted) return;
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto eliminada')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo eliminar: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: () async {
                    // animación tipo IG + toggle like
                    await _playHeartPop();
                    await _toggleLike(userId: userId, userName: userName);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        widget.photo.url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 48),
                        ),
                      ),
                      IgnorePointer(
                        child: AnimatedScale(
                          scale: _showDoubleTapHeart ? 1.0 : 0.6,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _showDoubleTapHeart ? 0.9 : 0.0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 120,
                              shadows: [
                                Shadow(
                                  blurRadius: 12,
                                  color: Colors.black38,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
                      IconButton(
                        onPressed: () async {
                          await _toggleLike(userId: userId, userName: userName);
                        },
                        icon: Icon(
                          (_initialIsLiked ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: (_initialIsLiked ?? false) ? Colors.red : null,
                        ),
                        tooltip: (_initialIsLiked ?? false)
                            ? 'Quitar like'
                            : 'Me gusta',
                      ),
                      Text(_initialLikeCount == null ? '—' : '$_initialLikeCount'),
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
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) =>
                              _submitComment(userId: userId, userName: userName),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          await _submitComment(
                            userId: userId,
                            userName: userName,
                          );
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loadingComments
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin comentarios',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final ts = c['timestamp'];
                          DateTime? dt;
                          if (ts is String) {
                            dt = DateTime.tryParse(ts);
                          } else if (ts is Timestamp) {
                            dt = ts.toDate();
                          }
                          final dateStr = dt != null
                              ? '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}'
                              : '';
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                      ),
          ),
        ],
      ),
    );
  }
}
