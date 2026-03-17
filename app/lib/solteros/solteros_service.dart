import 'package:dio/dio.dart';

class SolterosMessage {
  final String id;
  final String userId;
  final String name;
  final String text;
  final String createdAt;

  SolterosMessage({
    required this.id,
    required this.userId,
    required this.name,
    required this.text,
    required this.createdAt,
  });

  factory SolterosMessage.fromJson(Map<String, dynamic> json) {
    return SolterosMessage(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? 'Invitado').toString(),
      text: (json['text'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class SolteroProfile {
  final String userId;
  final String name;
  final String activatedAt;

  SolteroProfile({
    required this.userId,
    required this.name,
    required this.activatedAt,
  });

  factory SolteroProfile.fromJson(Map<String, dynamic> json) {
    return SolteroProfile(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? 'Invitado').toString(),
      activatedAt: (json['activatedAt'] ?? '').toString(),
    );
  }
}

/// Servicio Solteros (backend API)
class SolterosService {
  final Dio _dio = Dio();

  static const String backendBaseUrl = 'https://weddingapp-c6ix.onrender.com';

  Future<void> activateSingle({
    required String eventId,
    required String userId,
    required String name,
  }) async {
    await _dio.post(
      '$backendBaseUrl/api/solteros/event/$eventId/activate',
      data: {'userId': userId, 'name': name},
    );
  }

  Future<List<SolteroProfile>> listSingles({
    required String eventId,
    required String viewerId,
    String q = '',
  }) async {
    final res = await _dio.get(
      '$backendBaseUrl/api/solteros/event/$eventId/list',
      queryParameters: {
        'viewerId': viewerId,
        if (q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    final data = res.data;
    final items = (data is Map<String, dynamic> ? (data['items'] ?? []) : data) as List<dynamic>;
    return items
        .whereType<Map>()
        .map((e) => SolteroProfile.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<SolterosMessage>> getGlobalMessages({
    required String eventId,
    required String viewerId,
    String? after,
    int limit = 60,
  }) async {
    final res = await _dio.get(
      '$backendBaseUrl/api/solteros/event/$eventId/chat/messages',
      queryParameters: {
        'viewerId': viewerId,
        'limit': limit,
        if (after != null && after.trim().isNotEmpty) 'after': after.trim(),
      },
    );
    final data = res.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map>()
        .map((e) => SolterosMessage.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> sendGlobalMessage({
    required String eventId,
    required String viewerId,
    required String name,
    required String text,
  }) async {
    await _dio.post(
      '$backendBaseUrl/api/solteros/event/$eventId/chat/messages',
      data: {'viewerId': viewerId, 'name': name, 'text': text},
    );
  }

  Future<List<SolterosMessage>> getDmMessages({
    required String eventId,
    required String viewerId,
    required String otherUserId,
    String? after,
    int limit = 60,
  }) async {
    final res = await _dio.get(
      '$backendBaseUrl/api/solteros/event/$eventId/dm/$otherUserId/messages',
      queryParameters: {
        'viewerId': viewerId,
        'limit': limit,
        if (after != null && after.trim().isNotEmpty) 'after': after.trim(),
      },
    );
    final data = res.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? const []);
    return items
        .whereType<Map>()
        .map((e) => SolterosMessage.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> sendDmMessage({
    required String eventId,
    required String viewerId,
    required String name,
    required String otherUserId,
    required String text,
  }) async {
    await _dio.post(
      '$backendBaseUrl/api/solteros/event/$eventId/dm/$otherUserId/messages',
      data: {'viewerId': viewerId, 'name': name, 'text': text},
    );
  }
}
