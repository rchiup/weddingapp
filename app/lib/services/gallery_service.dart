/// Servicio de galería
/// 
/// Maneja la subida de fotos a Firebase Storage y
/// la gestión de metadatos en Firestore. Incluye
/// operaciones en tiempo real para el feed de fotos.
class GalleryService {
  /// Sube una foto al evento
  Future<String> uploadPhoto(String eventId, String userId, String imagePath) async {
    try {
      // TODO: Implementar lógica cuando se integre Firebase
      return '';
    } catch (e) {
      throw Exception('Error subiendo foto: $e');
    }
  }

  /// Obtiene las fotos del evento (stream en tiempo real)
  Stream<List<Map<String, dynamic>>> getPhotosStream(String eventId) {
    try {
      // TODO: Implementar lógica cuando se integre Firebase
      return const Stream.empty();
    } catch (e) {
      throw Exception('Error obteniendo fotos: $e');
    }
  }

  /// Elimina una foto
  Future<void> deletePhoto(String photoId, String imageUrl) async {
    try {
      // TODO: Implementar lógica cuando se integre Firebase
    } catch (e) {
      throw Exception('Error eliminando foto: $e');
    }
  }

  /// Obtiene las fotos de un evento (una vez)
  Future<List<Map<String, dynamic>>> getPhotos(String eventId) async {
    try {
      // TODO: Implementar lógica cuando se integre Firebase
      return [];
    } catch (e) {
      throw Exception('Error obteniendo fotos: $e');
    }
  }
}
