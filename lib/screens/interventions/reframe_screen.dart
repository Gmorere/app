import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';

class ReframeScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const ReframeScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<ReframeScreen> createState() => _ReframeScreenState();
}

class _ReframeScreenState extends State<ReframeScreen> {
  int step = 0;

  static const Color _primaryColor = Color(0xFFEFD8A2);
  static const Color _backgroundColor = Color(0xFFFCF7EA);

  final List<String> prompts = [
    "No necesitas resolver todo ahora. Solo vamos a mirar esto con un poco más de espacio.",
    "A veces la mente elige de inmediato la versión más dura, más negativa o más pesada de lo que pasa.",
    "Pregúntate por un momento: ¿hay otra forma de interpretar esto, aunque no sea perfecta?",
    "No se trata de engañarte ni de pensar positivo a la fuerza. Solo de abrir una posibilidad un poco más neutral o más amable.",
    "Si logras ver una versión menos dura de esto, ya hiciste algo importante.",
  ];

  String _getButtonLabel() {
    return step < prompts.length - 1 ? "Seguir" : "Finalizar";
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: "reframe",
        ),
      ),
    );
  }

  void nextStep() {
    if (step < prompts.length - 1) {
      setState(() {
        step++;
      });
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = step == prompts.length - 1;

    return MainLayout(
      title: "Mirar desde otro ángulo",
      child: Container(
        color: _backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.autorenew,
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
                      "No buscamos negar lo que sientes, solo aflojar un poco la forma de mirarlo.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      prompts[step],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Paso ${step + 1} de ${prompts.length}",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                    if (isLastStep) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "No necesitas tener una respuesta perfecta. Solo una mirada un poco menos dura.",
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