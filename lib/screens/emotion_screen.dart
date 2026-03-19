import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import 'intensity_screen.dart';

class EmotionScreen extends StatelessWidget {
  const EmotionScreen({super.key});

  static const Color _anxietyColor = Color(0xFFA9D6E5);
  static const Color _anxietyBg = Color(0xFFEEF8FB);

  static const Color _overloadColor = Color(0xFFEFD8A2);
  static const Color _overloadBg = Color(0xFFFCF7EA);

  static const Color _blockColor = Color(0xFFB9D6A3);
  static const Color _blockBg = Color(0xFFF1F8EC);

  static const Color _angerColor = Color(0xFFE8B4A2);
  static const Color _angerBg = Color(0xFFFBEFEB);

  static const Color _sadnessColor = Color(0xFFC9B6E4);
  static const Color _sadnessBg = Color(0xFFF4EEFB);

  @override
  Widget build(BuildContext context) {
    final emotions = [
      {
        "label": "Siento ansiedad",
        "value": "ansiedad",
        "icon": Icons.air,
        "color": _anxietyColor,
        "backgroundColor": _anxietyBg,
      },
      {
        "label": "Me siento sobrepasado",
        "value": "sobrepasado",
        "icon": Icons.layers_outlined,
        "color": _overloadColor,
        "backgroundColor": _overloadBg,
      },
      {
        "label": "Me siento bloqueado",
        "value": "bloqueado",
        "icon": Icons.pause_circle_outline,
        "color": _blockColor,
        "backgroundColor": _blockBg,
      },
      {
        "label": "Siento rabia",
        "value": "rabia",
        "icon": Icons.local_fire_department_outlined,
        "color": _angerColor,
        "backgroundColor": _angerBg,
      },
      {
        "label": "Me siento triste",
        "value": "triste",
        "icon": Icons.water_drop_outlined,
        "color": _sadnessColor,
        "backgroundColor": _sadnessBg,
      },
    ];

    return MainLayout(
      title: "Apoyo emocional",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 6),
            const Text(
              "¿Qué estás sintiendo ahora?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              itemCount: emotions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.32,
              ),
              itemBuilder: (context, index) {
                final emotion = emotions[index];

                return _EmotionCard(
                  title: emotion["label"] as String,
                  icon: emotion["icon"] as IconData,
                  color: emotion["color"] as Color,
                  backgroundColor: emotion["backgroundColor"] as Color,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IntensityScreen(
                          emotion: emotion["value"] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _EmotionCard({
    required this.title,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}