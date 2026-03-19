import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/intervention_selector.dart';
import 'intervention_screen.dart';

class SupportPathScreen extends StatefulWidget {
  final String emotion;
  final String intensity;

  const SupportPathScreen({
    super.key,
    required this.emotion,
    required this.intensity,
  });

  @override
  State<SupportPathScreen> createState() => _SupportPathScreenState();
}

class _SupportPathScreenState extends State<SupportPathScreen> {
  final TextEditingController _contextController = TextEditingController();
  bool showContextInput = false;

  void _goToIntervention({String briefContext = ""}) {
    final decision = InterventionSelector.select(
      emotion: widget.emotion,
      intensity: widget.intensity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterventionScreen(
          decision: decision,
          emotion: widget.emotion,
          intensity: widget.intensity,
          briefContext: briefContext,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          const Text(
            "Gracias por decírmelo.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "¿Quieres contarme un poco más o prefieres que te ayude de inmediato?",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 30),
          if (!showContextInput) ...[
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _goToIntervention(),
                child: const Text("Ayúdame de inmediato"),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    showContextInput = true;
                  });
                },
                child: const Text("Quiero contarlo"),
              ),
            ),
          ] else ...[
            const Text(
              "Cuéntamelo en una frase breve.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contextController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: "Escribe aquí lo que está pasando...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _goToIntervention(
                    briefContext: _contextController.text.trim(),
                  );
                },
                child: const Text("Continuar"),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  showContextInput = false;
                  _contextController.clear();
                });
              },
              child: const Text("Volver"),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}