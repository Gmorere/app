import 'package:flutter/material.dart';

import '../core/intervention_origin.dart';
import '../models/emotion_record.dart';
import '../services/ai_service.dart';
import '../services/history_service.dart';
import '../widgets/main_layout.dart';
import 'home_screen.dart';

class FeedbackScreen extends StatefulWidget {
  final String emotion;
  final String intensity;
  final String intervention;
  final String authToken;
  final int sessionId;
  final String interventionOrigin;
  final String? contextTag;
  final String? possibleTheme;
  final String? themeConfidence;

  const FeedbackScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    required this.intervention,
    required this.authToken,
    required this.sessionId,
    this.interventionOrigin = InterventionOrigin.motor,
    this.contextTag,
    this.possibleTheme,
    this.themeConfidence,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool? _selectedReliefFeedback;
  bool? _selectedUtilityFeedback;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _hasCompletedDualFeedback =>
      _selectedReliefFeedback != null && _selectedUtilityFeedback != null;

  String get _selectedFeedbackBand {
    return _buildLegacyFeedback(
      reliefFeedback: _selectedReliefFeedback ?? false,
      utilityFeedback: _selectedUtilityFeedback ?? false,
    );
  }

  String _buildLegacyFeedback({
    required bool reliefFeedback,
    required bool utilityFeedback,
  }) {
    if (reliefFeedback && utilityFeedback) {
      return 'good';
    }

    if (!reliefFeedback && !utilityFeedback) {
      return 'bad';
    }

    return 'neutral';
  }

  Future<void> _saveFeedback({
    required bool reliefFeedback,
    required bool utilityFeedback,
  }) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final legacyFeedback = _buildLegacyFeedback(
      reliefFeedback: reliefFeedback,
      utilityFeedback: utilityFeedback,
    );
    final helped = reliefFeedback || utilityFeedback;

    try {
      if (widget.sessionId > 0) {
        await AiService.sendFeedback(
          token: widget.authToken,
          sessionId: widget.sessionId,
          helped: helped,
          reliefFeedback: reliefFeedback,
          utilityFeedback: utilityFeedback,
        );
      }

      await HistoryService.addRecord(
        EmotionRecord(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: widget.intervention,
          feedback: legacyFeedback,
          reliefFeedback: reliefFeedback,
          utilityFeedback: utilityFeedback,
          interventionOrigin: InterventionOrigin.normalize(
            widget.interventionOrigin,
            intervention: widget.intervention,
            emotion: widget.emotion,
          ),
          contextTag: widget.contextTag,
          possibleTheme: widget.possibleTheme,
          themeConfidence: widget.themeConfidence,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _selectedReliefFeedback = reliefFeedback;
        _selectedUtilityFeedback = utilityFeedback;
      });
    } catch (e) {
      if (!mounted) return;
      final rawMessage = e.toString().replaceFirst('Exception: ', '').trim();

      setState(() {
        _errorMessage = rawMessage.isNotEmpty
            ? rawMessage
            : 'No pude guardar tu respuesta en este momento.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _selectReliefFeedback(bool value) {
    setState(() {
      _selectedReliefFeedback = value;
      _selectedUtilityFeedback = null;
      _errorMessage = null;
    });
  }

  Future<void> _selectUtilityFeedback(bool value) async {
    final reliefFeedback = _selectedReliefFeedback;
    if (reliefFeedback == null) return;

    await _saveFeedback(
      reliefFeedback: reliefFeedback,
      utilityFeedback: value,
    );
  }

  void _goBackToReliefStep() {
    setState(() {
      _selectedReliefFeedback = null;
      _selectedUtilityFeedback = null;
      _errorMessage = null;
    });
  }

  String _getResponseMessage() {
    switch (_selectedFeedbackBand) {
      case 'good':
        return 'Bien. Esto parece haberte ayudado de verdad.';
      case 'neutral':
        return 'Bien. Algo de esto si te ayudo.';
      case 'bad':
        return 'Gracias por decirmelo. Esto no fue lo que necesitabas ahora.';
      default:
        return '';
    }
  }

  String _getSupportText() {
    switch (_selectedFeedbackBand) {
      case 'good':
        return 'Puedes volver al inicio cuando quieras. Lo importante es que algo de esto si te haya servido.';
      case 'neutral':
        return 'Si necesitas mas apoyo, podemos volver al inicio y probar otra ayuda.';
      case 'bad':
        return 'No pasa nada si esto no era lo que necesitabas. Lo correcto ahora es cambiar de via.';
      default:
        return '';
    }
  }

  String _getClosingTitle() {
    switch (_selectedFeedbackBand) {
      case 'good':
        return 'Para cerrar por ahora';
      case 'neutral':
        return 'Siguiente paso simple';
      case 'bad':
        return 'No lo fuerces';
      default:
        return '';
    }
  }

  String _getClosingBody() {
    final interventionLabel = _getInterventionLabel();

    switch (_selectedFeedbackBand) {
      case 'good':
        return 'Quedate con lo que si te sirvio de $interventionLabel. No necesitas hacer mas ahora si ya bajo un poco la carga.';
      case 'neutral':
        return 'Quedate con lo que si te sirvio de $interventionLabel. Si necesitas mas apoyo, vuelve al inicio y prueba otra ayuda.';
      case 'bad':
        return 'Si esto no ayudo, vuelve al inicio y cambia de via. Si te sientes al limite, prioriza apoyo humano visible.';
      default:
        return '';
    }
  }

  String _getPrimaryButtonLabel() {
    switch (_selectedFeedbackBand) {
      case 'neutral':
      case 'bad':
        return 'Volver y probar otra ayuda';
      case 'good':
      default:
        return 'Volver al inicio';
    }
  }

  String _getInterventionLabel() {
    switch (widget.intervention) {
      case 'breathing':
        return 'respiracion guiada';
      case 'grounding':
        return 'volver al presente';
      case 'movement':
        return 'movimiento breve';
      case 'sensory_pause':
        return 'pausa para bajar carga';
      case 'expressive_writing':
        return 'ponerlo en palabras';
      case 'reframe':
        return 'reencuadre mental';
      case 'micro_action':
        return 'accion concreta';
      case 'support_path':
        return 'ruta de apoyo';
      case 'conversation':
      default:
        return 'acompanamiento conversacional';
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          authToken: widget.authToken,
          closingOutcome: _selectedFeedbackBand,
          closingIntervention: widget.intervention,
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildErrorCard() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8A5C5C),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReliefStep() {
    return Column(
      children: [
        const Text(
          'Esto bajo un poco lo que sentias?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          'ArmonIA te acompano con ${_getInterventionLabel()}. Esta respuesta ayuda a entender si te alivio un poco ahora.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildErrorCard(),
        ElevatedButton(
          onPressed: () => _selectReliefFeedback(true),
          child: const Text('Si'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _selectReliefFeedback(false),
          child: const Text('No'),
        ),
      ],
    );
  }

  Widget _buildUtilityStep() {
    return Column(
      children: [
        const Text(
          'Te ayudo a avanzar, ordenar o entender mejor lo que te pasaba?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        const Text(
          'No es lo mismo aliviar un poco que ser realmente util. Esta segunda respuesta ayuda a ajustar mejor futuras ayudas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildErrorCard(),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _selectUtilityFeedback(true),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Si'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSaving ? null : () => _selectUtilityFeedback(false),
          child: const Text('No'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSaving ? null : _goBackToReliefStep,
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _buildCompleteStep() {
    return Column(
      children: [
        Text(
          _getResponseMessage(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          _getSupportText(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                _getClosingTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getClosingBody(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _goHome,
          child: Text(_getPrimaryButtonLabel()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Tu respuesta importa',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedReliefFeedback == null)
              _buildReliefStep()
            else if (!_hasCompletedDualFeedback)
              _buildUtilityStep()
            else
              _buildCompleteStep(),
          ],
        ),
      ),
    );
  }
}
