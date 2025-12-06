import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg/data/dao/valoraciones_dao.dart';

class PantallaValorarPsicologo extends StatefulWidget {
  final String psicologoId;

  const PantallaValorarPsicologo({
    super.key,
    required this.psicologoId,
  });

  @override
  State<PantallaValorarPsicologo> createState() =>
      _PantallaValorarPsicologoState();
}

class _PantallaValorarPsicologoState extends State<PantallaValorarPsicologo> {
  final dao = ValoracionesDAO(Supabase.instance.client);

  int _puntuacion = 5;
  final TextEditingController _comentario = TextEditingController();
  bool _guardando = false;

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => IconButton(
          icon: Icon(
            i < _puntuacion ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 34,
          ),
          onPressed: () => setState(() => _puntuacion = i + 1),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    try {
      await dao.valorar(
        psicologoId: widget.psicologoId,
        puntuacion: _puntuacion,
        comentario: _comentario.text.trim().isEmpty
            ? null
            : _comentario.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valoración guardada')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDEB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A80),
        title: const Text("Valorar psicólogo"),
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450, // 🔥 Tarjeta compacta, no muy grande
            padding: const EdgeInsets.all(22),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 6),
                )
              ],
            ),

            child: Column(
              children: [
                const Text(
                  "Tu valoración",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB6A68),
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "¿Qué puntuación le das?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),
                _buildStars(),

                const SizedBox(height: 20),

                TextField(
                  controller: _comentario,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Comentario (opcional)",
                    filled: true,
                    fillColor: const Color(0xFFFFF2F1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A80),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _guardando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Guardar valoración",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
