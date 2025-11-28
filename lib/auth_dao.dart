import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDAO {
  final SupabaseClient supabase;

  AuthDAO(this.supabase);

  /// Iniciar sesión
  Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Registrar usuario: crea en Auth y en tabla usuarios
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    String tipo = 'usuario',
  }) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      // Puede que el registro necesite confirmación; igualmente devolvemos res
      return res;
    }

    // Insertar registro en tabla usuarios
    await supabase.from('usuarios').insert({
      'id': user.id,
      'tipo': tipo,
      'nombre': nombre,
      'apellidos': apellidos,
      'correo': email,
      'telefono': '',
      'foto_perfil': '',
      'descripcion': '',
      'tags': [],
    });

    return res;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
