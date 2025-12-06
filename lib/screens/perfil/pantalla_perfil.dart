import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:tfg/data/dao/usuario_dao.dart';
import 'package:tfg/screens/valoraciones/pantalla_valorar_psicologo.dart';

class PantallaPerfil extends StatefulWidget {
  final Map<String, dynamic>? psicologo;

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
  Uint8List? _webImageBytes;

  late String nombre;
  late String apellidos;
  late String correo;
  late String telefono;
  late String descripcion;

  late String fotoPath; // SOLO PATH en BD
  String? fotoUrl; // URL firmada para mostrar

  @override
  void initState() {
    super.initState();

    if (widget.psicologo != null) {
      esPerfilPropio = false;
      final u = widget.psicologo!;

      nombre = u['nombre'] ?? '';
      apellidos = u['apellidos'] ?? '';
      correo = u['correo'] ?? '';
      telefono = u['telefono'] ?? '';
      descripcion = u['descripcion'] ?? '';

      // Lo que viene desde principal es:
      // foto_perfil = path
      // foto_url = signed URL generada en el DAO
      fotoPath = u['foto_perfil'] ?? '';
      fotoUrl = u['foto_url'];

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

    fotoPath = datos?['foto_perfil'] ?? '';
    fotoUrl = datos?['foto_url']; // URL firmada generada por el DAO

    setState(() => cargando = false);
  }

  Future<void> _seleccionarImagen() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        fotoLocal = null;
      });
    } else {
      setState(() {
        fotoLocal = File(picked.path);
        _webImageBytes = null;
      });
    }
  }

  /// SUBIR IMAGEN — SOLO GUARDAMOS PATH EN BD, URL firmada solo para mostrar
  Future<String?> _subirImagen() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    final path = "perfiles/$uid/perfil.jpg";

    try {
      // Borrar anterior si existe
      try {
        await supa.storage.from('perfiles').remove([path]);
      } catch (_) {}

      // Subir nueva
      if (kIsWeb) {
        await supa.storage.from('perfiles').uploadBinary(
          path,
          _webImageBytes!,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        await supa.storage.from('perfiles').upload(
          path,
          fotoLocal!,
          fileOptions: const FileOptions(upsert: true),
        );
      }

      // Crear URL firmada nueva
      final signed = await supa.storage
          .from('perfiles')
          .createSignedUrl(path, 3600);

      fotoUrl = "$signed&cache=${DateTime.now().millisecondsSinceEpoch}";

      return path; // Lo que se guarda en BDD

    } catch (e) {
      debugPrint("Error al subir imagen: $e");
      return null;
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() => cargando = true);

    try {
      final nuevoPath = await _subirImagen();
      if (nuevoPath != null) fotoPath = nuevoPath;

      await usuarioDAO.actualizarPerfil(
        nombre: nombre,
        apellidos: apellidos,
        correo: correo,
        telefono: telefono,
        descripcion: descripcion,
        foto: fotoPath, // BD → SOLO PATH
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado")),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  InputDecoration estiloCampo(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFFF8A80)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        title: Text(esPerfilPropio ? "Mi perfil" : "Perfil del psicólogo"),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: esPerfilPropio ? _seleccionarImagen : null,
                      child: CircleAvatar(
                        radius: 90,
                        backgroundColor: Colors.white,
                        backgroundImage: _webImageBytes != null
                            ? MemoryImage(_webImageBytes!)
                            : fotoLocal != null
                                ? FileImage(fotoLocal!)
                                : (fotoUrl != null && fotoUrl!.isNotEmpty
                                        ? NetworkImage(fotoUrl!)
                                        : null)
                                    as ImageProvider?,
                        child: (fotoUrl == null &&
                                fotoLocal == null &&
                                _webImageBytes == null)
                            ? Text(
                                nombre.isNotEmpty ? nombre[0] : "?",
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A80),
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      initialValue: nombre,
                      enabled: esPerfilPropio,
                      decoration: estiloCampo("Nombre", Icons.person),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                      onSaved: (v) => nombre = v ?? '',
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: apellidos,
                      enabled: esPerfilPropio,
                      decoration:
                          estiloCampo("Apellidos", Icons.person_outline),
                      onSaved: (v) => apellidos = v ?? '',
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: correo,
                      enabled: false,
                      decoration: estiloCampo("Correo", Icons.email),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: telefono,
                      enabled: esPerfilPropio,
                      keyboardType: TextInputType.phone,
                      decoration: estiloCampo("Teléfono", Icons.phone),
                      onSaved: (v) => telefono = v ?? '',
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      initialValue: descripcion,
                      enabled: esPerfilPropio,
                      maxLines: 4,
                      decoration:
                          estiloCampo("Descripción", Icons.text_fields),
                      onSaved: (v) => descripcion = v ?? '',
                    ),

                    const SizedBox(height: 30),

                    // PERFIL PROPIO → Guardar + Cancelar
                    if (esPerfilPropio) ...[
                      ElevatedButton(
                        onPressed: _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A80),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Guardar cambios",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancelar",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],

                    // PERFIL AJENO → Valorar
                    if (!esPerfilPropio)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PantallaValorarPsicologo(
                                psicologoId: widget.psicologo!['id'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A80),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Valorar psicólogo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
