import 'package:flutter/foundation.dart';

import 'rsvp_model.dart';
import 'rsvp_repository.dart';

/// Provider del flujo RSVP
///
/// Mantiene estado local del RSVP y coordina guardado/lectura.
class RsvpProvider extends ChangeNotifier {
  final RsvpRepository _repository = RsvpRepository();

  RsvpModel? _rsvp;
  bool _isLoading = false;

  RsvpModel? get rsvp => _rsvp;
  bool get isLoading => _isLoading;

  /// Carga el RSVP desde backend/Firestore
  Future<void> loadRsvp({
    required String eventId,
    required String userId,
  }) async {
    _setLoading(true);
    try {
      _rsvp = await _repository.getRsvp(eventId: eventId, userId: userId);
    } finally {
      _setLoading(false);
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
    _setLoading(true);
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
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
