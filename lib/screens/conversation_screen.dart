import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/ai_service.dart';
import 'feedback_screen.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && phase == ConversationPhase.writing) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _responseController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _getPromptQuestion() {
    switch (widget.emotion.toLowerCase()) {
      case "ansiedad":
        return "Si tuvieras que poner en una frase qué es lo que más te inquieta ahora, ¿qué sería?";
      case "sobrepasado":
        return "Si tuvieras que elegir qué es lo que más pesa en este momento, ¿qué sería?";
      case "bloqueado":
        return "Si tuvieras que nombrar qué es lo que más te está frenando ahora, ¿qué dirías?";
      case "molesto":
      case "rabia":
      case "enojo":
        return "Si tuvieras que decir qué fue lo que más te removió, ¿qué sería?";
      case "triste":
      case "pena":
        return "Si tuvieras que poner en palabras qué es lo que más duele o pesa ahora, ¿qué sería?";
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

  String _getFallbackReflectionMessage() {
    final response = _responseController.text.trim();

    if (response.isNotEmpty) {
      return "Gracias por ponerlo en palabras. A veces decirlo no resuelve todo, pero sí baja un poco el peso.";
    }

    return "No hace falta decirlo perfecto ni explicarlo todo ahora. A veces incluso detenerse un momento ya cambia algo.";
  }

  String _toolLabel(String tool) {
    switch (tool) {
      case "breathing":
        return "respiración guiada";
      case "grounding":
        return "volver al presente";
      case "reframe":
        return "mirar esto desde otro ángulo";
      case "micro_action":
        return "dar un paso pequeño";
      case "support_path":
        return "buscar apoyo";
      case "conversation":
      default:
        return "seguir conversando un poco";
    }
  }

  String _getPrimaryButtonLabel() {
    switch (phase) {
      case ConversationPhase.writing:
        return "Pedir ayuda a ArmonIA";
      case ConversationPhase.loading:
        return "Pensando...";
      case ConversationPhase.reflection:
        return "Finalizar";
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
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      setState(() {
        _aiResponse = result;
        phase = ConversationPhase.reflection;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            "No pude conectarme con la IA ahora mismo. Revisemos la conexión y volvamos a intentar.";
        phase = ConversationPhase.reflection;
      });
    }
  }

  void _onPrimaryPressed() {
    switch (phase) {
      case ConversationPhase.writing:
        _requestAiResponse();
        break;
      case ConversationPhase.loading:
        break;
      case ConversationPhase.reflection:
        _finish();
        break;
    }
  }

  void _skipWriting() {
    _requestAiResponse();
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          emotion: widget.emotion,
          intensity: widget.intensity,
          intervention: "conversation",
        ),
      ),
    );
  }

  Widget _buildWritingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _getIntroLine(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.4,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getPromptQuestion(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            height: 1.28,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "No hace falta decirlo perfecto. Una frase simple basta.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _responseController,
          focusNode: _inputFocusNode,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: "Escribe aquí lo que más pesa ahora...",
            filled: true,
            fillColor: const Color(0xFFF8F5FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _skipWriting,
          child: const Text(
            "Prefiero seguir sin escribir",
            style: TextStyle(
              color: Color(0xFF7A6A95),
              fontSize: 15,
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
        const SizedBox(
          width: 38,
          height: 38,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          "Ya entendí lo principal. Estoy buscando la mejor forma de ayudarte con esto...",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
        if (typedText.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "\"$typedText\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReflectionContent() {
    final typedText = _responseController.text.trim();
    final hasResponse = typedText.isNotEmpty;
    final validation = _aiResponse?.validation ?? _getFallbackReflectionMessage();
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
            fontSize: 20,
            height: 1.42,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          nextMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            height: 1.42,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5FC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "Sugerencia de ArmonIA: ${_toolLabel(suggestedTool)}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.black54,
            ),
          ),
        ),
        if (hasResponse) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              "\"$typedText\"",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 18),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentContent() {
    switch (phase) {
      case ConversationPhase.writing:
        return _buildWritingContent();
      case ConversationPhase.loading:
        return _buildLoadingContent();
      case ConversationPhase.reflection:
        return _buildReflectionContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 54,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: SizedBox(
                              key: ValueKey(phase),
                              width: double.infinity,
                              child: _buildCurrentContent(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  keyboardInset > 0 ? keyboardInset + 12 : 20,
                ),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                        phase == ConversationPhase.loading ? null : _onPrimaryPressed,
                    child: Text(
                      _getPrimaryButtonLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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