import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/history_service.dart';
import '../services/emotional_pulse_service.dart';
import '../models/emotional_pulse_record.dart';
import 'emotion_screen.dart';
import 'emotional_pulse_screen.dart';
import 'conversation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  String _getHistoryMessage() {
    final records = HistoryService.getRecords().reversed.toList();

    for (final record in records) {
      if (record.feedback == "good") {
        return "La última vez te ayudó ${_readableIntervention(record.intervention)}.";
      }
    }

    return "Estoy aquí para ayudarte con lo que estés sintiendo ahora.";
  }

  String _readableIntervention(String intervention) {
    switch (intervention) {
      case "breathing":
        return "una respiración breve";
      case "grounding":
        return "volver al presente";
      case "clench_fists":
        return "soltar tensión en el cuerpo";
      case "micro_action":
        return "dar un paso pequeño";
      case "reframe":
        return "mirarlo desde otro ángulo";
      case "conversation":
        return "hablarlo un momento";
      default:
        return "una ayuda breve";
    }
  }

  String? _getPulseMessage() {
    final EmotionalPulseRecord? latest =
        EmotionalPulseService.getLatestRecentRecord();

    if (latest == null) return null;

    final overloadHigh =
        latest.overload == "bastante" || latest.overload == "mucho";
    final lowEnergy = latest.energy == "muy baja" || latest.energy == "baja";
    final lowCoping =
        latest.copingCapacity == "muy baja" || latest.copingCapacity == "baja";

    if ((overloadHigh && lowEnergy) || lowCoping) {
      return "Tu último pulso muestra bastante carga. Lo voy a considerar para acompañarte con más suavidad.";
    }

    return "Ya registré tu pulso emocional reciente y lo tendré en cuenta para acompañarte mejor.";
  }

  @override
  Widget build(BuildContext context) {
    final historyMessage = _getHistoryMessage();
    final pulseMessage = _getPulseMessage();

    return MainLayout(
      title: "Inicio",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.self_improvement,
                        size: 52,
                        color: _primaryBlue,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Hola, estoy aquí para apoyarte.",
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    "Elige cómo quieres empezar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _HomeActionCard(
              title: "Necesito apoyo ahora",
              subtitle: "Elegir cómo te sientes y recibir ayuda más directa",
              icon: Icons.favorite_border,
              color: _primaryBlue,
              backgroundColor: const Color(0xFFEEF8FB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmotionScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              title: "Hablar con ArmonIA",
              subtitle: "Escribir libremente y recibir una respuesta personalizada",
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFC9B6E4),
              backgroundColor: const Color(0xFFF4EEFB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConversationScreen(
                      emotion: "general",
                      intensity: "medio",
                      briefContext: "",
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              title: "Pulso Emocional",
              subtitle: "Registrar cómo has estado y ver tus patrones recientes",
              icon: Icons.insights_outlined,
              color: _primaryBlue,
              backgroundColor: const Color(0xFFF4F8FA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmotionalPulseScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (pulseMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  pulseMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                historyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}