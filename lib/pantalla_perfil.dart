import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'usuario_dao.dart';

class PantallaPerfil extends StatefulWidget {
  final Map<String, dynamic>? psicologo; // Si es nulo, es el perfil propio

  const PantallaPerfil({super.key, this.psicologo});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final usuarioDAO = UsuarioDAO(Supabase.instance.client);
  final picker = ImagePicker();

  bool cargando = true;
  bool esPerfilPropio = true;

  File? fotoLocal;
  late String nombre;
  late String apellidos;
  late String descripcion;
  late String foto;

  @override
  void initState() {
    super.initState();

    if (widget.psicologo != null) {
      esPerfilPropio = false;
      final u = widget.psicologo!;
      nombre = u['nombre'];
      apellidos = u['apellidos'];
      descripcion = u['descripcion'] ?? '';
      foto = u['foto_perfil'] ?? '';
      cargando = false;
    } else {
      _cargarPerfilPropio();
    }
  }

  Future<void> _cargarPerfilPropio() async {
    final datos = await usuarioDAO.getUsuarioActual();

    nombre = datos?['nombre'] ?? '';
    apellidos = datos?['apellidos'] ?? '';
    descripcion = datos?['descripcion'] ?? '';
    foto = datos?['foto_perfil'] ?? '';

    setState(() => cargando = false);
  }

  /// ------------------------------------------------------
  /// Selecciona foto desde galería
  /// ------------------------------------------------------
  Future<void> _seleccionarImagen() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;
    setState(() => fotoLocal = File(picked.path));
  }

  /// ------------------------------------------------------
  /// Sube a Supabase Storage
  /// ------------------------------------------------------
  Future<String?> _subirImagen() async {
    if (fotoLocal == null) return foto;

    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    final ext = fotoLocal!.path.split('.').last;
    final path = '$uid/perfil.$ext';

    await supa.storage.from('perfiles').upload(
      path,
      fotoLocal!,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = supa.storage.from('perfiles').getPublicUrl(path);
    return url;
  }

  /// ------------------------------------------------------
  /// Guardar cambios
  /// ------------------------------------------------------
  Future<void> _guardar() async {
    setState(() => cargando = true);

    try {
      final nueva = await _subirImagen();
      if (nueva != null) foto = nueva;

      await usuarioDAO.actualizarPerfil(
        nombre: nombre,
        apellidos: apellidos,
        correo: '',
        telefono: '',
        descripcion: descripcion,
        foto: foto,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(esPerfilPropio ? "Mi perfil" : "Perfil"),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: esPerfilPropio ? _seleccionarImagen : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: fotoLocal != null
                          ? FileImage(fotoLocal!)
                          : (foto.isNotEmpty ? NetworkImage(foto) : null)
                              as ImageProvider?,
                      child: (foto.isEmpty && fotoLocal == null)
                          ? Text(
                              nombre.isNotEmpty ? nombre[0] : '?',
                              style: const TextStyle(fontSize: 38),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "$nombre $apellidos",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(descripcion),

                  if (esPerfilPropio) ...[
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A80),
                      ),
                      child: const Text("Guardar cambios"),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
