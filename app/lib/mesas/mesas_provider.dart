import 'package:flutter/foundation.dart';

import 'guest_model.dart';
import 'mesa_model.dart';
import 'mesas_service.dart';

/// Provider de mesas
class MesasProvider extends ChangeNotifier {
  final MesasService _service = MesasService();

  bool _isLoading = false;
  String? _error;
  MesaModel? _currentTable;
  List<GuestModel> _guestResults = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  MesaModel? get currentTable => _currentTable;
  List<GuestModel> get guestResults => _guestResults;

  Future<MesaModel?> findTableByNumber(String eventId, String tableNumber) async {
    _setLoading(true);
    _error = null;
    try {
      final table = await _service.getTableByNumber(eventId, tableNumber);
      _currentTable = table;
      _setLoading(false);
      return table;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<MesaModel?> findTableByGuestNameExact(String eventId, String name) async {
    _setLoading(true);
    _error = null;
    try {
      final guest = await _service.getGuestByExactName(eventId, name);
      if (guest == null) {
        _setLoading(false);
        return null;
      }
      final table = await _service.getTableByNumber(eventId, guest.tableNumber);
      _currentTable = table;
      _setLoading(false);
      return table;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<void> searchGuests(String eventId, String query) async {
    _setLoading(true);
    _error = null;
    try {
      _guestResults = await _service.searchGuestsByName(eventId, query);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  void clearResults() {
    _guestResults = [];
    _currentTable = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
