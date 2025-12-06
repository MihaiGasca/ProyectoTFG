import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers
import 'package:tfg/providers/unread_provider.dart';

// DAOs
import 'package:tfg/data/dao/usuario_dao.dart';
import 'package:tfg/data/dao/conversacion_dao.dart';

// Pantallas
import 'package:tfg/screens/chat/pantalla_chat_individual.dart';
import 'package:tfg/screens/chat/pantalla_conversaciones.dart';
import 'package:tfg/screens/perfil/pantalla_perfil.dart';
import 'package:tfg/screens/valoraciones/pantalla_valorar_psicologo.dart';
import 'package:tfg/screens/valoraciones/pantalla_valoraciones_psicologo.dart';
import 'package:tfg/screens/citas/pantalla_agenda_psicologo.dart';
import 'package:tfg/screens/citas/pantalla_citas_usuario.dart';
import 'package:tfg/screens/citas/pantalla_citas.dart';
import 'package:tfg/screens/login/pantalla_login.dart';

// PANTALLA DE VALORACIONES
import 'package:tfg/screens/valoraciones/pantalla_valoraciones_de_psicologo.dart';

class PaginaUsuarios extends StatefulWidget {
  const PaginaUsuarios({super.key});

  @override
  State<PaginaUsuarios> createState() => _PaginaUsuariosState();
}

class _PaginaUsuariosState extends State<PaginaUsuarios> {
  final usuarioDAO = UsuarioDAO(Supabase.instance.client);
  final conversacionDAO = ConversacionDAO(Supabase.instance.client);

  List<Map<String, dynamic>> psicologos = [];
  List<Map<String, dynamic>> psicologosFiltrados = [];

  List<Map<String, dynamic>> conversaciones = [];
  List<Map<String, dynamic>> conversacionesFiltradas = [];

  String tipoUsuario = '';
  bool cargando = true;

  String query = '';

  late String myId;

  @override
  void initState() {
    super.initState();
    myId = Supabase.instance.client.auth.currentUser!.id;
    _init();
  }

  Future<void> _init() async {
    await _cargarUsuario();
    await _cargarPsicologos();
    if (tipoUsuario == "psicologo") {
      await _cargarConversaciones();
    }
  }

  Future<void> _cargarUsuario() async {
    final u = await usuarioDAO.getUsuarioActual();
    tipoUsuario = u?['tipo'] ?? '';
  }

  Future<void> _cargarPsicologos() async {
    final lista = await usuarioDAO.getPsicologosConRating();
    if (!mounted) return;
    setState(() {
      psicologos = List<Map<String, dynamic>>.from(lista);
      psicologosFiltrados = psicologos;
      cargando = false;
    });
  }

  Future<void> _cargarConversaciones() async {
    final lista = await conversacionDAO.getConversacionesUsuario();

    conversaciones = lista.where((c) {
      final other =
          (c['usuario1_id'] == myId) ? c['usuario2'] : c['usuario1'];
      return other['tipo'] == 'usuario';
    }).toList();

    conversaciones.sort((a, b) {
      final da = DateTime.parse(a['updated_at']);
      final db = DateTime.parse(b['updated_at']);
      return db.compareTo(da);
    });

    conversacionesFiltradas = List<Map<String, dynamic>>.from(conversaciones);

    if (!mounted) return;
    setState(() {});
  }

  void _buscar(String t) {
    query = t.toLowerCase();

    if (tipoUsuario != "psicologo") {
      psicologosFiltrados = psicologos.where((p) {
        final full = "${p['nombre']} ${p['apellidos']}".toLowerCase();
        return full.contains(query);
      }).toList();
    } else {
      conversacionesFiltradas = conversaciones.where((c) {
        final other =
            c['usuario1_id'] == myId ? c['usuario2'] : c['usuario1'];
        final full =
            "${other['nombre']} ${other['apellidos']}".toLowerCase();
        return full.contains(query);
      }).toList();
    }

    setState(() {});
  }

  void _abrirChat(Map<String, dynamic> other) async {
    final conv = await conversacionDAO.getOrCreateConversation(other['id']);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaChatIndividual(conversacion: conv),
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

  void _valorarPsicologo(Map<String, dynamic> psicologo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaValorarPsicologo(
          psicologoId: psicologo['id'],
        ),
      ),
    );
  }

  void _pedirCita(Map<String, dynamic> psicologo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaCitas(psicologoSeleccionado: psicologo),
      ),
    );
  }

  void _irACitas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => tipoUsuario == "psicologo"
            ? const PantallaAgendaPsicologo()
            : const PantallaCitasUsuario(),
      ),
    );
  }

  void _verValoraciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => tipoUsuario == "psicologo"
            ? const PantallaValoracionesPsicologo()
            : PantallaValoracionesPsicologo(),
      ),
    );
  }

  void _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  Widget _menuSuperior(int unread) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFFFC4BD),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (tipoUsuario != "psicologo")
            _menuBoton(Icons.chat, "Chat", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaConversaciones()),
              );
            }, badge: unread),
          _menuBoton(Icons.calendar_month, "Citas", _irACitas),
          if (tipoUsuario == "psicologo")
            _menuBoton(Icons.star, "Valoraciones", _verValoraciones),
          _menuBoton(Icons.person, "Mi perfil", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaPerfil()),
            );
          }),
          _menuBoton(Icons.logout, "Salir", _cerrarSesion),
        ],
      ),
    );
  }

  Widget _menuBoton(IconData icon, String txt, VoidCallback onTap,
      {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Icon(icon, color: Colors.red),
              Text(txt),
            ],
          ),
          if (badge > 0)
            Positioned(
              right: -10,
              top: -5,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  badge.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            )
        ],
      ),
    );
  }

  // ============= LISTA PSICÓLOGOS =============
  Widget _listaUsuarios() {
    if (psicologosFiltrados.isEmpty) {
      return const Center(child: Text("Sin resultados"));
    }

    final width = MediaQuery.of(context).size.width;
    final columnas = (width ~/ 260).clamp(1, 4);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnas,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: psicologosFiltrados.length,
        itemBuilder: (_, i) {
          final p = psicologosFiltrados[i];

          final String nombre = "${p['nombre']} ${p['apellidos']}";
          final String foto = p["foto_url"] ?? "";
          final String descripcion = p["descripcion"] ?? "";

          return GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(nombre,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _abrirChat(p);
                              },
                              icon: const Icon(Icons.message),
                              label: const Text("Mensaje"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _verPerfil(p);
                              },
                              icon: const Icon(Icons.person_search),
                              label: const Text("Ver perfil"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _valorarPsicologo(p);
                              },
                              icon: const Icon(Icons.star),
                              label: const Text("Valorar"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _pedirCita(p);
                              },
                              icon: const Icon(Icons.calendar_month),
                              label: const Text("Pedir cita"),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PantallaValoracionesDePsicologo(
                                      psicologoId: p['id'],
                                      nombre: nombre,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.reviews),
                              label: const Text("Ver valoraciones"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    color: Colors.black.withOpacity(0.08),
                  )
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: foto.isNotEmpty
                          ? Image.network(foto, fit: BoxFit.cover)
                          : Container(
                              color: Colors.pink.shade100,
                              child: Center(
                                child: Text(
                                  p['nombre'][0],
                                  style: const TextStyle(
                                      fontSize: 34,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      child: Column(
                        children: [
                          Text(nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text("⭐ ${p['media']} (${p['total']})",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============= LISTA CONVERSACIONES PSICÓLOGO =============
  Widget _listaConversacionesPsicologo() {
    if (conversacionesFiltradas.isEmpty) {
      return const Center(child: Text("No hay conversaciones"));
    }

    return ListView.builder(
      itemCount: conversacionesFiltradas.length,
      itemBuilder: (_, i) {
        final c = conversacionesFiltradas[i];
        final other =
            c['usuario1_id'] == myId ? c['usuario2'] : c['usuario1'];

        final unread = (c['usuario1_id'] == myId
                ? c['unread_usuario1']
                : c['unread_usuario2']) ??
            0;

        final foto = other["foto_url"] ?? "";

        return ListTile(
          onTap: () async {
            await conversacionDAO.marcarLeidos(c['id']);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaChatIndividual(conversacion: c),
              ),
            );

            _cargarConversaciones();
          },
          title: Text("${other['nombre']} ${other['apellidos']}"),
          subtitle: Text(c['last_message'] ?? ""),
          leading: CircleAvatar(
            backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
            child: foto.isEmpty ? Text(other['nombre'][0]) : null,
          ),
          trailing: unread > 0
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadProvider>().totalUnread;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(title: const Text("TherapyFind")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _menuSuperior(unread),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: _buscar,
                    decoration: InputDecoration(
                      hintText: tipoUsuario == "psicologo"
                          ? "Buscar conversaciones..."
                          : "Buscar psicólogos...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // ⭐⭐⭐ FIX DEL OVERFLOW AQUÍ ⭐⭐⭐
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: tipoUsuario == "psicologo"
                        ? _listaConversacionesPsicologo()
                        : _listaUsuarios(),
                  ),
                )
              ],
            ),
    );
  }
}
