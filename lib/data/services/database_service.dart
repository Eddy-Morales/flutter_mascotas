import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_model.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- GESTIÓN DE SECTORES ---
  
  // Obtener todos los sectores
  Future<List<Map<String, dynamic>>> obtenerSectores() async {
    try {
      final data = await _supabase.from('sectores').select().order('nombre');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      rethrow;
    }
  }

  // Crear un nuevo sector
  Future<void> crearSector(String nombre) async {
    try {
      await _supabase.from('sectores').insert({'nombre': nombre});
    } catch (e) {
      rethrow;
    }
  }

  // --- GESTIÓN DE USUARIOS POR ROL ---

  // Crear un usuario secundario (Coordinador de Brigada o Vacunador)
  // Nota: Al usar signUp, registramos en Auth y el trigger/perfil manual insertará los datos.
  Future<void> crearUsuarioPorRol({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required String rol, // 'coordinador_brigada' o 'vacunador'
  }) async {
    try {
      // Registramos en el Auth de Supabase con la contraseña obligatoria Ecuador2026
      // Pasamos los datos adicionales en data para que los podamos mapear al crear el perfil
      final AuthResponse response = await _supabase.auth.signUp(
        email: correo,
        password: 'Ecuador2026',
        data: {
          'cedula': cedula,
          'nombres': nombres,
          'apellidos': apellidos,
          'telefono': telefono,
          'rol': rol,
        },
      );

      if (response.user != null) {
        // Para asegurar que se inserte correctamente en perfiles si desactivamos el trigger remoto,
        // hacemos un insert preventivo/directo en la tabla perfiles
        await _supabase.from('perfiles').insert({
          'id': response.user!.id,
          'cedula': cedula,
          'nombres': nombres,
          'apellidos': apellidos,
          'telefono': telefono,
          'correo': correo,
          'rol': rol,
          'requiere_cambio_clave': true,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Asignar un usuario a un sector específico
  Future<void> asignarUsuarioASector(String usuarioId, int sectorId, String asignadoPorId) async {
    try {
      await _supabase.from('asignaciones_sectores').insert({
        'usuario_id': usuarioId,
        'sector_id': sectorId,
        'asignado_por': asignadoPorId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Obtener lista de usuarios por rol (ej: para listar los coordinadores de brigada creados)
  Future<List<UsuarioModel>> obtenerUsuariosPorRol(String rol) async {
    try {
      final data = await _supabase.from('perfiles').select().eq('rol', rol);
      return (data as List).map((json) => UsuarioModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

    // Obtener estadísticas de un sector
  Future<Map<String, int>> obtenerEstadisticasSector(int sectorId) async {
    try {
      final vacunados = await _supabase
          .from('vacunaciones')
          .select('id')
          .eq('sector_id', sectorId);

      final perros = await _supabase
          .from('vacunaciones')
          .select('id')
          .eq('sector_id', sectorId)
          .eq('tipo_mascota', 'perro');

      final gatos = await _supabase
          .from('vacunaciones')
          .select('id')
          .eq('sector_id', sectorId)
          .eq('tipo_mascota', 'gato');

      return {
        'vacunados': vacunados.length,
        'perros': perros.length,
        'gatos': gatos.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reasignarUsuarioASector(
    String usuarioId,
    int nuevoSectorId,
    String updatedBy,
  ) async {
    try {
      await _supabase
          .from('asignaciones_sectores')
          .update({
            'sector_id': nuevoSectorId,
            'asignado_por': updatedBy,
          })
          .eq('usuario_id', usuarioId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UsuarioModel>> obtenerVacunadoresPorSector(int sectorId) async {
    final data = await _supabase
        .from('asignaciones_sectores')
        .select('''
          usuario_id,
          perfiles:usuario_id (
            id,
            cedula,
            nombres,
            apellidos,
            correo,
            telefono,
            rol
          )
        ''')
        .eq('sector_id', sectorId)
        .eq('perfiles.rol', 'vacunador');

    return (data as List)
        .map((e) => UsuarioModel.fromJson(e['perfiles']))
        .toList();
  }
}