import 'rsvp_model.dart';

/// Mapper de RSVP <-> Firestore
class RsvpMapper {
  static RsvpModel fromMap(String id, Map<String, dynamic> data) {
    return RsvpModel.fromMap(id, data);
  }

  static Map<String, dynamic> toMap(RsvpModel model) {
    return model.toMap();
  }
}
