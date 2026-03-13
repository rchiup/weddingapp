import 'package:flutter/foundation.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';

/// Provider para gestión de estado de matches/conexiones
/// 
/// Maneja la lógica de conexión entre solteros dentro del evento,
/// incluyendo likes, matches, y lista de conexiones.
class MatchProvider extends ChangeNotifier {
  final MatchService _matchService = MatchService();
  
  List<MatchModel> _matches = [];
  List<MatchModel> _potentialMatches = [];
  bool _isLoading = false;

  List<MatchModel> get matches => _matches;
  List<MatchModel> get potentialMatches => _potentialMatches;
  bool get isLoading => _isLoading;

  /// Carga los matches del usuario para el evento actual
  Future<void> loadMatches(String eventId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar matches desde MatchService
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      // TODO: Manejar error
    }
  }

  /// Carga usuarios potenciales para hacer match
  Future<void> loadPotentialMatches(String eventId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar usuarios potenciales desde MatchService
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  /// Da like a un usuario
  Future<bool> likeUser(String userId, String eventId) async {
    try {
      // TODO: Implementar like con MatchService
      // TODO: Verificar si hay match
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Rechaza a un usuario (pass)
  Future<void> passUser(String userId, String eventId) async {
    try {
      // TODO: Implementar pass con MatchService
    } catch (e) {
      // TODO: Manejar error
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
