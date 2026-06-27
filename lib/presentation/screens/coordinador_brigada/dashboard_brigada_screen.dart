import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';

class DashboardBrigadaScreen extends StatefulWidget {
  const DashboardBrigadaScreen({super.key});

  @override
  State<DashboardBrigadaScreen> createState() => _DashboardBrigadaScreenState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coordId =
          Provider.of<AuthProvider>(context, listen: false).usuarioActual!.id;

      final brigada =
          Provider.of<BrigadaProvider>(context, listen: false);

      brigada.cargarSectorCoordinador(coordId);
      brigada.cargarVacunadores();
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
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final brigadaProvider = Provider.of<BrigadaProvider>(context);
    final sector = brigadaProvider.sectorAsignado;

    return Scaffold(
      appBar: AppBar(
        title: Text('Brigada: ${authProvider.usuarioActual?.nombres}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.salir(),
          )
        ],
      ),
      body: brigadaProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ESTADÍSTICAS (NUEVO)
                  const Text(
                    'Estadísticas del sector',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildStatCard(
                        'Vacunados',
                        brigadaProvider.totalVacunados.toString(),
                        Icons.health_and_safety,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Perros',
                        brigadaProvider.totalPerros.toString(),
                        Icons.pets,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Gatos',
                        brigadaProvider.totalGatos.toString(),
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
                        ElevatedButton.icon(
                          onPressed: () => _mostrarDialogoVacunador(
                              authProvider.usuarioActual!.id,
                              sector['id']),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Añadir Vacunador'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LISTA VACUNADORES
                  Expanded(
                    child: brigadaProvider.vacunadores.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes vacunadores registrados todavía.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: brigadaProvider.vacunadores.length,
                            itemBuilder: (context, index) {
                              final vacunador =
                                  brigadaProvider.vacunadores[index];

                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.badge,
                                        color: Colors.white),
                                  ),
                                  title: Text(vacunador.nombreCompleto),
                                  subtitle: Text(
                                    'Cédula: ${vacunador.cedula} | Correo: ${vacunador.correo}',
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