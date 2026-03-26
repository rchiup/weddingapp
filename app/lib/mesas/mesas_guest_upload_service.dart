import 'dart:typed_data';

import 'package:dio/dio.dart';

class MesasGuestUploadResult {
  MesasGuestUploadResult({required this.imported, required this.warnings});

  final int imported;
  final List<String> warnings;
}

/// Subida de Excel de invitados al backend (mismo host que lista de novios).
class MesasGuestUploadService {
  MesasGuestUploadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const String _backendBaseUrl = 'https://weddingapp-c6ix.onrender.com';

  Future<MesasGuestUploadResult> uploadExcel({
    required String eventId,
    required String adminCode,
    required Uint8List bytes,
    String filename = 'invitados.xlsx',
  }) async {
    if (eventId.isEmpty || adminCode.trim().isEmpty) {
      throw Exception('Faltan datos del evento o código de novios');
    }
    final form = FormData.fromMap({
      'adminCode': adminCode.trim().toUpperCase(),
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_backendBaseUrl/api/gallery/event/$eventId/guests/upload',
        data: form,
      );
      final data = res.data ?? {};
      if (data['ok'] == true) {
        final w = data['warnings'];
        final list = w is List ? w.map((e) => e.toString()).toList() : <String>[];
        return MesasGuestUploadResult(
          imported: (data['imported'] as num?)?.toInt() ?? 0,
          warnings: list,
        );
      }
      throw Exception(data['error']?.toString() ?? 'Error al importar');
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] != null) {
        throw Exception(body['error'].toString());
      }
      throw Exception(e.message ?? 'Error de red');
    }
  }
}
