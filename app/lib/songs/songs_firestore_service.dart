import 'package:cloud_firestore/cloud_firestore.dart';

import 'songs_model.dart';

class SongsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _songsCol(String eventId) {
    return _firestore.collection('events').doc(eventId).collection('songs');
  }

  Future<List<SongModel>> listSongs({required String eventId}) async {
    final snap = await _songsCol(eventId).orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => SongModel.fromMap(d.id, d.data())).toList();
  }

  Future<void> addSong({
    required String eventId,
    required SongModel song,
  }) async {
    await _songsCol(eventId).add(song.toMap());
  }
}

