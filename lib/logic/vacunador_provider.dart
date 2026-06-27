import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class VacunadorProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  
  // Variables de captura de Hardware
  Position? _posicionActual;
  XFile? _fotoCapturada;
  Uint8List? _webImageBytes; // Requerido para previsualizar y subir desde Chrome Web

  // Listado de registros asignados al vacunador logueado
  List<Map<String, dynamic>> _misRegistros = [];

  // Getters públicos
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Position? get posicionActual => _posicionActual;
  XFile? get fotoCapturada => _fotoCapturada;
  Uint8List? get webImageBytes => _webImageBytes;
  List<Map<String, dynamic>> get misRegistros => _misRegistros;

  // 1. Obtener la ubicación GPS real desde el navegador o dispositivo
  Future<void> obtenerUbicacion() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados por el usuario.';
        }
      }
      
      _posicionActual = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // 2. Activar la interfaz de la cámara nativa
  Future<void> tomarFoto() async {
    _errorMessage = null;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Compresión óptima para almacenamiento eficiente
      );
      
      if (image != null) {
        _fotoCapturada = image;
        _webImageBytes = await image.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Error al abrir la cámara: ${e.toString()}";
      notifyListeners();
    }
  }

  // 3. Guardar el registro de vacunación completo en la tabla 'vacunaciones'
  Future<bool> registrarVacunacion({
    required String nombreMascota,
    required String especie,       // Debe mapear a tu ENUM pet_type ('perro' o 'gato')
    required String edad,          // Recibe texto (Ej: "2 años", "6 meses")
    required String color,         // Se concatena en observaciones
    required String observacion,
    required String vacunadorId,
    required int sectorId,
    // Parámetros por defecto para cumplir las restricciones NOT NULL de tu tabla
    String nombrePropietario = "Por Registrar",
    String cedulaPropietario = "0000000000",
    String telefonoPropietario = "0000000000",
    String sexoMascota = "macho",   // Debe mapear a tu ENUM pet_sex ('macho' o 'hembra')
    String vacunaAplicada = "Antirrábica Campaña 2026",
  }) async {
    if (_posicionActual == null || _fotoCapturada == null) {
      _errorMessage = "Es obligatorio capturar la foto de la mascota y la ubicación GPS.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    
    try {
      // A. Subir la imagen al bucket público 'mascotas'
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('mascotas').uploadBinary(
        fileName,
        _webImageBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      // Obtener la URL estática generada por Supabase Storage
      final String fotoUrl = _supabase.storage.from('mascotas').getPublicUrl(fileName);

      // B. Insertar la fila en tu tabla real respetando las restricciones de clave foránea
      await _supabase.from('vacunaciones').insert({
        'vacunador_id': vacunadorId,
        'sector_id': sectorId,
        'nombre_propietario': nombrePropietario,
        'cedula_propietario': cedulaPropietario,
        'telefono_propietario': telefonoPropietario,
        'tipo_mascota': especie,
        'nombre_mascota': nombreMascota,
        'edad_aproximada': edad,
        'sexo_mascota': sexoMascota,
        'vacuna_aplicada': vacunaAplicada,
        'observaciones': '$observacion | Rasgos/Color: $color',
        'url_fotografia': fotoUrl,
        'latitud': _posicionActual!.latitude,
        'longitud': _posicionActual!.longitude,
      });

      // Limpiar el estado local de hardware para el siguiente registro
      _fotoCapturada = null;
      _webImageBytes = null;
      _posicionActual = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
      return false;
    }
  }

  // 4. Cargar solo las vacunaciones realizadas por el vacunador logueado
  Future<void> cargarMisRegistros(String vacunadorId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _supabase
          .from('vacunaciones')
          .select('*, sectores(nombre)')
          .eq('vacunador_id', vacunadorId)
          .order('fecha_hora', ascending: false);

      _misRegistros = List<Map<String, dynamic>>.from(res);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = e.toString();
    }
  }

  // 5. Editar un registro propio — todos los campos relevantes excepto GPS y foto
  Future<bool> actualizarRegistroPropio({
    required int registroId,
    required String nombreMascota,
    required String edadAproximada,
    required String observaciones,
    required String usuarioModificadorId,
    // Campos adicionales ahora editables
    String? nombrePropietario,
    String? cedulaPropietario,
    String? telefonoPropietario,
    String? tipoMascota,   // 'perro' | 'gato'
    String? sexoMascota,   // 'macho' | 'hembra'
    String? vacunaAplicada,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _supabase.from('vacunaciones').update({
        'nombre_mascota': nombreMascota,
        'edad_aproximada': edadAproximada,
        'observaciones': observaciones,
        'modificado_por': usuarioModificadorId,
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

      _setLoading(false);
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