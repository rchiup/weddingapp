import 'package:cloud_firestore/cloud_firestore.dart';

import 'songs_model.dart';

class SongsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _songsCol(String eventId) {
    return _firestore.collection('events').doc(eventId).collection('songs');
  }

  Future<List<SongModel>> listSongs({required String eventId}) async {
    try {
      final snap = await _songsCol(eventId).orderBy('created_at', descending: true).get();
      return snap.docs.map((d) => SongModel.fromMap(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      // Sin índice compuesto u orden: listar todo y ordenar en cliente.
      if (e.code == 'failed-precondition') {
        final snap = await _songsCol(eventId).get();
        final list = snap.docs.map((d) => SongModel.fromMap(d.id, d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      rethrow;
    }
  }

  Future<void> addSong({
    required String eventId,
    required SongModel song,
  }) async {
    await _songsCol(eventId).add(song.toMap());
  }
}

