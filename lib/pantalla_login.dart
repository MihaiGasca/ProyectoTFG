import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_dao.dart';
import 'pantalla_registro.dart';
import 'principal.dart';

// Widgets globales
import 'widgets/app_navbar.dart';
import 'widgets/app_footer.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool cargando = false;

  late final AuthDAO authDAO;

  @override
  void initState() {
    super.initState();
    authDAO = AuthDAO(Supabase.instance.client);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => cargando = true);
    try {
      final res = await authDAO.login(email, password);

      if (res.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaginaUsuarios()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas o pendiente confirmación'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  void _irRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PantallaRegistro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(title: "TherapyFind"),
      bottomNavigationBar: const AppFooter(),

      body: Center(
        child: SizedBox(
          width: 480, // 🔥 50% más grande
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32), // 🔥 Más padding
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 36, // 🔥 Más grande
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDB6A68),
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        labelStyle: TextStyle(fontSize: 20), // <-- grande
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatorio' : null,
                      onSaved: (v) => email = v!.trim(),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: TextStyle(fontSize: 20),
                      ),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Obligatorio' : null,
                      onSaved: (v) => password = v!.trim(),
                    ),

                    const SizedBox(height: 30),

                    cargando
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 32),
                              textStyle: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Entrar'),
                          ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: _irRegistro,
                      child: const Text(
                        '¿No tienes cuenta? Regístrate',
                        style: TextStyle(
                          fontSize: 18, // Más grande
                          color: Color(0xFFDB6A68),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
