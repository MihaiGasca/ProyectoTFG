import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'citas_dao.dart';
import 'pantalla_perfil.dart';  // SOLO este

class PantallaCitas extends StatefulWidget {
  final Map<String, dynamic>? psicologoSeleccionado;
  const PantallaCitas({super.key, this.psicologoSeleccionado});

  @override
  State<PantallaCitas> createState() => _PantallaCitasState();
}

class _PantallaCitasState extends State<PantallaCitas> {
  final citasDAO = CitasDAO(Supabase.instance.client);

  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  bool _loading = true;
  List<Map<String, dynamic>> _citasUsuario = [];

  final Map<int, List<String>> _tramosPorDiaSemana = {
    DateTime.monday: ['09:00', '10:30', '12:00', '16:00'],
    DateTime.tuesday: ['09:30', '11:00', '14:00', '17:00'],
    DateTime.wednesday: ['09:00', '10:30', '12:00', '16:00'],
    DateTime.thursday: ['09:30', '11:00', '14:00', '17:00'],
    DateTime.friday: ['09:00', '10:30', '12:00'],
    DateTime.saturday: ['10:00', '11:30'],
    DateTime.sunday: [],
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);

    try {
      _citasUsuario = await citasDAO.getCitasUsuario();
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final psicologo = widget.psicologoSeleccionado;

    return Scaffold(
      appBar: AppBar(
        title: Text(psicologo != null ? "Reservar cita" : "Mis citas"),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : psicologo != null
              ? _buildModoReserva(psicologo)
              : _buildModoUsuario(),
    );
  }

  // ------------------------------------------------------------------
  //     👤 MODO USUARIO NORMAL
  // ------------------------------------------------------------------
  Widget _buildModoUsuario() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2030),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(d, _selected),
          onDaySelected: (sel, foc) =>
              setState(() => {_selected = sel, _focused = foc}),
        ),
        Expanded(
          child: ListView(
            children: _citasUsuario.map((c) {
              final psic = c['psicologo'];
              return ListTile(
                title: Text("${psic['nombre']} ${psic['apellidos']}"),
                subtitle: Text("Fecha: ${c['fecha']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaPerfil(psicologo: psic),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  //     👤 MODO RESERVAR CITA CON PSICÓLOGO
  // ------------------------------------------------------------------
  Widget _buildModoReserva(Map<String, dynamic> psicologo) {
    final tramos = _tramosPorDiaSemana[_selected.weekday] ?? [];

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: (psicologo['foto_perfil'] ?? "").isNotEmpty
                ? NetworkImage(psicologo['foto_perfil'])
                : null,
          ),
          title: Text("${psicologo['nombre']} ${psicologo['apellidos']}"),
          subtitle: Text(psicologo['descripcion'] ?? ""),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaPerfil(psicologo: psicologo),
              ),
            );
          },
        )
      ],
    );
  }
}
