import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de foto
class FotoModel {
  final String id;
  final String url;
  final String uploadedBy;
  final String uploadedByName;
  final String visibility; // 'public' | 'novios'
  final DateTime createdAt;

  /// Clave estable para likes/comentarios (misma URL = misma clave aunque el backend cambie photoId)
  /// Firestore doc id solo permite [a-zA-Z0-9_-]
  String get likesKey {
    if (url.isEmpty) return id;
    final safe = url.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (safe.isEmpty) return id;
    if (safe.length <= 1500) return safe;
    return safe.substring(0, 1500);
  }

  FotoModel({
    required this.id,
    required this.url,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.visibility,
    required this.createdAt,
  });

  factory FotoModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : (rawCreatedAt is String ? DateTime.tryParse(rawCreatedAt) : null) ??
            DateTime.now();

    return FotoModel(
      id: id,
      url: data['url'] ?? data['imageUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? data['userId'] ?? '',
      uploadedByName: (data['uploadedByName'] ?? data['userName'] ?? '').toString(),
      visibility: (data['visibility'] ?? 'public').toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
