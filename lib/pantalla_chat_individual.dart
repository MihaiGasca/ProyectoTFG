import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class PantallaChatIndividual extends StatefulWidget {
  final Map<String, dynamic>? conversacion;

  const PantallaChatIndividual({super.key, this.conversacion});

  @override
  State<PantallaChatIndividual> createState() =>
      _PantallaChatIndividualState();
}

class _PantallaChatIndividualState extends State<PantallaChatIndividual> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<Map<String, dynamic>> mensajes = [];
  bool _loading = true;

  RealtimeChannel? canal;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _escucharMensajesRealtime();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _loading = true);

    try {
      final convId = widget.conversacion?['id'];
      if (convId == null) return;

      final data = await supabase
          .from('mensajes')
          .select()
          .eq('conversacion_id', convId)
          .order('created_at', ascending: true);

      mensajes = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _escucharMensajesRealtime() {
    final convId = widget.conversacion?['id'];
    if (convId == null) return;

    canal = supabase
        .channel('chat_$convId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversacion_id',
            value: convId,
          ),
          callback: (payload) {
            final nuevo = payload.newRecord;
            setState(() => mensajes.add(nuevo));
            _scrollToEnd();
          },
        )
        .subscribe();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    final user = supabase.auth.currentUser;
    final convId = widget.conversacion?['id'];
    if (user == null || convId == null) return;

    _controller.clear();

    try {
      await supabase.from('mensajes').insert({
        'conversacion_id': convId,
        'remitente_id': user.id,
        'contenido': texto,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    canal?.unsubscribe();
    super.dispose();
  }

  String _formatHora(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    return DateFormat('HH:mm').format(dt);
  }

  String _formatFecha(String ts) {
    final d = DateTime.parse(ts).toLocal();
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    if (d.year == hoy.year &&
        d.month == hoy.month &&
        d.day == hoy.day) return "Hoy";
    if (d.year == ayer.year &&
        d.month == ayer.month &&
        d.day == ayer.day) return "Ayer";

    return DateFormat('dd/MM/yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversacion;
    final yoId = supabase.auth.currentUser?.id;

    final u1 = conv?['usuario1'];
    final u2 = conv?['usuario2'];

    final other = (u1 != null && u1['id'] != yoId) ? u1 : u2;

    final foto = (other?['foto_perfil'] ?? "").toString();
    final nombre = other?['nombre'] ?? "Usuario";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
              child: foto.isEmpty
                  ? Text(nombre.substring(0, 1))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(nombre),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final m = mensajes[index];
                      final esYo = m['remitente_id'] == yoId;

                      bool mostrarFecha = false;
                      if (index == 0) mostrarFecha = true;
                      else {
                        final fActual = _formatFecha(m['created_at']);
                        final fAnterior = _formatFecha(mensajes[index - 1]['created_at']);
                        mostrarFecha = fActual != fAnterior;
                      }

                      return Column(
                        children: [
                          if (mostrarFecha)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(_formatFecha(m['created_at']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                            ),
                          Row(
                            mainAxisAlignment:
                                esYo ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: esYo
                                      ? const Color(0xFFFFC1BD)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(m['contenido'] ?? '',
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text(_formatHora(m['created_at']),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 3),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: InputBorder.none),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFF8A80)),
                  onPressed: _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
