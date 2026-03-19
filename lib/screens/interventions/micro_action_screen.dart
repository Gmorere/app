import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';

class MicroActionScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const MicroActionScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<MicroActionScreen> createState() => _MicroActionScreenState();
}

class _MicroActionScreenState extends State<MicroActionScreen> {
  int step = 0;

  static const Color _primaryColor = Color(0xFFB9D6A3);
  static const Color _backgroundColor = Color(0xFFF1F8EC);

  final List<String> steps = [
    "No necesitas resolver todo ahora. Solo vamos a hacer una cosa pequeña.",
    "Mira a tu alrededor y elige una acción mínima que sí puedas hacer ahora mismo.",
    "Puede ser algo como tomar agua, pararte, ordenar una sola cosa o anotar una idea breve.",
    "Elige una sola. No la mejor: solo una que puedas hacer sin exigirte demasiado.",
    "Bien. Cuando la tengas clara, hazla o prepárate para hacerla apenas salgas de aquí.",
    "Eso ya cuenta. A veces un paso pequeño basta para salir un poco del bloqueo.",
  ];

  String _getButtonLabel() {
    return step < steps.length - 1 ? "Seguir" : "Finalizar";
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: "micro_action",
        ),
      ),
    );
  }

  void nextStep() {
    if (step < steps.length - 1) {
      setState(() {
        step++;
      });
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = step == steps.length - 1;

    return MainLayout(
      title: "Dar un pequeño paso",
      child: Container(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_forward,
                size: 54,
                color: _primaryColor,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "No hace falta resolver todo. Solo salir un poco de la parálisis.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      steps[step],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Paso ${step + 1} de ${steps.length}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                    if (isLastStep) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "Quédate con esa acción simple. No necesitas más por ahora.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: nextStep,
                  child: Text(
                    _getButtonLabel(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}