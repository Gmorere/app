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
      );

      if (!mounted) return;

      if (output.riskLevel == 'crisis') {
        _goToSupportPath(writtenText, output.riskLevel);
        return;
      }

      setState(() {
        _result = output;
      });
    } catch (e) {
      if (!mounted) return;
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
                  content.intro,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
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
                  maxLines: 8,
                  minLines: 8,
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
        if (result.shouldOfferHumanSupport) ...[
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
        ],
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
