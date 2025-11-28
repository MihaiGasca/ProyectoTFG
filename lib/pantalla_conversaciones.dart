import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_chat_individual.dart';

class PantallaConversaciones extends StatefulWidget {
  final Map<String, dynamic>? peer;

  const PantallaConversaciones({super.key, this.peer});

  @override
  State<PantallaConversaciones> createState() =>
      _PantallaConversacionesState();
}

class _PantallaConversacionesState extends State<PantallaConversaciones> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> conversaciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
  }

  Future<void> _cargarConversaciones() async {
    setState(() => _cargando = true);

    try {
      final me = supabase.auth.currentUser;
      if (me == null) return;

      final data = await supabase
          .from('conversaciones')
          .select('''
            id,
            last_message,
            updated_at,
            usuario1_id,
            usuario2_id,
            usuario1:usuario1_id (
              id,
              nombre,
              apellidos,
              foto_perfil
            ),
            usuario2:usuario2_id (
              id,
              nombre,
              apellidos,
              foto_perfil
            )
          ''')
          .or('usuario1_id.eq.${me.id},usuario2_id.eq.${me.id}')
          .order('updated_at', ascending: false);

      conversaciones = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _abrirChat(Map<String, dynamic> conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaChatIndividual(conversacion: conv),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversaciones'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : conversaciones.isEmpty
              ? const Center(child: Text('No hay conversaciones todavía'))
              : ListView.builder(
                  itemCount: conversaciones.length,
                  itemBuilder: (context, index) {
                    final conv = conversaciones[index];

                    final u1 = conv['usuario1'];
                    final u2 = conv['usuario2'];
                    final other =
                        (u1 != null && u1['id'] != meId) ? u1 : u2;

                    final foto = (other?['foto_perfil'] ?? '').toString();
                    final nombre = other?['nombre'] ?? 'Usuario';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            foto.isNotEmpty ? NetworkImage(foto) : null,
                        child: foto.isEmpty
                            ? Text(nombre.substring(0, 1))
                            : null,
                      ),
                      title: Text(
                        '${other?['nombre'] ?? 'Usuario'} '
                        '${other?['apellidos'] ?? ''}',
                      ),
                      subtitle: Text(conv['last_message'] ?? ''),
                      onTap: () => _abrirChat(conv),
                    );
                  },
                ),
    );
  }
}
