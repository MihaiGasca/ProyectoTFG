import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/valoraciones_dao.dart';

/// Ahora mismo no funciona, revisar más adelante

class PantallaValoraciones extends StatefulWidget {
  const PantallaValoraciones({super.key});

  @override
  State<PantallaValoraciones> createState() => _PantallaValoracionesState();
}

class _PantallaValoracionesState extends State<PantallaValoraciones> {
  final dao = ValoracionesDAO(Supabase.instance.client);

  double media = 0;
  int total = 0;
  List<Map<String, dynamic>> valoraciones = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final r = await dao.getMisValoraciones();
    setState(() {
      media = (r['media'] as num).toDouble();
      total = r['total'] as int;
      valoraciones =
          List<Map<String, dynamic>>.from(r['valoraciones'] as List<dynamic>);
      cargando = false;
    });
  }

  Widget _estrellas(int n) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < n ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 20,
        ),
      ),
    );
  }

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: const Text("Mis valoraciones"),
        elevation: 0,
      ),

      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),

                /// Media general
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.08),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "⭐ ${media.toStringAsFixed(1)}  •  $total valoraciones",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDB6A68),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                Expanded(
                  child: valoraciones.isEmpty
                      ? const Center(
                          child: Text(
                            "Todavía no tienes valoraciones",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          itemCount: valoraciones.length,
                          itemBuilder: (_, i) {
                            final v = valoraciones[i];

                            final usuario =
                                (v['usuario'] ?? {}) as Map<String, dynamic>;
                            final nombre =
                                "${usuario['nombre'] ?? 'Usuario'} ${usuario['apellidos'] ?? ''}"
                                    .trim();
                            final comentario = v['comentario'] ?? '';
                            final puntuacion = (v['puntuacion'] as int?) ?? 0;
                            final fecha = _formatFecha(v['fecha'] ?? "");

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    color: Colors.black.withOpacity(0.12),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Nombre
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDB6A68),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  
                                  _estrellas(puntuacion),

                                  if (comentario.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      comentario,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],

                                  const SizedBox(height: 8),

                                  /// Fecha
                                  Text(
                                    fecha,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
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
    );
  }
}
