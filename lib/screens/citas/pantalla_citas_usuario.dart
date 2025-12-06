import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg/data/dao/citas_dao.dart';

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
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _citasDia(DateTime d) {
    final dClean = DateTime(d.year, d.month, d.day);

    return todas.where((c) {
      final f = DateTime.parse(c['fecha']).toLocal();
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
    final f = DateTime.parse(cita['fecha']).toLocal();
    final fechaStr =
        "${f.day}/${f.month}/${f.year} ${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}";

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancelar cita"),
        content: Text(
            "¿Cancelar cita con ${psic['nombre']} ${psic['apellidos']} el $fechaStr?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, cancelar"),
          )
        ],
      ),
    );

    if (confirmar == true) {
      await citasDAO.cancelarCita(cita['id'] as String);
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final citasHoy = _citasDia(_selected);

    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        title: const Text("Mis citas"),
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),

                // CALENDARIO
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020),
                    lastDay: DateTime.utc(2030),
                    focusedDay: _focused,
                    calendarFormat: _format,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),

                    onDaySelected: (day, f) => setState(() {
                      _selected = day;
                      _focused = f;
                    }),
                    onPageChanged: (f) => setState(() => _focused = f),

                    eventLoader: (day) => _citasDia(
                      DateTime(day.year, day.month, day.day),
                    ),

                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFFFFC4BD),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: const Color(0xFFFF8A80),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Citas del día",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFB75C5C),
                  ),
                ),
                const SizedBox(height: 10),

                
                SizedBox(
                  height: 170,
                  child: citasHoy.isEmpty
                      ? const Center(child: Text("No hay citas este día"))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: citasHoy.length,
                          itemBuilder: (_, i) {
                            final c = citasHoy[i];
                            final psic = c['psicologo'];
                            final f = DateTime.parse(c['fecha']).toLocal();

                            return Container(
                              width: 230,
                              margin: const EdgeInsets.only(left: 18),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${psic['nombre']} ${psic['apellidos']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${f.day}/${f.month}/${f.year} "
                                    "${f.hour.toString().padLeft(2, '0')}:"
                                    "${f.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      onPressed: c['estado'] == "cancelada"
                                          ? null
                                          : () =>
                                              _cancelarCitaConConfirmacion(c),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 1),

              ],
            ),
    );
  }
}
