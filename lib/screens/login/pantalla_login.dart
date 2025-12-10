import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/screens/home/principal.dart';

import 'package:tfg/data/dao/auth_dao.dart';
import 'pantalla_registro.dart';

// Widgets globales
import 'package:tfg/widgets/app_footer.dart';
import 'package:tfg/widgets/app_navbar.dart';

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
            content:
                Text('Credenciales incorrectas o usuario pendiente de confirmar'),
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

      backgroundColor: const Color(0xFFFFEDEB),

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// TÍTULO
              const Text(
                "Bienvenido",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A80),
                ),
              ),

              const SizedBox(height: 20),

              ///  TARJETA PRINCIPAL
              Container(
                width: 420,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Iniciar sesión",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDB6A68),
                        ),
                      ),

                      const SizedBox(height: 25),

                      /// EMAIL
                      _input(
                        label: "Correo electrónico",
                        icon: Icons.email_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Obligatorio" : null,
                        onSaved: (v) => email = v!.trim(),
                      ),

                      const SizedBox(height: 20),

                      /// CONTRASEÑA
                      _input(
                        label: "Contraseña",
                        icon: Icons.lock_outline,
                        obscure: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Obligatorio" : null,
                        onSaved: (v) => password = v!.trim(),
                      ),

                      const SizedBox(height: 35),

                      ///  BOTÓN LOGIN
                      cargando
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A80),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("Entrar"),
                              ),
                            ),

                      const SizedBox(height: 20),

                      ///  REGISTRO
                      TextButton(
                        onPressed: _irRegistro,
                        child: const Text(
                          "¿No tienes cuenta? Regístrate",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFDB6A68),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Estilo  inputs
  Widget _input({
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      obscureText: obscure,
      validator: validator,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFF8A80)),
        filled: true,
        fillColor: const Color(0xFFFFF4F3),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
