import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/dao/chat_dao.dart';
import '../../data/models/chat_message.dart';

class PantallaChatIndividual extends StatefulWidget {
  final Map<String, dynamic> conversacion;

  const PantallaChatIndividual({super.key, required this.conversacion});

  @override
  State<PantallaChatIndividual> createState() => _PantallaChatIndividualState();
}

class _PantallaChatIndividualState extends State<PantallaChatIndividual> {
  final supa = Supabase.instance.client;
  late final ChatDao dao;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late String convId;
  late String myId;
  late Map otherUser;

  List<ChatMessage> mensajes = [];

  StreamSubscription<List<ChatMessage>>? sub;
  RealtimeChannel? realtimeChannel;

  @override
  void initState() {
    super.initState();
    dao = ChatDao(supa);

    convId = widget.conversacion['id'];
    myId = supa.auth.currentUser!.id;

    _prepareHeader();
    _loadInitialMessages();
    _listenStreamDAO();
    _listenRealtime();
  }

  @override
  void dispose() {
    sub?.cancel();
    realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _prepareHeader() {
    final u1 = widget.conversacion['usuario1'];
    final u2 = widget.conversacion['usuario2'];
    otherUser = u1['id'] == myId ? u2 : u1;
  }

  // Cargar mensajes iniciales
  Future<void> _loadInitialMessages() async {
    mensajes = await dao.loadInitialMessages(convId, myId);
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _listenStreamDAO() {
    sub = dao.listenMessages(convId, myId).listen((nuevos) {
      if (!mounted) return;
      setState(() => mensajes = nuevos);
      _scrollToBottom();
    });
  }

  void _listenRealtime() {
    realtimeChannel = supa.channel("chat_$convId")
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'mensajes_chat',
        callback: (payload) async {
          final data = payload.newRecord ?? payload.oldRecord;
          if (data != null && data["conversacion_id"] == convId) {
            await _loadInitialMessages();
          }
        },
      )
      ..subscribe();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    await dao.sendMessage(convId, myId, text);
    await dao.updateConversation(convId, text);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.minScrollExtent);
      }
    });
  }

  String _hora(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('HH:mm').format(dt);
  }

  String _dia(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('d MMM yyyy').format(dt);
  }

  bool _esNuevoDia(int index) {
    if (index == 0) return true;

    final prev = DateTime.parse(mensajes[index - 1].createdAt).toLocal();
    final curr = DateTime.parse(mensajes[index].createdAt).toLocal();

    return prev.day != curr.day ||
        prev.month != curr.month ||
        prev.year != curr.year;
  }

  @override
  Widget build(BuildContext context) {
    final String foto = otherUser["foto_url"] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
              child: foto.isEmpty
                  ? Text(otherUser['nombre'][0],
                      style: const TextStyle(fontSize: 20))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              "${otherUser['nombre']} ${otherUser['apellidos']}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              reverse: true,
              padding: const EdgeInsets.all(12),
              itemCount: mensajes.length,
              itemBuilder: (_, i) {
                final m = mensajes[i];
                final nuevoDia = _esNuevoDia(i);

                return Column(
                  children: [
                    if (nuevoDia)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _dia(m.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: m.isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              m.isMine ? const Color(0xFFFF8A80) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.08),
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: m.isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.content,
                              style: TextStyle(
                                fontSize: 15,
                                color: m.isMine
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hora(m.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: m.isMine
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _BarraMensaje(controller: _controller, send: _send),
        ],
      ),
    );
  }
}

class _BarraMensaje extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback send;

  const _BarraMensaje({required this.controller, required this.send});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      color: const Color(0xFFFFEDEB),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Escribe un mensaje...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: send,
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFFF8A80),
              child: Icon(Icons.send, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
