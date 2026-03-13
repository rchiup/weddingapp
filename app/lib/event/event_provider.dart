import 'package:flutter/foundation.dart';

import '../models/event_model.dart';
import '../services/event_service.dart';

/// Provider para gestión de estado de eventos
/// 
/// Maneja la lista de eventos, detalles del evento actual,
/// mesas, invitados, y configuración del evento.
class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  
  List<EventModel> _events = [];
  EventModel? _currentEvent;
  bool _isLoading = false;

  List<EventModel> get events => _events;
  EventModel? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;

  /// Carga todos los eventos del usuario
  Future<void> loadEvents(String userId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar eventos desde EventService
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  /// Carga los detalles de un evento específico
  Future<void> loadEventDetails(String eventId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar detalles del evento desde EventService
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  /// Establece el evento actual
  void setCurrentEvent(EventModel event) {
    _currentEvent = event;
    notifyListeners();
  }

  /// Carga las mesas del evento
  Future<void> loadTables(String eventId) async {
    try {
      // TODO: Cargar mesas desde EventService
      notifyListeners();
    } catch (e) {
      // TODO: Manejar error
    }
  }

  /// Carga los invitados del evento
  Future<void> loadGuests(String eventId) async {
    try {
      // TODO: Cargar invitados desde EventService
      notifyListeners();
    } catch (e) {
      // TODO: Manejar error
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
