import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'foto_model.dart';

const String _backendBaseUrl = 'https://weddingapp-c6ix.onrender.com';

/// Repository de fotos
class FotosRepository {
  final Dio _dio = Dio();

  Future<List<FotoModel>> fetchPhotos(String eventId) async {
    final response = await _dio.get('$_backendBaseUrl/api/gallery/event/$eventId');
    final data = response.data as Map<String, dynamic>;
    final rawItems = (data['items'] as List<dynamic>? ?? []);
    final items = rawItems
        .where((item) => item is Map)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return items
        .map((item) => FotoModel.fromFirestore(
              (item['photoId'] ?? '').toString(),
              item,
            ))
        .toList();
  }

  /// Lee likes de una foto desde la API (backend escribe/lee en gallery/{photoId}/likes).
  /// GET /api/gallery/photos/<photoId>/likes?userId=...
  Future<({int count, bool userLiked})?> getPhotoLikes(
    String photoId,
    String userId,
  ) async {
    if (photoId.isEmpty) return null;
    try {
      final uri = Uri.parse(_backendBaseUrl).replace(
        path: '/api/gallery/photos/$photoId/likes',
        queryParameters: userId.isNotEmpty ? {'userId': userId} : null,
      );
      final response = await _dio.get(uri.toString());
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;
      final count = (data['count'] is int)
          ? data['count'] as int
          : (int.tryParse('${data['count']}') ?? 0);
      final userLiked = data['userLiked'] == true;
      return (count: count, userLiked: userLiked);
    } on DioException catch (_) {
      return null;
    }
  }

  /// Toggle like en la API. Backend escribe en gallery/{photoId}/likes/{userId}.
  /// POST /api/gallery/photos/<photoId>/likes/toggle
  Future<({bool liked, int count})?> togglePhotoLike(
    String photoId,
    String userId,
    String name,
  ) async {
    if (photoId.isEmpty || userId.isEmpty) return null;
    try {
      final response = await _dio.post(
        '$_backendBaseUrl/api/gallery/photos/$photoId/likes/toggle',
        data: {'userId': userId, 'name': name.isNotEmpty ? name : 'Invitado'},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;
      final liked = data['liked'] == true;
      final count = (data['count'] is int)
          ? data['count'] as int
          : (int.tryParse('${data['count']}') ?? 0);
      return (liked: liked, count: count);
    } on DioException catch (_) {
      return null;
    }
  }

  /// Comentarios: gallery/{photoId}/comments
  /// GET /api/gallery/photos/<photoId>/comments
  Future<List<Map<String, dynamic>>> getPhotoComments(String photoId) async {
    if (photoId.isEmpty) return [];
    final response =
        await _dio.get('$_backendBaseUrl/api/gallery/photos/$photoId/comments');
    final data = response.data as List<dynamic>? ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  /// GET /api/gallery/photos/<photoId>/comments/count
  Future<int?> getPhotoCommentsCount(String photoId) async {
    if (photoId.isEmpty) return null;
    try {
      final response =
          await _dio.get('$_backendBaseUrl/api/gallery/photos/$photoId/comments/count');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return null;
      final count = (data['count'] is int)
          ? data['count'] as int
          : (int.tryParse('${data['count']}') ?? 0);
      return count;
    } on DioException catch (_) {
      return null;
    }
  }

  /// POST /api/gallery/photos/<photoId>/comments
  Future<void> addPhotoComment({
    required String photoId,
    required String userId,
    required String name,
    required String message,
  }) async {
    if (photoId.isEmpty || userId.isEmpty || message.trim().isEmpty) return;
    await _dio.post(
      '$_backendBaseUrl/api/gallery/photos/$photoId/comments',
      data: {
        'userId': userId,
        'name': name,
        'message': message.trim(),
      },
    );
  }

  Future<void> deletePhoto(String photoId) async {
    if (photoId.isEmpty) return;
    await _dio.delete('$_backendBaseUrl/api/gallery/photos/$photoId');
  }

  Future<FotoModel> uploadPhoto({
    required String eventId,
    required String userId,
    required String userName,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.name.isNotEmpty ? file.name : 'upload.jpg';
    final MultipartFile multipartFile;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
    } else {
      multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
    }

    try {
      final formData = FormData.fromMap({
        'file': multipartFile,
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
      });

      final response = await _dio.post(
        '$_backendBaseUrl/api/gallery/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(sent / total);
          }
        },
      );

      final data = response.data as Map<String, dynamic>;
      final url = (data['imageUrl'] ?? '').toString();
      final photoId = (data['photoId'] ?? '').toString();

    final model = FotoModel(
      id: photoId.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : photoId,
      url: url,
      uploadedBy: userId,
      createdAt: DateTime.now(),
    );

      return model;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString();
      final detail = body ?? e.message ?? 'upload failed';
      throw Exception('HTTP ${status ?? '-'}: $detail');
    }
  }
}
