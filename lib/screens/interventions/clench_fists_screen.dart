import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';

class ClenchFistsScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const ClenchFistsScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<ClenchFistsScreen> createState() => _ClenchFistsScreenState();
}

class _ClenchFistsScreenState extends State<ClenchFistsScreen> {
  int step = 0;

  static const Color _primaryColor = Color(0xFFA9D6E5);
  static const Color _backgroundColor = Color(0xFFEEF8FB);

  final List<String> steps = [
    "Cierra los puños con fuerza durante unos segundos.",
    "Mantén esa tensión un momento y toma una respiración profunda.",
    "Ahora suelta lentamente los puños y deja que las manos se relajen.",
    "Nota la diferencia entre tensión y relajación en tu cuerpo.",
    "Bien. A veces aflojar el cuerpo ayuda a que la mente también baje un poco la intensidad.",
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
          intervention: "clench_fists",
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
      title: "Liberar tensión",
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
                      "Solo acompáñame paso a paso. No necesitas hacerlo perfecto.",
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
                        "Quédate un segundo con esa sensación antes de seguir.",
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