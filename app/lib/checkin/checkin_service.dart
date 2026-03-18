import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Servicio de check-in al evento
///
/// Crea documento en events/{eventId}/checkins/{userId}
class CheckinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  static const String _backendBaseUrl = 'https://weddingapp-c6ix.onrender.com';

  Future<List<Map<String, dynamic>>> getArrivals({
    required String eventId,
    String? query,
  }) async {
    if (eventId.isEmpty) return [];
    final uri = Uri.parse(_backendBaseUrl).replace(
      path: '/api/gallery/event/$eventId/arrivals',
      queryParameters: (query == null || query.trim().isEmpty) ? null : {'q': query.trim()},
    );
    final res = await _dio.get(uri.toString()).timeout(const Duration(seconds: 20));
    final data = res.data as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    return items;
  }

  Future<bool> hasArrived({
    required String eventId,
    required String userId,
  }) async {
    if (eventId.isEmpty || userId.isEmpty) return false;
    try {
      final items = await getArrivals(eventId: eventId);
      return items.any((it) => (it['userId'] ?? '').toString() == userId);
    } catch (_) {
      return false;
    }
  }

  Future<void> checkIn({
    required String eventId,
    required String userId,
    required String name,
  }) async {
    // En Flutter Web el cliente Firestore suele quedar offline tras refresh.
    // Para check-in usamos el backend (Admin SDK) y evitamos hangs.
    if (kIsWeb) {
      // Warm-up (Render free tier puede estar dormido)
      try {
        await _dio
            .get('$_backendBaseUrl/')
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // no bloqueamos por fallos del warmup
      }

      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          await _dio
              .post(
                '$_backendBaseUrl/api/gallery/event/$eventId/checkin',
                data: {'userId': userId, 'name': name},
              )
              .timeout(const Duration(seconds: 25));
          return;
        } catch (e) {
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(Duration(milliseconds: 600 * attempt));
        }
      }
      return;
    }

    // Registro de check-in para estadísticas
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('checkins')
        .doc(userId)
        .set({
      'name': name,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Para la demo: marcar al invitado como "llegó"
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('guests')
        .doc(userId)
        .set({
      'name': name,
      'nameLower': name.toLowerCase(),
      'status': 'arrived',
      'tableNumber': '',
      'arrivalAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
