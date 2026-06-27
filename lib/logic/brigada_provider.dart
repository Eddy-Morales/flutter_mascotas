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

  Map<String, dynamic>? get sectorAsignado => _sectorAsignado;
  List<UsuarioModel> get vacunadores => _vacunadores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 1. Buscar qué sector tiene asignado el coordinador actual
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
      }
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // 2. Obtener la lista de vacunadores registrados en el sistema
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

  // 3. Crear un nuevo Vacunador y asignarlo automáticamente a su sector
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

      // Buscamos el ID asignado al vacunador recién creado
      final lista = await _dbService.obtenerUsuariosPorRol('vacunador');
      final nuevoVacunador = lista.firstWhere((u) => u.cedula == cedula);

      // Lo vinculamos relacionalmente al sector de la brigada
      await _dbService.asignarUsuarioASector(nuevoVacunador.id, sectorId, creadorId);
      
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