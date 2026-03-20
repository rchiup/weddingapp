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
  /// Evita que el pan horizontal del zoom compita con el gesto “volver” del sistema
  /// (iOS edge-swipe / Android predictive back): solo permitir arrastre si ya hay zoom.
  final TransformationController _imageViewerController = TransformationController();
  bool _imageViewerPanEnabled = false;
  int? _initialLikeCount;
  bool? _initialIsLiked;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = false;
  bool _showDoubleTapHeart = false;

  void _onImageViewerTransform() {
    final scale = _imageViewerController.value.getMaxScaleOnAxis();
    final wantPan = scale > 1.02;
    if (wantPan != _imageViewerPanEnabled && mounted) {
      setState(() => _imageViewerPanEnabled = wantPan);
    }
  }

  @override
  void initState() {
    super.initState();
    _imageViewerController.addListener(_onImageViewerTransform);
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
    /// En desktop: la imagen llena el marco (sin franjas gigantes arriba/abajo).
    bool fillCover = false,
  }) {
    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final effectiveH = maxHeight ?? boxConstraints.maxHeight;
        if (!effectiveH.isFinite || effectiveH <= 0) {
          return const SizedBox.shrink();
        }
        final h = effectiveH;
        final imageFit = fillCover ? BoxFit.cover : BoxFit.contain;
        final imageCard = Container(
          width: double.infinity,
          height: h,
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
              fit: imageFit,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
        );

        return InteractiveViewer(
          transformationController: _imageViewerController,
          // En desktop (fillCover) anclamos arriba para que el marco blanco coincida
          // con el inicio del panel de comentarios; el default (centro) puede dejar
          // la tarjeta “bajada” vs. la columna derecha en algunos navegadores.
          alignment: fillCover ? Alignment.topCenter : null,
          panEnabled: _imageViewerPanEnabled,
          minScale: 1,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(80),
          clipBehavior: Clip.hardEdge,
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
      },
    );
  }

  Widget _buildSocialCard({
    required String uploadedByName,
    required String userId,
    required String userName,
    /// Tarjeta más baja en móvil: prioriza la foto; comentarios van abajo con scroll.
    bool compact = false,
  }) {
    if (compact) {
      return CustomCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x1_5,
          vertical: AppSpacing.x1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Subido por: $uploadedByName',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () async => _toggleLike(userId: userId, userName: userName),
                  icon: Icon(
                    (_initialIsLiked ?? false) ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: (_initialIsLiked ?? false) ? Colors.red : AppColors.textPrimary.withOpacity(0.7),
                  ),
                  tooltip: (_initialIsLiked ?? false) ? 'Quitar like' : 'Me gusta',
                ),
                Text(
                  _initialLikeCount == null ? '—' : '$_initialLikeCount',
                  style: AppTextStyles.title.copyWith(fontSize: 14),
                ),
                Text(' likes', style: AppTextStyles.subtitle.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(userId: userId, userName: userName),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () async => _submitComment(userId: userId, userName: userName),
                  icon: const Icon(Icons.send, size: 22),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      );
    }

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

  /// Una sola tarjeta de comentario (reutilizado en lista móvil, desktop y scroll móvil).
  Widget _commentCard(Map<String, dynamic> c, String fallbackName) {
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
    return CustomCard(
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
    );
  }

  /// Móvil: likes + input + comentarios en un scroll; la foto ocupa el Expanded de arriba.
  Widget _buildMobileScrollSection({
    required String uploadedByName,
    required String userId,
    required String userName,
    required String fallbackName,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 0, AppSpacing.x2, AppSpacing.x1),
            child: _buildSocialCard(
              uploadedByName: uploadedByName,
              userId: userId,
              userName: userName,
              compact: true,
            ),
          ),
        ),
        if (_loadingComments)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.x3),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_comments.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
              child: Text('Sin comentarios', style: AppTextStyles.subtitle),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 0, AppSpacing.x2, AppSpacing.x2),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = _comments[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _comments.length - 1 ? 0 : AppSpacing.x1_5,
                    ),
                    child: _commentCard(c, fallbackName),
                  );
                },
                childCount: _comments.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Panel derecho en desktop: un solo scroll (metadatos + input + comentarios)
  /// para no dejar un bloque vacío enorme debajo de pocos comentarios.
  Widget _buildWideSidePanel({
    required String uploadedByName,
    required String userId,
    required String userName,
    required String fallbackName,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: AppSpacing.x2),
            child: _buildSocialCard(
              uploadedByName: uploadedByName,
              userId: userId,
              userName: userName,
            ),
          ),
        ),
        if (_loadingComments)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
              child: Text('Sin comentarios', style: AppTextStyles.subtitle),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.x2,
                      0,
                      AppSpacing.x2,
                      i == _comments.length - 1 ? AppSpacing.x2 : AppSpacing.x1_5,
                    ),
                    child: _commentCard(_comments[i], fallbackName),
                  );
                },
                childCount: _comments.length,
              ),
            ),
          ),
      ],
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
    _imageViewerController.removeListener(_onImageViewerTransform);
    _imageViewerController.dispose();
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
    final isWide = screenWidth >= 760;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Altura útil debajo del AppBar (el body ya está debajo; LayoutBuilder
                  // usa el alto disponible del body).
                  final innerHeight = constraints.maxHeight;
                  // crossAxisAlignment.start + misma altura explícita: el panel de
                  // comentarios arranca al mismo nivel que el marco de la foto (no más arriba).
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: SizedBox(
                          height: innerHeight,
                          width: double.infinity,
                          child: _buildPhotoViewer(
                            userId: userId,
                            userName: userName,
                            maxHeight: innerHeight,
                            fillCover: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: innerHeight,
                          width: double.infinity,
                          child: _buildWideSidePanel(
                            uploadedByName: uploadedByName,
                            userId: userId,
                            userName: userName,
                            fallbackName: fallbackName,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            )
          : Column(
              children: [
                // ~76% del cuerpo: foto llena el Expanded (sin tope 62% de pantalla).
                Expanded(
                  flex: 16,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x2,
                      AppSpacing.x2,
                      AppSpacing.x2,
                      AppSpacing.x1,
                    ),
                    child: _buildPhotoViewer(
                      userId: userId,
                      userName: userName,
                      maxHeight: null,
                      fillCover: true,
                    ),
                  ),
                ),
                // ~24%: tarjeta compacta + comentarios (scroll para ver todo).
                Expanded(
                  flex: 5,
                  child: _buildMobileScrollSection(
                    uploadedByName: uploadedByName,
                    userId: userId,
                    userName: userName,
                    fallbackName: fallbackName,
                  ),
                ),
              ],
            ),
    );
  }
}
