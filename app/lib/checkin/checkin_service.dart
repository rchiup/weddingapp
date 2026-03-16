import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de check-in al evento
///
/// Crea documento en events/{eventId}/checkins/{userId}
class CheckinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String name,
  }) async {
    // Registro de check-in para estadísticas
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('checkins')
        .doc(userId)
        .set({
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Para la demo: marcar al invitado como "llegó"
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .doc(userId)
        .set({
      'name': name,
      'nameLower': name.toLowerCase(),
      'status': 'arrived',
      'tableNumber': '',
    }, SetOptions(merge: true));
  }
}
