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

  factory EventModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];
    final parsedDate = rawDate is DateTime
        ? rawDate
        : (rawDate is String ? DateTime.tryParse(rawDate) : null) ??
            DateTime.now();

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
