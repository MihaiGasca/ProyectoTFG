import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/auth_dao.dart';
import 'package:tfg/screens/home/principal.dart';

// Widgets globales
import 'package:tfg/widgets/app_footer.dart';
import 'package:tfg/widgets/app_navbar.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  String nombre = '';
  String apellidos = '';
  String email = '';
  String password = '';
  String confirmPass = '';
  String tipo = 'paciente';

  bool cargando = false;
  late final AuthDAO authDAO;

  @override
  void initState() {
    super.initState();
    authDAO = AuthDAO(Supabase.instance.client);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (password != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final res = await authDAO.register(
        email: email,
        password: password,
        nombre: nombre,
        apellidos: apellidos,
        tipo: tipo,
      );

      if (res.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaginaUsuarios()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Revisa tu correo para activar la cuenta")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en registro: $e")),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),

      ///  NAVBAR (ya incluye botón volver)
      appBar: const AppNavbar(title: "TherapyFind"),

      ///  FOOTER
      bottomNavigationBar: const AppFooter(),

      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              ///  TÍTULO
              const Text(
                "Crear cuenta",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8A80),
                ),
              ),

              const SizedBox(height: 25),

              /// TARJETA DEL FORMULARIO
              Container(
                width: 480,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),

                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _campo("Nombre", Icons.person, (v) => nombre = v!),
                      const SizedBox(height: 16),

                      _campo("Apellidos", Icons.badge, (v) => apellidos = v!),
                      const SizedBox(height: 16),

                      _campo(
                        "Correo electrónico",
                        Icons.email,
                        (v) => email = v!,
                        tipo: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _campo(
                        "Contraseña",
                        Icons.lock,
                        (v) => password = v!,
                        esPass: true,
                      ),
                      const SizedBox(height: 16),

                      _campo(
                        "Confirmar contraseña",
                        Icons.lock_outline,
                        (v) => confirmPass = v!,
                        esPass: true,
                      ),

                      const SizedBox(height: 25),

                      /// Tipo usuario
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Registrarse como:",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: tipo,
                            items: const [
                              DropdownMenuItem(
                                  value: 'paciente', child: Text('Usuario')),
                              DropdownMenuItem(
                                  value: 'psicologo', child: Text('Psicólogo')),
                            ],
                            onChanged: cargando
                                ? null
                                : (v) {
                                    if (v != null) setState(() => tipo = v);
                                  },
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      cargando
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _registrar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A80),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("Crear cuenta"),
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

  /// 🔧 Campo estilizado reutilizable
  Widget _campo(
    String label,
    IconData icon,
    Function(String?) onSaved, {
    bool esPass = false,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextFormField(
      obscureText: esPass,
      keyboardType: tipo,
      validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFFFF8A80)),
        filled: true,
        fillColor: const Color(0xFFFFF4F3),
        labelStyle: const TextStyle(fontSize: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
