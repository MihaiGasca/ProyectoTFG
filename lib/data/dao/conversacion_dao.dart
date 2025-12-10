import 'package:supabase_flutter/supabase_flutter.dart';

class ConversacionDAO {
  final SupabaseClient supabase;
  ConversacionDAO(this.supabase);

  /// Crear URL firmada para una imagen de perfil si existe
  Future<String?> _signedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final res = await supabase.storage.from('perfiles').createSignedUrl(
            path,
            60 * 60, // 1 hora 3600 segundos
          );
      return res;
    } catch (_) {
      return null;
    }
  }

   
  /// Obtener conversaciones del usuario con foto url añadida
   
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
          unread_usuario1,
          unread_usuario2,
          usuario1:usuario1_id(id, nombre, apellidos, foto_perfil, tipo),
          usuario2:usuario2_id(id, nombre, apellidos, foto_perfil, tipo)
        ''')
        .or('usuario1_id.eq.${me.id},usuario2_id.eq.${me.id}')
        .order('updated_at', ascending: false);

    if (resp == null) return [];

    List<Map<String, dynamic>> lista = resp
        .where((c) => c["usuario1"] != null && c["usuario2"] != null)
        .map((c) => Map<String, dynamic>.from(c))
        .toList();

    // Agregar foto url firmada a usuario1 y usuario2
    for (var c in lista) {
      final u1 = c["usuario1"];
      final u2 = c["usuario2"];

      final String? foto1 = u1["foto_perfil"];
      final String? foto2 = u2["foto_perfil"];

      u1["foto_url"] = await _signedUrl(foto1);
      u2["foto_url"] = await _signedUrl(foto2);
    }

    return lista;
  }

  
  ///Obtener conversación o crearla
 
  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final me = supabase.auth.currentUser;
    if (me == null) throw Exception('No autenticado');

    Future<Map<String, dynamic>> _loadFull(String id) async {
      final data = await supabase
          .from('conversaciones')
          .select('''
            id,
            usuario1_id,
            usuario2_id,
            last_message,
            updated_at,
            unread_usuario1,
            unread_usuario2,
            usuario1:usuario1_id(id, nombre, apellidos, foto_perfil, tipo),
            usuario2:usuario2_id(id, nombre, apellidos, foto_perfil, tipo)
          ''')
          .eq('id', id)
          .single();

      final c = Map<String, dynamic>.from(data);

      //  añadir URL firmada
      c["usuario1"]["foto_url"] =
          await _signedUrl(c["usuario1"]["foto_perfil"]);
      c["usuario2"]["foto_url"] =
          await _signedUrl(c["usuario2"]["foto_perfil"]);

      return c;
    }

    final existing = await supabase
        .from('conversaciones')
        .select('id')
        .or(
          'and(usuario1_id.eq.${me.id},usuario2_id.eq.$otherUserId),'
          'and(usuario1_id.eq.$otherUserId,usuario2_id.eq.${me.id})',
        )
        .maybeSingle();

    if (existing != null) {
      return _loadFull(existing['id']);
    }

    final created = await supabase
        .from('conversaciones')
        .insert({
          'usuario1_id': me.id,
          'usuario2_id': otherUserId,
          'last_message': null,
          'updated_at': DateTime.now().toIso8601String(),
          'unread_usuario1': 0,
          'unread_usuario2': 0,
        })
        .select('id')
        .single();

    return _loadFull(created['id']);
  }

  
  /// Marcar mensajes como leídos
 
  Future<void> marcarLeidos(String conversacionId) async {
    await supabase
        .from('conversaciones')
        .update({
          'unread_usuario1': 0,
          'unread_usuario2': 0,
        })
        .eq('id', conversacionId);
  }
}
