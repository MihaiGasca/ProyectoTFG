import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioDAO {
  final SupabaseClient client;
  UsuarioDAO(this.client);

  /// Convierte path → URL firmada
  Future<String?> generarUrlFirmada(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final signed = await client.storage
          .from('perfiles')
          .createSignedUrl(path, 3600); // 1h

      return "$signed&cache=${DateTime.now().millisecondsSinceEpoch}";
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUsuarioActual() async {
    final id = client.auth.currentUser?.id;
    if (id == null) return null;

    final data = await client
        .from('usuarios')
        .select()
        .eq('id', id)
        .maybeSingle();

    // Generar URL firmada
    if (data != null && data['foto_perfil'] != null) {
      final signed = await generarUrlFirmada(data['foto_perfil']);
      data['foto_url'] = signed;
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getPsicologosConRating() async {
    final lista = await client.rpc('get_psicologos_con_rating');

    for (final p in lista) {
      if (p['foto_perfil'] != null && p['foto_perfil'] != '') {
        p['foto_url'] = await generarUrlFirmada(p['foto_perfil']);
      }
    }

    return List<Map<String, dynamic>>.from(lista);
  }

  Future<void> actualizarPerfil({
    required String nombre,
    required String apellidos,
    required String correo,
    required String telefono,
    required String descripcion,
    required String foto, // solo path
  }) async {
    final id = client.auth.currentUser!.id;

    await client.from('usuarios').update({
      'nombre': nombre,
      'apellidos': apellidos,
      'correo': correo,
      'telefono': telefono,
      'descripcion': descripcion,
      'foto_perfil': foto, // solo path
    }).eq('id', id);
  }
}
