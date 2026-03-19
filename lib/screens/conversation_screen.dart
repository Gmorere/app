import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/ai_service.dart';
import '../models/intervention_decision.dart';
import '../core/intervention_type.dart';
import 'feedback_screen.dart';
import 'intervention_screen.dart';

class ConversationScreen extends StatefulWidget {
  final String emotion;
  final String intensity;
  final String briefContext;

  const ConversationScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    this.briefContext = "",
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

enum ConversationPhase {
  writing,
  loading,
  reflection,
}

class _ConversationScreenState extends State<ConversationScreen> {
  ConversationPhase phase = ConversationPhase.writing;

  final TextEditingController _responseController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  static const Color _primaryColor = Color(0xFFC9B6E4);
  static const Color _backgroundColor = Color(0xFFF4EEFB);

  AiResponse? _aiResponse;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (widget.briefContext.trim().isNotEmpty) {
      _responseController.text = widget.briefContext.trim();
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  bool get _hasRiskCheck =>
      _aiResponse != null &&
      _aiResponse!.riskLevel == "medium" &&
      _aiResponse!.shouldOfferHumanSupport;

  bool get _isCrisisPath =>
      _aiResponse != null && _aiResponse!.recommendedTool == "support_path";

  String _getPromptQuestion() {
    switch (widget.emotion.toLowerCase()) {
      case "ansiedad":
        return "Si tuvieras que resumir en una frase qué te inquieta más ahora, ¿qué sería?";
      case "sobrepasado":
        return "Si tuvieras que decir qué es lo que más pesa ahora, ¿qué sería?";
      case "bloqueado":
        return "Si tuvieras que nombrar qué te está frenando ahora, ¿qué dirías?";
      case "molesto":
      case "rabia":
      case "enojo":
        return "Si tuvieras que decir qué fue lo que más te removió, ¿qué sería?";
      case "triste":
      case "pena":
        return "Si tuvieras que poner en palabras qué es lo que más duele ahora, ¿qué sería?";
      default:
        return "Si tuvieras que resumir qué es lo que más pesa ahora, ¿qué dirías?";
    }
  }

  String _getIntroLine() {
    switch (widget.emotion.toLowerCase()) {
      case "ansiedad":
        return "Estoy contigo. No tienes que resolverlo todo ahora.";
      case "sobrepasado":
        return "Vamos paso a paso. Solo necesito entender qué pesa más ahora.";
      case "bloqueado":
        return "No hace falta tenerlo todo claro. Basta con ubicar qué te está frenando.";
      case "molesto":
      case "rabia":
      case "enojo":
        return "Vamos a bajar un poco el ruido y mirar qué fue lo que más te removió.";
      case "triste":
      case "pena":
        return "Lamento que estés pasando por esto. Pongamos en palabras lo más importante.";
      default:
        return "Estoy aquí contigo. Vamos a mirar esto con un poco más de calma.";
    }
  }

  String _toolLabel(String tool) {
    switch (tool) {
      case "breathing":
        return "Respiración guiada";
      case "grounding":
        return "Volver al presente";
      case "reframe":
        return "Mirar esto desde otro ángulo";
      case "micro_action":
        return "Dar un paso pequeño";
      case "support_path":
        return "Buscar apoyo";
      case "conversation":
      default:
        return "Seguir conversando un poco";
    }
  }

  String _toolSupportText(String tool) {
    switch (tool) {
      case "breathing":
        return "Puede ayudarte a bajar la intensidad física de este momento.";
      case "grounding":
        return "Puede ayudarte a salir del ruido mental y volver al presente.";
      case "reframe":
        return "Puede ayudarte a mirar esto con un poco más de claridad.";
      case "micro_action":
        return "Puede ayudarte más que seguir dándole vueltas ahora mismo.";
      case "support_path":
        return "Ahora lo más importante es acercarte a apoyo humano y no quedarte solo con esto.";
      case "conversation":
      default:
        return "Podemos seguir acompañando esto con calma.";
    }
  }

  InterventionType _mapToolToType(String tool) {
    switch (tool) {
      case "breathing":
      case "grounding":
      case "clench_fists":
        return InterventionType.physicalRegulation;
      case "micro_action":
        return InterventionType.concreteAction;
      case "reframe":
        return InterventionType.mentalReframe;
      case "support_path":
      case "conversation":
      default:
        return InterventionType.conversation;
    }
  }

  String _getPrimaryButtonLabel() {
    switch (phase) {
      case ConversationPhase.writing:
        return "Pedir ayuda a ArmonIA";
      case ConversationPhase.loading:
        return "Pensando...";
      case ConversationPhase.reflection:
        if (_errorMessage != null) {
          return "Intentar nuevamente";
        }
        if (_isCrisisPath) {
          return "Buscar apoyo ahora";
        }
        if (_hasRiskCheck) {
          return "Continuar con cuidado";
        }
        return "Probar esta ayuda";
    }
  }

  Future<void> _requestAiResponse() async {
    FocusScope.of(context).unfocus();

    setState(() {
      phase = ConversationPhase.loading;
      _errorMessage = null;
      _aiResponse = null;
    });

    try {
      final result = await AiService.getConversationResponse(
        emotion: widget.emotion,
        intensity: widget.intensity,
        briefContext: widget.briefContext,
        userMessage: _responseController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _aiResponse = result;
        phase = ConversationPhase.reflection;
      });
    } catch (e) {
      if (!mounted) return;

      final rawMessage = e.toString().replaceFirst("Exception: ", "").trim();

      setState(() {
        _errorMessage = rawMessage.isNotEmpty
            ? rawMessage
            : "Ahora mismo me está costando responderte. Probemos otra vez con calma.";
        phase = ConversationPhase.reflection;
      });
    }
  }

  void _goToSuggestedHelp() {
    final suggestedTool =
        (_aiResponse?.recommendedTool.trim().isNotEmpty ?? false)
            ? _aiResponse!.recommendedTool.trim()
            : "conversation";

    final decision = InterventionDecision(
      type: _mapToolToType(suggestedTool),
      intervention: suggestedTool,
      validationMessage:
          _aiResponse?.validation ??
              "Estoy aquí contigo. Vamos paso a paso.",
      fromHistory: false,
      usedFallback: false,
      requiresSupportPath: suggestedTool == "support_path",
      rationale: "Sugerencia directa desde la respuesta de IA.",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InterventionScreen(
          decision: decision,
          emotion: widget.emotion,
          intensity: widget.intensity,
          briefContext: _responseController.text.trim(),
        ),
      ),
    );
  }

  void _onPrimaryPressed() {
    switch (phase) {
      case ConversationPhase.writing:
        _requestAiResponse();
        break;
      case ConversationPhase.loading:
        break;
      case ConversationPhase.reflection:
        if (_errorMessage != null) {
          _requestAiResponse();
          return;
        }
        _goToSuggestedHelp();
        break;
    }
  }

  void _skipWriting() {
    _requestAiResponse();
  }

  void _finish() {
    final intervention =
        (_aiResponse?.recommendedTool.trim().isNotEmpty ?? false)
            ? _aiResponse!.recommendedTool.trim()
            : "conversation";

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: intervention,
        ),
      ),
    );
  }

  Widget _buildWritingContent(bool keyboardOpen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _getIntroLine(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _getPromptQuestion(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            height: 1.3,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "No hace falta decirlo perfecto. Una frase simple basta.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _responseController,
          focusNode: _inputFocusNode,
          minLines: keyboardOpen ? 2 : 3,
          maxLines: keyboardOpen ? 3 : 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: "Escribe aquí lo que más pesa ahora...",
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F5FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _skipWriting,
          child: const Text(
            "Prefiero seguir sin escribir",
            style: TextStyle(
              color: Color(0xFF7A6A95),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    final typedText = _responseController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Estoy buscando la mejor forma de acompañarte con esto...",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            height: 1.35,
            color: Colors.black87,
          ),
        ),
        if (typedText.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "\"$typedText\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorContent() {
    final typedText = _responseController.text.trim();
    final hasResponse = typedText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Ahora mismo me está costando responderte como quisiera.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            height: 1.4,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "No hiciste nada mal. Probemos nuevamente en un momento.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.black54,
          ),
        ),
        if (hasResponse) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "\"$typedText\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF8A5C5C),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionContent() {
    if (_errorMessage != null) {
      return _buildErrorContent();
    }

    final typedText = _responseController.text.trim();
    final hasResponse = typedText.isNotEmpty;
    final validation = _aiResponse?.validation ??
        "Estoy aquí contigo. Vamos paso a paso.";
    final nextMessage = _aiResponse?.nextMessage ??
        "Por ahora, vamos paso a paso. No necesitas resolverlo todo de una vez.";
    final suggestedTool = _aiResponse?.recommendedTool ?? "conversation";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          validation,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            height: 1.4,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          nextMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isCrisisPath
                ? const Color(0xFFFCF0F0)
                : const Color(0xFFF8F5FC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isCrisisPath
                  ? const Color(0xFFE7B3B3)
                  : const Color(0xFFE4D8F3),
            ),
          ),
          child: Column(
            children: [
              Text(
                _isCrisisPath
                    ? "Apoyo prioritario"
                    : _hasRiskCheck
                        ? "Chequeo importante"
                        : "Ayuda breve sugerida",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _toolLabel(suggestedTool),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.35,
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _toolSupportText(suggestedTool),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        if (hasResponse) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "\"$typedText\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentContent(bool keyboardOpen) {
    switch (phase) {
      case ConversationPhase.writing:
        return _buildWritingContent(keyboardOpen);
      case ConversationPhase.loading:
        return _buildLoadingContent();
      case ConversationPhase.reflection:
        return _buildReflectionContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return MainLayout(
      title: "Hablemos un momento",
      child: Container(
        color: _backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      keyboardOpen ? 12 : 20,
                      20,
                      12,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: keyboardOpen ? 0 : 4),
                        if (!keyboardOpen) ...[
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 46,
                            color: _primaryColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(keyboardOpen ? 16 : 20),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: SizedBox(
                              key: ValueKey(phase),
                              width: double.infinity,
                              child: _buildCurrentContent(keyboardOpen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCrisisPath
                                ? const Color(0xFFD88F8F)
                                : _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: phase == ConversationPhase.loading
                              ? null
                              : _onPrimaryPressed,
                          child: Text(
                            _getPrimaryButtonLabel(),
                            style: const TextStyle(
                              fontSize: 15.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (phase == ConversationPhase.reflection &&
                          _errorMessage == null &&
                          !_isCrisisPath) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _finish,
                          child: const Text(
                            "Terminar por ahora",
                            style: TextStyle(
                              color: Color(0xFF7A6A95),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
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