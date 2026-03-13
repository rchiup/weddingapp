import 'package:flutter/foundation.dart';

import '../user_context/user_context_provider.dart';
import 'event_join_service.dart';
import 'event_join_validator.dart';
import 'event_model.dart';
import 'event_settings_model.dart';

/// Provider de Event Join
///
/// Maneja el estado de unión al evento por código.
class EventJoinProvider extends ChangeNotifier {
  final EventJoinService _service = EventJoinService();

  EventModel? _event;
  String? _errorMessage;
  bool _isLoading = false;

  EventModel? get event => _event;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> joinByCode({
    required String code,
    required UserContextProvider userContext,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final normalized = EventJoinValidator.normalizeCode(code);
      // Modo libre para pruebas: cualquier código activa el menú.
      final event = EventModel(
        id: normalized,
        name: 'Evento de prueba',
        date: DateTime.now(),
        active: true,
        settings: EventSettingsModel(
          guestsVisible: true,
          tablesVisible: true,
          singlesEnabled: true,
          photosEnabled: true,
          giftRegistryEnabled: true,
          giftRegistryProvider: 'other',
          giftRegistryCode: 'DEMO',
          giftRegistryUrlOverride: null,
          adminExportEnabled: true,
        ),
      );
      _event = event;
      await userContext.setEvent(
        eventId: event.id,
        eventName: event.name,
        eventDate: event.date,
        settings: event.settings.toMap(),
        eventActive: event.active,
        isAdmin: true,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
