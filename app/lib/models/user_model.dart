/// Modelo de usuario
/// 
/// Representa los datos de un usuario en la aplicación.
/// Incluye información básica y preferencias.
class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final bool isSingle;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.isSingle = false,
    required this.createdAt,
  });

  /// Crea un UserModel desde un documento de Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is DateTime
        ? rawCreatedAt
        : (rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null) ??
            DateTime.now();

    return UserModel(
      id: id,
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
      isSingle: data['isSingle'] ?? false,
      createdAt: createdAt,
    );
  }

  /// Convierte un UserModel a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'isSingle': isSingle,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
