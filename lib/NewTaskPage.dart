import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewTaskPage extends StatefulWidget {
  final VoidCallback? onTaskSaved; // callback para avisar al padre

  const NewTaskPage({super.key, this.onTaskSaved});

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _tituloController = TextEditingController();
  bool _estado = false;
  bool _compartida = false;
  File? _imagen;
  bool _isLoading = false;
  String? _mensajeError;

  final supabase = Supabase.instance.client;

  Future<String?> _subirImagen(String userId) async {
    if (_imagen == null) return null;
    try {
      final uuid = const Uuid().v4();
      final fileName = basename(_imagen!.path);
      final path = 'public/$userId/$uuid-$fileName';

      final bytes = await _imagen!.readAsBytes();
      await supabase.storage.from('tareasfotos').uploadBinary(path, bytes);
      return supabase.storage.from('tareasfotos').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _guardarTareaAsync() async {
    if (_tituloController.text.trim().isEmpty) {
      setState(() {
        _mensajeError = 'El título no puede estar vacío';
      });
      return false;
    }
    setState(() {
      _isLoading = true;
      _mensajeError = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final imageUrl = await _subirImagen(userId);
      await supabase.from('tareas').insert({
        'usuario_id': userId,
        'titulo': _tituloController.text.trim(),
        'estado': _estado,
        'compartida': _compartida,
        'imagen_url': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      setState(() {
        _mensajeError = 'Error al guardar la tarea';
      });
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _guardarTarea() async {
    final success = await _guardarTareaAsync();
    if (success) {
      if (widget.onTaskSaved != null) {
        widget.onTaskSaved!();
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva tarea')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mensajeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título de la tarea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _estado,
                  onChanged: (val) => setState(() => _estado = val ?? false),
                ),
                const Text('¿Está completada?'),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _compartida,
                  onChanged: (val) =>
                      setState(() => _compartida = val ?? false),
                ),
                const Text('¿Tarea compartida?'),
              ],
            ),
            const SizedBox(height: 16),
            _imagen != null
                ? Image.file(
                    _imagen!,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : const Text('No se ha seleccionado imagen'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() {
                    _imagen = File(picked.path);
                    _mensajeError = null;
                  });
                }
              },
              icon: const Icon(Icons.image),
              label: const Text('Seleccionar imagen'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardarTarea,
                      child: const Text('Guardar tarea'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
