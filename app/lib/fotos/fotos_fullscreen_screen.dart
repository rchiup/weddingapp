import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import 'foto_model.dart';
import 'fotos_download.dart';
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

  Future<void> _downloadCurrentPhoto() async {
    final url = widget.photo.url.trim();
    if (url.isEmpty) return;
    final safeId = widget.photo.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : widget.photo.id;
    try {
      await downloadPhoto(url, suggestedFilename: 'foto_$safeId.jpg');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga iniciada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar: $e')),
      );
    }
  }

  Widget _buildPhotoViewer({
    required String userId,
    required String userName,
    double? maxHeight,
  }) {
    final constraints = maxHeight == null
        ? const BoxConstraints(minHeight: 260)
        : BoxConstraints(minHeight: 260, maxHeight: maxHeight);
    final imageCard = Container(
      width: double.infinity,
      constraints: constraints,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.card,
        child: Image.network(
          widget.photo.url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      ),
    );

    return InteractiveViewer(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () async {
          await _playHeartPop();
          await _toggleLike(userId: userId, userName: userName);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            imageCard,
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
    );
  }

  Widget _buildSocialCard({
    required String uploadedByName,
    required String userId,
    required String userName,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Subido por: $uploadedByName', style: AppTextStyles.subtitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.x1),
          Row(
            children: [
              IconButton(
                onPressed: () async => _toggleLike(userId: userId, userName: userName),
                icon: Icon(
                  (_initialIsLiked ?? false) ? Icons.favorite : Icons.favorite_border,
                  color: (_initialIsLiked ?? false) ? Colors.red : AppColors.textPrimary.withOpacity(0.7),
                ),
                tooltip: (_initialIsLiked ?? false) ? 'Quitar like' : 'Me gusta',
              ),
              Text(
                _initialLikeCount == null ? '—' : '$_initialLikeCount',
                style: AppTextStyles.title.copyWith(fontSize: 16),
              ),
              const SizedBox(width: AppSpacing.x1),
              Text('likes', style: AppTextStyles.subtitle),
              const SizedBox(width: AppSpacing.x1),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Descargar',
                  onPressed: _downloadCurrentPhoto,
                  icon: const Icon(
                    Icons.arrow_downward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Divider(color: AppColors.border.withOpacity(0.8)),
          const SizedBox(height: AppSpacing.x1),
          Text('Comentarios', style: AppTextStyles.title.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.x1),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario...',
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(userId: userId, userName: userName),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              IconButton(
                onPressed: () async => _submitComment(userId: userId, userName: userName),
                icon: const Icon(Icons.send),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(String fallbackName) {
    if (_loadingComments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return Center(child: Text('Sin comentarios', style: AppTextStyles.subtitle));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
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
        final commentName = (c['name'] ?? '').toString().trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x1_5),
          child: CustomCard(
            padding: const EdgeInsets.all(AppSpacing.x1_5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${commentName.isNotEmpty ? commentName : fallbackName} · $dateStr',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text('${c['message'] ?? ''}'),
              ],
            ),
          ),
        );
      },
    );
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
    final fallbackName = userContext.isAdmin ? 'Novios' : 'Invitado';
    final userName = userContext.isAdmin
        ? 'Novios'
        : (userContext.userName ?? 'Invitado');
    final uploadedByName = widget.photo.uploadedBy == userId
        ? userName
        : (widget.photo.uploadedByName.isNotEmpty
            ? widget.photo.uploadedByName
            : fallbackName);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth >= 760;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto'),
        actions: [
          IconButton(
            tooltip: 'Descargar',
            icon: const Icon(Icons.download_outlined),
            onPressed: _downloadCurrentPhoto,
          ),
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
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'Cancelar',
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1_5),
                          Expanded(
                            child: CustomButton(
                              label: 'Eliminar',
                              icon: Icons.delete_outline,
                              onPressed: () => Navigator.of(ctx).pop(true),
                            ),
                          ),
                        ],
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
      body: isWide
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildPhotoViewer(
                      userId: userId,
                      userName: userName,
                      maxHeight: screenHeight - 140,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildSocialCard(
                          uploadedByName: uploadedByName,
                          userId: userId,
                          userName: userName,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Expanded(child: _buildCommentsList(fallbackName)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.x2, AppSpacing.x2, AppSpacing.x2, AppSpacing.x1),
                    child: _buildPhotoViewer(
                      userId: userId,
                      userName: userName,
                      maxHeight: screenHeight * 0.56,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 0, AppSpacing.x2, AppSpacing.x2),
                  child: _buildSocialCard(
                    uploadedByName: uploadedByName,
                    userId: userId,
                    userName: userName,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _buildCommentsList(fallbackName),
                ),
              ],
            ),
    );
  }
}
