/// Modelo de RSVP
///
/// Estructura pensada para Firestore:
/// - attending: bool
/// - plus_one: bool
/// - dietary_preference: string ('none' | 'vegetarian' | 'vegan')
/// - allergies: bool
/// - allergies_notes: string
/// - dietary_notes: string (legacy / texto libre)
/// - updated_at: string (ISO)
class RsvpModel {
  final String id;
  final bool attending;
  final bool plusOne;
  final String dietaryPreference;
  final bool allergies;
  final String allergiesNotes;
  final String dietaryNotes;
  final DateTime updatedAt;

  RsvpModel({
    required this.id,
    required this.attending,
    required this.plusOne,
    required this.dietaryPreference,
    required this.allergies,
    required this.allergiesNotes,
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
      dietaryPreference: (data['dietary_preference'] ?? 'none').toString(),
      allergies: data['allergies'] ?? false,
      allergiesNotes: (data['allergies_notes'] ?? '').toString(),
      dietaryNotes: data['dietary_notes'] ?? '',
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attending': attending,
      'plus_one': plusOne,
      'dietary_preference': dietaryPreference,
      'allergies': allergies,
      'allergies_notes': allergiesNotes,
      'dietary_notes': dietaryNotes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
