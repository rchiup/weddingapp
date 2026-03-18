import 'package:dio/dio.dart';

class NoviosRegistryService {
  final Dio _dio = Dio();
  static const String _backendBaseUrl = 'https://weddingapp-c6ix.onrender.com';

  Future<String?> getRegistryUrl(String eventId) async {
    if (eventId.isEmpty) return null;
    final res = await _dio.get('$_backendBaseUrl/api/gallery/event/$eventId/registry');
    final data = res.data as Map<String, dynamic>? ?? {};
    final url = (data['registryUrl'] ?? '').toString();
    return url.isEmpty ? null : url;
  }

  Future<void> setRegistryUrl({
    required String eventId,
    required String adminCode,
    required String registryUrl,
  }) async {
    final url = registryUrl.trim();
    if (eventId.isEmpty || adminCode.trim().isEmpty || url.isEmpty) {
      throw Exception('Faltan datos');
    }
    await _dio.post(
      '$_backendBaseUrl/api/gallery/event/$eventId/registry',
      data: {
        'adminCode': adminCode.trim(),
        'registryUrl': url,
      },
    );
  }

  Future<Map<String, dynamic>?> getLocation(String eventId) async {
    if (eventId.isEmpty) return null;
    final res = await _dio.get('$_backendBaseUrl/api/gallery/event/$eventId/location');
    final data = res.data as Map<String, dynamic>? ?? {};
    final location = data['location'];
    if (location is Map<String, dynamic>) return location;
    if (location is Map) return Map<String, dynamic>.from(location);
    return null;
  }

  Future<void> setLocation({
    required String eventId,
    required String adminCode,
    required double latitude,
    required double longitude,
    String label = '',
  }) async {
    if (eventId.isEmpty || adminCode.trim().isEmpty) {
      throw Exception('Faltan datos');
    }
    await _dio.post(
      '$_backendBaseUrl/api/gallery/event/$eventId/location',
      data: {
        'adminCode': adminCode.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'label': label.trim(),
      },
    );
  }
}

