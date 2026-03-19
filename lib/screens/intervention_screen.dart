import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../models/intervention_decision.dart';
import '../services/history_recommendation_service.dart';

import 'interventions/breathing_screen.dart';
import 'interventions/clench_fists_screen.dart';
import 'interventions/grounding_screen.dart';
import 'interventions/micro_action_screen.dart';
import 'interventions/reframe_screen.dart';
import 'support_path_screen.dart';
import 'conversation_screen.dart';

class InterventionScreen extends StatefulWidget {
  final InterventionDecision decision;
  final String emotion;
  final String intensity;
  final String briefContext;

  const InterventionScreen({
    super.key,
    required this.decision,
    required this.emotion,
    required this.intensity,
    this.briefContext = "",
  });

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  late String intervention;

  @override
  void initState() {
    super.initState();
    intervention = widget.decision.intervention.trim().toLowerCase();
  }

  String _getTitle(String intervention) {
    switch (intervention) {
      case "breathing":
        return "Respiración guiada";
      case "grounding":
        return "Volver al presente";
      case "clench_fists":
        return "Liberar tensión";
      case "micro_action":
        return "Dar un pequeño paso";
      case "reframe":
        return "Mirar desde otro ángulo";
      case "conversation":
        return "Hablemos un momento";
      case "support_path":
        return "Buscar apoyo";
      default:
        return "Pausa breve";
    }
  }

  String _getSupportMessage(String intervention) {
    switch (intervention) {
      case "breathing":
        return "Primero voy a ayudarte a bajar un poco la intensidad en tu cuerpo.";
      case "grounding":
        return "Antes de seguir pensando en esto, puede ayudarte volver un poco al presente.";
      case "clench_fists":
        return "A veces soltar tensión física ayuda a recuperar un poco de claridad.";
      case "micro_action":
        return "En este momento, una acción pequeña puede ayudarte más que seguir dándole vueltas.";
      case "reframe":
        return "Puede ayudarte mirar esto desde otro ángulo, sin exigirte resolverlo todo ahora.";
      case "conversation":
        return "Podemos tomar un momento para ordenar lo que está pasando.";
      case "support_path":
        return "Lo más importante ahora es acompañarte y acercarte a apoyo real.";
      default:
        return "Vamos a elegir una ayuda simple para acompañarte mejor ahora.";
    }
  }

  String _getActionLabel(String intervention) {
    switch (intervention) {
      case "breathing":
        return "Empezar respiración";
      case "grounding":
        return "Empezar grounding";
      case "clench_fists":
        return "Empezar ejercicio";
      case "micro_action":
        return "Empezar paso breve";
      case "reframe":
        return "Empezar reencuadre";
      case "conversation":
        return "Continuar";
      case "support_path":
        return "Ver apoyo";
      default:
        return "Continuar";
    }
  }

  String _getContextAcknowledgement() {
    final context = widget.briefContext.trim();

    if (context.isEmpty) return "";

    return "Gracias por contármelo. Ya con eso tengo un poco más de contexto para acompañarte mejor.";
  }

  Color _getPrimaryColor() {
    switch (intervention) {
      case "conversation":
        return const Color(0xFFC9B6E4);
      case "breathing":
      case "grounding":
      case "clench_fists":
        return const Color(0xFFA9D6E5);
      case "reframe":
        return const Color(0xFFEFD8A2);
      case "micro_action":
        return const Color(0xFFB9D6A3);
      case "support_path":
        return const Color(0xFFE7B3B3);
      default:
        return const Color(0xFF7FA8B8);
    }
  }

  Color _getBackgroundColor() {
    switch (intervention) {
      case "conversation":
        return const Color(0xFFF4EEFB);
      case "breathing":
      case "grounding":
      case "clench_fists":
        return const Color(0xFFEEF8FB);
      case "reframe":
        return const Color(0xFFFCF7EA);
      case "micro_action":
        return const Color(0xFFF1F8EC);
      case "support_path":
        return const Color(0xFFFCF0F0);
      default:
        return Colors.white;
    }
  }

  IconData _getIcon() {
    switch (intervention) {
      case "conversation":
        return Icons.chat_bubble_outline;
      case "breathing":
      case "grounding":
      case "clench_fists":
        return Icons.self_improvement;
      case "reframe":
        return Icons.autorenew;
      case "micro_action":
        return Icons.arrow_forward;
      case "support_path":
        return Icons.support_agent;
      default:
        return Icons.circle_outlined;
    }
  }

  void _goToNextScreen() {
    switch (intervention) {
      case "breathing":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BreathingScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      case "clench_fists":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClenchFistsScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      case "grounding":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroundingScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      case "micro_action":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MicroActionScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      case "reframe":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReframeScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      case "conversation":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
              briefContext: widget.briefContext,
            ),
          ),
        );
        break;

      case "support_path":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupportPathScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
            ),
          ),
        );
        break;

      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              emotion: widget.emotion,
              intensity: widget.intensity,
              briefContext: widget.briefContext,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = HistoryRecommendationService.getRecommendation(
      emotion: widget.emotion,
      intensity: widget.intensity,
    );

    final visibleSupportMessage =
        widget.decision.fromHistory && recommendation.hasRecommendation
            ? recommendation.message
            : _getSupportMessage(intervention);

    final contextAcknowledgement = _getContextAcknowledgement();
    final primaryColor = _getPrimaryColor();
    final backgroundColor = _getBackgroundColor();
    final icon = _getIcon();

    return MainLayout(
      title: _getTitle(intervention),
      child: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                icon,
                size: 54,
                color: primaryColor,
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
                    Text(
                      widget.decision.validationMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    if (contextAcknowledgement.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        contextAcknowledgement,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      visibleSupportMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _goToNextScreen,
                  child: Text(
                    _getActionLabel(intervention),
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