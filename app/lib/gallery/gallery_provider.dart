import 'package:flutter/foundation.dart';

import '../models/gallery_model.dart';
import '../services/gallery_service.dart';

/// Provider para gestión de estado de galería
/// 
/// Maneja la carga y visualización de fotos del evento
/// en tiempo real. Incluye subida de fotos y feed de galería.
class GalleryProvider extends ChangeNotifier {
  final GalleryService _galleryService = GalleryService();
  
  List<GalleryModel> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;

  List<GalleryModel> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  /// Carga las fotos del evento
  Future<void> loadPhotos(String eventId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar fotos desde GalleryService
      // TODO: Escuchar nuevas fotos en tiempo real
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  /// Sube una foto al evento
  Future<bool> uploadPhoto(String eventId, String imagePath) async {
    _setUploading(true);
    
    try {
      // TODO: Subir foto con GalleryService
      _setUploading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setUploading(false);
      return false;
    }
  }

  /// Elimina una foto
  Future<void> deletePhoto(String photoId) async {
    try {
      // TODO: Eliminar foto con GalleryService
      notifyListeners();
    } catch (e) {
      // TODO: Manejar error
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }
}
