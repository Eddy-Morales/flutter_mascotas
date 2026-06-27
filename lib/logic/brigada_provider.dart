import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/database_service.dart';
import '../data/models/usuario_model.dart';

class BrigadaProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _sectorAsignado;
  List<UsuarioModel> _vacunadores = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Estadísticas del sector
  int _totalVacunados = 0;
  int _totalPerros = 0;
  int _totalGatos = 0;

  Map<String, dynamic>? get sectorAsignado => _sectorAsignado;
  List<UsuarioModel> get vacunadores => _vacunadores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalVacunados => _totalVacunados;
  int get totalPerros => _totalPerros;
  int get totalGatos => _totalGatos;

  // Obtener el sector asignado al coordinador
  Future<void> cargarSectorCoordinador(String coordinadorId) async {
    _setLoading(true);

    try {
      final data = await _supabase
          .from('asignaciones_sectores')
          .select('sectores(id, nombre)')
          .eq('usuario_id', coordinadorId)
          .maybeSingle();

      if (data != null && data['sectores'] != null) {
        _sectorAsignado = Map<String, dynamic>.from(data['sectores']);

        // Cargar automáticamente las estadísticas del sector
        await cargarEstadisticasSector();
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // Cargar estadísticas del sector asignado
  Future<void> cargarEstadisticasSector() async {
    if (_sectorAsignado == null) return;

    try {
      final datos = await _dbService.obtenerEstadisticasSector(
        _sectorAsignado!['id'],
      );

      _totalVacunados = datos['vacunados'] ?? 0;
      _totalPerros = datos['perros'] ?? 0;
      _totalGatos = datos['gatos'] ?? 0;

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Obtener vacunadores
  Future<void> cargarVacunadores() async {
    _setLoading(true);

    try {
      _vacunadores = await _dbService.obtenerUsuariosPorRol('vacunador');

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // Registrar un nuevo vacunador
  Future<bool> registrarVacunador({
    required String cedula,
    required String nombres,
    required String apellidos,
    required String telefono,
    required String correo,
    required int sectorId,
    required String creadorId,
  }) async {
    _setLoading(true);

    try {
      await _dbService.crearUsuarioPorRol(
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: 'vacunador',
      );

      final lista = await _dbService.obtenerUsuariosPorRol('vacunador');

      final nuevoVacunador = lista.firstWhere(
        (u) => u.cedula == cedula,
      );

      await _dbService.asignarUsuarioASector(
        nuevoVacunador.id,
        sectorId,
        creadorId,
      );

      await cargarVacunadores();

      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}