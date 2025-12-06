import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/disponibilidad_dao.dart';

class PantallaAgendaPsicologo extends StatefulWidget {
  const PantallaAgendaPsicologo({super.key});

  @override
  State<PantallaAgendaPsicologo> createState() =>
      _PantallaAgendaPsicologoState();
}

class _PantallaAgendaPsicologoState extends State<PantallaAgendaPsicologo> {
  late DisponibilidadDAO dao;

  List<Map<String, dynamic>> horarios = [];
  List<Map<String, dynamic>> citas = [];

  DateTime _selected = DateTime.now();
  DateTime _focused = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    dao = DisponibilidadDAO(Supabase.instance.client);
    cargar();
  }

  Future<void> cargar() async {
    final h = await dao.getDisponibilidad();
    final c = await dao.getCitas(); 

    setState(() {
      horarios = h;
      citas = c;
      loading = false;
    });
  }

  // Solo citas del día seleccionado, y además no pasadas si es hoy
  List<Map<String, dynamic>> citasDelDia(DateTime d) {
    final now = DateTime.now();

    return citas.where((c) {
      final f = DateTime.parse(c['fecha']).toLocal();

      final mismoDia =
          f.year == d.year && f.month == d.month && f.day == d.day;
      if (!mismoDia) return false;

      // Si es hoy, no mostrar horas ya pasadas
      if (DateTime(d.year, d.month, d.day) ==
          DateTime(now.year, now.month, now.day)) {
        return f.isAfter(now);
      }

      return true;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> horariosPorDia() {
    final map = <String, List<Map<String, dynamic>>>{};

    for (var h in horarios) {
      final name = _dia(h['dia_semana']);
      map.putIfAbsent(name, () => []);
      map[name]!.add(h);
    }

    // ordenar cada día por hora de inicio
    for (final entry in map.entries) {
      entry.value.sort((a, b) =>
          (a['hora_inicio'] as String).compareTo(b['hora_inicio'] as String));
    }

    return map;
  }

  String _dia(int d) {
    const dias = [
      "",
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo"
    ];
    return dias[d];
  }

  Future<void> cancelarCita(String id) async {
    await Supabase.instance.client
        .from('citas')
        .update({'estado': 'cancelada'})
        .eq('id', id);
    await cargar();
  }

  Future<void> _addHorario() async {
    int dia = DateTime.monday;
    final inicio = TextEditingController();
    final fin = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: dia,
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_dia(i + 1)),
                ),
              ),
              onChanged: (v) {
                if (v == null) return;
                setState(() => dia = v);
              },
            ),
            TextField(
              controller: inicio,
              decoration:
                  const InputDecoration(hintText: "Inicio ej: 09:00"),
            ),
            TextField(
              controller: fin,
              decoration:
                  const InputDecoration(hintText: "Fin ej: 12:00"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dao.addHorario(dia, inicio.text, fin.text);
                if (!mounted) return;
                Navigator.pop(context);
                await cargar();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _editHorario(Map h) async {
    final inicio = TextEditingController(
        text: (h['hora_inicio'] as String).substring(0, 5));
    final fin =
        TextEditingController(text: (h['hora_fin'] as String).substring(0, 5));

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: inicio,
              decoration: const InputDecoration(labelText: "Inicio (HH:MM)"),
            ),
            TextField(
              controller: fin,
              decoration: const InputDecoration(labelText: "Fin (HH:MM)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await dao.updateHorario(
                    h['id'] as String, inicio.text, fin.text);
                if (!mounted) return;
                Navigator.pop(context);
                await cargar();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  if (loading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  final citasHoy = citasDelDia(_selected);
  final horariosDia = horariosPorDia();

  return Scaffold(
    backgroundColor: const Color(0xFFFFEDEB),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFF8A80),
      title: const Text("Mi agenda"),
    ),

    floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFFFF8A80),
      child: const Icon(Icons.add),
      onPressed: _addHorario,
    ),

    body: Column(
      children: [
        const SizedBox(height: 10),

        //  CALENDARIO 
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            startingDayOfWeek: StartingDayOfWeek.monday,

            onFormatChanged: (f) => setState(() => _format = f),
            onDaySelected: (d, f) => setState(() {
              _selected = d;
              _focused = f;
            }),

            eventLoader: citasDelDia,

          
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8A80),
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

        //TARJETAS PARA CITAS
        SizedBox(
          height: 160,
          child: citasHoy.isEmpty
              ? const Center(child: Text("No hay citas"))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: citasHoy.length,
                  itemBuilder: (_, i) {
                    final c = citasHoy[i];
                    final f = DateTime.parse(c['fecha']).toLocal();
                    final u = (c['usuario'] ?? {}) ?? {};

                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(left: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${u['nombre'] ?? 'Usuario'} ${u['apellidos'] ?? ''}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${f.day}/${f.month}/${f.year}  "
                            "${f.hour.toString().padLeft(2, '0')}:"
                            "${f.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => cancelarCita(c['id']),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const Text(
          "Horarios disponibles",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFFB75C5C),
          ),
        ),

        // 🌸 HORARIOS EN TARJETAS ESTÉTICAS
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: horariosDia.entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  title: Text(
                    e.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8A80),
                    ),
                  ),
                  children: e.value.map((h) {
                    final hi = (h['hora_inicio'] as String).substring(0, 5);
                    final hf = (h['hora_fin'] as String).substring(0, 5);

                    return ListTile(
                      title: Text(
                        "$hi  -  $hf",
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await dao.deleteHorario(h['id']);
                          await cargar();
                        },
                      ),
                      onTap: () => _editHorario(h),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
}
