import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_provider.dart';
import '../../../logic/brigada_provider.dart';
import '../../../logic/vacunador_provider.dart';

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
  String _especieSeleccionada = 'perro';

  // Controladores para el diálogo de edición
  final _editNombreCtrl = TextEditingController();
  final _editEdadCtrl = TextEditingController();
  final _editObsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).usuarioActual!;
      Provider.of<BrigadaProvider>(context, listen: false).cargarSectorCoordinador(user.id);
      Provider.of<VacunadorProvider>(context, listen: false).cargarMisRegistros(user.id);
    });
  }

  void _mostrarDialogoEditar(Map<String, dynamic> registro, String usuarioId) {
    _editNombreCtrl.text = registro['nombre_mascota'] ?? '';
    _editEdadCtrl.text = registro['edad_aproximada'] ?? '';
    _editObsCtrl.text = registro['observaciones'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Registro Propio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _editNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Mascota')),
              TextField(controller: _editEdadCtrl, decoration: const InputDecoration(labelText: 'Edad (Ej: 2 años)')),
              TextField(controller: _editObsCtrl, decoration: const InputDecoration(labelText: 'Observaciones / Rasgos'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final exito = await Provider.of<VacunadorProvider>(context, listen: false).actualizarRegistroPropio(
                registroId: registro['id'],
                nombreMascota: _editNombreCtrl.text.trim(),
                edadAproximada: _editEdadCtrl.text.trim(),
                observaciones: _editObsCtrl.text.trim(),
                usuarioModificadorId: usuarioId,
              );
              if (mounted) {
                Navigator.pop(context);
                Provider.of<VacunadorProvider>(context, listen: false).cargarMisRegistros(usuarioId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(exito ? 'Registro actualizado correctamente' : 'Error al actualizar')),
                );
              }
            },
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
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
              onPressed: () => vacunadorProvider.cargarMisRegistros(user.id)
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => authProvider.salir())
          ],
        ),
        body: TabBarView(
          children: [
            // --- PESTAÑA 1: FORMULARIO DE REGISTRO ---
            vacunadorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            color: Colors.blue.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.pin_drop, color: Colors.blueAccent),
                              title: const Text('Barrio de Trabajo asignado:'),
                              subtitle: Text(sector != null ? sector['nombre'].toString().toUpperCase() : 'Cargando sector...'),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextFormField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Mascota'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _especieSeleccionada,
                            items: const [
                              DropdownMenuItem(value: 'perro', child: Text('Perro')),
                              DropdownMenuItem(value: 'gato', child: Text('Gato')),
                            ],
                            onChanged: (val) => setState(() => _especieSeleccionada = val!),
                            decoration: const InputDecoration(labelText: 'Especie'),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(controller: _edadCtrl, decoration: const InputDecoration(labelText: 'Edad Estimada (Ej: 2 años / 6 meses)'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
                          TextFormField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Color / Rasgos particulares'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
                          TextFormField(controller: _observacionCtrl, decoration: const InputDecoration(labelText: 'Observaciones médicas')),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => vacunadorProvider.tomarFoto(),
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text(vacunadorProvider.fotoCapturada != null ? 'Foto OK ✔' : 'Tomar Foto'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => vacunadorProvider.obtenerUbicacion(),
                                  icon: const Icon(Icons.gps_fixed),
                                  label: Text(vacunadorProvider.posicionActual != null ? 'GPS OK ✔' : 'Capturar GPS'),
                                ),
                              ),
                            ],
                          ),
                          if (vacunadorProvider.webImageBytes != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15.0),
                              child: Image.memory(vacunadorProvider.webImageBytes!, height: 150, fit: BoxFit.cover),
                            ),
                          const SizedBox(height: 25),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
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
                              );

                              if (mounted && exito) {
                                _nombreCtrl.clear(); _edadCtrl.clear(); _colorCtrl.clear(); _observacionCtrl.clear();
                                vacunadorProvider.cargarMisRegistros(user.id);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Vacunación registrada con éxito!')));
                              }
                            },
                            child: const Text('Guardar Registro de Vacunación', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),

            // --- PESTAÑA 2: HISTORIAL Y EDICIÓN PROPIA ---
            vacunadorProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vacunadorProvider.misRegistros.isEmpty
                    ? const Center(child: Text('No tienes registros guardados aún.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: vacunadorProvider.misRegistros.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
                          final reg = vacunadorProvider.misRegistros[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  reg['url_fotografia'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 30),
                                ),
                              ),
                              title: Text(
                                '${reg['nombre_mascota'].toString().toUpperCase()} (${reg['tipo_mascota']})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Edad: ${reg['edad_aproximada']}'),
                                  Text('Obs: ${reg['observaciones']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (reg['ultima_modificacion'] != null)
                                    const Text(
                                      '⚠️ Editado por el vacunador',
                                      style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _mostrarDialogoEditar(reg, user.id),
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
}