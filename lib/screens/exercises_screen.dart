import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';

import 'interventions/breathing_screen.dart';
import 'interventions/grounding_screen.dart';
import 'interventions/clench_fists_screen.dart';
import 'interventions/micro_action_screen.dart';
import 'interventions/reframe_screen.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  static const Color _regulationColor = Color(0xFFA9D6E5);
  static const Color _regulationBg = Color(0xFFEEF8FB);

  static const Color _reframeColor = Color(0xFFEFD8A2);
  static const Color _reframeBg = Color(0xFFFCF7EA);

  static const Color _actionColor = Color(0xFFB9D6A3);
  static const Color _actionBg = Color(0xFFF1F8EC);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Ayuda breve",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
                        Icons.flash_on_outlined,
                        size: 48,
                        color: _primaryBlue,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          "Ayuda breve",
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
                    "Elige una ayuda breve para empezar.",
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

            const Text(
              "Regulación física",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _compactHelpCard(
                    context,
                    title: "Respiración guiada",
                    subtitle: "Bajar intensidad.",
                    icon: Icons.air,
                    color: _regulationColor,
                    backgroundColor: _regulationBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BreathingScreen(
                          emotion: "preventivo",
                          intensity: "bajo",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactHelpCard(
                    context,
                    title: "Volver al presente",
                    subtitle: "Salir del desborde.",
                    icon: Icons.center_focus_strong,
                    color: _regulationColor,
                    backgroundColor: _regulationBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroundingScreen(
                          emotion: "preventivo",
                          intensity: "bajo",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactHelpCard(
                    context,
                    title: "Liberar tensión",
                    subtitle: "Soltar carga física.",
                    icon: Icons.pan_tool_alt_outlined,
                    color: _regulationColor,
                    backgroundColor: _regulationBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClenchFistsScreen(
                          emotion: "preventivo",
                          intensity: "bajo",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _wideHelpCard(
                    context,
                    title: "Dar un pequeño paso",
                    subtitle: "Para salir del bloqueo con una acción simple.",
                    icon: Icons.arrow_forward,
                    color: _actionColor,
                    backgroundColor: _actionBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MicroActionScreen(
                          emotion: "preventivo",
                          intensity: "bajo",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _wideHelpCard(
                    context,
                    title: "Mirarlo desde otro ángulo",
                    subtitle:
                        "Para aflojar una idea rígida o darle otra perspectiva.",
                    icon: Icons.autorenew,
                    color: _reframeColor,
                    backgroundColor: _reframeBg,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReframeScreen(
                          emotion: "preventivo",
                          intensity: "bajo",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactHelpCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _wideHelpCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}