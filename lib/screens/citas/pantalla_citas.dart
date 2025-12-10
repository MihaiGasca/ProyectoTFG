import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class PantallaCitas extends StatefulWidget {
  final Map<String, dynamic>? psicologoSeleccionado;

  const PantallaCitas({super.key, this.psicologoSeleccionado});

  @override
  State<PantallaCitas> createState() => _PantallaCitasState();
}

class _PantallaCitasState extends State<PantallaCitas> {
  bool cargando = true;

  List<Map<String, dynamic>> disponibilidad = [];
  List<DateTime> citasOcupadas = [];

  DateTime diaSeleccionado = DateTime.now();
  DateTime diaEnfocado = DateTime.now();
  CalendarFormat formato = CalendarFormat.month;

  RealtimeChannel? canal;

  @override
  void initState() {
    super.initState();
    cargarTodo();
    _supabaseListener();
  }

  @override
  void dispose() {
    canal?.unsubscribe();
    super.dispose();
  }

  void _supabaseListener() {
    final supa = Supabase.instance.client;

    canal = supa.channel('citas-changes');

    canal!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'citas',
          callback: (payload) {
            cargarTodo();
          },
        )
        .subscribe();
  }

  Future<void> cargarTodo() async {
    final supa = Supabase.instance.client;
    final psicologo = widget.psicologoSeleccionado!;

    try {
      final d = await supa
          .from('disponibilidad_psicologos')
          .select('dia_semana, hora_inicio')
          .eq('psicologo_id', psicologo['id'])
          .order('dia_semana, hora_inicio');

      disponibilidad = List<Map<String, dynamic>>.from(d);

      final desde = DateTime.now().toIso8601String();
      final hasta =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();

      final c = await supa
          .from('citas')
          .select('fecha, estado')
          .eq('psicologo_id', psicologo['id'])
          .gt('fecha', desde)
          .lte('fecha', hasta)
          .neq('estado', 'cancelada');

      citasOcupadas = c
          .where((e) => e['estado'] != 'cancelada')
          .map<DateTime>((e) => parseLocal(e['fecha']))
          .toList();
    } catch (_) {}

    if (mounted) setState(() => cargando = false);
  }

  DateTime parseLocal(String fecha) {
    final dt = DateTime.parse(fecha);
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  List<DateTime> generarSlots() {
    final List<DateTime> result = [];
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final day = now.add(Duration(days: i));

      for (final row in disponibilidad) {
        if (int.parse(row['dia_semana'].toString()) == day.weekday) {
          final parts =
              row['hora_inicio'].toString().substring(0, 5).split(':');

          final slot = DateTime(
            day.year,
            day.month,
            day.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );

          if (slot.isAfter(DateTime.now())) {
            result.add(slot);
          }
        }
      }
    }

    return result;
  }

  bool ocupado(DateTime slot) {
    return citasOcupadas.any((c) =>
        c.year == slot.year &&
        c.month == slot.month &&
        c.day == slot.day &&
        c.hour == slot.hour &&
        c.minute == slot.minute);
  }

  Future<void> reservar(DateTime slot) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final psicologo = widget.psicologoSeleccionado!;

    final slotUtc = DateTime.utc(
      slot.year,
      slot.month,
      slot.day,
      slot.hour,
      slot.minute,
    );

    final fechaSql =
        "${slotUtc.year}-${slotUtc.month.toString().padLeft(2, '0')}-${slotUtc.day.toString().padLeft(2, '0')} "
        "${slotUtc.hour.toString().padLeft(2, '0')}:${slotUtc.minute.toString().padLeft(2, '0')}:00";

    await Supabase.instance.client.from('citas').insert({
      'usuario_id': uid,
      'psicologo_id': psicologo['id'],
      'fecha': fechaSql,
      'estado': 'pendiente',
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Cita solicitada")));

    await cargarTodo();
  }

  Future<void> confirmarReserva(DateTime slot) async {
    final fecha = "${slot.day}/${slot.month}/${slot.year}";
    final hora =
        "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirmar reserva"),
        content: Text("¿Reservar el $fecha a las $hora?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A80)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );

    if (confirmar == true) reservar(slot);
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final slots = generarSlots();
    Map<DateTime, List<DateTime>> eventos = {};

    for (final slot in slots) {
      final key = DateTime(slot.year, slot.month, slot.day);
      eventos.putIfAbsent(key, () => []);
      eventos[key]!.add(slot);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFEDEB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFF8A80),
            title: const Text("Reservar cita"),
          ),
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 30)),
                      focusedDay: diaEnfocado,
                      calendarFormat: formato,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      rowHeight: 42,
                      daysOfWeekHeight: 32,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, diaSeleccionado),
                      onDaySelected: (sel, foc) {
                        setState(() {
                          diaSeleccionado = sel;
                          diaEnfocado = foc;
                        });
                      },
                      onFormatChanged: (f) => setState(() => formato = f),
                      eventLoader: (day) {
                        final key =
                            DateTime(day.year, day.month, day.day);
                        return eventos[key] ?? [];
                      },
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
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final ev = events.whereType<DateTime>().toList();
                          if (ev.isEmpty) return null;

                          final total = ev.length;
                          final ocupadas = ev.where((e) => ocupado(e)).length;

                          return Positioned(
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$ocupadas/$total",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Horarios del ${diaSeleccionado.day}/${diaSeleccionado.month}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB75C5C),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final slot
                          in eventos[DateTime(
                                  diaSeleccionado.year,
                                  diaSeleccionado.month,
                                  diaSeleccionado.day)] ??
                              [])
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
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
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ocupado(slot)
                                  ? const Text(
                                      "Ocupado",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFF8A80),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () =>
                                          confirmarReserva(slot),
                                      child: const Text(
                                        "Reservar",
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
