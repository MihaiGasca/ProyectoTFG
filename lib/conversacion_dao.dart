import 'package:supabase_flutter/supabase_flutter.dart';

class ConversacionDAO {
  final SupabaseClient supabase;
  ConversacionDAO(this.supabase);

  Future<List<Map<String, dynamic>>> getConversacionesUsuario() async {
    final me = supabase.auth.currentUser;
    if (me == null) return [];

    final resp = await supabase
        .from('conversaciones')
        .select('''
          id,
          usuario1_id,
          usuario2_id,
          last_message,
          updated_at,
          usuario1:usuario1_id(id,nombre,apellidos,foto_perfil,tipo),
          usuario2:usuario2_id(id,nombre,apellidos,foto_perfil,tipo)
        ''')
        .or('usuario1_id.eq.${me.id},usuario2_id.eq.${me.id}')
        .order('updated_at', ascending: false);

    /// 🔥 filtramos las conversaciones que vienen corruptas
    final sanos = resp.where((c) {
      return c['usuario1'] != null && c['usuario2'] != null;
    }).toList();

    return List<Map<String, dynamic>>.from(sanos);
  }

  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final me = supabase.auth.currentUser;
    if (me == null) throw Exception('No autenticado');

    Future<Map<String, dynamic>> _load(String id) async {
      final conv = await supabase
          .from('conversaciones')
          .select('''
            id,
            usuario1_id,
            usuario2_id,
            last_message,
            updated_at,
            usuario1:usuario1_id(id,nombre,apellidos,foto_perfil,tipo),
            usuario2:usuario2_id(id,nombre,apellidos,foto_perfil,tipo)
          ''')
          .eq('id', id)
          .single();

      return Map<String, dynamic>.from(conv);
    }

    final existing = await supabase
        .from('conversaciones')
        .select('id')
        .or(
          'and(usuario1_id.eq.${me.id},usuario2_id.eq.$otherUserId),'
          'and(usuario1_id.eq.$otherUserId,usuario2_id.eq.${me.id})'
        )
        .maybeSingle();

    if (existing != null) {
      return _load(existing['id']);
    }

    final created = await supabase
        .from('conversaciones')
        .insert({
          'usuario1_id': me.id,
          'usuario2_id': otherUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return _load(created['id']);
  }
}
