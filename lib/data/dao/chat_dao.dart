import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatDao {
  final SupabaseClient supa;

  ChatDao(this.supa);

  Future<List<ChatMessage>> loadInitialMessages(String convId, String myId) async {
    final data = await supa
        .from("mensajes")
        .select()
        .eq("conversacion_id", convId)
        .order("created_at");

    return data.map<ChatMessage>((m) => ChatMessage.fromMap(m, myId)).toList();
  }

  Stream<List<ChatMessage>> listenMessages(String convId, String myId) {
    return supa
        .from("mensajes")
        .stream(primaryKey: ["id"])
        .eq("conversacion_id", convId)
        .order("created_at")
        .map((data) => data.map((m) => ChatMessage.fromMap(m, myId)).toList());
  }

  Future<void> sendMessage(String convId, String myId, String text) async {
    await supa.from('mensajes').insert({
      'conversacion_id': convId,
      'remitente_id': myId,
      'contenido': text,
    });
  }

  Future<void> updateConversation(String convId, String text) async {
    await supa.from('conversaciones').update({
      'last_message': text,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', convId);
  }
}
