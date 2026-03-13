import 'package:cloud_firestore/cloud_firestore.dart';

import 'guest_model.dart';
import 'mesa_model.dart';

/// Servicio de mesas
class MesasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MesaModel?> getTableByNumber(String eventId, String tableNumber) async {
    final tableDoc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('tables')
        .doc(tableNumber)
        .get();

    if (tableDoc.exists) {
      return MesaModel.fromFirestore(tableDoc.id, tableDoc.data() ?? {});
    }

    final guestsQuery = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .where('tableNumber', isEqualTo: tableNumber)
        .get();

    if (guestsQuery.docs.isEmpty) {
      return null;
    }

    final guests = guestsQuery.docs
        .map((doc) => GuestModel.fromFirestore(doc.id, doc.data()))
        .toList();

    return MesaModel(number: tableNumber, guests: guests);
  }

  Future<GuestModel?> getGuestByExactName(String eventId, String name) async {
    final query = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .where('nameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return GuestModel.fromFirestore(doc.id, doc.data());
  }

  Future<List<GuestModel>> searchGuestsByName(String eventId, String queryText) async {
    final queryLower = queryText.toLowerCase();
    final query = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .where('nameLower', isGreaterThanOrEqualTo: queryLower)
        .where('nameLower', isLessThanOrEqualTo: '$queryLower\uf8ff')
        .limit(20)
        .get();

    return query.docs
        .map((doc) => GuestModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
