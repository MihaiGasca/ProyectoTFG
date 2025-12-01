import 'package:supabase_flutter/supabase_flutter.dart';

class CitasDAO {
  final SupabaseClient supabase;

  CitasDAO(this.supabase);

  // -------------------------
  //  Citas del PACIENTE
  // -------------------------
  Future<List<Map<String, dynamic>>> getCitasUsuario() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('citas')
        .select('''
          id,
          fecha,
          estado,
          psicologo:psicologo_id (
            id,
            nombre,
            apellidos
          )
        ''')
        .eq('usuario_id', uid)
        .order('fecha');

    return List<Map<String, dynamic>>.from(res);
  }

  // -------------------------
  //  Citas del PSICÓLOGO
  // -------------------------
  Future<List<Map<String, dynamic>>> getCitasPsicologo() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('citas')
        .select('''
          id,
          fecha,
          estado,
          usuario:usuario_id (
            id,
            nombre,
            apellidos
          )
        ''')
        .eq('psicologo_id', uid)
        .order('fecha');

    return List<Map<String, dynamic>>.from(res);
  }

  // -------------------------
  //  Cancelar cita
  // -------------------------
  Future<void> cancelarCita(String id) async {
    await supabase
        .from('citas')
        .update({'estado': 'cancelada'})
        .eq('id', id);
  }
}
