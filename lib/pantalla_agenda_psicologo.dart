import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'disponibilidad_dao.dart';

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

  List<Map<String, dynamic>> citasDelDia(DateTime d) {
    return citas.where((c) {
      final f = DateTime.parse(c['fecha']);
      return f.year == d.year && f.month == d.month && f.day == d.day;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> horariosPorDia() {
    final map = <String, List<Map<String, dynamic>>>{};

    for (var h in horarios) {
      final name = _dia(h['dia_semana']);
      map.putIfAbsent(name, () => []);
      map[name]!.add(h);
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
    cargar();
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
              onChanged: (v) => setState(() => dia = v!),
            ),
            TextField(
              controller: inicio,
              decoration: const InputDecoration(hintText: "Inicio ej: 09:00"),
            ),
            TextField(
              controller: fin,
              decoration: const InputDecoration(hintText: "Fin ej: 12:00"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              try {
                await dao.addHorario(dia, inicio.text, fin.text);
                Navigator.pop(context);
                cargar();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  Future<void> _editHorario(Map h) async {
    final inicio = TextEditingController(text: h['hora_inicio']);
    final fin = TextEditingController(text: h['hora_fin']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: inicio),
            TextField(controller: fin),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              try {
                await dao.updateHorario(h['id'], inicio.text, fin.text);
                Navigator.pop(context);
                cargar();
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text("Guardar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final citasHoy = citasDelDia(_selected);
    final horariosDia = horariosPorDia();

    return Scaffold(
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
          const SizedBox(height: 8),

          /// ---------------- CALENDARIO -----------------
          TableCalendar(
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
            calendarStyle: const CalendarStyle(
              todayDecoration:
                  BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              selectedDecoration:
                  BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),

          const SizedBox(height: 8),
          const Text("Citas del día",
              style: TextStyle(fontWeight: FontWeight.bold)),

          SizedBox(
            height: 140,
            child: citasHoy.isEmpty
                ? const Center(child: Text("No hay citas"))
                : ListView.builder(
                    itemCount: citasHoy.length,
                    itemBuilder: (_, i) {
                      final c = citasHoy[i];
                      final f = DateTime.parse(c['fecha']);

                      return ListTile(
                        title: Text(
                            "${c['usuario']['nombre']} ${c['usuario']['apellidos']}"),
                        subtitle: Text(
                            "${f.day}/${f.month} ${f.hour}:${f.minute.toString().padLeft(2, '0')}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => cancelarCita(c['id']),
                        ),
                      );
                    }),
          ),

          const Divider(),
          const Text("Horarios disponibles",
              style: TextStyle(fontWeight: FontWeight.bold)),

          /// ---------------- HORARIOS -----------------
          Expanded(
            child: ListView(
              children: horariosDia.entries.map((e) {
                return Card(
                  child: ExpansionTile(
                    title: Text(e.key),
                    children: e.value.map((h) {
                      return ListTile(
                        title: Text(
                            "${h['hora_inicio']} - ${h['hora_fin'] ?? ''}"),
                        onTap: () => _editHorario(h),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await dao.deleteHorario(h['id']);
                            cargar();
                          },
                        ),
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
