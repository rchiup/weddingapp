import 'package:flutter/widgets.dart';

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
  String? _loadError;
  /// Cargas [loadRsvp] solapadas (p. ej. reintento): no bajar `isFetching` hasta la última.
  int _loadRsvpInFlight = 0;

  RsvpModel? get rsvp => _rsvp;

  /// Carga inicial desde Firestore (no bloquea el botón Guardar en detalles).
  bool get isFetching => _fetching;

  /// Guardado en curso.
  bool get isSaving => _saving;

  /// Error al leer RSVP (red, permisos, etc.).
  String? get loadError => _loadError;

  /// Carga el RSVP desde backend/Firestore
  Future<void> loadRsvp({
    required String eventId,
    required String userId,
  }) async {
    _loadRsvpInFlight++;
    _loadError = null;
    _setFetching(true);
    try {
      _rsvp = await _repository.getRsvp(eventId: eventId, userId: userId);
    } catch (e, st) {
      debugPrint('RsvpProvider.loadRsvp: $e\n$st');
      _loadError = 'No se pudo cargar tu RSVP. Revisa conexión o vuelve a intentar.';
      _rsvp = null;
    } finally {
      _loadRsvpInFlight--;
      if (_loadRsvpInFlight <= 0) {
        _loadRsvpInFlight = 0;
        _setFetching(false);
      }
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
    // Tras async + otros listenables, un solo notify a veces no repinta en web
    // (loading infinito aunque `_fetching` ya sea false).
    if (!value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _setSaving(bool value) {
    _saving = value;
    notifyListeners();
    if (!value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
