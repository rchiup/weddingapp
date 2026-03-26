import 'package:flutter/foundation.dart';

import 'rsvp_model.dart';
import 'rsvp_repository.dart';

/// Provider del flujo RSVP
///
/// Mantiene estado local del RSVP y coordina guardado/lectura.
class RsvpProvider extends ChangeNotifier {
  final RsvpRepository _repository = RsvpRepository();

  RsvpModel? _rsvp;
  bool _fetching = false;
  bool _saving = false;

  RsvpModel? get rsvp => _rsvp;

  /// Carga inicial desde Firestore (no bloquea el botón Guardar en detalles).
  bool get isFetching => _fetching;

  /// Guardado en curso.
  bool get isSaving => _saving;

  /// Carga el RSVP desde backend/Firestore
  Future<void> loadRsvp({
    required String eventId,
    required String userId,
  }) async {
    _setFetching(true);
    try {
      _rsvp = await _repository.getRsvp(eventId: eventId, userId: userId);
    } finally {
      _setFetching(false);
    }
  }

  /// Guarda el RSVP en backend/Firestore
  Future<void> saveRsvp({
    required String eventId,
    required String userId,
    required bool attending,
    required bool plusOne,
    required String dietaryPreference,
    required bool allergies,
    required String allergiesNotes,
    required String dietaryNotes,
  }) async {
    _setSaving(true);
    try {
      final model = RsvpModel(
        id: userId,
        attending: attending,
        plusOne: plusOne,
        dietaryPreference: dietaryPreference,
        allergies: allergies,
        allergiesNotes: allergiesNotes,
        dietaryNotes: dietaryNotes,
        updatedAt: DateTime.now(),
      );
      _rsvp = model;
      await _repository.saveRsvp(eventId: eventId, userId: userId, rsvp: model);
      notifyListeners();
    } finally {
      _setSaving(false);
    }
  }

  /// Actualiza solo la preferencia de menú sin borrar el resto del RSVP.
  Future<void> saveDietaryPreferenceOnly({
    required String eventId,
    required String userId,
    required String dietaryPreference,
  }) async {
    _setSaving(true);
    try {
      final existing = _rsvp ?? await _repository.getRsvp(eventId: eventId, userId: userId);
      final base = existing ??
          RsvpModel(
            id: userId,
            attending: false,
            plusOne: false,
            dietaryPreference: 'none',
            allergies: false,
            allergiesNotes: '',
            dietaryNotes: '',
            updatedAt: DateTime.now(),
          );
      final model = RsvpModel(
        id: userId,
        attending: base.attending,
        plusOne: base.plusOne,
        dietaryPreference: dietaryPreference,
        allergies: base.allergies,
        allergiesNotes: base.allergiesNotes,
        dietaryNotes: base.dietaryNotes,
        updatedAt: DateTime.now(),
      );
      _rsvp = model;
      await _repository.saveRsvp(eventId: eventId, userId: userId, rsvp: model);
      notifyListeners();
    } finally {
      _setSaving(false);
    }
  }

  void _setFetching(bool value) {
    _fetching = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _saving = value;
    notifyListeners();
  }
}
