class UsuarioModel {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String correo;
  final String rol;
  final bool requiereCambioClave;

  UsuarioModel({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.correo,
    required this.rol,
    required this.requiereCambioClave,
  });

  // Convierte un JSON de la base de datos a un Objeto Dart
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      cedula: json['cedula'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      telefono: json['telefono'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'vacunador',
      requiereCambioClave: json['requiere_cambio_clave'] ?? true,
    );
  }

  // Permite obtener el nombre completo fácilmente en la UI
  String get nombreCompleto => '$nombres $apellidos';
}