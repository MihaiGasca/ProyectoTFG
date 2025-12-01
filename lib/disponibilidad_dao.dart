import 'package:supabase_flutter/supabase_flutter.dart';

class DisponibilidadDAO {
  final SupabaseClient supabase;

  DisponibilidadDAO(this.supabase);

  Future<List<Map<String, dynamic>>> getDisponibilidad() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('disponibilidad_psicologos')
        .select()
        .eq('psicologo_id', uid)
        .order('dia_semana')
        .order('hora_inicio');

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getCitas() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('citas')
        .select('''
          id,
          fecha,
          usuario:usuario_id(nombre,apellidos)
        ''')
        .eq('psicologo_id', uid)
        .neq('estado', 'cancelada')
        .order('fecha');

    return List<Map<String, dynamic>>.from(res);
  }

  // ========== solapamiento corregido ==========
  bool _overlap(String aStart, String aEnd, String bStart, String bEnd) {
    final start1 = _parse(aStart);
    final end1   = _parse(aEnd);
    final start2 = _parse(bStart);
    final end2   = _parse(bEnd);

    return start1 < end2 && start2 < end1;
  }

  Duration _parse(String hhmm) {
    final parts = hhmm.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  Future<void> addHorario(int dia, String inicio, String fin) async {
    if (inicio.length != 5 || fin.length != 5) {
      throw Exception("Formato horario incorrecto (HH:MM)");
    }

    final existentes = await getDisponibilidad();

    for (final h in existentes) {
      if (h['dia_semana'] == dia) {
        final hi = h['hora_inicio'];
        final hf = h['hora_fin'] ?? hi;

        if (_overlap(inicio, fin, hi, hf)) {
          throw Exception("Horario solapado con otro existente");
        }
      }
    }

    await supabase.from('disponibilidad_psicologos').insert({
      'psicologo_id': supabase.auth.currentUser!.id,
      'dia_semana': dia,
      'hora_inicio': inicio,
      'hora_fin': fin,
    });
  }

  Future<void> deleteHorario(String id) async {
    await supabase
        .from('disponibilidad_psicologos')
        .delete()
        .eq('id', id);
  }

  Future<void> updateHorario(String id, String inicio, String fin) async {
    await supabase
        .from('disponibilidad_psicologos')
        .update({
          'hora_inicio': inicio,
          'hora_fin': fin,
        })
        .eq('id', id);
  }
}
