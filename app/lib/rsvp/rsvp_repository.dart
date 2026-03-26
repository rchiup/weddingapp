import 'rsvp_firestore_service.dart';
import 'rsvp_mapper.dart';
import 'rsvp_model.dart';

/// Repository de RSVP
class RsvpRepository {
  final RsvpFirestoreService _service = RsvpFirestoreService();

  Future<RsvpModel?> getRsvp({
    required String eventId,
    required String userId,
  }) async {
    if (eventId.isEmpty || userId.isEmpty) return null;
    final data = await _service.getRsvpDoc(eventId: eventId, userId: userId);
    if (data == null) return null;
    return RsvpMapper.fromMap(userId, data);
  }

  Future<void> saveRsvp({
    required String eventId,
    required String userId,
    required RsvpModel rsvp,
  }) async {
    await _service.setRsvpDoc(
      eventId: eventId,
      userId: userId,
      data: RsvpMapper.toMap(rsvp),
    );
  }
}
