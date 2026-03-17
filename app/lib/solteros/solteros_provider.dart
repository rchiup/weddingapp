import 'package:flutter/foundation.dart';

/// Provider del flujo de solteros
///
/// Centraliza el estado del flujo: perfiles, likes y matches.
/// No comparte estado con el flujo de fotos.
class SolterosProvider extends ChangeNotifier {
  bool _hasUnreadGlobal = false;
  bool _hasUnreadDm = false;

  bool get hasUnreadGlobal => _hasUnreadGlobal;
  bool get hasUnreadDm => _hasUnreadDm;
  bool get hasAnyUnread => _hasUnreadGlobal || _hasUnreadDm;

  void markGlobalUnread() {
    if (_hasUnreadGlobal) return;
    _hasUnreadGlobal = true;
    notifyListeners();
  }

  void clearGlobalUnread() {
    if (!_hasUnreadGlobal) return;
    _hasUnreadGlobal = false;
    notifyListeners();
  }

  void markDmUnread() {
    if (_hasUnreadDm) return;
    _hasUnreadDm = true;
    notifyListeners();
  }

  void clearDmUnread() {
    if (!_hasUnreadDm) return;
    _hasUnreadDm = false;
    notifyListeners();
  }

  void clearAll() {
    if (!_hasUnreadGlobal && !_hasUnreadDm) return;
    _hasUnreadGlobal = false;
    _hasUnreadDm = false;
    notifyListeners();
  }
}
