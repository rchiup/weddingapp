import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_settings_model.dart';

/// Modelo de evento (join)
///
/// Contiene datos mínimos para contexto del evento.
class EventModel {
  final String id;
  final String name;
  final DateTime date;
  final bool active;
  final EventSettingsModel settings;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.active,
    required this.settings,
  });

  /// Lee `date` tal como viene de Firestore (Timestamp, String ISO o DateTime).
  static DateTime? parseStoredDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  factory EventModel.fromFirestore(String id, Map<String, dynamic> data) {
    final parsedDate = parseStoredDate(data['date']) ?? DateTime.now();

    return EventModel(
      id: id,
      name: data['name'] ?? '',
      date: parsedDate,
      active: data['active'] ?? true,
      settings: EventSettingsModel.fromMap(data['settings']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'active': active,
      'settings': settings.toMap(),
    };
  }
}
