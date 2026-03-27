import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de foto
class FotoModel {
  final String id;
  final String url;
  final String mediaType; // 'image' | 'video'
  final String uploadedBy;
  final String uploadedByName;
  final String visibility; // 'public' | 'novios'
  final DateTime createdAt;

  bool get isVideo => mediaType == 'video' || _looksLikeVideoUrl(url);

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
    required this.mediaType,
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
      url: data['url'] ?? data['mediaUrl'] ?? data['imageUrl'] ?? '',
      mediaType: (data['mediaType'] ?? '').toString().toLowerCase().trim().isNotEmpty
          ? (data['mediaType'] ?? 'image').toString().toLowerCase()
          : (_looksLikeVideoUrl((data['url'] ?? data['mediaUrl'] ?? data['imageUrl'] ?? '').toString())
              ? 'video'
              : 'image'),
      uploadedBy: data['uploadedBy'] ?? data['userId'] ?? '',
      uploadedByName: (data['uploadedByName'] ?? data['userName'] ?? '').toString(),
      visibility: (data['visibility'] ?? 'public').toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'mediaType': mediaType,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

bool _looksLikeVideoUrl(String value) {
  final u = value.toLowerCase();
  return u.contains('.mp4') ||
      u.contains('.mov') ||
      u.contains('.webm') ||
      u.contains('/video/upload/');
}
