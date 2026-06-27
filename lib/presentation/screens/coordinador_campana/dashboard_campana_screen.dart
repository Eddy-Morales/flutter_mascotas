import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/sector_provider.dart';

class DashboardCampanaScreen extends StatefulWidget {
  const DashboardCampanaScreen({super.key});

  @override
  State<DashboardCampanaScreen> createState() => _DashboardCampanaScreenState();
}

class _DashboardCampanaScreenState extends State<DashboardCampanaScreen> {
  final _sectorController = TextEditingController();
  
  // Controladores para registrar Coordinador de Brigada
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  int? _sectorSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sectorProv = Provider.of<SectorProvider>(context, listen: false);
      await sectorProv.cargarSectores();
      await sectorProv.cargarCoordinadores();
      await sectorProv.cargarMetricasGlobales();
    });
  }

  void _mostrarDialogoSector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Sector / Barrio'),
        content: TextField(
          controller: _sectorController,
          decoration: const InputDecoration(labelText: 'Nombre del Barrio (Ej: Centro, Sur)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_sectorController.text.trim().isEmpty) return;
              final res = await Provider.of<SectorProvider>(context, listen: false)
                  .agregarSector(_sectorController.text.trim());
              if (mounted) {
                Navigator.pop(context);
                _sectorController.clear();
                Provider.of<SectorProvider>(context, listen: false).cargarMetricasGlobales();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res ? 'Sector Creado' : 'Error al crear sector')),
                );
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoCoordinador(String creadorId, List<Map<String, dynamic>> sectores) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Coordinador de Brigada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _cedulaCtrl, decoration: const InputDecoration(labelText: 'Cédula')),
                TextField(controller: _nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres')),
                TextField(controller: _apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos')),
                TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                TextField(controller: _correoCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  hint: const Text('Asignar Sector (Obligatorio)'),
                  value: _sectorSeleccionado,
                  items: sectores.map((s) {
                    return DropdownMenuItem<int>(value: s['id'], child: Text(s['nombre']));
                  }).toList(),
                  onChanged: (val) => setModalState(() => _sectorSeleccionado = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (_sectorSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, asigne un sector obligatoriamente.'), backgroundColor: Colors.orange),
                  );
                  return; 
                }
                if (_cedulaCtrl.text.trim().isEmpty || _nombresCtrl.text.trim().isEmpty || _correoCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, llene los campos obligatorios.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final exito = await Provider.of<SectorProvider>(context, listen: false)
                    .registrarCoordinadorYAsignar(
                  cedula: _cedulaCtrl.text.trim(),
                  nombres: _nombresCtrl.text.trim(),
                  apellidos: _apellidosCtrl.text.trim(),
                  telefono: _telefonoCtrl.text.trim(),
                  correo: _correoCtrl.text.trim(),
                  sectorId: _sectorSeleccionado,
                  creadorId: creadorId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _cedulaCtrl.clear(); _nombresCtrl.clear(); _apellidosCtrl.clear();
                  _telefonoCtrl.clear(); _correoCtrl.clear(); _sectorSeleccionado = null;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(exito ? 'Coordinador registrado con contraseña: Ecuador2026' : 'Error al registrar')),
                  );
                }
              },
              child: const Text('Registrar'),
            )
          ],
        ),
      ),
    );
  }

  // Helper para generar las secciones de forma compatible con fl_chart 0.69+
  List<PieChartSectionData> _obtenerSeccionesGrafico(int perros, int gatos) {
    return [
      PieChartSectionData(
        color: Colors.blue,
        value: perros.toDouble() == 0 && gatos.toDouble() == 0 ? 1 : perros.toDouble(),
        title: perros > 0 ? 'Perros ($perros)' : 'Perros',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: perros.toDouble() == 0 && gatos.toDouble() == 0 ? 0 : gatos.toDouble(),
        title: gatos > 0 ? 'Gatos ($gatos)' : 'Gatos',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sectorProvider = Provider.of<SectorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo General'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => sectorProvider.cargarMetricasGlobales(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.salir(),
          )
        ],
      ),
      body: sectorProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido, ${authProvider.usuarioActual?.nombres}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 15),

                // --- SECCIÓN KPIs ---
                Row(
                  children: [
                    _buildCardKpi("Vacunados", sectorProvider.totalVacunados.toString(), Colors.green, Icons.health_and_safety),
                    const SizedBox(width: 10),
                    _buildCardKpi("Perros", sectorProvider.totalPerros.toString(), Colors.blue, Icons.pets),
                    const SizedBox(width: 10),
                    _buildCardKpi("Gatos", sectorProvider.totalGatos.toString(), Colors.orange, Icons.pets_outlined),
                  ],
                ),
                const SizedBox(height: 25),

                // --- SECCIÓN ACCIONES RÁPIDAS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: _mostrarDialogoSector,
                      icon: const Icon(Icons.map),
                      label: const Text('Crear Sector / Barrio'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () => _mostrarDialogoCoordinador(authProvider.usuarioActual!.id, sectorProvider.sectores),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Crear Coordinador'),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // --- GRÁFICO 1: DISTRIBUCIÓN POR ESPECIE (Corregido estructuralmente) ---
                const Text('Distribución de Especies Vacunadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: sectorProvider.totalVacunados == 0
                      ? const Center(child: Text("No hay datos de vacunas registrados en el sistema.", style: TextStyle(color: Colors.grey)))
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 45,
                            sections: _obtenerSeccionesGrafico(
                              sectorProvider.totalPerros, 
                              sectorProvider.totalGatos
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 25),

                // --- LISTA DE MONITOREO DE SECTORES ---
                const Text('Cobertura Territorial por Sector', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sectorProvider.vacunacionesPorSector.length,
                  itemBuilder: (context, index) {
                    final itemSector = sectorProvider.vacunacionesPorSector[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.location_city, color: Colors.white, size: 20),
                        ),
                        title: Text(itemSector['nombre'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${itemSector['cantidad']} Vacunas',
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
    );
  }

  Widget _buildCardKpi(String titulo, String valor, Color color, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(titulo, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}