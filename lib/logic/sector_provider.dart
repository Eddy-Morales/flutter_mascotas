import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/database_service.dart';
import '../data/models/usuario_model.dart';

class SectorProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _sectores = [];
  List<UsuarioModel> _coordinadores = [];
  bool _isLoading = false;
  String? _errorMessage;

  // --- VARIABLES PARA EL DASHBOARD ANALÍTICO GENERAL (fl_chart 0.69+) ---
  int _totalVacunados = 0;
  int _totalPerros = 0;
  int _totalGatos = 0;
  List<Map<String, dynamic>> _vacunacionesPorSector = [];

  // Getters públicos
  List<Map<String, dynamic>> get sectores => _sectores;
  List<UsuarioModel> get coordinadores => _coordinadores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalVacunados => _totalVacunados;
  int get totalPerros => _totalPerros;
  int get totalGatos => _totalGatos;
  List<Map<String, dynamic>> get vacunacionesPorSector => _vacunacionesPorSector;

  // 1. Cargar todos los sectores de la base de datos
  Future<void> cargarSectores() async {
    _setLoading(true);
    try {
      final res = await _supabase
          .from('sectores')
          .select('id, nombre')
          .order('nombre', ascending: true);
      
      _sectores = List<Map<String, dynamic>>.from(res);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // 2. Agregar un nuevo sector o barrio a la campaña
  Future<bool> agregarSector(String nombreSector) async {
    _setLoading(true);
    try {
      await _supabase.from('sectores').insert({
        'nombre': nombreSector.trim(),
      });
      await cargarSectores();
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      return false;
    }
  }

  // 3. Obtener el listado de todos los Coordinadores de Brigada
  Future<void> cargarCoordinadores() async {
    _setLoading(true);
    try {
      _coordinadores = await _dbService.obtenerUsuariosPorRol('coordinador_brigada');
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // 4. Crear un Coordinador de Brigada y asignarle obligatoriamente su sector
  Future<bool> registrarCoordinadorYAsignar({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required int? sectorId,
    required String creadorId,
  }) async {
    if (sectorId == null) {
      _errorMessage = "El sector es obligatorio para el blindaje relacional.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      // A. Crear la cuenta en auth.users y registrarlo en perfiles usando tu servicio base
      await _dbService.crearUsuarioPorRol(
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: 'coordinador_brigada',
      );

      // B. Consultar el ID generado para vincularlo al sector correspondiente
      final listaActualizada = await _dbService.obtenerUsuariosPorRol('coordinador_brigada');
      final nuevoCoordinador = listaActualizada.firstWhere((u) => u.cedula == cedula);

      // C. Insertar la asignación en tu tabla de rompimiento/relacional
      await _dbService.asignarUsuarioASector(nuevoCoordinador.id, sectorId, creadorId);
      
      await cargarCoordinadores();
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      return false;
    }
  }

  // 5. NUEVO MÉTODO: Compilar métricas analíticas en tiempo real
  Future<void> cargarMetricasGlobales() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Consultar la tabla relacional definitiva 'vacunaciones'
      final List<dynamic> resVacunaciones = await _supabase
          .from('vacunaciones')
          .select('tipo_mascota, sector_id');
      
      _totalVacunados = resVacunaciones.length;
      
      // Conteo por especie basándonos en los ENUMs almacenados
      _totalPerros = resVacunaciones.where((v) => v['tipo_mascota'] == 'perro').length;
      _totalGatos = resVacunaciones.where((v) => v['tipo_mascota'] == 'gato').length;

      // Agrupar las estadísticas calculadas para cada uno de los sectores cargados
      _vacunacionesPorSector = _sectores.map((sector) {
        final conteo = resVacunaciones.where((v) => v['sector_id'] == sector['id']).length;
        return {
          'id': sector['id'],
          'nombre': sector['nombre'],
          'cantidad': conteo,
        };
      }).toList();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // Helper de control de estados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}