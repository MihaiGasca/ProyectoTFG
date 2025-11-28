import 'package:supabase_flutter/supabase_flutter.dart';

class CitasDAO {
  final SupabaseClient supabase;
  CitasDAO(this.supabase);

  /// Citas del usuario actual
  Future<List<Map<String, dynamic>>> getCitasUsuario() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final resp = await supabase
        .from('citas')
        .select('''
          id,
          fecha,
          estado,
          motivo_cancelacion,
          created_at,
          psicologo:psicologo_id(id,nombre,apellidos,foto_perfil)
        ''')
        .eq('usuario_id', user.id)
        .order('fecha', ascending: true);

    return List<Map<String, dynamic>>.from(resp);
  }

  /// Citas de un psicólogo (agenda)
  Future<List<Map<String, dynamic>>> getCitasPsicologo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final resp = await supabase
        .from('citas')
        .select('''
          id,
          fecha,
          estado,
          motivo_cancelacion,
          created_at,
          usuario:usuario_id(id,nombre,apellidos,foto_perfil)
        ''')
        .eq('psicologo_id', user.id)
        .order('fecha', ascending: true);

    return List<Map<String, dynamic>>.from(resp);
  }

  /// Crear nueva cita
  Future<Map<String, dynamic>> crearCita({
    required String psicologoId,
    required DateTime fecha,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("No autenticado");

    final insert = await supabase.from('citas').insert({
      'usuario_id': user.id,
      'psicologo_id': psicologoId,
      'fecha': fecha.toIso8601String(),
      'estado': 'pendiente',
    }).select().single();

    return Map<String, dynamic>.from(insert);
  }

  /// Aceptar cita (psicólogo)
  Future<void> aceptarCita(String citaId) async {
    await supabase.from('citas').update({
      'estado': 'aceptada',
      'motivo_cancelacion': null,
    }).eq('id', citaId);
  }

  /// Rechazar / cancelar cita con motivo (psicólogo o usuario)
  Future<void> cancelarCita(String citaId, String motivo) async {
    await supabase.from('citas').update({
      'estado': 'cancelada',
      'motivo_cancelacion': motivo,
    }).eq('id', citaId);
  }
}
