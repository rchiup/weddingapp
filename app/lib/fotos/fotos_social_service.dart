import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de likes y comentarios en fotos (Firestore)
class FotosSocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ——— Likes ——— events/{eventId}/photos/{photoId}/likes/{userId}
  /// Cuenta con get() para no depender de RunAggregationQuery (reglas a veces no permiten count)
  Future<int> getLikeCount(String eventId, String photoId) async {
    final snap = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .get();
    return snap.docs.length;
  }

  Stream<int> watchLikeCount(String eventId, String photoId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Future<bool> isLikedBy(String eventId, String photoId, String userId) async {
    final doc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .doc(userId)
        .get();
    return doc.exists;
  }

  /// Stream del like del usuario actual (actualización en tiempo real)
  Stream<bool> watchUserLike(String eventId, String photoId, String userId) {
    if (eventId.isEmpty || photoId.isEmpty || userId.isEmpty) {
      return Stream.value(false);
    }
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((s) => s.exists);
  }

  /// [isLikedNow] = estado actual desde la UI (evita el get() que falla si está offline)
  Future<void> toggleLike({
    required String eventId,
    required String photoId,
    required String userId,
    required String name,
    required bool isLikedNow,
  }) async {
    final ref = _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .doc(userId);

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _firestore.enableNetwork();
        if (isLikedNow) {
          await ref.delete();
        } else {
          await ref.set({
            'name': name,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  // ——— Comentarios ——— events/{eventId}/photos/{photoId}/comments/{commentId}
  Stream<List<Map<String, dynamic>>> watchComments(String eventId, String photoId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addComment({
    required String eventId,
    required String photoId,
    required String name,
    required String message,
  }) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('comments')
        .add({
      'name': name,
      'message': message.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
