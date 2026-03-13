/// Modelo de RSVP
///
/// Estructura pensada para Firestore:
/// - attending: bool
/// - plus_one: bool
/// - dietary_notes: string
/// - updated_at: string (ISO)
class RsvpModel {
  final String id;
  final bool attending;
  final bool plusOne;
  final String dietaryNotes;
  final DateTime updatedAt;

  RsvpModel({
    required this.id,
    required this.attending,
    required this.plusOne,
    required this.dietaryNotes,
    required this.updatedAt,
  });

  factory RsvpModel.fromMap(String id, Map<String, dynamic> data) {
    final rawUpdatedAt = data['updated_at'];
    final updatedAt = rawUpdatedAt is DateTime
        ? rawUpdatedAt
        : (rawUpdatedAt is String ? DateTime.tryParse(rawUpdatedAt) : null) ??
            DateTime.now();

    return RsvpModel(
      id: id,
      attending: data['attending'] ?? false,
      plusOne: data['plus_one'] ?? false,
      dietaryNotes: data['dietary_notes'] ?? '',
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attending': attending,
      'plus_one': plusOne,
      'dietary_notes': dietaryNotes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
