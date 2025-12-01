import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'conversacion_dao.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final resp = await Supabase.instance.client
        .from('usuarios')
        .select('tipo')
        .eq('id', userId)
        .maybeSingle();

    tipoUsuario = resp?['tipo'] ?? '';
    setState(() => _loadingUser = false);

    _loadChats();
  }

  Future<void> _loadChats() async {
    final lista = await conversacionDAO.getConversacionesUsuario();
    final me = Supabase.instance.client.auth.currentUser!.id;

    if (tipoUsuario == 'psicologo') {
      conversaciones = lista.where((c) {
        final other = (c['usuario1_id'] == me)
            ? c['usuario2']
            : c['usuario1'];

        return other['tipo'] == 'usuario';
      }).toList();
    } else {
      conversaciones = lista;
    }

    setState(() => _loadingChats = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser || _loadingChats) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversaciones'),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: conversaciones.isEmpty
          ? const Center(child: Text("No hay conversaciones"))
          : ListView.builder(
              itemCount: conversaciones.length,
              itemBuilder: (_, i) {
                final c = conversaciones[i];
                final me = Supabase.instance.client.auth.currentUser!.id;

                final otherRaw = c['usuario1_id'] == me
                    ? c['usuario2']
                    : c['usuario1'];

                if (otherRaw == null) return const SizedBox.shrink();

                final other = Map<String, dynamic>.from(otherRaw);

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PantallaChatIndividual(conversacion: c),
                      ),
                    );
                  },
                  title: Text("${other['nombre']} ${other['apellidos']}"),
                  subtitle: Text(c['last_message'] ?? ''),
                  leading: CircleAvatar(
                    backgroundImage: (other['foto_perfil'] ?? "").isNotEmpty
                        ? NetworkImage(other['foto_perfil'])
                        : null,
                    child: (other['foto_perfil'] ?? "").isEmpty
                        ? Text(other['nombre'][0])
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
