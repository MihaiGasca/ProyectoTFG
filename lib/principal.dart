import 'package:flutter/material.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Usuarios Expandibles',
      home: PaginaUsuarios(),
    );
  }
}

class PaginaUsuarios extends StatefulWidget {
  const PaginaUsuarios({super.key});

  @override
  State<PaginaUsuarios> createState() => _PaginaUsuariosState();
}

class _PaginaUsuariosState extends State<PaginaUsuarios> {
  final List<Map<String, String>> usuarios = const [
    {'nombre': 'Juan', 'apellidos': 'Pérez López'},
    {'nombre': 'María', 'apellidos': 'Gómez Sánchez'},
    {'nombre': 'Carlos', 'apellidos': 'Ramírez Ortega'},
    {'nombre': 'Lucía', 'apellidos': 'Fernández Ruiz'},
    {'nombre': 'Ana', 'apellidos': 'Martínez Díaz'},
  ];

  int? _indiceExpandido; // guarda cuál usuario está abierto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        centerTitle: true,
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 🔹 Barra de opciones debajo del navbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: const Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OpcionMenu(
                  icono: Icons.chat_bubble_outline,
                  texto: 'Chat',
                  onTap: () => _mostrarMensaje(context, 'Chat'),
                ),
                _OpcionMenu(
                  icono: Icons.filter_alt_outlined,
                  texto: 'Filtros',
                  onTap: () => _mostrarMensaje(context, 'Filtros'),
                ),
                _OpcionMenu(
                  icono: Icons.person_outline,
                  texto: 'Mi perfil',
                  onTap: () => _mostrarMensaje(context, 'Mi perfil'),
                ),
                _OpcionMenu(
                  icono: Icons.calendar_today_outlined,
                  texto: 'Citas',
                  onTap: () => _mostrarMensaje(context, 'Citas'),
                ),
              ],
            ),
          ),

          // 🔹 Lista expandible de usuarios
          Expanded(
            child: ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];
                final bool estaExpandido = _indiceExpandido == index;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    key: Key(index.toString()),
                    initiallyExpanded: estaExpandido,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _indiceExpandido = expanded ? index : null;
                      });
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(usuario['nombre']![0],
                          style: const TextStyle(color: Colors.black87)),
                    ),
                    title: Text(usuario['nombre'] ?? ''),
                    subtitle: Text(usuario['apellidos'] ?? ''),
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BotonAccion(
                              icono: Icons.message_outlined,
                              texto: 'Mensaje',
                              onTap: () => _mostrarMensaje(context,
                                  'Enviar mensaje a ${usuario['nombre']}'),
                            ),
                            _BotonAccion(
                              icono: Icons.calendar_today_outlined,
                              texto: 'Pedir cita',
                              onTap: () => _mostrarMensaje(context,
                                  'Pedir cita con ${usuario['nombre']}'),
                            ),
                            _BotonAccion(
                              icono: Icons.person_search_outlined,
                              texto: 'Ver perfil',
                              onTap: () => _mostrarMensaje(context,
                                  'Ver perfil de ${usuario['nombre']}'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Text(
          '© 2025 Mi App Flutter',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }

  void _mostrarMensaje(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }
}

// 🔸 Pequeños widgets reutilizables

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _OpcionMenu({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 24, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            texto,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icono, color: Colors.black87),
      label: Text(
        texto,
        style: const TextStyle(color: Colors.black87),
      ),
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
