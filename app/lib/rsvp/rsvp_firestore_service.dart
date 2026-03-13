import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio Firestore para RSVP
class RsvpFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getRsvpDoc({
    required String eventId,
    required String userId,
  }) async {
    final doc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('rsvps')
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> setRsvpDoc({
    required String eventId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('rsvps')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }
}
