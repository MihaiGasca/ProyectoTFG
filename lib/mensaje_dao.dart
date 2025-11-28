import 'package:supabase_flutter/supabase_flutter.dart';

class MensajeDAO {
  final SupabaseClient supabase;
  MensajeDAO(this.supabase);

  /// --------------------------------------------------------
  ///  Obtener mensajes de una conversación (historial completo)
  /// --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMensajes(String conversacionId) async {
    final resp = await supabase
        .from('mensajes')
        .select('''
          id,
          conversacion_id,
          remitente_id,
          contenido,
          created_at,
          remitente:remitente_id (
            id,
            nombre,
            apellidos,
            foto_perfil
          )
        ''')
        .eq('conversacion_id', conversacionId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(resp);
  }

  /// --------------------------------------------------------
  ///  Enviar mensaje
  /// --------------------------------------------------------
  Future<Map<String, dynamic>> enviarMensaje(
      String conversacionId, String texto) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    final insert = await supabase.from('mensajes').insert({
      'conversacion_id': conversacionId,
      'remitente_id': user.id,
      'contenido': texto,
    }).select().single();

    await supabase.from('conversaciones').update({
      'last_message': texto,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversacionId);

    return Map<String, dynamic>.from(insert);
  }

  /// --------------------------------------------------------
  ///  🔴 Realtime V2 — escuchar nuevos mensajes
  /// --------------------------------------------------------
  RealtimeChannel escucharMensajes(
    String conversacionId,
    void Function(Map<String, dynamic>) onMessage,
  ) {
    final channel = supabase.channel('mensajes_$conversacionId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'mensajes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversacion_id',
        value: conversacionId,
      ),
      callback: (payload) {
        onMessage(payload.newRecord); // ⭐ nunca es null en insert events
      },
    );

    channel.subscribe();
    return channel;
  }

  /// --------------------------------------------------------
  ///  Cancelar escucha realtime
  /// --------------------------------------------------------
  void cancelarEscucha(RealtimeChannel channel) {
    supabase.removeChannel(channel);
  }
}
