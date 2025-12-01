import 'package:flutter/material.dart';
import 'auth_dao.dart';
import 'principal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revisa tu correo para activar la cuenta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en registro: $e')),
      );
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                onSaved: (v) => nombre = v!.trim(),
              ),
              const SizedBox(height: 8),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellidos'),
                validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                onSaved: (v) => apellidos = v!.trim(),
              ),
              const SizedBox(height: 8),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                onSaved: (v) => email = v!.trim(),
              ),
              const SizedBox(height: 8),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                onSaved: (v) => password = v!.trim(),
              ),
              const SizedBox(height: 8),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                obscureText: true,
                validator: (v) => v!.trim() != password ? 'Las contraseñas no coinciden' : null,
                onSaved: (v) => confirmPass = v!.trim(),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Registrarse como:'),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: tipo,
                    items: const [
                      DropdownMenuItem(value: 'paciente', child: Text('Usuario')),
                      DropdownMenuItem(value: 'psicologo', child: Text('Psicólogo')),
                    ],
                    onChanged: (!cargando)
                        ? (v) {
                            if (v != null) setState(() => tipo = v);
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A80)),
                      onPressed: _registrar,
                      child: const Text('Crear cuenta'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
