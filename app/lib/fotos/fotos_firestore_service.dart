import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio Firestore para fotos
class FotosFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPhotos(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> savePhoto({
    required String eventId,
    required String photoId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('photos')
        .doc(photoId)
        .set(data, SetOptions(merge: true));
  }
}
