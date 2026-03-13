import 'package:flutter/foundation.dart';

/// Provider del flujo de solteros
///
/// Centraliza el estado del flujo: perfiles, likes y matches.
/// No comparte estado con el flujo de fotos.
class SolterosProvider extends ChangeNotifier {
  bool _hasMatch = false;
  bool get hasMatch => _hasMatch;

  /// Marca un match (mock)
  void setMockMatch(bool value) {
    _hasMatch = value;
    notifyListeners();
  }
}
