import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_model.dart';

/// Servicio de Event Join
///
/// Resuelve evento por código y obtiene settings.
class EventJoinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<EventModel> getEventByCode(String code) async {
    final codeDoc = await _firestore.collection('events_by_code').doc(code).get();
    if (!codeDoc.exists) {
      throw Exception('Código inválido');
    }
    final eventId = codeDoc.data()?['eventId'] as String?;
    if (eventId == null || eventId.isEmpty) {
      throw Exception('Evento no encontrado');
    }

    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Evento no encontrado');
    }

    return EventModel.fromFirestore(eventDoc.id, eventDoc.data() ?? {});
  }
}
