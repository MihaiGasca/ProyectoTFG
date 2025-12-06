import 'package:supabase_flutter/supabase_flutter.dart';

class DisponibilidadDAO {
  final SupabaseClient supabase;

  DisponibilidadDAO(this.supabase);

  //  HORARIOS DEL PSICÓLOGO
  
  Future<List<Map<String, dynamic>>> getDisponibilidad() async {
    final uid = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('disponibilidad_psicologos')
        .select('id, dia_semana, hora_inicio, hora_fin')
        .eq('psicologo_id', uid)
        .order('dia_semana', ascending: true)
        .order('hora_inicio', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return h * 60 + m;
  }

  bool _seSolapan(String start1, String end1, String start2, String end2) {
    final s1 = _toMinutes(start1);
    final e1 = _toMinutes(end1);
    final s2 = _toMinutes(start2);
    final e2 = _toMinutes(end2);

    // (s1, e1) se solapa con (s2, e2) si no se cumple que uno acaba antes de que empiece el otro
    return !(e1 <= s2 || e2 <= s1);
  }

  // Crear horario nuevo con validaciones y sin solapamientos
  Future<void> addHorario(int diaSemana, String horaInicio, String horaFin) async {
    final uid = supabase.auth.currentUser!.id;

    horaInicio = horaInicio.trim();
    horaFin = horaFin.trim();

    if (horaInicio.isEmpty || horaFin.isEmpty) {
      throw Exception("Debes indicar hora de inicio y fin");
    }

    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(horaInicio) ||
        !RegExp(r'^\d{2}:\d{2}$').hasMatch(horaFin)) {
      throw Exception("Formato de hora inválido. Usa HH:MM (ej: 09:00)");
    }

    if (_toMinutes(horaFin) <= _toMinutes(horaInicio)) {
      throw Exception("La hora de fin debe ser posterior a la de inicio");
    }

    // Cargar horarios existentes del mismo día
    final existentes = await supabase
        .from('disponibilidad_psicologos')
        .select('hora_inicio, hora_fin')
        .eq('psicologo_id', uid)
        .eq('dia_semana', diaSemana);

    for (final h in existentes) {
      final hi = (h['hora_inicio'] as String).substring(0, 5);
      final hf = (h['hora_fin'] as String).substring(0, 5);

      if (_seSolapan(horaInicio, horaFin, hi, hf)) {
        throw Exception(
            "Este intervalo se solapa con otro existente ($hi - $hf)");
      }
    }

    await supabase.from('disponibilidad_psicologos').insert({
      'psicologo_id': uid,
      'dia_semana': diaSemana,
      'hora_inicio': "$horaInicio:00",
      'hora_fin': "$horaFin:00",
    });
  }

  // Editar horario existente
  Future<void> updateHorario(String id, String horaInicio, String horaFin) async {
    final uid = supabase.auth.currentUser!.id;

    horaInicio = horaInicio.trim();
    horaFin = horaFin.trim();

    if (horaInicio.isEmpty || horaFin.isEmpty) {
      throw Exception("Debes indicar hora de inicio y fin");
    }

    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(horaInicio) ||
        !RegExp(r'^\d{2}:\d{2}$').hasMatch(horaFin)) {
      throw Exception("Formato de hora inválido. Usa HH:MM (ej: 09:00)");
    }

    if (_toMinutes(horaFin) <= _toMinutes(horaInicio)) {
      throw Exception("La hora de fin debe ser posterior a la de inicio");
    }

    // buscamos el registro para saber el día de la semana
    final actual = await supabase
        .from('disponibilidad_psicologos')
        .select('dia_semana')
        .eq('id', id)
        .maybeSingle();

    if (actual == null) {
      throw Exception("Horario no encontrado");
    }

    final diaSemana = actual['dia_semana'] as int;

    // Cargar otros horarios del mismo día excluyendo este id
    final existentes = await supabase
        .from('disponibilidad_psicologos')
        .select('id, hora_inicio, hora_fin')
        .eq('psicologo_id', uid)
        .eq('dia_semana', diaSemana)
        .neq('id', id);

    for (final h in existentes) {
      final hi = (h['hora_inicio'] as String).substring(0, 5);
      final hf = (h['hora_fin'] as String).substring(0, 5);

      if (_seSolapan(horaInicio, horaFin, hi, hf)) {
        throw Exception(
            "Este intervalo se solapa con otro existente ($hi - $hf)");
      }
    }

    await supabase
        .from('disponibilidad_psicologos')
        .update({
          'hora_inicio': "$horaInicio:00",
          'hora_fin': "$horaFin:00",
        })
        .eq('id', id);
  }

  Future<void> deleteHorario(String id) async {
    await supabase
        .from('disponibilidad_psicologos')
        .delete()
        .eq('id', id);
  }

  //  CITAS DEL PSICÓLOGO SOLO FUTURAS NO CANCELADAS
  Future<List<Map<String, dynamic>>> getCitas() async {
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
        .neq('estado', 'cancelada')
        .order('fecha');

    final list = List<Map<String, dynamic>>.from(res);
    final now = DateTime.now();

    // Filtramos en cliente para evitar líos de zona horaria
    return list.where((c) {
      final f = DateTime.parse(c['fecha']).toLocal();
      return f.isAfter(now);
    }).toList();
  }
}
