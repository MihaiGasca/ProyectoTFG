import 'package:supabase_flutter/supabase_flutter.dart';

class ValoracionesDAO {
  final SupabaseClient client;
  ValoracionesDAO(this.client);

  /// registrar valoración solo si no existe ya
  Future<void> valorar({
    required String psicologoId,
    required int puntuacion,
    String? comentario,
  }) async {
    final userId = client.auth.currentUser!.id;

    //  Evitar doble valoración
    final existe = await client
        .from('valoraciones')
        .select()
        .eq('usuario_id', userId)
        .eq('psicologo_id', psicologoId)
        .maybeSingle();

    if (existe != null) {
      throw Exception("Ya has valorado a este psicólogo");
    }

    await client.from('valoraciones').insert({
      'psicologo_id': psicologoId,
      'usuario_id': userId,
      'puntuacion': puntuacion,
      'comentario': comentario ?? '',
      'fecha': DateTime.now().toIso8601String()
    });
  }

  ///  Obtener todas las valoraciones de un psicologo nuevo
  Future<Map<String, dynamic>> getValoracionesDePsicologo(
      String psicologoId) async {
    final data = await client
        .from('valoraciones')
        .select('''
          id,
          puntuacion,
          comentario,
          fecha,
          usuario:usuario_id (nombre, apellidos, foto_perfil)
        ''')
        .eq('psicologo_id', psicologoId);

    final list = List<Map<String, dynamic>>.from(data);

    if (list.isEmpty) {
      return {
        'media': 0.0,
        'total': 0,
        'valoraciones': [],
      };
    }

    final media = list
            .map((e) => e['puntuacion'] as int)
            .reduce((a, b) => a + b) /
        list.length;

    return {
      'media': double.parse(media.toStringAsFixed(1)),
      'total': list.length,
      'valoraciones': list,
    };
  }

  ///  Obtener valoraciones del psicologo logueado
  Future<Map<String, dynamic>> getValoracionesPsicologo() async {
    final userId = client.auth.currentUser!.id;
    return getValoracionesDePsicologo(userId);
  }

  ///  Obtener valoraciones realizadas por el usuario logueado
  Future<Map<String, dynamic>> getMisValoraciones() async {
    final userId = client.auth.currentUser!.id;

    final data = await client
        .from('valoraciones')
        .select('''
          puntuacion,
          comentario,
          fecha,
          usuario:usuario_id (nombre, apellidos)
        ''')
        .eq('usuario_id', userId);

    final list = List<Map<String, dynamic>>.from(data);

    if (list.isEmpty) {
      return {
        'media': 0.0,
        'total': 0,
        'valoraciones': [],
      };
    }

    final media = list
            .map((e) => e['puntuacion'] as int)
            .reduce((a, b) => a + b) /
        list.length;

    return {
      'media': double.parse(media.toStringAsFixed(1)),
      'total': list.length,
      'valoraciones': list,
    };
  }
}
