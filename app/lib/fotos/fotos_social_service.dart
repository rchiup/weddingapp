import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de likes y comentarios en fotos (Firestore)
class FotosSocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ——— Likes ——— events/{eventId}/photos/{photoId}/likes/{userId}
  Future<int> getLikeCount(String eventId, String photoId) async {
    final snap = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .count()
        .get();
    return snap.count ?? 0;
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

  Future<void> toggleLike({
    required String eventId,
    required String photoId,
    required String userId,
    required String name,
  }) async {
    final ref = _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .collection('likes')
        .doc(userId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'name': name,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
