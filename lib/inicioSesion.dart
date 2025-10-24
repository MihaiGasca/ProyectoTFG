import 'package:flutter/material.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login',
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E1),
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8BBD0),
      ),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const LoginForm(),
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        color: const Color(0xFFF8BBD0),
        alignment: Alignment.center,
        child: const Text(
          '© 2025 App Mihai',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Ajusta la altura al contenido
      children: [
        const Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: 22,
            color: Colors.pinkAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _usuarioController,
          decoration: InputDecoration(
            labelText: 'Usuario',
            prefixIcon: const Icon(Icons.person, color: Colors.pinkAccent),
            filled: true,
            fillColor: const Color(0xFFFFF0F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _contrasenaController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock, color: Colors.pinkAccent),
            filled: true,
            fillColor: const Color(0xFFFFF0F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: () {
            final usuario = _usuarioController.text;
            final contrasena = _contrasenaController.text;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Usuario: $usuario\nContraseña: $contrasena')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          child: const Text(
            'Entrar',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
