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

  int _totalVacunados = 0;
  int _totalPerros = 0;
  int _totalGatos = 0;

  // GETTERS
  Map<String, dynamic>? get sectorAsignado => _sectorAsignado;
  List<UsuarioModel> get vacunadores => _vacunadores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalVacunados => _totalVacunados;
  int get totalPerros => _totalPerros;
  int get totalGatos => _totalGatos;

  // =========================
  // SECTOR COORDINADOR
  // =========================
  Future<void> cargarSectorCoordinador(String coordinadorId) async {
    _setLoading(true);

    try {
      final data = await _supabase
          .from('asignaciones_sectores')
          .select('sectores(id, nombre)')
          .eq('usuario_id', coordinadorId)
          .maybeSingle();

      if (data != null && data['sectores'] != null) {
        _sectorAsignado =
            Map<String, dynamic>.from(data['sectores']);

        await _cargarTodoDelSector();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // CARGA COMPLETA
  // =========================
  Future<void> _cargarTodoDelSector() async {
    if (_sectorAsignado == null) return;

    await cargarEstadisticasSector();
    await cargarVacunadoresPorSector(_sectorAsignado!['id']);
  }

  // =========================
  // ESTADÍSTICAS
  // =========================
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
    }
  }

  // =========================
  // VACUNADORES POR SECTOR (ÚNICO)
  // =========================
  Future<void> cargarVacunadoresPorSector(int sectorId) async {
    _setLoading(true);

    try {
      _vacunadores =
          await _dbService.obtenerVacunadoresPorSector(sectorId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // REGISTRAR VACUNADOR
  // =========================
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
      // crearUsuarioPorRol devuelve el UUID del nuevo usuario directamente,
      // evitando la búsqueda extra por cédula que podía fallar por timing.
      final nuevoId = await _dbService.crearUsuarioPorRol(
        cedula: cedula,
        nombres: nombres,
        apellidos: apellidos,
        telefono: telefono,
        correo: correo,
        rol: 'vacunador',
      );

      await _dbService.asignarUsuarioASector(
        nuevoId,
        sectorId,
        creadorId,
      );

      await cargarVacunadoresPorSector(sectorId);
      await cargarEstadisticasSector();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // REASIGNAR VACUNADOR
  // =========================
  Future<bool> reasignarVacunador({
    required String usuarioId,
    required int nuevoSectorId,
    required String adminId,
  }) async {
    _setLoading(true);

    try {
      await _dbService.reasignarUsuarioASector(
        usuarioId,
        nuevoSectorId,
        adminId,
      );

      // 🔥 IMPORTANTE: recargar del sector actual, no global
      if (_sectorAsignado != null) {
        await cargarVacunadoresPorSector(_sectorAsignado!['id']);
      }

      await cargarEstadisticasSector();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // RECARGA GENERAL
  // =========================
  Future<void> recargarTodo(String coordinadorId) async {
    await cargarSectorCoordinador(coordinadorId);
  }

  // =========================
  // LOADING
  // =========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =========================
  // FALLBACK GENERAL
  // =========================
  Future<void> cargarVacunadores() async {
    if (_sectorAsignado == null) return;

    await cargarVacunadoresPorSector(_sectorAsignado!['id']);
  }
}