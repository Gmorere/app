import 'package:flutter/material.dart';

import '../core/intervention_origin.dart';
import '../widgets/main_layout.dart';
import 'emotion_screen.dart';
import 'emotional_pulse_screen.dart';
import 'exercises_screen.dart';
import 'interventions/expressive_writing_screen.dart';

class ComoFuncionaScreen extends StatelessWidget {
  final String authToken;

  const ComoFuncionaScreen({
    super.key,
    required this.authToken,
  });

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'C\u00f3mo funciona ArmonIA',
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _GuideCard(
              title: 'Qu\u00e9 es ArmonIA',
              body:
                  'ArmonIA es un asistente emocional para momentos de ansiedad, sobrecarga, bloqueo, rabia o tristeza. Busca ayudarte con intervenciones breves y concretas.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'C\u00f3mo te ayuda',
              body:
                  'La entrada principal es un flujo guiado: primero ubica c\u00f3mo est\u00e1s y luego propone la ayuda m\u00e1s adecuada para ese momento. No entrega siempre lo mismo ni se limita a conversar.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Tipos de ayuda',
              body:
                  'Seg\u00fan lo que necesites, ArmonIA puede ayudarte a regular activaci\u00f3n, reencuadrar algo r\u00edgido, conversar brevemente o dar un paso simple.',
              chips: [
                'Conversar',
                'Regular',
                'Reencuadrar',
                'Paso concreto',
              ],
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Ayuda breve y escritura',
              body:
                  'Tambi\u00e9n tienes accesos laterales. Ayuda breve te deja entrar directo a ejercicios puntuales, y Ponerlo en palabras te permite escribir y recibir una salida breve con IA.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Qu\u00e9 es el Pulso',
              body:
                  'Pulso muestra dos cosas: c\u00f3mo viene tu carga y qu\u00e9 se\u00f1ales te est\u00e1n ayudando. Sirve para observar patrones con m\u00e1s claridad, pero no reemplaza el flujo guiado.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Qu\u00e9 muestra el Historial',
              body:
                  'Historial te ayuda a ver qu\u00e9 te ha pasado, qu\u00e9 te ayud\u00f3 antes y c\u00f3mo se ha venido moviendo tu proceso reciente.',
            ),
            const SizedBox(height: 12),
            const _GuideCard(
              title: 'Seguridad y apoyo',
              body:
                  'ArmonIA no reemplaza terapia ni urgencias. Si detecta riesgo, corta el flujo normal y te orienta a apoyo humano visible y m\u00e1s inmediato.',
              accent: Color(0xFFFDF3F3),
            ),
            const SizedBox(height: 18),
            const Text(
              'Acciones \u00fatiles ahora',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.favorite_border,
              title: 'Iniciar una pausa',
              subtitle: 'Entrar al flujo guiado principal',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmotionScreen(
                      authToken: authToken,
                      interventionOrigin: InterventionOrigin.motor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.auto_awesome_motion_outlined,
              title: 'Abrir ayuda breve',
              subtitle: 'Entrar directo a ejercicios puntuales',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExercisesScreen(authToken: authToken),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.edit_note_outlined,
              title: 'Ponerlo en palabras',
              subtitle: 'Escribir y recibir una salida breve',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpressiveWritingScreen(
                      emotion: 'preventivo',
                      intensity: 'bajo',
                      authToken: authToken,
                      sessionId: 0,
                      interventionOrigin: InterventionOrigin.manualLibrary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.insights_outlined,
              title: 'Tomar mi pulso',
              subtitle: 'Ver c\u00f3mo est\u00e1n tu carga y lo que ayuda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmotionalPulseScreen(authToken: authToken),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.bar_chart,
              title: 'Ver historial',
              subtitle: 'Revisar continuidad y ayudas previas',
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.phone_outlined,
              title: 'Abrir Fono Ayuda',
              subtitle: 'Ir directo a apoyo humano visible',
              onTap: () {
                Navigator.pushNamed(context, '/fono');
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String body;
  final List<String> chips;
  final Color? accent;

  const _GuideCard({
    required this.title,
    required this.body,
    this.chips = const [],
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF7FA8B8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF7FA8B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
