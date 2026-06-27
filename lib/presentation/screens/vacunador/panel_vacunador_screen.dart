import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';
import '../../../logic/vacunador_provider.dart';

const List<String> _kVacunas = [
  'Antirrábica',
  'Antirrábica Campaña 2026',
  'Triple Felina (Panleucopenia, Rinotraqueitis, Calicivirus)',
  'Cuádruple Felina (+ Clamidiosis)',
  'Séxtuple Canina (DHPPI+L)',
  'Óctuple Canina (DHPPI+L+C)',
  'Parvovirus',
  'Moquillo',
  'Hepatitis Infecciosa Canina',
  'Tos de las Perreras (Bordetella)',
  'Leptospirosis',
  'Giardia Canina',
  'Leishmaniosis',
  'Otra',
];

class PanelVacunadorScreen extends StatefulWidget {
  const PanelVacunadorScreen({super.key});

  @override
  State<PanelVacunadorScreen> createState() => _PanelVacunadorScreenState();
}

class _PanelVacunadorScreenState extends State<PanelVacunadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();
  final _propietarioCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  String _especieSeleccionada = 'perro';
  String _sexoSeleccionado = 'macho';
  String _vacunaSeleccionada = 'Antirrábica';
  final _otraVacunaRegCtrl = TextEditingController();
  final _otraVacunaCtrl = TextEditingController();
  bool _esOtraVacuna = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).usuarioActual!;
      Provider.of<BrigadaProvider>(context, listen: false).cargarSectorCoordinador(user.id);
      Provider.of<VacunadorProvider>(context, listen: false).cargarMisRegistros(user.id);
    });
  }
  

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _colorCtrl.dispose();
    _observacionCtrl.dispose();
    _propietarioCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _otraVacunaCtrl.dispose();
    _otraVacunaRegCtrl.dispose();
    super.dispose();
  }

  // Navega a la pantalla de edición completa
  void _abrirEdicion(Map<String, dynamic> registro, String usuarioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditarRegistroScreen(
          registro: registro,
          usuarioId: usuarioId,
        ),
      ),
    ).then((_) {
      // Al volver, recargar la lista
      if (mounted) {
        Provider.of<VacunadorProvider>(context, listen: false)
            .cargarMisRegistros(usuarioId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final brigadaProvider = Provider.of<BrigadaProvider>(context);
    final vacunadorProvider = Provider.of<VacunadorProvider>(context);
    final sector = brigadaProvider.sectorAsignado;
    final user = authProvider.usuarioActual!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Vacunador: ${user.nombres}'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: 'Registrar Vacuna'),
              Tab(icon: Icon(Icons.history), text: 'Mis Registros'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => vacunadorProvider.cargarMisRegistros(user.id),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authProvider.salir(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // --- TAB 1: FORMULARIO DE REGISTRO ---
            vacunadorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sector asignado
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.pin_drop, color: Colors.blueAccent),
                              title: const Text('Barrio asignado:',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                sector != null
                                    ? sector['nombre'].toString().toUpperCase()
                                    : 'Cargando sector...',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.blueAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Mascota
                          const _SeccionLabel('Datos de la Mascota', Icons.pets),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nombreCtrl,
                            decoration: _inputDeco('Nombre de la Mascota', Icons.badge),
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _especieSeleccionada,
                            decoration: _inputDeco('Especie', Icons.category),
                            items: const [
                              DropdownMenuItem(value: 'perro', child: Text('Perro')),
                              DropdownMenuItem(value: 'gato', child: Text('Gato')),
                            ],
                            onChanged: (val) =>
                                setState(() => _especieSeleccionada = val!),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _sexoSeleccionado,
                            decoration: _inputDeco('Sexo', Icons.transgender),
                            items: const [
                              DropdownMenuItem(value: 'macho', child: Text('Macho')),
                              DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                            ],
                            onChanged: (val) =>
                                setState(() => _sexoSeleccionado = val!),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _edadCtrl,
                            decoration: _inputDeco('Edad estimada (Ej: 2 años)', Icons.cake),
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _colorCtrl,
                            decoration: _inputDeco('Color / Rasgos', Icons.palette),
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _observacionCtrl,
                            decoration: _inputDeco('Observaciones médicas', Icons.notes),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _vacunaSeleccionada,
                            decoration: _inputDeco('Vacuna Aplicada', Icons.vaccines),
                            isExpanded: true,
                            items: _kVacunas
                                .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) => setState(() {
                              _vacunaSeleccionada = val!;
                              if (val != 'Otra') _otraVacunaRegCtrl.clear();
                            }),
                          ),
                          if (_vacunaSeleccionada == 'Otra') ...[  
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _otraVacunaRegCtrl,
                              decoration: _inputDeco('Especificar vacuna', Icons.edit),
                              validator: (v) => (_vacunaSeleccionada == 'Otra' && (v == null || v.isEmpty))
                                  ? 'Ingrese el nombre de la vacuna'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Propietario
                          const _SeccionLabel('Datos del Propietario', Icons.person),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _propietarioCtrl,
                            decoration: _inputDeco('Nombre del Propietario', Icons.person_outline),
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _cedulaCtrl,
                            decoration: _inputDeco('Cédula', Icons.credit_card),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _telefonoCtrl,
                            decoration: _inputDeco('Teléfono', Icons.phone),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 20),

                          // Captura
                          const _SeccionLabel('Evidencia requerida', Icons.camera_alt),
                          const SizedBox(height: 8),

                          Consumer<VacunadorProvider>(
                            builder: (_, vacunadorProvider, __) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _CaptureButton(
                                          icon: Icons.camera_alt,
                                          label: vacunadorProvider.fotoCapturada != null
                                              ? 'Foto capturada'
                                              : 'Tomar Foto',
                                          done: vacunadorProvider.fotoCapturada != null,
                                          onTap: () => vacunadorProvider.tomarFoto(),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _CaptureButton(
                                          icon: Icons.gps_fixed,
                                          label: vacunadorProvider.posicionActual != null
                                              ? 'GPS capturado'
                                              : 'Capturar GPS',
                                          done: vacunadorProvider.posicionActual != null,
                                          onTap: () => vacunadorProvider.obtenerUbicacion(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (vacunadorProvider.webImageBytes != null) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        vacunadorProvider.webImageBytes!,
                                        height: 160,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                  if (vacunadorProvider.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        vacunadorProvider.errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              if (sector == null) return;
                              final exito = await vacunadorProvider.registrarVacunacion(
                                nombreMascota: _nombreCtrl.text.trim(),
                                especie: _especieSeleccionada,
                                edad: _edadCtrl.text.trim(),
                                color: _colorCtrl.text.trim(),
                                observacion: _observacionCtrl.text.trim(),
                                vacunadorId: user.id,
                                sectorId: sector['id'],
                                nombrePropietario: _propietarioCtrl.text.trim(),
                                cedulaPropietario: _cedulaCtrl.text.trim(),
                                telefonoPropietario: _telefonoCtrl.text.trim(),
                                sexoMascota: _sexoSeleccionado,
                                vacunaAplicada: _vacunaSeleccionada == 'Otra'
                                    ? _otraVacunaRegCtrl.text.trim()
                                    : _vacunaSeleccionada,
                              );
                              if (mounted && exito) {
                                _nombreCtrl.clear();
                                _edadCtrl.clear();
                                _colorCtrl.clear();
                                _observacionCtrl.clear();
                                _propietarioCtrl.clear();
                                _cedulaCtrl.clear();
                                _telefonoCtrl.clear();
                                setState(() {
                                  _especieSeleccionada = 'perro';
                                  _sexoSeleccionado = 'macho';
                                  _vacunaSeleccionada = 'Antirrábica';
                                });
                                _otraVacunaRegCtrl.clear();
                                vacunadorProvider.cargarMisRegistros(user.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vacunacion registrada con exito'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Registro',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),

            // --- TAB 2: HISTORIAL ---
            vacunadorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vacunadorProvider.misRegistros.isEmpty
                    ? const Center(
                        child: Text('No tienes registros guardados aún.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: vacunadorProvider.misRegistros.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final reg = vacunadorProvider.misRegistros[index];
                          final fueEditado = reg['ultima_modificacion'] != null;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    reg['url_fotografia'] ?? '',
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.pets, size: 30),
                                  ),
                                ),
                              title: Text(
                                '${(reg['nombre_mascota'] ?? '').toString().toUpperCase()} - ${reg['tipo_mascota'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Edad: ${reg['edad_aproximada'] ?? '-'}'),
                                  Text(
                                    'Propietario: ${reg['nombre_propietario'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  if (fueEditado)
                                    const Text(
                                      'Editado',
                                      style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                tooltip: 'Editar',
                                onPressed: () => _abrirEdicion(reg, user.id),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

// ──────────────────────────────────────────────
// Pantalla de edición completa (nueva ruta)
// ──────────────────────────────────────────────
class _EditarRegistroScreen extends StatefulWidget {
  final Map<String, dynamic> registro;
  final String usuarioId;

  const _EditarRegistroScreen({
    required this.registro,
    required this.usuarioId,
  });

  @override
  State<_EditarRegistroScreen> createState() => _EditarRegistroScreenState();
}

class _EditarRegistroScreenState extends State<_EditarRegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _edadCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _propietarioCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late TextEditingController _otraVacunaCtrl;
  late String _tipoMascota;
  late String _sexoMascota;
  late String _vacunaAplicada;

  @override
  void initState() {
    super.initState();
    final r = widget.registro;
    _nombreCtrl = TextEditingController(text: r['nombre_mascota'] ?? '');
    _edadCtrl = TextEditingController(text: r['edad_aproximada'] ?? '');

    // Parsear el color/rasgos de las observaciones
    final obsCompleta = r['observaciones'] ?? '';
    String color = '';
    String obs = obsCompleta;
    if (obsCompleta.contains(' | Rasgos/Color: ')) {
      final partes = obsCompleta.split(' | Rasgos/Color: ');
      obs = partes[0];
      color = partes[1];
    }
    _obsCtrl = TextEditingController(text: obs);
    _colorCtrl = TextEditingController(text: color);

    _propietarioCtrl =
        TextEditingController(text: r['nombre_propietario'] ?? '');
    _cedulaCtrl =
        TextEditingController(text: r['cedula_propietario'] ?? '');
    _telefonoCtrl =
        TextEditingController(text: r['telefono_propietario'] ?? '');
    _tipoMascota = r['tipo_mascota'] ?? 'perro';
    _sexoMascota = r['sexo_mascota'] ?? 'macho';
    final vacunaDb = r['vacuna_aplicada'] ?? 'Antirrábica';
    _vacunaAplicada = _kVacunas.contains(vacunaDb) ? vacunaDb : 'Otra';
    if (!_kVacunas.contains(vacunaDb) || vacunaDb == 'Otra') {
      _otraVacunaCtrl = TextEditingController(text: vacunaDb == 'Otra' ? '' : vacunaDb);
    } else {
      _otraVacunaCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _colorCtrl.dispose();
    _obsCtrl.dispose();
    _propietarioCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _otraVacunaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VacunadorProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Editar Registro'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto de referencia
              if (widget.registro['url_fotografia'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.registro['url_fotografia'],
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 20),

              // ── SECCIÓN: Mascota ──
              _buildSectionCard(
                title: 'Datos de la Mascota',
                icon: Icons.pets,
                color: Colors.blue,
                children: [
                  _field(_nombreCtrl, 'Nombre de la Mascota', Icons.badge,
                      required: true),
                  const SizedBox(height: 12),
                  _dropdown(
                    label: 'Especie',
                    value: _tipoMascota,
                    icon: Icons.category,
                    items: const [
                      DropdownMenuItem(value: 'perro', child: Text('Perro')),
                      DropdownMenuItem(value: 'gato', child: Text('Gato')),
                    ],
                    onChanged: (v) => setState(() => _tipoMascota = v!),
                  ),
                  const SizedBox(height: 12),
                  _dropdown(
                    label: 'Sexo',
                    value: _sexoMascota,
                    icon: Icons.transgender,
                    items: const [
                      DropdownMenuItem(value: 'macho', child: Text('Macho')),
                      DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                    ],
                    onChanged: (v) => setState(() => _sexoMascota = v!),
                  ),
                  const SizedBox(height: 12),
                  _field(_edadCtrl, 'Edad (Ej: 2 años / 6 meses)', Icons.cake,
                      required: true),
                  const SizedBox(height: 12),
                  _field(_colorCtrl, 'Color / Rasgos', Icons.palette, required: true),
                  const SizedBox(height: 12),
                  _dropdown(
                    label: 'Vacuna Aplicada',
                    value: _vacunaAplicada,
                    icon: Icons.vaccines,
                    items: _kVacunas
                        .map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _vacunaAplicada = v!;
                      if (v != 'Otra') _otraVacunaCtrl.clear();
                    }),
                  ),
                  if (_vacunaAplicada == 'Otra') ...[  
                    const SizedBox(height: 12),
                    _field(_otraVacunaCtrl, 'Especificar vacuna', Icons.edit,
                        required: _vacunaAplicada == 'Otra'),
                  ],
                  const SizedBox(height: 12),
                  _field(_obsCtrl, 'Observaciones', Icons.notes, maxLines: 3),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECCIÓN: Propietario ──
              _buildSectionCard(
                title: 'Datos del Propietario',
                icon: Icons.person,
                color: Colors.teal,
                children: [
                  _field(_propietarioCtrl, 'Nombre del Propietario',
                      Icons.person_outline),
                  const SizedBox(height: 12),
                  _field(_cedulaCtrl, 'Cédula', Icons.credit_card,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(_telefonoCtrl, 'Teléfono', Icons.phone,
                      keyboardType: TextInputType.phone),
                ],
              ),
              const SizedBox(height: 24),

              // Botón guardar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final obsConcatenada = '${_obsCtrl.text.trim()} | Rasgos/Color: ${_colorCtrl.text.trim()}';
                        final exito = await provider.actualizarRegistroPropio(
                          registroId: widget.registro['id'],
                          nombreMascota: _nombreCtrl.text.trim(),
                          edadAproximada: _edadCtrl.text.trim(),
                          observaciones: obsConcatenada,
                          usuarioModificadorId: widget.usuarioId,
                          nombrePropietario: _propietarioCtrl.text.trim(),
                          cedulaPropietario: _cedulaCtrl.text.trim(),
                          telefonoPropietario: _telefonoCtrl.text.trim(),
                          tipoMascota: _tipoMascota,
                          sexoMascota: _sexoMascota,
                          vacunaAplicada: _vacunaAplicada == 'Otra'
                              ? _otraVacunaCtrl.text.trim()
                              : _vacunaAplicada,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(exito
                                  ? 'Registro actualizado correctamente'
                                  : 'Error: ${provider.errorMessage}'),
                              backgroundColor:
                                  exito ? Colors.green : Colors.red,
                            ),
                          );
                          if (exito) Navigator.pop(context);
                        }
                      },
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Guardar Cambios',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ──────────────────────────────────────────────
// Widgets auxiliares
// ──────────────────────────────────────────────
class _SeccionLabel extends StatelessWidget {
  final String texto;
  final IconData icono;
  const _SeccionLabel(this.texto, this.icono);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icono, size: 18, color: Colors.blueAccent),
      const SizedBox(width: 6),
      Text(texto,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueAccent)),
    ]);
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: done ? Colors.green : Colors.blueAccent,
        side: BorderSide(color: done ? Colors.green : Colors.blueAccent),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onTap,
      icon: Icon(done ? Icons.check_circle : icon),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}