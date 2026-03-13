import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de foto
class FotoModel {
  final String id;
  final String url;
  final String uploadedBy;
  final DateTime createdAt;

  FotoModel({
    required this.id,
    required this.url,
    required this.uploadedBy,
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
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
