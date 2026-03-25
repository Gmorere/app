import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/backend_config.dart';
import '../core/intervention_origin.dart';
import '../widgets/main_layout.dart';
import '../services/history_service.dart';
import '../services/emotional_pulse_service.dart';
import '../models/emotional_pulse_record.dart';
import 'emotion_screen.dart';
import 'emotional_pulse_screen.dart';
import 'conversation_screen.dart';

class HomeScreen extends StatefulWidget {
  final String authToken;

  const HomeScreen({
    super.key,
    required this.authToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primaryBlue = Color(0xFF7FA8B8);
  static bool _backendWakeUpDone = false;

  @override
  void initState() {
    super.initState();
    _wakeUpBackendOnce();
  }

  Future<void> _wakeUpBackendOnce() async {
    if (_backendWakeUpDone) return;
    _backendWakeUpDone = true;
    try {
      await http
          .get(Uri.parse('${BackendConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días.';
    if (hour < 19) return 'Buenas tardes.';
    return 'Buenas noches.';
  }

  int _sessionsInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return HistoryService.getRecords()
        .where((r) => r.timestamp.isAfter(cutoff))
        .length;
  }

  String? _dominantEmotionRecent({int lastN = 5}) {
    final records = HistoryService.getRecords().reversed.take(lastN).toList();
    if (records.isEmpty) return null;

    final counts = <String, int>{};
    for (final r in records) {
      counts[r.emotion] = (counts[r.emotion] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.first.value < 2) return null;
    return sorted.first.key;
  }

  String? _lastHelpfulIntervention() {
    final records = HistoryService.getRecords().reversed.toList();
    for (final r in records) {
      if (r.feedback == 'good') return r.intervention;
    }
    return null;
  }

  String? _pulseTrend() {
    final records = EmotionalPulseService.getRecords();
    if (records.length < 2) return null;
    return EmotionalPulseService.getSimpleTrend();
  }

  EmotionalPulseRecord? _recentPulse() =>
      EmotionalPulseService.getLatestRecentRecord();

  List<_ContextMessage> _buildContextMessages() {
    final messages = <_ContextMessage>[];

    final dominant = _dominantEmotionRecent(lastN: 5);
    final sessionsWeek = _sessionsInLastDays(7);

    if (dominant != null && sessionsWeek >= 3) {
      messages.add(_ContextMessage(
        icon: Icons.repeat_rounded,
        text: 'Esta semana llegaste varias veces con '
            '${_readableEmotion(dominant)}. '
            'Lo tengo en cuenta para acompañarte mejor.',
        color: _primaryBlue,
      ));
    }

    final trend = _pulseTrend();
    final pulse = _recentPulse();

    if (trend == 'bajando' && pulse != null) {
      messages.add(_ContextMessage(
        icon: Icons.trending_down_rounded,
        text: 'Tu pulso bajó respecto a antes. Algo está funcionando.',
        color: const Color(0xFF5DA07A),
      ));
    } else if (trend == 'subiendo' && pulse != null) {
      final primary = _readablePulseCategory(pulse.primaryCategory);
      messages.add(_ContextMessage(
        icon: Icons.trending_up_rounded,
        text: 'Tu pulso subió esta semana, sobre todo en $primary. '
            'Tiene sentido buscar apoyo ahora.',
        color: const Color(0xFFB87333),
      ));
    } else if (pulse != null && trend == null) {
      final overall = _pulseOverallLevel(pulse);
      final primary = _readablePulseCategory(pulse.primaryCategory);
      if (overall >= 4.0) {
        messages.add(_ContextMessage(
          icon: Icons.insights_outlined,
          text: 'Tu último pulso muestra bastante carga en $primary. '
              'Voy a acompañarte con más suavidad.',
          color: _primaryBlue,
        ));
      }
    }

    if (messages.length < 2) {
      final helpful = _lastHelpfulIntervention();
      if (helpful != null) {
        messages.add(_ContextMessage(
          icon: Icons.check_circle_outline,
          text: 'La última vez te ayudó ${_readableIntervention(helpful)}.',
          color: _primaryBlue,
        ));
      }
    }

    if (messages.isEmpty) {
      messages.add(_ContextMessage(
        icon: Icons.favorite_border,
        text: 'Estoy aquí para ayudarte con lo que estés sintiendo ahora.',
        color: _primaryBlue,
      ));
    }

    return messages.take(2).toList();
  }

  String _readableEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'ansiedad':
        return 'ansiedad';
      case 'sobrepasado':
      case 'sobrecarga':
        return 'sobrecarga';
      case 'bloqueado':
      case 'bloqueo':
        return 'bloqueo';
      case 'rabia':
      case 'enojo':
      case 'molesto':
        return 'rabia';
      case 'triste':
      case 'tristeza':
      case 'pena':
        return 'tristeza';
      default:
        return emotion.toLowerCase();
    }
  }

  String _readableIntervention(String intervention) {
    switch (intervention) {
      case 'breathing':
        return 'una respiración breve';
      case 'grounding':
        return 'volver al presente';
      case 'clench_fists':
        return 'soltar tensión en el cuerpo';
      case 'micro_action':
        return 'dar un paso pequeño';
      case 'reframe':
        return 'mirarlo desde otro ángulo';
      case 'conversation':
        return 'hablarlo un momento';
      case 'expressive_writing':
        return 'escribir para soltarlo';
      case 'movement':
        return 'mover el cuerpo un momento';
      case 'sensory_pause':
        return 'una pausa de silencio';
      case 'functional_gratitude':
        return 'encontrar algo que no está roto';
      default:
        return 'una ayuda breve';
    }
  }

  String _readablePulseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'ansiedad':
        return 'ansiedad';
      case 'estrés':
        return 'estrés';
      case 'bloqueo':
        return 'bloqueo';
      case 'rabia':
        return 'rabia';
      case 'tristeza':
        return 'tristeza';
      default:
        return category.toLowerCase();
    }
  }

  double _pulseOverallLevel(EmotionalPulseRecord pulse) {
    final total = pulse.anxiety +
        pulse.stress +
        pulse.blockage +
        pulse.anger +
        pulse.sadness;
    return total / 5;
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final contextMessages = _buildContextMessages();

    return MainLayout(
      title: 'Inicio',
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
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.self_improvement,
                        size: 52,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Elige cómo quieres empezar.',
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
              title: 'Necesito apoyo ahora',
              subtitle: 'Elegir cómo te sientes y recibir ayuda más directa',
              icon: Icons.favorite_border,
              color: _primaryBlue,
              backgroundColor: const Color(0xFFEEF8FB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmotionScreen(
                      authToken: widget.authToken,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              title: 'Hablar con ArmonIA',
              subtitle: 'Escribir libremente y recibir una respuesta personalizada',
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFFC9B6E4),
              backgroundColor: const Color(0xFFF4EEFB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationScreen(
                      emotion: 'general',
                      intensity: 'medio',
                      authToken: widget.authToken,
                      briefContext: '',
                      interventionOrigin:
                          InterventionOrigin.conversationFollowup,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              title: 'Pulso Emocional',
              subtitle: 'Registrar cómo has estado y ver tus patrones recientes',
              icon: Icons.insights_outlined,
              color: _primaryBlue,
              backgroundColor: const Color(0xFFF4F8FA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
builder: (_) => EmotionalPulseScreen(
  authToken: widget.authToken,
),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ...contextMessages.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContextCard(message: msg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextMessage {
  final IconData icon;
  final String text;
  final Color color;

  const _ContextMessage({
    required this.icon,
    required this.text,
    required this.color,
  });
}

class _ContextCard extends StatelessWidget {
  final _ContextMessage message;

  const _ContextCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            message.icon,
            size: 18,
            color: message.color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
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
                child: Icon(icon, color: color, size: 24),
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
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
