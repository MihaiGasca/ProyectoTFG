// lib/conversacion_dao.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ConversacionDAO {
  final SupabaseClient supabase;
  ConversacionDAO(this.supabase);

  /// -------------------------------------------------------
  ///  🔥 Obtener todas las conversaciones del usuario actual
  /// -------------------------------------------------------
  Future<List<Map<String, dynamic>>> getConversacionesUsuario() async {
    final me = supabase.auth.currentUser;
    if (me == null) return [];

    final resp = await supabase
        .from('conversaciones')
        .select('''
          id,
          usuario1_id,
          usuario2_id,
          updated_at,
          usuario1:usuario1_id(id,nombre,apellidos,foto_perfil),
          usuario2:usuario2_id(id,nombre,apellidos,foto_perfil)
        ''')
        .or('usuario1_id.eq.${me.id},usuario2_id.eq.${me.id}')
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(resp);
  }

  /// -------------------------------------------------------
  ///  🔥 Buscar o crear conversación EXACTA entre dos usuarios
  /// -------------------------------------------------------
  Future<Map<String, dynamic>> getOrCreateConversation(String otherUserId) async {
    final me = supabase.auth.currentUser;
    if (me == null) throw Exception('No autenticado');

    // 🔎 Buscar conversación directa
    final direct = await supabase
        .from('conversaciones')
        .select()
        .match({'usuario1_id': me.id, 'usuario2_id': otherUserId})
        .maybeSingle();

    if (direct != null) {
      return Map<String, dynamic>.from(direct);
    }

    // 🔎 Buscar conversación inversa
    final inverse = await supabase
        .from('conversaciones')
        .select()
        .match({'usuario1_id': otherUserId, 'usuario2_id': me.id})
        .maybeSingle();

    if (inverse != null) {
      return Map<String, dynamic>.from(inverse);
    }

    // 🆕 Crear nueva conversación
    final created = await supabase.from('conversaciones').insert({
      'usuario1_id': me.id,
      'usuario2_id': otherUserId,
      'updated_at': DateTime.now().toIso8601String()
    }).select().single();

    return Map<String, dynamic>.from(created);
  }

  /// -------------------------------------------------------
  ///  🔥 Actualizar updated_at (llamar tras enviar mensaje)
  /// -------------------------------------------------------
  Future<void> actualizarUltimoMovimiento(String conversacionId) async {
    await supabase.from('conversaciones').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversacionId);
  }
}
