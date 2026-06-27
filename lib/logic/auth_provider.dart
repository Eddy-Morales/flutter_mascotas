import 'package:flutter/material.dart';
import '../data/models/usuario_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UsuarioModel? _usuarioActual;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para la UI
  UsuarioModel? get usuarioActual => _usuarioActual;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Verificar si hay una sesión guardada en el dispositivo al iniciar la app
  Future<void> verificarSesionActiva() async {
    _setLoading(true);
    final sessionUser = _authService.usuarioAuthActual;
    if (sessionUser != null) {
      _usuarioActual = await _authService.obtenerPerfil(sessionUser.id);
    }
    _setLoading(false);
  }

  // Acción de Login
  Future<bool> ingresar(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      _usuarioActual = await _authService.login(email, password);
      _setLoading(false);
      return _usuarioActual != null;
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Acción de Cambio de Clave
  Future<bool> cambiarClaveInicial(String nuevaClave) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.actualizarContrasenaObligatoria(nuevaClave);
      // Actualizamos el estado local del modelo
      if (_usuarioActual != null) {
        _usuarioActual = await _authService.obtenerPerfil(_usuarioActual!.id);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Acción de Recuperar Clave
  Future<bool> enviarEnlaceRecuperacion(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.recuperarContrasena(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // Cerrar Sesión
  Future<void> salir() async {
    await _authService.logout();
    _usuarioActual = null;
    notifyListeners();
  }

  // Métodos auxiliares de control de estado interno
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Mapeo amigable de errores de Supabase para el usuario/profesor
  String _parseError(dynamic error) {
    final strError = error.toString();
    if (strError.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    } else if (strError.contains('Network')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return 'Ocurrió un inconveniente: $strError';
  }
}