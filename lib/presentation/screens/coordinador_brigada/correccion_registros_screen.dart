import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';
import '../../../data/services/database_service.dart';

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

class CorreccionRegistrosScreen extends StatefulWidget {
  const CorreccionRegistrosScreen({super.key});

  @override
  State<CorreccionRegistrosScreen> createState() => _CorreccionRegistrosScreenState();
}

class _CorreccionRegistrosScreenState extends State<CorreccionRegistrosScreen> {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _registros = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarRegistros());
  }

  Future<void> _cargarRegistros() async {
    final sectorId = context.read<BrigadaProvider>().sectorAsignado?['id'];
    if (sectorId == null) {
      setState(() { _cargando = false; _error = 'Sin sector asignado.'; });
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await _db.obtenerVacunacionesPorSector(sectorId);
      setState(() { _registros = data; _cargando = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  void _abrirCorreccion(Map<String, dynamic> registro, String coordinadorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditarRegistroCoordinadorScreen(
          registro: registro,
          coordinadorId: coordinadorId,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _cargarRegistros();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final coordId = auth.usuarioActual!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corregir Registros del Sector'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargarRegistros,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _registros.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay registros de vacunacion en tu sector.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _registros.length,
                      itemBuilder: (context, index) {
                        final reg = _registros[index];
                        final vacunador = reg['perfiles'];
                        final nombreVacunador = vacunador != null
                            ? '${vacunador['nombres']} ${vacunador['apellidos']}'
                            : 'Sin vacunador';
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
                                errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 30),
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
                                  'Vacunador: $nombreVacunador',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                if (fueEditado)
                                  const Text(
                                    'Corregido',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.teal, size: 28),
                              tooltip: 'Corregir',
                              onPressed: () => _abrirCorreccion(reg, coordId),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// ──────────────────────────────────────────────
// Pantalla de edicion para Coordinador (pantalla completa)
// ──────────────────────────────────────────────
class _EditarRegistroCoordinadorScreen extends StatefulWidget {
  final Map<String, dynamic> registro;
  final String coordinadorId;

  const _EditarRegistroCoordinadorScreen({
    required this.registro,
    required this.coordinadorId,
  });

  @override
  State<_EditarRegistroCoordinadorScreen> createState() => _EditarRegistroCoordinadorScreenState();
}

class _EditarRegistroCoordinadorScreenState extends State<_EditarRegistroCoordinadorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  bool _guardando = false;

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _edadCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _propietarioCtrl;
  late final TextEditingController _cedulaCtrl;
  late final TextEditingController _telefonoCtrl;
  late String _tipoMascota;
  late String _sexoMascota;
  late String _vacunaAplicada;
  late TextEditingController _otraVacunaCtrl;

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
    _otraVacunaCtrl = TextEditingController(
      text: _vacunaAplicada == 'Otra' ? vacunaDb : '',
    );
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
    final vacunador = widget.registro['perfiles'];
    final nombreVacunador = vacunador != null
        ? '${vacunador['nombres']} ${vacunador['apellidos']}'
        : 'Desconocido';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Corregir Registro'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info del vacunador original
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informacion del Registro',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 4),
                      Text('Registrado por Vacunador: $nombreVacunador', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                color: Colors.teal,
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
                    TextFormField(
                      controller: _otraVacunaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Especificar vacuna',
                        prefixIcon: const Icon(Icons.edit),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (_vacunaAplicada == 'Otra' && (v == null || v.isEmpty))
                          ? 'Ingrese el nombre de la vacuna'
                          : null,
                    ),
                  ],
                  _field(_obsCtrl, 'Observaciones', Icons.notes, maxLines: 3),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECCIÓN: Propietario ──
              _buildSectionCard(
                title: 'Datos del Propietario',
                icon: Icons.person,
                color: Colors.blueGrey,
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
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _guardando
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _guardando = true);
                        try {
                          final obsConcatenada = '${_obsCtrl.text.trim()} | Rasgos/Color: ${_colorCtrl.text.trim()}';
                          await _db.corregirVacunacion(
                            registroId: widget.registro['id'],
                            nombreMascota: _nombreCtrl.text.trim(),
                            edadAproximada: _edadCtrl.text.trim(),
                            observaciones: obsConcatenada,
                            coordinadorId: widget.coordinadorId,
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
                              const SnackBar(
                                content: Text('Registro corregido correctamente'),
                                backgroundColor: Colors.teal,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _guardando = false);
                          }
                        }
                      },
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Guardar Correccion',
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
