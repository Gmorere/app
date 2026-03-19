import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';

class GroundingScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const GroundingScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  int step = 0;

  static const Color _primaryColor = Color(0xFFA9D6E5);
  static const Color _backgroundColor = Color(0xFFEEF8FB);

  final List<String> steps = [
    "Mira a tu alrededor con calma y reconoce 5 cosas que puedas ver.",
    "Ahora identifica 4 cosas que puedas tocar o sentir con tus manos.",
    "Escucha con atención y reconoce 3 sonidos a tu alrededor.",
    "Percibe 2 olores, aunque sean suaves o difíciles de notar.",
    "Por último, identifica 1 sensación en tu cuerpo en este momento.",
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
          intervention: "grounding",
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
      title: "Volver al presente",
      child: Container(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.self_improvement,
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
                      "No necesitas resolver nada ahora. Solo acompáñame paso a paso.",
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
                        "Bien. A veces volver a los sentidos ayuda a que la mente suelte un poco la presión.",
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