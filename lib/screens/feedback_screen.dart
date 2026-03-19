import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/history_service.dart';
import '../services/intervention_selector.dart';
import '../models/emotion_record.dart';
import 'intervention_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final String emotion;
  final String intensity;
  final String intervention;

  const FeedbackScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    required this.intervention,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String? selectedFeedback;
  bool _isSaving = false;

  Future<void> _saveFeedback(String feedback) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await HistoryService.addRecord(
        EmotionRecord(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: widget.intervention,
          feedback: feedback,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedFeedback = feedback;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getResponseMessage() {
    switch (selectedFeedback) {
      case "good":
        return "Bien. Ya diste un primer paso para ayudarte.";
      case "neutral":
        return "Está bien. A veces una sola intervención no basta.";
      case "bad":
        return "Gracias por decírmelo. Vamos a intentar otra forma de ayudarte.";
      default:
        return "";
    }
  }

  String _getSupportText() {
    switch (selectedFeedback) {
      case "good":
        return "Puedes volver al inicio cuando quieras. Lo importante es que esto te haya ayudado un poco.";
      case "neutral":
        return "Podemos probar una ayuda distinta, sin empezar todo de nuevo.";
      case "bad":
        return "No pasa nada si esto no era lo que necesitabas. Probemos otra vía.";
      default:
        return "";
    }
  }

  String _getInterventionLabel() {
    switch (widget.intervention) {
      case "breathing":
        return "respiración guiada";
      case "grounding":
        return "volver al presente";
      case "reframe":
        return "reencuadre mental";
      case "micro_action":
        return "acción concreta";
      case "support_path":
        return "ruta de apoyo";
      case "conversation":
      default:
        return "acompañamiento conversacional";
    }
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _tryAnotherHelp() {
    final decision = InterventionSelector.select(
      emotion: widget.emotion,
      intensity: widget.intensity,
      lastIntervention: widget.intervention,
      lastInterventionFailed: true,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InterventionScreen(
          decision: decision,
          emotion: widget.emotion,
          intensity: widget.intensity,
        ),
      ),
    );
  }

  bool get _shouldOfferAnotherHelp =>
      selectedFeedback == "neutral" || selectedFeedback == "bad";

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Tu respuesta importa",
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selectedFeedback == null) ...[
              const Text(
                "¿Esto te ayudó?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "ArmonIA te acompañó con ${_getInterventionLabel()}. Tu respuesta ayuda a entender mejor qué te sirve.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveFeedback("good"),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Sí, me ayudó"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveFeedback("neutral"),
                child: const Text("Un poco"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _saveFeedback("bad"),
                child: const Text("No mucho"),
              ),
            ] else ...[
              Text(
                _getResponseMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _getSupportText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _goHome,
                child: const Text("Volver al inicio"),
              ),
              if (_shouldOfferAnotherHelp) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _tryAnotherHelp,
                  child: const Text("Probar otra ayuda"),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}