import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'citas_dao.dart';

class PantallaCitasUsuario extends StatefulWidget {
  const PantallaCitasUsuario({super.key});

  @override
  State<PantallaCitasUsuario> createState() => _PantallaCitasUsuarioState();
}

class _PantallaCitasUsuarioState extends State<PantallaCitasUsuario> {
  late final CitasDAO citasDAO;

  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  bool _loading = true;
  List<Map<String, dynamic>> todas = [];

  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    citasDAO = CitasDAO(Supabase.instance.client);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);

    try {
      todas = await citasDAO.getCitasUsuario();
      // debug:
      // print("CITAS USUARIO: $todas");
    } catch (e) {
      // print("ERROR al cargar citas: $e");
    }

    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _citasDia(DateTime d) {
    final dClean = DateTime(d.year, d.month, d.day);

    return todas.where((c) {
      final f = DateTime.parse(c['fecha']);
      final fClean = DateTime(f.year, f.month, f.day);
      return fClean == dClean;
    }).toList();
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'aceptada':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelarCitaConConfirmacion(Map<String, dynamic> cita) async {
    final psic = cita['psicologo'];
    final f = DateTime.parse(cita['fecha']);
    final fechaStr =
        "${f.day}/${f.month}/${f.year} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}";

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Cancelar cita"),
          content: Text(
            "¿Seguro que quieres cancelar la cita con "
            "${psic['nombre']} ${psic['apellidos']} \nel $fechaStr?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sí, cancelar"),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await citasDAO.cancelarCita(cita['id'] as String);
      await _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cita cancelada")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final citasHoy = _citasDia(_selected);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis citas"),
        backgroundColor: const Color(0xFFFF8A80),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: Text(
                _format == CalendarFormat.month ? "Semana" : "Mes",
              ),
              onPressed: () {
                setState(() {
                  _format = (_format == CalendarFormat.month)
                      ? CalendarFormat.week
                      : CalendarFormat.month;
                });
              },
            ),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2030),
                  focusedDay: _focused,
                  calendarFormat: _format,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  weekendDays: const [],

                  selectedDayPredicate: (d) => isSameDay(d, _selected),

                  onDaySelected: (day, focusedDay) {
                    setState(() {
                      _selected = day;
                      _focused = focusedDay;
                    });
                  },

                  onPageChanged: (focusedDay) {
                    setState(() => _focused = focusedDay);
                  },

                  eventLoader: (day) =>
                      _citasDia(DateTime(day.year, day.month, day.day)),
                ),

                const Divider(),

                Expanded(
                  child: citasHoy.isEmpty
                      ? const Center(child: Text("No hay citas este día"))
                      : ListView.builder(
                          itemCount: citasHoy.length,
                          itemBuilder: (_, i) {
                            final c = citasHoy[i];
                            final psic = c['psicologo'];
                            final f = DateTime.parse(c['fecha']);

                            final estado = (c['estado'] ?? '').toString();

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  "${psic['nombre']} ${psic['apellidos']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "${f.day}/${f.month}/${f.year}  "
                                  "${f.hour.toString().padLeft(2, '0')}:"
                                  "${f.minute.toString().padLeft(2, '0')}",
                                ),
                                leading: Icon(
                                  Icons.circle,
                                  color: _colorEstado(estado),
                                ),
                                trailing: estado != 'cancelada'
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _cancelarCitaConConfirmacion(c),
                                      )
                                    : const Text(
                                        "Cancelada",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
