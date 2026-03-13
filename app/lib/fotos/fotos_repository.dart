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

  Future<FotoModel> uploadPhoto({
    required String eventId,
    required String userId,
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
