import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'foto_model.dart';
import 'fotos_repository.dart';

/// Provider del flujo de fotos
///
/// Maneja feed persistente y subida a Storage/Firestore.
class FotosProvider extends ChangeNotifier {
  final FotosRepository _repository = FotosRepository();

  static const int _pageSize = 12;

  final List<FotoModel> _photos = [];
  int _visibleCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  /// `true` = cuadrícula, `false` = feed vertical estilo Instagram.
  bool _galleryGridMode = true;

  String? _uploaderFilterUserId;

  String? get uploaderFilterUserId => _uploaderFilterUserId;

  List<FotoModel> _filteredAll() {
    final filterId = _uploaderFilterUserId;
    if (filterId == null || filterId.isEmpty) return _photos;
    return _photos.where((p) => p.uploadedBy == filterId).toList();
  }

  /// Fotos visibles en la UI. Si hay filtro “Subido por”, se muestran todas las coincidencias.
  List<FotoModel> get photos {
    final filtered = _filteredAll();
    if (_uploaderFilterUserId != null && _uploaderFilterUserId!.isNotEmpty) {
      return filtered;
    }
    return filtered.take(_visibleCount).toList();
  }
  /// Total de fotos (respetando filtro si aplica) para subtítulo del AppBar.
  int get photoCount => _filteredAll().length;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore {
    final filtering = _uploaderFilterUserId != null && _uploaderFilterUserId!.isNotEmpty;
    return filtering ? false : _hasMore;
  }
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;
  bool get galleryGridMode => _galleryGridMode;

  /// Opciones para el filtro “Subido por”.
  /// Devuelve (userId, displayName, count) ordenado por nombre.
  List<({String userId, String name, int count})> get uploaderOptions {
    final map = <String, ({String name, int count})>{};
    for (final p in _photos) {
      final id = p.uploadedBy.trim();
      if (id.isEmpty) continue;
      final name = p.uploadedByName.trim().isEmpty ? 'Invitado' : p.uploadedByName.trim();
      final prev = map[id];
      map[id] = (name: prev == null ? name : prev.name, count: (prev?.count ?? 0) + 1);
    }
    final list = map.entries
        .map((e) => (userId: e.key, name: e.value.name, count: e.value.count))
        .toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void setUploaderFilter(String? userId) {
    final next = userId?.trim();
    _uploaderFilterUserId = (next == null || next.isEmpty) ? null : next;
    notifyListeners();
  }

  void clearUploaderFilter() {
    if (_uploaderFilterUserId == null) return;
    _uploaderFilterUserId = null;
    notifyListeners();
  }

  void toggleGalleryLayout() {
    _galleryGridMode = !_galleryGridMode;
    notifyListeners();
  }

  Future<void> loadInitial(
    String eventId, {
    required String viewerId,
    required bool includePrivate,
  }) async {
    if (eventId.isEmpty) {
      _errorMessage = 'Debes unirte a un evento primero';
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final items = await _repository.fetchPhotos(
        eventId,
        viewerId: viewerId,
        includePrivate: includePrivate,
      );
      _photos
        ..clear()
        ..addAll(items);
      _visibleCount = items.length >= _pageSize ? _pageSize : items.length;
      _hasMore = _visibleCount < _photos.length;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FotoModel>> fetchNow(
    String eventId, {
    required String viewerId,
    required bool includePrivate,
  }) async {
    return _repository.fetchPhotos(
      eventId,
      viewerId: viewerId,
      includePrivate: includePrivate,
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 250));
      final nextCount = _visibleCount + _pageSize;
      _visibleCount = nextCount > _photos.length ? _photos.length : nextCount;
    _hasMore = _visibleCount < _photos.length;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refresh(
    String eventId, {
    required String viewerId,
    required bool includePrivate,
  }) async {
    await loadInitial(eventId, viewerId: viewerId, includePrivate: includePrivate);
  }

  Future<void> uploadPhotos({
    required String eventId,
    required String userId,
    required String userName,
    required String visibility,
    required List<XFile> files,
  }) async {
    if (eventId.isEmpty || userId.isEmpty) {
      _errorMessage = 'Debes unirte a un evento primero';
      notifyListeners();
      return;
    }
    _setUploading(true);
    _errorMessage = null;
    try {
      for (final file in files) {
        await _repository.uploadPhoto(
          eventId: eventId,
          userId: userId,
          userName: userName,
          visibility: visibility,
          file: file,
          onProgress: (progress) {
            _uploadProgress = progress;
            notifyListeners();
          },
        );
      }
      // refrescar feed (público por defecto); el feed real se recarga al volver
      await loadInitial(eventId, viewerId: userId, includePrivate: false);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setUploading(false);
    }
  }

  void _setUploading(bool value) {
    _isUploading = value;
    if (!value) _uploadProgress = 0;
    notifyListeners();
  }
}
