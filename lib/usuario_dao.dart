import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioDAO {
  final SupabaseClient supabase;

  UsuarioDAO(this.supabase);

  Future<List<Map<String, dynamic>>> getPsicologos() async {
    final data = await supabase
        .from('usuarios')
        .select()
        .eq('tipo', 'psicologo');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> getUsuarioActual() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final data = await supabase
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellidos,
    required String correo,
    required String telefono,
    required String descripcion,
    required String foto,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    await supabase.from('usuarios').update({
      'nombre': nombre,
      'apellidos': apellidos,
      'correo': correo,
      'telefono': telefono,
      'descripcion': descripcion,
      'foto_perfil': foto,
    }).eq('id', user.id);

    return true;
  }

  Future<Map<String, dynamic>?> getUsuarioPorId(String id) async {
    final data = await supabase.from('usuarios').select().eq('id', id).maybeSingle();
    return data;
  }
}
