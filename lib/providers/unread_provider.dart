import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnreadProvider extends ChangeNotifier {
  final supa = Supabase.instance.client;

  int totalUnread = 0;
  late String myId;

  UnreadProvider() {
    myId = supa.auth.currentUser!.id;
    refresh();
    _listenRealtime();
  }

  /// refrescar desde fuera
  Future<void> refresh() async {
    await _loadUnread();
  }

  /// carga total de mensajes no leídos
  Future<void> _loadUnread() async {
    final resp = await supa
        .from('conversaciones')
        .select('unread_usuario1, unread_usuario2, usuario1_id, usuario2_id');

    int count = 0;

    for (final c in resp) {
      if (c['usuario1_id'] == myId) {
        count += (c['unread_usuario1'] ?? 0) as int;
      } else {
        count += (c['unread_usuario2'] ?? 0) as int;
      }
    }

    totalUnread = count;
    notifyListeners();
  }

  ///  actualizaciones en tiempo real
  void _listenRealtime() {
    // MENSAJES NUEVOS
    supa.channel('public:mensajes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          callback: (_) => refresh(),
        )
        .subscribe();

    // CAMBIOS EN CONTADORES
    supa.channel('public:conversaciones')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversaciones',
          callback: (_) => refresh(),
        )
        .subscribe();
  }
}
