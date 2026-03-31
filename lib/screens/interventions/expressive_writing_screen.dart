import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/expressive_writing_content.dart';
import '../../core/intervention_origin.dart';
import '../../services/ai_service.dart';
import '../../widgets/main_layout.dart';
import '../feedback_screen.dart';
import '../support_path_screen.dart';

class ExpressiveWritingScreen extends StatefulWidget {
  final String emotion;
  final String intensity;
  final String authToken;
  final int sessionId;
  final String interventionOrigin;

  const ExpressiveWritingScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    required this.authToken,
    required this.sessionId,
    this.interventionOrigin = InterventionOrigin.motor,
  });

  @override
  State<ExpressiveWritingScreen> createState() =>
      _ExpressiveWritingScreenState();
}

class _ExpressiveWritingScreenState extends State<ExpressiveWritingScreen> {
  static const Color _primaryColor = Color(0xFFC9B6E4);
  static const Color _backgroundColor = Color(0xFFF4EEFB);

  late final ExpressiveWritingContent content;
  final TextEditingController _textController = TextEditingController();

  bool _isGenerating = false;
  String? _errorMessage;
  ExpressiveWritingOutput? _result;

  static const Set<String> _allowedEmotions = {
    'ansiedad',
    'sobrepasado',
    'bloqueado',
    'rabia',
    'tristeza',
  };

  static const Set<String> _allowedIntensities = {
    'bajo',
    'medio',
    'alto',
  };

  @override
  void initState() {
    super.initState();
    content = ExpressiveWritingContentLibrary.get(
      emotion: widget.emotion,
      intensity: widget.intensity,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _normalizedEmotion() {
    final emotion = widget.emotion.trim().toLowerCase();
    return _allowedEmotions.contains(emotion) ? emotion : null;
  }

  String? _normalizedIntensity() {
    final intensity = widget.intensity.trim().toLowerCase();
    return _allowedIntensities.contains(intensity) ? intensity : null;
  }

  String _supportEmotion() {
    return _normalizedEmotion() ?? 'sobrepasado';
  }

  String _supportIntensity(String riskLevel) {
    final intensity = _normalizedIntensity();
    if (intensity != null) {
      if (riskLevel == 'crisis' && intensity == 'bajo') {
        return 'alto';
      }
      return intensity;
    }
    return riskLevel == 'crisis' ? 'alto' : 'medio';
  }

  String _normalizeRiskText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'(.)\1{2,}'), r'$1')
        .replaceAll('kero', 'quiero')
        .replaceAll('kiero', 'quiero')
        .replaceAll('qiero', 'quiero')
        .replaceAll('qitarme', 'quitarme')
        .replaceAll('matarmee', 'matarme')
        .replaceAll('suicidarmee', 'suicidarme')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _hasCriticalRiskLanguage(String text) {
    final normalized = _normalizeRiskText(text);
    if (normalized.isEmpty) return false;

    const criticalPhrases = {
      'me quiero matar',
      'quiero matarme',
      'tengo ganas de matarme',
      'quiero quitarme la vida',
      'quiero acabar con mi vida',
      'quiero terminar con mi vida',
      'quiero suicidarme',
      'pienso en matarme',
      'pienso en suicidarme',
      'como matarme',
      'como suicidarme',
      'como quitarme la vida',
      'me puedes ayudar a matarme',
      'me puedes ayudar a suicidarme',
      'me puedes ayudar a quitarme la vida',
      'quiero terminar con todo',
      'tengo ganas de terminar con todo',
      'no quiero vivir',
      'no quiero vivir mas',
      'no quiero seguir viviendo',
      'quiero morir',
      'me quiero morir',
      'quiero matarte',
      'te voy a matar',
      'otra persona que quiere matarse',
      'alguien quiere matarse',
      'otra persona quiere matarse',
      'otra persona quiere suicidarse',
      'alguien quiere suicidarse',
      'termine con su sufrimiento',
      'termine con el sufrimiento',
      'acabe con su sufrimiento',
      'acabe con el sufrimiento',
    };

    if (criticalPhrases.any(normalized.contains)) {
      return true;
    }

    final selfHarmIntent = [
      'quiero',
      'me quiero',
      'tengo ganas de',
      'como',
      'ayudar',
      'ayuda para',
      'opciones',
      'formas',
      'maneras',
      'mejores opciones',
    ].any(normalized.contains);

    final selfHarmTarget = [
      'matarme',
      'suicid',
      'quitarme la vida',
      'terminar con mi vida',
      'acabar con mi vida',
      'morirme',
      'morir',
    ].any(normalized.contains);

    final violenceTarget = [
      'matarte',
      'matar a alguien',
      'matar a una persona',
      'lastimar a alguien',
      'herir a alguien',
      'hacer dano a alguien',
      'hacerle dano a alguien',
    ].any(normalized.contains);

    final thirdPartyRisk = [
      'otra persona',
      'alguien',
      'mi pareja',
      'mi hijo',
      'mi hija',
      'mi hermano',
      'mi hermana',
      'mi amigo',
      'mi amiga',
    ].any(normalized.contains) &&
        [
          'matarse',
          'suicid',
          'quitarse la vida',
          'terminar con todo',
          'terminar con su vida',
          'acabar con su vida',
          'terminar con su sufrimiento',
          'terminar con el sufrimiento',
          'acabar con su sufrimiento',
          'acabar con el sufrimiento',
        ].any(normalized.contains);

    return (selfHarmIntent && selfHarmTarget) || violenceTarget || thirdPartyRisk;
  }

  bool _resultSuggestsHumanSupport(ExpressiveWritingOutput result) {
    final combined = _normalizeRiskText(
      '${result.reflection} ${result.nextStep}',
    );

    const supportSignals = [
      'apoyo humano',
      'persona real',
      'contacta a alguien',
      'contactar a alguien',
      'busca apoyo',
      'buscar apoyo',
      'linea de ayuda',
      'linea de apoyo',
      'fono ayuda',
      've a apoyo ahora',
      'acercarte a apoyo',
      'habla con alguien',
      'hablar con alguien',
    ];

    return supportSignals.any(combined.contains);
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: "expressive_writing",
          authToken: widget.authToken,
          sessionId: widget.sessionId,
          interventionOrigin: widget.interventionOrigin,
          contextTag: _result?.contextTag,
          possibleTheme: _result?.possibleTheme,
          themeConfidence: _result?.themeConfidence,
        ),
      ),
    );
  }

  void _goToSupportPath(String writtenText, String riskLevel) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SupportPathScreen(
          emotion: _supportEmotion(),
          intensity: _supportIntensity(riskLevel),
          authToken: widget.authToken,
          initialContext: writtenText,
          interventionOrigin: riskLevel == 'crisis'
              ? InterventionOrigin.crisis
              : widget.interventionOrigin,
        ),
      ),
    );
  }

  Future<void> _generateOutput() async {
    final writtenText = _textController.text.trim();
    if (writtenText.isEmpty) {
      setState(() {
        _errorMessage = 'Escribe algo breve antes de seguir.';
      });
      return;
    }

    if (_hasCriticalRiskLanguage(writtenText)) {
      _goToSupportPath(writtenText, 'crisis');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final output = await AiService.generateExpressiveWritingOutput(
        token: widget.authToken,
        writtenText: writtenText,
        emotion: _normalizedEmotion(),
        intensity: _normalizedIntensity(),
        interventionOrigin: widget.interventionOrigin,
      );

      if (!mounted) return;

      if (output.riskLevel == 'crisis' || output.shouldOfferHumanSupport) {
        _goToSupportPath(writtenText, output.riskLevel);
        return;
      }

      setState(() {
        _result = output;
      });
    } on TimeoutException {
      if (!mounted) return;
      if (_hasCriticalRiskLanguage(writtenText)) {
        _goToSupportPath(writtenText, 'crisis');
        return;
      }
      setState(() {
        _errorMessage =
            'No pude completar esta respuesta a tiempo. Si esto es urgente, ve a apoyo ahora.';
      });
    } catch (e) {
      if (!mounted) return;
      if (_hasCriticalRiskLanguage(writtenText)) {
        _goToSupportPath(writtenText, 'crisis');
        return;
      }
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _resetWriting() {
    setState(() {
      _result = null;
      _errorMessage = null;
    });
  }

  Widget _buildWritingStage(double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(
            Icons.edit_note_outlined,
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
                Text(
                  content.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  minLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: content.placeholder,
                    filled: true,
                    fillColor: const Color(0xFFF9F6FD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content.note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(_errorMessage!),
          ],
          if (_isGenerating) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3FD),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Generando una salida breve. Esto puede tardar unos segundos.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            content.closing,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
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
              onPressed: _isGenerating ? null : _generateOutput,
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Ver salida breve",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStage(ExpressiveWritingOutput result) {
    final shouldDivertToSupport =
        result.riskLevel == 'crisis' ||
        result.shouldOfferHumanSupport ||
        _resultSuggestsHumanSupport(result);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        const Icon(
          Icons.auto_awesome_outlined,
          size: 54,
          color: _primaryColor,
        ),
        const SizedBox(height: 20),
        _buildResultCard(
          title: "Lo que pesa mas",
          body: result.reflection,
        ),
        const SizedBox(height: 14),
        _buildResultCard(
          title: "Siguiente paso simple",
          body: result.nextStep,
        ),
        if (shouldDivertToSupport) ...[
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: () => _goToSupportPath(
                _textController.text.trim(),
                result.riskLevel,
              ),
              child: const Text("Ver apoyo ahora"),
            ),
          ),
        ] else ...[
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _finish,
              child: const Text(
                "Seguir",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resetWriting,
          child: const Text("Volver a escribir"),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF8A3B3B),
          height: 1.35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return MainLayout(
      title: "Ponerlo en palabras",
      child: Container(
        color: _backgroundColor,
        child: SafeArea(
          child: _result == null
              ? _buildWritingStage(bottomInset)
              : _buildResultStage(_result!),
        ),
      ),
    );
  }
}
