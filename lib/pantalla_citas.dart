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

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  Future<void> cargarTodo() async {
    final psicologo = widget.psicologoSeleccionado!;
    final supa = Supabase.instance.client;

    final d = await supa
        .from('disponibilidad_psicologos')
        .select('dia_semana, hora_inicio')
        .eq('psicologo_id', psicologo['id'])
        .order('dia_semana, hora_inicio');

    disponibilidad = List<Map<String, dynamic>>.from(d);

    final desde = DateTime.now().toIso8601String().substring(0, 10);
    final hasta = DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String()
        .substring(0, 10);

    final c = await supa
        .from('citas')
        .select('fecha')
        .eq('psicologo_id', psicologo['id'])
        .gte('fecha::date', desde)
        .lte('fecha::date', hasta);

    citasOcupadas =
        c.map<DateTime>((e) => DateTime.parse(e['fecha'])).toList();

    setState(() => cargando = false);
  }

  List<DateTime> generarSlots() {
    final now = DateTime.now();
    List<DateTime> result = [];

    for (int i = 0; i < 30; i++) {
      final day = now.add(const Duration(days: 1)).subtract(const Duration(days: 1)).add(Duration(days: i));
      // lo anterior normaliza un poco, pero realmente podrías dejar sólo now.add(Duration(days: i))

      for (final row in disponibilidad) {
        final dia = int.parse(row['dia_semana'].toString());
        if (dia == day.weekday) {
          final parts =
              row['hora_inicio'].toString().substring(0, 5).split(':');
          result.add(DateTime(
            day.year,
            day.month,
            day.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          ));
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

  Future<void> confirmarReserva(DateTime slot) async {
    final hora =
        "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";
    final fecha = "${slot.day}/${slot.month}/${slot.year}";

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "Confirmación",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Text(
            "¿Quieres reservar el $fecha a las $hora?",
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              label: const Text("Confirmar"),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmacion == true) {
      reservar(slot);
    }
  }

  Future<void> reservar(DateTime slot) async {
    final uid = Supabase.instance.client.auth.currentUser!.id;
    final psicologo = widget.psicologoSeleccionado!;

    await Supabase.instance.client.from('citas').insert({
      'usuario_id': uid,
      'psicologo_id': psicologo['id'],
      'fecha': slot.toIso8601String(),
      'estado': 'pendiente'
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Cita solicitada")));

    cargarTodo();
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final slots = generarSlots();

    Map<DateTime, List<DateTime>> eventos = {};
    for (var slot in slots) {
      final key = DateTime(slot.year, slot.month, slot.day);
      eventos.putIfAbsent(key, () => []);
      eventos[key]!.add(slot);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar cita"),
        backgroundColor: const Color(0xFFFF8A80),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child:
                  Text(formato == CalendarFormat.month ? "Semana" : "Mes"),
              onPressed: () {
                setState(() {
                  formato = (formato == CalendarFormat.month)
                      ? CalendarFormat.week
                      : CalendarFormat.month;
                  // OJO: no tocamos diaEnfocado aquí, así no "salta" de mes
                });
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: diaEnfocado,
              calendarFormat: formato,

              startingDayOfWeek: StartingDayOfWeek.monday,
              weekendDays: const [], // no tratamos domingos como "especiales"

              selectedDayPredicate: (day) =>
                  isSameDay(diaSeleccionado, day),

              onDaySelected: (sel, foc) {
                setState(() {
                  diaSeleccionado = sel;
                  diaEnfocado = foc;
                });
              },

              // 🔧 IMPORTANTE: mantenemos el mes/semana que se está viendo
              onPageChanged: (focusedDay) {
                setState(() {
                  diaEnfocado = focusedDay;
                });
              },

              eventLoader: (day) {
                final hoy = DateTime.now();
                final limite = hoy.add(const Duration(days: 30));

                // sin eventos fuera del rango real de 30 días
                if (day.isBefore(
                        DateTime(hoy.year, hoy.month, hoy.day)) ||
                    day.isAfter(DateTime(
                        limite.year, limite.month, limite.day))) {
                  return [];
                }

                final key = DateTime(day.year, day.month, day.day);
                final eventosDia = eventos[key] ?? [];
                final libres =
                    eventosDia.where((e) => !ocupado(e)).toList();
                final ocupadosDia =
                    eventosDia.where((e) => ocupado(e)).toList();

                if (libres.isNotEmpty) return ["libre"];
                if (ocupadosDia.isNotEmpty) return ["ocupado"];
                return [];
              },

              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),

              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
              ),

              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.contains("libre")) {
                    return const Icon(Icons.circle,
                        size: 7, color: Colors.green);
                  }
                  if (events.contains("ocupado")) {
                    return const Icon(Icons.circle,
                        size: 7, color: Colors.red);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          Text(
            "Horarios del ${diaSeleccionado.day}/${diaSeleccionado.month}",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final slot
                    in (eventos[DateTime(
                              diaSeleccionado.year,
                              diaSeleccionado.month,
                              diaSeleccionado.day,
                            )] ??
                        []))
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        "${slot.hour.toString().padLeft(2, '0')}:"
                        "${slot.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      trailing: ocupado(slot)
                          ? const Text(
                              "Ocupado",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            )
                          : ElevatedButton(
                              onPressed: () => confirmarReserva(slot),
                              child: const Text("Reservar"),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
