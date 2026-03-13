/// Modelo de foto de galería
/// 
/// Representa una foto subida al evento con sus metadatos.
class GalleryModel {
  final String id;
  final String eventId;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime uploadedAt;
  final int likes;

  GalleryModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.uploadedAt,
    this.likes = 0,
  });

  /// Crea un GalleryModel desde un documento de Firestore
  factory GalleryModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawUploadedAt = data['uploadedAt'];
    final uploadedAt = rawUploadedAt is DateTime
        ? rawUploadedAt
        : (rawUploadedAt is String ? DateTime.tryParse(rawUploadedAt) : null) ??
            DateTime.now();

    return GalleryModel(
      id: id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      uploadedAt: uploadedAt,
      likes: data['likes'] ?? 0,
    );
  }

  /// Convierte un GalleryModel a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'uploadedAt': uploadedAt.toIso8601String(),
      'likes': likes,
    };
  }
}
