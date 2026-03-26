import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio Firestore para RSVP
class RsvpFirestoreService {
  RsvpFirestoreService({
    Duration? networkTimeout,
  }) : _timeout = networkTimeout ?? const Duration(seconds: 45);

  final Duration _timeout;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getRsvpDoc({
    required String eventId,
    required String userId,
  }) async {
    if (eventId.isEmpty || userId.isEmpty) return null;
    try {
      final doc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('rsvps')
          .doc(userId)
          .get()
          .timeout(_timeout);
      if (!doc.exists) return null;
      return doc.data();
    } on TimeoutException {
      return null;
    }
  }

  Future<void> setRsvpDoc({
    required String eventId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    if (eventId.isEmpty || userId.isEmpty) {
      throw StateError('eventId o userId vacío');
    }
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('rsvps')
        .doc(userId)
        .set(data, SetOptions(merge: true))
        .timeout(_timeout);
  }
}
