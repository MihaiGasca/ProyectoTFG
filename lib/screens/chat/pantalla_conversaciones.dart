import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/conversacion_dao.dart';
import 'pantalla_chat_individual.dart';

class PantallaConversaciones extends StatefulWidget {
  const PantallaConversaciones({super.key});

  @override
  State<PantallaConversaciones> createState() => _PantallaConversacionesState();
}

class _PantallaConversacionesState extends State<PantallaConversaciones> {
  final conversacionDAO = ConversacionDAO(Supabase.instance.client);

  String tipoUsuario = '';
  bool _loadingUser = true;
  bool _loadingChats = true;

  List<Map<String, dynamic>> conversaciones = [];
  List<Map<String, dynamic>> conversacionesFiltradas = []; // 🔍 lista filtrada
  late String myId;

  String query = ""; // 🔍 texto de búsqueda

  StreamSubscription<List<Map<String, dynamic>>>? subMensajes;

  @override
  void initState() {
    super.initState();
    myId = Supabase.instance.client.auth.currentUser!.id;
    _loadUser();
    _suscribirseStream();
  }

  @override
  void dispose() {
    subMensajes?.cancel();
    super.dispose();
  }

  void _suscribirseStream() {
    subMensajes = Supabase.instance.client
        .from("mensajes")
        .stream(primaryKey: ["id"])
        .listen((event) {
      _loadChats();
    });
  }

  Future<void> _loadUser() async {
    final resp = await Supabase.instance.client
        .from('usuarios')
        .select('tipo')
        .eq('id', myId)
        .maybeSingle();

    tipoUsuario = resp?['tipo'] ?? '';

    setState(() => _loadingUser = false);
    _loadChats();
  }

  Future<void> _loadChats() async {
    final lista = await conversacionDAO.getConversacionesUsuario();

    if (tipoUsuario == 'psicologo') {
      conversaciones = lista.where((c) {
        final other =
            (c['usuario1_id'] == myId) ? c['usuario2'] : c['usuario1'];
        return other['tipo'] == 'usuario';
      }).toList();
    } else {
      conversaciones = lista;
    }

    conversaciones.sort((a, b) {
      final da = DateTime.parse(a['updated_at']);
      final db = DateTime.parse(b['updated_at']);
      return db.compareTo(da);
    });

    conversacionesFiltradas = List.from(conversaciones); // 🔍 copiar lista inicial

    setState(() => _loadingChats = false);
  }

  // 🔍 FILTRO POR NOMBRE
  void _buscar(String t) {
    query = t.toLowerCase();

    conversacionesFiltradas = conversaciones.where((c) {
      final other =
          c['usuario1_id'] == myId ? c['usuario2'] : c['usuario1'];

      final fullName =
          "${other['nombre']} ${other['apellidos']}".toLowerCase();

      return fullName.contains(query);
    }).toList();

    setState(() {});
  }

  int _noLeidos(Map c) {
    if (c['usuario1_id'] == myId) {
      return c['unread_usuario1'] ?? 0;
    } else {
      return c['unread_usuario2'] ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser || _loadingChats) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        title: const Text('Conversaciones'),
        backgroundColor: const Color(0xFFFF8A80),
      ),

      body: Column(
        children: [
          // 🔍 BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: "Buscar por nombre...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: conversacionesFiltradas.isEmpty
                ? const Center(child: Text("No hay conversaciones"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: conversacionesFiltradas.length,
                    itemBuilder: (_, i) {
                      final c = conversacionesFiltradas[i];

                      final other = c['usuario1_id'] == myId
                          ? c['usuario2']
                          : c['usuario1'];

                      final unread = _noLeidos(c);

                      final String foto = other["foto_url"] ?? "";

                      return GestureDetector(
                        onTap: () async {
                          await conversacionDAO.marcarLeidos(c['id']);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PantallaChatIndividual(conversacion: c),
                            ),
                          );

                          _loadChats();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.08),
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    foto.isNotEmpty ? NetworkImage(foto) : null,
                                child: foto.isEmpty
                                    ? Text(
                                        other['nombre'][0],
                                        style: const TextStyle(fontSize: 22),
                                      )
                                    : null,
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${other['nombre']} ${other['apellidos']}",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      c['last_message'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (unread > 0)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
