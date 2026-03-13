/// Modelo de evento
/// 
/// Representa un evento de matrimonio con toda su información:
/// fecha, lugar, organizadores, y configuración.
class EventModel {
  final String id;
  final String name;
  final DateTime date;
  final String? location;
  final String? description;
  final String organizerId;
  final List<String> adminIds;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    this.location,
    this.description,
    required this.organizerId,
    this.adminIds = const [],
    required this.createdAt,
  });

  /// Crea un EventModel desde un documento de Firestore
  factory EventModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawDate = data['date'];
    final parsedDate = rawDate is DateTime
        ? rawDate
        : (rawDate is String ? DateTime.tryParse(rawDate) : null) ??
            DateTime.now();
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is DateTime
        ? rawCreatedAt
        : (rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null) ??
            DateTime.now();

    return EventModel(
      id: id,
      name: data['name'] ?? '',
      date: parsedDate,
      location: data['location'],
      description: data['description'],
      organizerId: data['organizerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      createdAt: createdAt,
    );
  }

  /// Convierte un EventModel a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'organizerId': organizerId,
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
