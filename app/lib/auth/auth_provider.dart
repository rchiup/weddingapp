import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider para gestión de estado de autenticación
/// 
/// Maneja el estado del usuario autenticado, login, logout,
/// y registro. Se comunica con AuthService para operaciones
/// con Firebase Auth.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Inicializa el provider y escucha cambios de autenticación
  AuthProvider() {
    _init();
  }

  void _init() {
    // TODO: Escuchar cambios de autenticación de Firebase
    // TODO: Cargar datos del usuario desde Firestore
  }

  /// Inicia sesión con email y contraseña
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implementar login con AuthService
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Registra un nuevo usuario
  Future<bool> register(String email, String password, Map<String, dynamic> userData) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implementar registro con AuthService
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Cierra sesión del usuario actual
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // TODO: Implementar logout con AuthService
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
