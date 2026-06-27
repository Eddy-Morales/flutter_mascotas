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
  /// Crea un usuario nuevo (vacunador o coordinador_brigada) y devuelve su UUID.
  /// IMPORTANTE: signUp() cambia la sesión activa al nuevo usuario. Aquí se
  /// restaura la sesión del coordinador ANTES de hacer el upsert en perfiles,
  /// para que la operación se ejecute con los permisos correctos.
  Future<String> crearUsuarioPorRol({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required String rol,
  }) async {
    final sessionActual = _supabase.auth.currentSession;
    String? nuevoUserId;

    try {
      // signUp() registra el usuario Y cambia la sesión activa al nuevo usuario.
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
      nuevoUserId = response.user?.id;
    } finally {
      // Restaurar la sesión del coordinador ANTES del upsert.
      // Así el upsert se ejecuta con los permisos del coordinador, no del vacunador.
      if (sessionActual != null) {
        await _supabase.auth.setSession(sessionActual.refreshToken!);
      }
    }

    if (nuevoUserId == null) {
      throw Exception('signUp no devolvió un usuario. Verifica que la confirmación de email esté desactivada en Supabase.');
    }

    // El trigger handle_new_user puede haber insertado ya el perfil.
    // Usamos upsert para garantizar que los datos sean correctos sin error de duplicado.
    await _supabase.from('perfiles').upsert({
      'id': nuevoUserId,
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'correo': correo,
      'rol': rol,
      'requiere_cambio_clave': true,
    });

    return nuevoUserId;
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

  // Obtener todas las vacunaciones de un sector (para el coordinador de brigada)
  Future<List<Map<String, dynamic>>> obtenerVacunacionesPorSector(int sectorId) async {
    try {
      final data = await _supabase
          .from('vacunaciones')
          .select('*, perfiles:vacunador_id(nombres, apellidos)')
          .eq('sector_id', sectorId)
          .order('fecha_hora', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      rethrow;
    }
  }

  // Corregir un registro de vacunación (usado por el coordinador de brigada)
  Future<void> corregirVacunacion({
    required int registroId,
    required String nombreMascota,
    required String edadAproximada,
    required String observaciones,
    required String coordinadorId,
    String? nombrePropietario,
    String? cedulaPropietario,
    String? telefonoPropietario,
    String? tipoMascota,
    String? sexoMascota,
    String? vacunaAplicada,
  }) async {
    try {
      await _supabase.from('vacunaciones').update({
        'nombre_mascota': nombreMascota,
        'edad_aproximada': edadAproximada,
        'observaciones': observaciones,
        'modificado_por': coordinadorId,
        'ultima_modificacion': DateTime.now().toIso8601String(),
        if (nombrePropietario != null && nombrePropietario.isNotEmpty)
          'nombre_propietario': nombrePropietario,
        if (cedulaPropietario != null && cedulaPropietario.isNotEmpty)
          'cedula_propietario': cedulaPropietario,
        if (telefonoPropietario != null && telefonoPropietario.isNotEmpty)
          'telefono_propietario': telefonoPropietario,
        if (tipoMascota != null) 'tipo_mascota': tipoMascota,
        if (sexoMascota != null) 'sexo_mascota': sexoMascota,
        if (vacunaAplicada != null && vacunaAplicada.isNotEmpty)
          'vacuna_aplicada': vacunaAplicada,
      }).eq('id', registroId);
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
    // Paso 1: obtener los IDs de usuarios asignados a este sector.
    // Consulta simple y directa, sin joins que puedan fallar al filtrar.
    final asignaciones = await _supabase
        .from('asignaciones_sectores')
        .select('usuario_id')
        .eq('sector_id', sectorId);

    if ((asignaciones as List).isEmpty) return [];

    final ids = asignaciones.map((e) => e['usuario_id'] as String).toList();

    // Paso 2: obtener perfiles cuyo id esté en esa lista Y rol sea vacunador.
    final data = await _supabase
        .from('perfiles')
        .select()
        .eq('rol', 'vacunador')
        .inFilter('id', ids);

    return (data as List).map((e) => UsuarioModel.fromJson(e)).toList();
  }
}