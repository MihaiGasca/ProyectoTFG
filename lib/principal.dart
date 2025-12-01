import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// DAOs
import 'usuario_dao.dart';
import 'conversacion_dao.dart';

// Pantallas
import 'pantalla_chat_individual.dart';
import 'pantalla_conversaciones.dart';
import 'pantalla_perfil.dart';
import 'pantalla_citas.dart';
import 'pantalla_citas_usuario.dart';
import 'pantalla_agenda_psicologo.dart';
import 'pantalla_login.dart';

class PaginaUsuarios extends StatefulWidget {
  const PaginaUsuarios({super.key});

  @override
  State<PaginaUsuarios> createState() => _PaginaUsuariosState();
}

class _PaginaUsuariosState extends State<PaginaUsuarios> {
  final usuarioDAO = UsuarioDAO(Supabase.instance.client);
  final conversacionDAO = ConversacionDAO(Supabase.instance.client);

  List<Map<String, dynamic>> psicologos = [];
  int? _indiceExpandido;
  bool _cargando = true;
  String tipoUsuario = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _cargarPsicologos();
  }

  Future<void> _cargarUsuario() async {
    final u = await usuarioDAO.getUsuarioActual();
    if (!mounted) return;
    setState(() => tipoUsuario = u?['tipo'] ?? '');
  }

  Future<void> _cargarPsicologos() async {
    setState(() => _cargando = true);

    try {
      final lista = await usuarioDAO.getPsicologos();
      setState(() => psicologos = lista);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error cargando psicólogos: $e")));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _abrirChat(Map<String, dynamic> psicologo) async {
    try {
      final conv = await conversacionDAO.getOrCreateConversation(psicologo['id']);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaChatIndividual(conversacion: conv),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error abriendo chat: $e")));
    }
  }

  void _irACitas() {
    if (tipoUsuario == 'psicologo') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaAgendaPsicologo()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaCitasUsuario()),
      );
    }
  }

  void _pedirCita(Map<String, dynamic> psicologo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaCitas(psicologoSeleccionado: psicologo),
      ),
    );
  }

  void _verPerfil(Map<String, dynamic> psicologo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPerfil(psicologo: psicologo),
      ),
    );
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),

      appBar: AppBar(
        title: const Text("TherapyFind"),
        backgroundColor: const Color(0xFFFF8A80),
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      body: Column(
        children: [
          // ------------------------------------------------------
          // 🔥 MENÚ SUPERIOR
          // ------------------------------------------------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC4BD),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
            ),
            child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    if (tipoUsuario != 'psicologo')
      _menuBoton(Icons.chat_bubble_outline, "Chat", () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantallaConversaciones()),
        );
      }),

    _menuBoton(Icons.calendar_month, "Citas", _irACitas),

    _menuBoton(Icons.person_outline, "Mi perfil", () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PantallaPerfil()),
      );
    }),

    _menuBoton(Icons.logout, "Salir", _cerrarSesion),
  ],
),

          ),

          // ------------------------------------------------------
          // 🔥 CONTENIDO PRINCIPAL SEGÚN TIPO DE USUARIO
          // ------------------------------------------------------
          Expanded(
            child: tipoUsuario == 'psicologo'
                ? const PantallaConversaciones()
                : _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : psicologos.isEmpty
                        ? const Center(child: Text("No se encontraron psicólogos"))
                        : ListView.builder(
                            itemCount: psicologos.length,
                            itemBuilder: (context, index) {
                              final p = psicologos[index];
                              final abierto = _indiceExpandido == index;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                                child: ExpansionTile(
                                  key: Key(index.toString()),
                                  initiallyExpanded: abierto,
                                  onExpansionChanged: (x) {
                                    setState(() => _indiceExpandido = x ? index : null);
                                  },

                                  leading: CircleAvatar(
                                    backgroundImage:
                                        (p["foto_perfil"] != null && p["foto_perfil"].toString().isNotEmpty)
                                            ? NetworkImage(p["foto_perfil"])
                                            : null,
                                    child:
                                        (p["foto_perfil"] == null || p["foto_perfil"].toString().isEmpty)
                                            ? Text((p["nombre"] ?? "?")[0])
                                            : null,
                                  ),

                                  title: Text("${p["nombre"]} ${p["apellidos"]}"),
                                  subtitle: Text(p["descripcion"] ?? ""),

                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _abrirChat(p),
                                            icon: const Icon(Icons.message),
                                            label: const Text("Mensaje"),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _pedirCita(p),
                                            icon: const Icon(Icons.calendar_month),
                                            label: const Text("Pedir cita"),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _verPerfil(p),
                                            icon: const Icon(Icons.person_search),
                                            label: const Text("Ver perfil"),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _menuBoton(IconData icon, String texto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 26, color: const Color(0xFFB1443C)),
          const SizedBox(height: 3),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB1443C),
            ),
          ),
        ],
      ),
    );
  }
}
