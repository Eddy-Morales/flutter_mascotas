import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';
import 'gestion_vacunadores_screen.dart';

class DashboardBrigadaScreen extends StatefulWidget {
  const DashboardBrigadaScreen({super.key});

  @override
  State<DashboardBrigadaScreen> createState() =>
      _DashboardBrigadaScreenState();
}

class _DashboardBrigadaScreenState extends State<DashboardBrigadaScreen> {
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final brigada = Provider.of<BrigadaProvider>(context, listen: false);

      await brigada.cargarSectorCoordinador(auth.usuarioActual!.id);

      final sector = brigada.sectorAsignado;

      if (sector != null && sector['id'] != null) {
        await brigada.cargarVacunadoresPorSector(sector['id']);
      }
    });
  }

  void _mostrarDialogoVacunador(String creadorId, int sectorId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nuevo Vacunador'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _cedulaCtrl,
                  decoration: const InputDecoration(labelText: 'Cédula')),
              TextField(
                  controller: _nombresCtrl,
                  decoration: const InputDecoration(labelText: 'Nombres')),
              TextField(
                  controller: _apellidosCtrl,
                  decoration: const InputDecoration(labelText: 'Apellidos')),
              TextField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(
                  controller: _correoCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Correo Electrónico')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_cedulaCtrl.text.isEmpty ||
                  _nombresCtrl.text.isEmpty ||
                  _correoCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, llene los datos obligatorios.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final exito =
                  await Provider.of<BrigadaProvider>(context, listen: false)
                      .registrarVacunador(
                cedula: _cedulaCtrl.text.trim(),
                nombres: _nombresCtrl.text.trim(),
                apellidos: _apellidosCtrl.text.trim(),
                telefono: _telefonoCtrl.text.trim(),
                correo: _correoCtrl.text.trim(),
                sectorId: sectorId,
                creadorId: creadorId,
              );

              if (mounted) {
                Navigator.pop(context);

                _cedulaCtrl.clear();
                _nombresCtrl.clear();
                _apellidosCtrl.clear();
                _telefonoCtrl.clear();
                _correoCtrl.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(exito
                        ? 'Vacunador asignado con éxito a tu sector.'
                        : 'Error al registrar'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final brigada = Provider.of<BrigadaProvider>(context);
    final sector = brigada.sectorAsignado;

    return Scaffold(
      appBar: AppBar(
        title: Text('Brigada: ${auth.usuarioActual?.nombres}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.salir(),
          )
        ],
      ),
      body: brigada.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTOR
                  Card(
                    color: Colors.teal.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.streetview,
                          color: Colors.teal, size: 40),
                      title: const Text(
                        'Sector bajo tu supervisión:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        sector != null
                            ? sector['nombre'].toString().toUpperCase()
                            : 'Buscando sector...',
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.teal,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ESTADÍSTICAS
                  const Text(
                    'Estadísticas del sector',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildStatCard(
                        'Vacunados',
                        brigada.totalVacunados.toString(),
                        Icons.health_and_safety,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Perros',
                        brigada.totalPerros.toString(),
                        Icons.pets,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Gatos',
                        brigada.totalGatos.toString(),
                        Icons.pets_outlined,
                        Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // VACUNADORES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vacunadores a cargo:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (sector != null)
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _mostrarDialogoVacunador(
                                  auth.usuarioActual!.id,
                                  sector['id']),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Añadir Vacunador'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const GestionVacunadoresScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.manage_accounts),
                              label: const Text('Gestionar Vacunadores'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LISTA
                  Expanded(
                    child: brigada.vacunadores.isEmpty
                        ? const Center(
                            child:
                                Text('No tienes vacunadores registrados.'),
                          )
                        : ListView.builder(
                            itemCount: brigada.vacunadores.length,
                            itemBuilder: (context, index) {
                              final v = brigada.vacunadores[index];

                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.badge,
                                        color: Colors.white),
                                  ),
                                  title: Text(v.nombreCompleto),
                                  subtitle: Text(
                                    'Cédula: ${v.cedula} | Correo: ${v.correo}',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}