import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Iniciar sesión
  Future<UsuarioModel?> login(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await obtenerPerfil(response.user!.id);
      }
      return null;
    } catch (e) {
      rethrow; // Lanzamos el error para que el Provider lo capture e informe a la UI
    }
  }

  // 2. Obtener los detalles extras (rol, cédula) de la tabla perfiles
  Future<UsuarioModel?> obtenerPerfil(String uid) async {
    try {
      final data = await _supabase
          .from('perfiles')
          .select()
          .eq('id', uid)
          .single();
      
      return UsuarioModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 3. Cambio obligatorio de contraseña (Primer inicio de sesión)
  Future<void> actualizarContrasenaObligatoria(String nuevaContrasena) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("No hay un usuario autenticado");

      // Actualizar la clave en Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: nuevaContrasena),
      );

      // Cambiar el estado de la bandera en la tabla perfiles
      await _supabase
          .from('perfiles')
          .update({'requiere_cambio_clave': false})
          .eq('id', user.id);
          
    } catch (e) {
      rethrow;
    }
  }

  // 4. Recuperación de contraseña por Correo Electrónico
  Future<void> recuperarContrasena(String email) async {
    try {
      // Supabase enviará un correo con un enlace de reinicio
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // 5. Cerrar sesión
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Obtener sesión activa al abrir la app de nuevo
  User? get usuarioAuthActual => _supabase.auth.currentUser;
}