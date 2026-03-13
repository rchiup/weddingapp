/// Servicio del flujo de fotos
///
/// Encapsula operaciones de galería y subida.
/// No debe depender del módulo de solteros.
class FotosService {
  /// Obtiene fotos del evento (mock)
  Future<List<String>> getPhotos(String eventId) async {
    // TODO: Implementar cuando se integre Firebase Storage
    return [];
  }
}
