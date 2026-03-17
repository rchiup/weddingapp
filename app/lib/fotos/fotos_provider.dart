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

  List<FotoModel> get photos => _photos.take(_visibleCount).toList();
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;

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
