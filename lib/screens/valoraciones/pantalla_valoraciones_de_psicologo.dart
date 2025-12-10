import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaValoracionesDePsicologo extends StatefulWidget {
  final String psicologoId;
  final String nombre;

  const PantallaValoracionesDePsicologo({
    super.key,
    required this.psicologoId,
    required this.nombre,
  });

  @override
  State<PantallaValoracionesDePsicologo> createState() =>
      _PantallaValoracionesDePsicologoState();
}

class _PantallaValoracionesDePsicologoState
    extends State<PantallaValoracionesDePsicologo> {
  final supa = Supabase.instance.client;

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
    final data = await supa
        .from('valoraciones')
        .select('''
          id,
          puntuacion,
          comentario,
          fecha,
          usuario:usuario_id (nombre, apellidos, foto_perfil)
        ''')
        .eq('psicologo_id', widget.psicologoId)
        .order('fecha', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);

    double promedio = 0;
    if (list.isNotEmpty) {
      promedio = list
              .map((e) => e['puntuacion'] as int)
              .reduce((a, b) => a + b) /
          list.length;
    }

    setState(() {
      lista = list;
      total = list.length;
      media = double.parse(promedio.toStringAsFixed(1));
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
        lista.sort(
          (a, b) => DateTime.parse(b['fecha'])
              .compareTo(DateTime.parse(a['fecha'])),
        );
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
        title: Text("Valoraciones de ${widget.nombre}"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 18),

                /// MEDIA Y TOTAL
                Text(
                  "⭐ ${media.toStringAsFixed(1)}  •  $total valoraciones",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB6A68),
                  ),
                ),

                const SizedBox(height: 14),

                /// FILTRO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: orden,
                    items: const [
                      DropdownMenuItem(
                          value: "default",
                          child: Text("Ordenar por defecto")),
                      DropdownMenuItem(
                          value: "mayor",
                          child: Text("Mejor puntuación")),
                      DropdownMenuItem(
                          value: "menor",
                          child: Text("Peor puntuación")),
                      DropdownMenuItem(
                          value: "recientes",
                          child: Text("Más recientes")),
                    ],
                    onChanged: (v) => _ordenar(v!),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final v = lista[i];
                      final user = v['usuario'] ?? {};

                      return ListTile(
                        title:
                            Text("${user['nombre']} ${user['apellidos']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _estrellas(v['puntuacion']),
                            if ((v['comentario'] ?? '').toString().isNotEmpty)
                              Text(v['comentario']),
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
