import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String id;
  final String content;
  final String sender;
  final String createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromMap(Map map, String myId) {
    return ChatMessage(
      id: map['id'],
      content: map['contenido'],
      sender: map['remitente_id'],
      createdAt: map['created_at'],
      isMine: map['remitente_id'] == myId,
    );
  }
}

class PantallaChatIndividual extends StatefulWidget {
  final Map<String, dynamic> conversacion;
  const PantallaChatIndividual({super.key, required this.conversacion});

  @override
  State<PantallaChatIndividual> createState() =>
      _PantallaChatIndividualState();
}

class _PantallaChatIndividualState extends State<PantallaChatIndividual> {
  final supa = Supabase.instance.client;

  late final Stream<List<ChatMessage>> _stream;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  late final String convId;
  late final String myId;
  late Map otherUser;

  @override
  void initState() {
    super.initState();

    convId = widget.conversacion['id'];
    myId = supa.auth.currentUser!.id;

    _prepareHeader();
    _prepareStream();
  }

  void _prepareStream() {
    _stream = supa
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', convId)
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((r) => ChatMessage.fromMap(r, myId)).toList());
  }

  void _prepareHeader() {
    final u1 = widget.conversacion['usuario1'];
    final u2 = widget.conversacion['usuario2'];
    otherUser = u1['id'] == myId ? u2 : u1;
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    await supa.from('mensajes').insert({
      'conversacion_id': convId,
      'remitente_id': myId,
      'contenido': text,
    });

    await supa.from('conversaciones').update({
      'last_message': text,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', convId);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.minScrollExtent);
    });
  }

  String _hora(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _dia(String iso) {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('d MMM yyyy').format(dt);
  }

  bool _esNuevoDia(String? prevIso, String currentIso) {
    if (prevIso == null) return true;
    final prev = DateTime.parse(prevIso).toLocal();
    final curr = DateTime.parse(currentIso).toLocal();
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (otherUser['foto_perfil'] ?? '').isNotEmpty
                  ? NetworkImage(otherUser['foto_perfil'])
                  : null,
              child: (otherUser['foto_perfil'] ?? '').isEmpty
                  ? Text(otherUser['nombre'][0])
                  : null,
            ),
            const SizedBox(width: 10),
            Text("${otherUser['nombre']} ${otherUser['apellidos']}"),
          ],
        ),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mensajes = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 15),
                  itemCount: mensajes.length,
                  itemBuilder: (context, i) {
                    final m = mensajes[i];

                    bool showDate = i == mensajes.length - 1 ||
                        _esNuevoDia(
                          mensajes[i + 1].createdAt,
                          m.createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              _dia(m.createdAt),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),

                        Align(
                          alignment: m.isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 5),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: m.isMine
                                  ? const Color(0xFFB3D7FF)
                                  : const Color(0xFFE8E8E8),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: m.isMine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.content,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hora(m.createdAt),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600]),
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
          );
        },
      ),
    );
  }
}

class _BarraMensaje extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback send;

  const _BarraMensaje({
    Key? key,
    required this.controller,
    required this.send,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
                onSubmitted: (_) => send(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: send,
            ),
          ],
        ),
      ),
    );
  }
}
