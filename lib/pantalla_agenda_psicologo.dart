import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'citas_dao.dart';
import 'pantalla_perfil.dart';   // ← ASEGÚRATE DE QUE ESTE PATH ES CORRECTO

class PantallaAgendaPsicologo extends StatefulWidget {
  const PantallaAgendaPsicologo({super.key});

  @override
  State<PantallaAgendaPsicologo> createState() =>
      _PantallaAgendaPsicologoState();
}

class _PantallaAgendaPsicologoState extends State<PantallaAgendaPsicologo> {
  late final CitasDAO citasDAO;
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  List<Map<String, dynamic>> todasCitas = [];

  @override
  void initState() {
    super.initState();
    citasDAO = CitasDAO(Supabase.instance.client);
    _cargar();
  }

  Future<void> _cargar() async {
    final datos = await citasDAO.getCitasPsicologo();
    setState(() => todasCitas = datos);
  }

  List<Map<String, dynamic>> _citasDelDia(DateTime d) {
    return todasCitas.where((c) {
      final f = DateTime.parse(c['fecha']).toLocal();
      return f.year == d.year && f.month == d.month && f.day == d.day;
    }).toList();
  }

  Future<void> _aceptar(String id) async {
    await citasDAO.aceptarCita(id);
    await _cargar();
  }

  Future<void> _cancelar(String id) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || motivo.isEmpty) return;

    await citasDAO.cancelarCita(id, motivo);
    await _cargar();
  }

  Future<String?> _pedirMotivo() async {
    String motivo = "";
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancelar cita"),
        content: TextField(
          decoration: const InputDecoration(
            hintText: "Motivo de cancelación",
          ),
          onChanged: (v) => motivo = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Volver"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivo),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final citasHoy = _citasDelDia(_selected);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Agenda del Psicólogo"),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF8A80),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: _focused,
            selectedDayPredicate: (d) =>
                d.year == _selected.year &&
                d.month == _selected.month &&
                d.day == _selected.day,
            onDaySelected: (sel, foc) {
              setState(() {
                _selected = sel;
                _focused = foc;
              });
            },
            eventLoader: (day) => _citasDelDia(day),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),

          const Divider(),

          Expanded(
            child: citasHoy.isEmpty
                ? const Center(child: Text("No hay citas este día"))
                : ListView.builder(
                    itemCount: citasHoy.length,
                    itemBuilder: (_, i) {
                      final c = citasHoy[i];
                      final usuario = c['usuario'];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                (usuario['foto_perfil'] != null &&
                                        usuario['foto_perfil'].toString().isNotEmpty)
                                    ? NetworkImage(usuario['foto_perfil'])
                                    : null,
                            child: (usuario['foto_perfil'] == null ||
                                    usuario['foto_perfil'].toString().isEmpty)
                                ? Text(usuario['nombre'][0])
                                : null,
                          ),
                          title: Text("${usuario['nombre']} ${usuario['apellidos']}"),
                          subtitle: Text(
                            "Hora: ${DateTime.parse(c['fecha']).toLocal().hour}:${DateTime.parse(c['fecha']).minute.toString().padLeft(2, '0')}\nEstado: ${c['estado']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c['estado'] == 'pendiente')
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _aceptar(c['id']),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _cancelar(c['id']),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PantallaPerfil(psicologo: usuario),
                              ),
                            );
                          },
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
