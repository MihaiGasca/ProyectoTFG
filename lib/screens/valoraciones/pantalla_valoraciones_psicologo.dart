import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/valoraciones_dao.dart';

class PantallaValoracionesPsicologo extends StatefulWidget {
  const PantallaValoracionesPsicologo({super.key});

  @override
  State<PantallaValoracionesPsicologo> createState() =>
      _PantallaValoracionesPsicologoState();
}

class _PantallaValoracionesPsicologoState
    extends State<PantallaValoracionesPsicologo> {
  final dao = ValoracionesDAO(Supabase.instance.client);

  List<Map<String, dynamic>> lista = [];
  double media = 0;
  int total = 0;
  bool cargando = true;

  String orden = "default";

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final r = await dao.getValoracionesPsicologo();

    setState(() {
      lista = List<Map<String, dynamic>>.from(r['valoraciones']);
      media = (r['media'] as num).toDouble();
      total = r['total'] as int;
      cargando = false;
    });
  }

  void _ordenar(String modo) {
    setState(() {
      orden = modo;

      if (modo == "mayor") {
        lista.sort((a, b) => b['puntuacion'].compareTo(a['puntuacion']));
      } else if (modo == "menor") {
        lista.sort((a, b) => a['puntuacion'].compareTo(b['puntuacion']));
      } else if (modo == "recientes") {
        lista.sort((a, b) =>
            DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])));
      }
    });
  }

  Widget _estrellas(int n) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < n ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        ),
      ),
    );
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
                const SizedBox(height: 18),

                /// MEDIA Y TOTAL
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.12),
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

                const SizedBox(height: 14),

                /// 🔽 FILTRO MODERNO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: orden,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: const [
                      DropdownMenuItem(
                        value: "default",
                        child: Text("Ordenar por defecto"),
                      ),
                      DropdownMenuItem(
                        value: "mayor",
                        child: Text("Mejor puntuación"),
                      ),
                      DropdownMenuItem(
                        value: "menor",
                        child: Text("Peor puntuación"),
                      ),
                      DropdownMenuItem(
                        value: "recientes",
                        child: Text("Más recientes"),
                      ),
                    ],
                    onChanged: (v) => _ordenar(v!),
                  ),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: lista.isEmpty
                      ? const Center(
                          child: Text(
                            "Sin valoraciones todavía",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          itemCount: lista.length,
                          itemBuilder: (_, i) {
                            final v = lista[i];
                            final u = (v['usuario'] ?? {}) as Map;

                            final nombre =
                                "${u['nombre'] ?? 'Usuario'} ${u['apellidos'] ?? ''}"
                                    .trim();

                            final comentario =
                                (v['comentario'] ?? "").toString();

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                    color: Colors.black.withOpacity(0.10),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDB6A68),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  
                                  _estrellas(v['puntuacion']),

                                  if (comentario.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(comentario),
                                  ],
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
