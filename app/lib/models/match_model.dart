/// Modelo de match
/// 
/// Representa una conexión entre dos usuarios solteros
/// dentro de un evento.
class MatchModel {
  final String id;
  final String userId1;
  final String userId2;
  final String eventId;
  final DateTime matchedAt;
  final bool isActive;

  MatchModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.eventId,
    required this.matchedAt,
    this.isActive = true,
  });

  /// Crea un MatchModel desde un documento de Firestore
  factory MatchModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawMatchedAt = data['matchedAt'];
    final matchedAt = rawMatchedAt is DateTime
        ? rawMatchedAt
        : (rawMatchedAt is String ? DateTime.tryParse(rawMatchedAt) : null) ??
            DateTime.now();

    return MatchModel(
      id: id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      eventId: data['eventId'] ?? '',
      matchedAt: matchedAt,
      isActive: data['isActive'] ?? true,
    );
  }

  /// Convierte un MatchModel a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'eventId': eventId,
      'matchedAt': matchedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
