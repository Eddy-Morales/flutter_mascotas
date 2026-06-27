import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';
import '../../../data/services/database_service.dart';

class GestionVacunadoresScreen extends StatefulWidget {
  const GestionVacunadoresScreen({super.key});

  @override
  State<GestionVacunadoresScreen> createState() =>
      _GestionVacunadoresScreenState();
}

class _GestionVacunadoresScreenState
    extends State<GestionVacunadoresScreen> {
  List<dynamic> _sectores = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth =
          Provider.of<AuthProvider>(context, listen: false);
      final brigada =
          Provider.of<BrigadaProvider>(context, listen: false);

      final coordId = auth.usuarioActual!.id;

      await brigada.cargarSectorCoordinador(coordId);

      if (brigada.sectorAsignado != null) {
        await brigada.cargarVacunadoresPorSector(
          brigada.sectorAsignado!['id'],
        );
      }

      await _cargarSectores();
    });
  }

  Future<void> _cargarSectores() async {
    final db = DatabaseService();
    final data = await db.obtenerSectores();

    setState(() {
      _sectores = data;
    });
  }

  void _mostrarDialogoReasignacion(
    String usuarioId,
    String adminId,
  ) {
    int? sectorSeleccionado;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reasignar Vacunador'),
              content: _sectores.isEmpty
                  ? const Text('Cargando sectores...')
                  : DropdownButton<int>(
                      value: sectorSeleccionado,
                      isExpanded: true,
                      hint: const Text('Selecciona un sector'),
                      items: _sectores.map((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text(s['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          sectorSeleccionado = value;
                        });
                      },
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: sectorSeleccionado == null
                      ? null
                      : () async {
                          final ok = await context
                              .read<BrigadaProvider>()
                              .reasignarVacunador(
                                usuarioId: usuarioId,
                                nuevoSectorId: sectorSeleccionado!,
                                adminId: adminId,
                              );

                          if (mounted) {
                            Navigator.pop(context);

                            final brigada = context.read<BrigadaProvider>();

                            if (brigada.sectorAsignado != null) {
                              await brigada.cargarVacunadoresPorSector(
                                brigada.sectorAsignado!['id'],
                              );
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Vacunador reasignado correctamente'
                                    : 'Error al reasignar'),
                              ),
                            );
                          }
                        },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final brigada = Provider.of<BrigadaProvider>(context);
    final sector = brigada.sectorAsignado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vacunadores'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () async {
              final coordId = auth.usuarioActual!.id;
              final brigada = context.read<BrigadaProvider>();
              await brigada.recargarTodo(coordId);
            },
          ),
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
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.teal,
                        size: 40,
                      ),
                      title: const Text(
                        'Tu sector actual',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        sector != null
                            ? sector['nombre']
                                .toString()
                                .toUpperCase()
                            : 'Sin sector asignado',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Vacunadores',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // LISTA
                  Expanded(
                    child: brigada.vacunadores.isEmpty
                        ? const Center(
                            child: Text('No hay vacunadores registrados'),
                          )
                        : ListView.builder(
                            itemCount: brigada.vacunadores.length,
                            itemBuilder: (context, index) {
                              final v = brigada.vacunadores[index];

                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Colors.teal,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(v.nombreCompleto),
                                  subtitle: Text(
                                    'Cédula: ${v.cedula}\nCorreo: ${v.correo}',
                                  ),
                                  isThreeLine: true,
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                    onPressed: () {
                                      _mostrarDialogoReasignacion(
                                        v.id,
                                        auth.usuarioActual!.id,
                                      );
                                    },
                                    child: const Text('Reasignar'),
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