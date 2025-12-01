import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'usuario_dao.dart';

class PantallaPerfil extends StatefulWidget {
  final Map<String, dynamic>? psicologo; // Si no viene, es tu perfil

  const PantallaPerfil({super.key, this.psicologo});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final usuarioDAO = UsuarioDAO(Supabase.instance.client);
  final picker = ImagePicker();

  final _form = GlobalKey<FormState>();

  bool cargando = true;
  bool esPerfilPropio = true;

  File? fotoLocal;

  late String nombre;
  late String apellidos;
  late String correo;
  late String telefono;
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
      correo = u['correo'] ?? '';
      telefono = u['telefono'] ?? '';
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
    correo = datos?['correo'] ?? '';
    telefono = datos?['telefono'] ?? '';
    descripcion = datos?['descripcion'] ?? '';
    foto = datos?['foto_perfil'] ?? '';

    setState(() => cargando = false);
  }

  Future<void> _seleccionarImagen() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;
    setState(() => fotoLocal = File(picked.path));
  }

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

    return supa.storage.from('perfiles').getPublicUrl(path);
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() => cargando = true);

    try {
      final nueva = await _subirImagen();
      if (nueva != null) foto = nueva;

      await usuarioDAO.actualizarPerfil(
        nombre: nombre,
        apellidos: apellidos,
        correo: correo,
        telefono: telefono,
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
              child: Form(
                key: _form,
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

                    const SizedBox(height: 20),

                    TextFormField(
                      initialValue: nombre,
                      enabled: esPerfilPropio,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                      onSaved: (v) => nombre = v!,
                    ),

                    TextFormField(
                      initialValue: apellidos,
                      enabled: esPerfilPropio,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      onSaved: (v) => apellidos = v ?? '',
                    ),

                    TextFormField(
                      initialValue: correo,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Correo'),
                    ),

                   TextFormField(
                    initialValue: telefono,
                    enabled: esPerfilPropio,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,

                    validator: (v) {
                      if (v == null || v.isEmpty) return null; // campo opcional
                      if (!RegExp(r'^[0-9]{9}$').hasMatch(v)) {
                        return 'Formato inválido (debe ser 9 dígitos)';
                      }
                      return null;
                    },
                    onSaved: (v) => telefono = v ?? '',
                  ),


                    TextFormField(
                      initialValue: descripcion,
                      enabled: esPerfilPropio,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      onSaved: (v) => descripcion = v ?? '',
                    ),

                    if (esPerfilPropio) ...[
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A80),
                        ),
                        child: const Text("Guardar cambios"),
                      ),

                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      )
                    ]
                  ],
                ),
              ),
            ),
    );
  }
}
