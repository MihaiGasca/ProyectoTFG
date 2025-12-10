import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg/data/dao/citas_dao.dart';
import 'package:tfg/data/dao/disponibilidad_dao.dart';

class PantallaAgendaPsicologo extends StatefulWidget {
  const PantallaAgendaPsicologo({super.key});

  @override
  State<PantallaAgendaPsicologo> createState() =>
      _PantallaAgendaPsicologoState();
}

class _PantallaAgendaPsicologoState extends State<PantallaAgendaPsicologo> {
  late DisponibilidadDAO dao;
  late CitasDAO citasDAO;

  List<Map<String, dynamic>> horarios = [];
  List<Map<String, dynamic>> citas = [];

  DateTime _selected = DateTime.now();
  DateTime _focused = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  bool loading = true;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    dao = DisponibilidadDAO(Supabase.instance.client);
    citasDAO = CitasDAO(Supabase.instance.client);

    cargar();
    iniciarRealtime();
  }

  // REALTIME escuchar tabla citas
  void iniciarRealtime() {
    final supa = Supabase.instance.client;

    channel = supa.channel("realtime.citas")
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        table: "citas",
        schema: "public",
        callback: (payload) async {
          await cargar();
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  // CARGA INICIAL
  Future<void> cargar() async {
    final h = await dao.getDisponibilidad();
    final c = await dao.getCitas();

    // quitar citas canceladas
    final filtradas =
        c.where((e) => (e['estado'] ?? '') != 'cancelada').toList();

    setState(() {
      horarios = h;
      citas = filtradas;
      loading = false;
    });
  }

  DateTime parseLocal(String? fecha) {
    if (fecha == null) return DateTime.now();
    final dt = DateTime.parse(fecha);
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  List<Map<String, dynamic>> citasDelDia(DateTime d) {
    final now = DateTime.now();

    return citas.where((c) {
      final f = parseLocal(c['fecha']);

      final mismoDia =
          f.year == d.year && f.month == d.month && f.day == d.day;

      if (!mismoDia) return false;
      if (isSameDay(d, now)) return f.isAfter(now);

      return true;
    }).toList();
  }

  Map<int, List<Map<String, dynamic>>> horariosPorDia() {
    final map = <int, List<Map<String, dynamic>>>{};

    for (var h in horarios) {
      final d = h['dia_semana'] as int? ?? 0;
      map.putIfAbsent(d, () => []);
      map[d]!.add(h);
    }

    for (final list in map.values) {
      list.sort((a, b) {
        final ha = (a['hora_inicio'] ?? '') as String;
        final hb = (b['hora_inicio'] ?? '') as String;
        return ha.compareTo(hb);
      });
    }

    return map;
  }

  List<Map<String, dynamic>> huecosDelDia(DateTime d) {
    final dow = d.weekday;

    final horariosDia =
        horarios.where((h) => h['dia_semana'] == dow).toList();

    final citasDia = citas.where((c) {
      final f = parseLocal(c['fecha']);
      return f.year == d.year && f.month == d.month && f.day == d.day;
    }).toList();

    final eventos = <Map<String, dynamic>>[];

    for (final h in horariosDia) {
      final hi = (h['hora_inicio'] as String).substring(0, 5);
      final parts = hi.split(":");

      final horaLocal = DateTime(
        d.year,
        d.month,
        d.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final cita = citasDia.firstWhere(
        (c) {
          final f = parseLocal(c['fecha']);
          return f.hour == horaLocal.hour && f.minute == horaLocal.minute;
        },
        orElse: () => {},
      );

      if (cita.isNotEmpty) {
        eventos.add(cita);
      } else {
        eventos.add({
          'id': 'h_${h['id']}',
          'estado': 'libre',
          'hora_inicio': h['hora_inicio'],
          'hora_fin': h['hora_fin'],
        });
      }
    }

    return eventos;
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
        .update({'estado': 'cancelada'}).eq('id', id);

    cargar();
  }

  // AÑADIR HORARIO
  Future<void> _nuevoHorario() async {
    int diaSemana = 1;
    final inicio = TextEditingController();
    final fin = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Añadir horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: diaSemana,
              decoration: const InputDecoration(labelText: "Día de la semana"),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Lunes")),
                DropdownMenuItem(value: 2, child: Text("Martes")),
                DropdownMenuItem(value: 3, child: Text("Miércoles")),
                DropdownMenuItem(value: 4, child: Text("Jueves")),
                DropdownMenuItem(value: 5, child: Text("Viernes")),
                DropdownMenuItem(value: 6, child: Text("Sábado")),
                DropdownMenuItem(value: 7, child: Text("Domingo")),
              ],
              onChanged: (v) => diaSemana = v ?? 1,
            ),
            TextField(
              controller: inicio,
              decoration: const InputDecoration(labelText: "Hora inicio (HH:MM)"),
            ),
            TextField(
              controller: fin,
              decoration: const InputDecoration(labelText: "Hora fin (HH:MM)"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              final hi = inicio.text.trim();
              final hf = fin.text.trim();

              bool validarFormato(String t) {
                final exp = RegExp(r'^\d{2}:\d{2}$');
                return exp.hasMatch(t);
              }

              if (!validarFormato(hi) || !validarFormato(hf)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Formato inválido. Use HH:MM")),
                );
                return;
              }

              final hInicio = int.tryParse(hi.split(":")[0]) ?? -1;
              final mInicio = int.tryParse(hi.split(":")[1]) ?? -1;
              final hFin = int.tryParse(hf.split(":")[0]) ?? -1;
              final mFin = int.tryParse(hf.split(":")[1]) ?? -1;

              if (hInicio < 0 || hInicio > 23 || mInicio < 0 || mInicio > 59 ||
                  hFin < 0 || hFin > 23 || mFin < 0 || mFin > 59) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hora inválida. Debe ser HH:MM válido.")),
                );
                return;
              }

              final nuevoInicio = DateTime(0, 0, 0, hInicio, mInicio);
              final nuevoFin = DateTime(0, 0, 0, hFin, mFin);

              if (!nuevoFin.isAfter(nuevoInicio)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("La hora final debe ser mayor que la inicial")),
                );
                return;
              }

              final existentes = horarios
                  .where((h) => h['dia_semana'] == diaSemana)
                  .toList();

              final existeIgual = existentes.any((h) =>
                  h['hora_inicio'].substring(0, 5) == hi &&
                  h['hora_fin'].substring(0, 5) == hf);

              if (existeIgual) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Ya existe un horario idéntico")),
                );
                return;
              }

              for (final h in existentes) {
                final eInicioStr = (h['hora_inicio'] as String).substring(0, 5);
                final eFinStr = (h['hora_fin'] as String).substring(0, 5);

                final eInicio = DateTime(
                  0,
                  0,
                  0,
                  int.parse(eInicioStr.split(":")[0]),
                  int.parse(eInicioStr.split(":")[1]),
                );

                final eFin = DateTime(
                  0,
                  0,
                  0,
                  int.parse(eFinStr.split(":")[0]),
                  int.parse(eFinStr.split(":")[1]),
                );

                final solapa =
                    !(nuevoFin.isBefore(eInicio) || nuevoInicio.isAfter(eFin));

                if (solapa) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "El horario se solapa con otro: $eInicioStr - $eFinStr"),
                    ),
                  );
                  return;
                }
              }

              try {
                final supa = Supabase.instance.client;
                final uid = supa.auth.currentUser!.id;

                await supa.from('disponibilidad_psicologos').insert({
                  'psicologo_id': uid,
                  'dia_semana': diaSemana,
                  'hora_inicio': "$hi:00",
                  'hora_fin': "$hf:00",
                });

                Navigator.pop(context);
                await cargar();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // EDITAR HORARIO
  Future<void> _editHorario(Map h) async {
    final inicio = TextEditingController(
        text: (h['hora_inicio'] as String).substring(0, 5));
    final fin = TextEditingController(
        text: (h['hora_fin'] as String).substring(0, 5));

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar horario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: inicio,
                decoration:
                    const InputDecoration(labelText: "Inicio HH:MM")),
            TextField(
                controller: fin,
                decoration: const InputDecoration(labelText: "Fin HH:MM")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              final hi = inicio.text.trim();
              final hf = fin.text.trim();

              bool validarFormato(String t) {
                final exp = RegExp(r'^\d{2}:\d{2}$');
                return exp.hasMatch(t);
              }

              if (!validarFormato(hi) || !validarFormato(hf)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Formato inválido. Use HH:MM")),
                );
                return;
              }

              final hInicio = int.tryParse(hi.split(":")[0]) ?? -1;
              final mInicio = int.tryParse(hi.split(":")[1]) ?? -1;
              final hFin = int.tryParse(hf.split(":")[0]) ?? -1;
              final mFin = int.tryParse(hf.split(":")[1]) ?? -1;

              if (hInicio < 0 || hInicio > 23 ||
                  mInicio < 0 || mInicio > 59 ||
                  hFin < 0 || hFin > 23 ||
                  mFin < 0 || mFin > 59) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Hora inválida. HH:MM válido.")),
                );
                return;
              }

              final nuevoInicio = DateTime(0, 1, 1, hInicio, mInicio);
              final nuevoFin = DateTime(0, 1, 1, hFin, mFin);

              if (!nuevoFin.isAfter(nuevoInicio)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("La hora final debe ser mayor que la inicial")),
                );
                return;
              }

              final existentes = horarios.where((x) =>
                  x['dia_semana'] == h['dia_semana'] &&
                  x['id'] != h['id']).toList();

              for (final e in existentes) {
                final eInicioStr = (e['hora_inicio'] as String).substring(0, 5);
                final eFinStr = (e['hora_fin'] as String).substring(0, 5);

                final eInicio = DateTime(
                  0,
                  1,
                  1,
                  int.parse(eInicioStr.split(":")[0]),
                  int.parse(eInicioStr.split(":")[1]),
                );

                final eFin = DateTime(
                  0,
                  1,
                  1,
                  int.parse(eFinStr.split(":")[0]),
                  int.parse(eFinStr.split(":")[1]),
                );

                if (eInicio == nuevoInicio && eFin == nuevoFin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ya existe un horario igual.")),
                  );
                  return;
                }

                final solapa = !(nuevoFin.isBefore(eInicio) || nuevoInicio.isAfter(eFin));
                if (solapa) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Solapa con $eInicioStr - $eFinStr")),
                  );
                  return;
                }
              }

              try {
                await dao.updateHorario(h['id'], hi, hf);
                Navigator.pop(context);
                await cargar();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final citasHoy = citasDelDia(_selected);
    final horariosDia = horariosPorDia();
    final huecos = huecosDelDia(_selected);

    final totalHuecos = huecos.length;
    final totalCitas = huecos.where((e) => e['estado'] != 'libre').length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: const Text("Mi agenda"),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // CALENDARIO
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020),
                      lastDay: DateTime.utc(2030),
                      focusedDay: _focused,
                      selectedDayPredicate: (d) => isSameDay(d, _selected),
                      onDaySelected: (d, f) {
                        setState(() {
                          _selected = d;
                          _focused = f;
                        });
                      },
                      calendarFormat: _format,
                      onFormatChanged: (f) => setState(() => _format = f),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      eventLoader: (d) => huecosDelDia(d),

                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          final list =
                              events.whereType<Map<String, dynamic>>().toList();

                          if (list.isEmpty) return null;

                          final tot = list.length;
                          final cit = list
                              .where((e) => (e['estado'] ?? 'libre') != 'libre')
                              .length;

                          return Positioned(
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$cit/$tot",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                    "Citas: $totalCitas / Huecos: $totalHuecos",
                    style: const TextStyle(
                      color: Color(0xFFB75C5C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),
                  const Text(
                    "Citas del día",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFB75C5C)),
                  ),

                  const SizedBox(height: 10),

                  // LISTA DE CITAS
                 LayoutBuilder(
  builder: (context, size) {
    final double altura = size.maxHeight < 200 ? size.maxHeight : 200;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 150,
        maxHeight: altura,
      ),
      child: citasHoy.isEmpty
          ? const Center(child: Text("No hay citas"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: citasHoy.length,
              itemBuilder: (_, i) {
                final c = citasHoy[i];
                final f = parseLocal(c['fecha']);
                final u = (c['usuario'] ?? {}) as Map<String, dynamic>;

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
                        "${u['nombre'] ?? ''} ${u['apellidos'] ?? ''}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${f.day}/${f.month}/${f.year} "
                        "${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Estado: ${c['estado']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: c['estado'] == 'pendiente'
                              ? Colors.orange
                              : c['estado'] == 'aceptada'
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8), // Reemplazo del Spacer()
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (c['estado'] == 'pendiente')
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              onPressed: () async {
                                await citasDAO.aceptarCita(c['id']);
                                await cargar();
                              },
                            ),
                          if (c['estado'] != 'cancelada')
                            IconButton(
                              icon:
                                  const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => cancelarCita(c['id']),
                            ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  },
),
                  const SizedBox(height: 20),

                  const Divider(),

                  const Text(
                    "Horarios disponibles",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFB75C5C)),
                  ),

                  // BOTÓN AÑADIR HORARIO
                  TextButton.icon(
                    onPressed: _nuevoHorario,
                    icon: const Icon(Icons.add, color: Color(0xFFFF8A80)),
                    label: const Text(
                      "Añadir horario",
                      style: TextStyle(
                        color: Color(0xFFFF8A80),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // LISTA DE HORARIOS
                  ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    children: horariosDia.entries.map((e) {
                      final dia = e.key;
                      final lista = e.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            _dia(dia),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF8A80)),
                          ),
                          children: lista.map((h) {
                            final hi =
                                (h['hora_inicio'] as String).substring(0, 5);
                            final hf =
                                (h['hora_fin'] as String).substring(0, 5);
                            return ListTile(
                              title: Text("$hi - $hf"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editHorario(h),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await dao.deleteHorario(h['id']);
                                      await cargar();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
