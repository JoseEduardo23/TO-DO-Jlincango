import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'NewTaskPage.dart';
import 'LoginPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tareas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    final userId = supabase.auth.currentUser?.id;
    final response = await supabase
        .from('tareas')
        .select()
        .or('usuario_id.eq.$userId,compartida.eq.true')
        .order('timestamp', ascending: false);

    setState(() {
      tareas = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> marcarComoCompletada(String id, bool completada) async {
    await supabase.from('tareas').update({'estado': !completada}).eq('id', id);
    cargarTareas();
  }

  Future<void> eliminarTarea(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('tareas').delete().eq('id', id);
      cargarTareas();
    }
  }

  Future<void> cerrarSesion() async {
    await supabase.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tareas.isEmpty
              ? const Center(child: Text('No hay tareas registradas'))
              : ListView.builder(
                  itemCount: tareas.length,
                  itemBuilder: (context, index) {
                    final tarea = tareas[index];
                    final completada = tarea['estado'] == true;

                    // Obtener y formatear la hora desde el timestamp
                    final fecha = DateTime.tryParse(tarea['timestamp']);
                    final formatoHora = fecha != null
                        ? '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                        : 'Hora desconocida';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: tarea['imagen_url'] != null
                            ? Image.network(tarea['imagen_url'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.task),
                        title: Text(tarea['titulo']),
                        subtitle: Text(
                          '${completada ? 'Completada' : 'Pendiente'} • $formatoHora',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: completada,
                              onChanged: (_) =>
                                  marcarComoCompletada(tarea['id'], completada),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarTarea(tarea['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewTaskPage()),
          );
          cargarTareas(); // refrescar después de crear tarea
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}