import 'rsvp_model.dart';

/// Servicio de RSVP
///
/// Encapsula la lógica de lectura/escritura en Firestore.
/// Este módulo no depende de solteros, fotos ni mesas.
class RsvpService {
  /// Obtiene el RSVP del invitado
  Future<RsvpModel?> getRsvp({
    required String eventId,
    required String userId,
  }) async {
    // TODO: Implementar lectura desde Firestore
    return null;
  }

  /// Guarda o actualiza el RSVP del invitado
  Future<void> saveRsvp({
    required String eventId,
    required String userId,
    required RsvpModel rsvp,
  }) async {
    // TODO: Implementar escritura en Firestore
  }
}
