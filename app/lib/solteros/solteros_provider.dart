import 'dart:async';

import 'package:flutter/foundation.dart';

import '../user_context/user_context_provider.dart';
import 'solteros_service.dart';

/// Provider del flujo de solteros
///
/// Centraliza el estado del flujo: perfiles, likes y matches.
/// No comparte estado con el flujo de fotos.
class SolterosProvider extends ChangeNotifier {
  final SolterosService _service = SolterosService();
  Timer? _pollTimer;
  bool _polling = false;
  String _eventId = '';
  String _viewerId = '';
  bool _enabled = false;

  bool _hasUnreadGlobal = false;
  bool _hasUnreadDm = false;
  int _unreadGlobalCount = 0;
  int _unreadDmCount = 0;
  List<SolterosConversation> _conversations = const [];

  bool get hasUnreadGlobal => _hasUnreadGlobal;
  bool get hasUnreadDm => _hasUnreadDm;
  bool get hasAnyUnread => _hasUnreadGlobal || _hasUnreadDm;
  int get unreadGlobalCount => _unreadGlobalCount;
  int get unreadDmCount => _unreadDmCount;
  List<SolterosConversation> get conversations => _conversations;

  void updateContext(UserContextProvider userContext) {
    final nextEnabled = userContext.isSingleForCurrentEvent;
    final nextEventId = userContext.eventId ?? '';
    final nextViewerId = userContext.userId ?? '';
    final changed =
        _enabled != nextEnabled || _eventId != nextEventId || _viewerId != nextViewerId;

    _enabled = nextEnabled;
    _eventId = nextEventId;
    _viewerId = nextViewerId;

    if (!_enabled || _eventId.isEmpty || _viewerId.isEmpty) {
      _stopPolling();
      if (_conversations.isNotEmpty || _hasUnreadDm || _hasUnreadGlobal) {
        _conversations = const [];
        _hasUnreadDm = false;
        _hasUnreadGlobal = false;
        _unreadDmCount = 0;
        _unreadGlobalCount = 0;
        notifyListeners();
      }
      return;
    }

    if (changed) {
      refreshStatus();
      _startPolling();
    } else if (_pollTimer == null) {
      _startPolling();
    }
  }

  Future<void> refreshStatus() async {
    if (!_enabled || _eventId.isEmpty || _viewerId.isEmpty || _polling) return;
    _polling = true;
    try {
      final conversations = await _service.getConversations(
        eventId: _eventId,
        viewerId: _viewerId,
      );
      final globalStatus = await _service.getGlobalStatus(
        eventId: _eventId,
        viewerId: _viewerId,
      );
      _conversations = conversations;
      _unreadDmCount = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
      _unreadGlobalCount = globalStatus.unreadCount;
      _hasUnreadDm = _unreadDmCount > 0;
      _hasUnreadGlobal = _unreadGlobalCount > 0;
      notifyListeners();
    } catch (_) {
      // Silencioso para polling.
    } finally {
      _polling = false;
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => refreshStatus());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void markGlobalUnread() {
    if (_hasUnreadGlobal) return;
    _hasUnreadGlobal = true;
    notifyListeners();
  }

  void clearGlobalUnread() {
    if (!_hasUnreadGlobal && _unreadGlobalCount == 0) return;
    _hasUnreadGlobal = false;
    _unreadGlobalCount = 0;
    notifyListeners();
  }

  void markDmUnread() {
    if (_hasUnreadDm) return;
    _hasUnreadDm = true;
    notifyListeners();
  }

  void clearDmUnread() {
    if (!_hasUnreadDm && _unreadDmCount == 0) return;
    _hasUnreadDm = false;
    _unreadDmCount = 0;
    notifyListeners();
  }

  void clearAll() {
    if (!_hasUnreadGlobal && !_hasUnreadDm && _unreadDmCount == 0 && _unreadGlobalCount == 0) return;
    _hasUnreadGlobal = false;
    _hasUnreadDm = false;
    _unreadGlobalCount = 0;
    _unreadDmCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
