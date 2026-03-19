import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import 'conversation_screen.dart';

class IntensityScreen extends StatelessWidget {
  final String emotion;

  const IntensityScreen({
    super.key,
    required this.emotion,
  });

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  String _getReadableEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case "ansiedad":
        return "la ansiedad";
      case "sobrepasado":
        return "esta sensación de estar sobrepasado";
      case "sobrecarga":
        return "esta sensación de sobrecarga";
      case "bloqueado":
        return "el bloqueo";
      case "rabia":
        return "la rabia";
      case "triste":
        return "la tristeza";
      default:
        return "esto";
    }
  }

  String _getSupportText(String emotion) {
    switch (emotion.toLowerCase()) {
      case "ansiedad":
        return "Vamos a ubicar qué tan fuerte se siente este momento ahora.";
      case "sobrepasado":
      case "sobrecarga":
        return "No hace falta explicarlo todo. Solo dime qué tan fuerte se siente ahora.";
      case "bloqueado":
        return "A veces basta con ubicar la intensidad para saber cómo ayudarte.";
      case "rabia":
        return "Vamos paso a paso. Primero ubiquemos qué tan fuerte se siente esto.";
      case "triste":
        return "No necesitas ordenar todo ahora. Solo dime qué tan fuerte se siente.";
      default:
        return "Solo quiero ubicar contigo qué tan fuerte se siente esto ahora.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensities = [
      {
        "label": "Bajo",
        "value": "bajo",
        "subtitle": "Se siente presente, pero manejable.",
        "icon": Icons.keyboard_arrow_down,
      },
      {
        "label": "Medio",
        "value": "medio",
        "subtitle": "Me está afectando bastante.",
        "icon": Icons.remove,
      },
      {
        "label": "Alto",
        "value": "alto",
        "subtitle": "Se siente muy fuerte ahora.",
        "icon": Icons.keyboard_arrow_up,
      },
    ];

    return MainLayout(
      title: "Intensidad",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 6),
            const Text(
              "Estoy aquí contigo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "¿Qué tan fuerte se siente ${_getReadableEmotion(emotion)} ahora?",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _getSupportText(emotion),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ...intensities.map((intensity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IntensityCard(
                  title: intensity["label"] as String,
                  subtitle: intensity["subtitle"] as String,
                  icon: intensity["icon"] as IconData,
                  color: _primaryBlue,
                  backgroundColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(
                          emotion: emotion,
                          intensity: intensity["value"] as String,
                          briefContext: "",
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _IntensityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _IntensityCard({
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FA),
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