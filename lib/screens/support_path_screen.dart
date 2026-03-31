import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/intervention_origin.dart';
import '../services/auth_service.dart';
import '../widgets/main_layout.dart';
import 'fono_ayuda_screen.dart';

class SupportPathScreen extends StatefulWidget {
  final String emotion;
  final String intensity;
  final String authToken;
  final String initialContext;
  final String interventionOrigin;

  const SupportPathScreen({
    super.key,
    required this.emotion,
    required this.intensity,
    required this.authToken,
    this.initialContext = "",
    this.interventionOrigin = InterventionOrigin.crisis,
  });

  @override
  State<SupportPathScreen> createState() => _SupportPathScreenState();
}

class _SupportPathScreenState extends State<SupportPathScreen> {
  TrustedContact? _trustedContact;
  bool _loadingTrustedContact = true;

  bool get _isCrisisFlow =>
      widget.interventionOrigin == InterventionOrigin.crisis;

  @override
  void initState() {
    super.initState();
    _loadTrustedContact();
  }

  Future<void> _loadTrustedContact() async {
    final contact = await AuthService.getTrustedContact();
    if (!mounted) return;
    setState(() {
      _trustedContact = contact;
      _loadingTrustedContact = false;
    });
  }

  void _goToImmediateSupport() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FonoAyudaScreen(
          interventionOrigin: widget.interventionOrigin,
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _callTrustedContact() async {
    final contact = _trustedContact;
    if (contact == null) return;

    final uri = Uri(scheme: 'tel', path: contact.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No fue posible abrir la llamada en este dispositivo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCrisisFlow ? 'Apoyo inmediato' : 'Apoyo cercano';
    final lead = _isCrisisFlow
        ? 'Gracias por decirlo.'
        : 'Vale la pena frenarlo aqu\u00ed.';
    final headline = _isCrisisFlow
        ? 'No tienes que seguir con esto solo. Lo mejor ahora es acercarte a apoyo humano.'
        : 'Puede ayudarte hablar con una persona real antes de que esto siga pesando m\u00e1s.';
    final intro = _isCrisisFlow
        ? 'Si puedes, toma contacto con una persona real y usa una de estas opciones ahora.'
        : 'Si lo necesitas, puedes apoyarte en una persona cercana o usar una de estas opciones ahora.';
    final primaryCta = _isCrisisFlow ? 'Ver apoyo ahora' : 'Ver opciones de apoyo';

    return MainLayout(
      title: title,
      showHomeButton: false,
      showBottomNavigation: false,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Text(
            lead,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            intro,
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
            child: const Column(
              children: [
                Text(
                  "Apoyo humano disponible",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "*4141",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Salud Responde 600 360 7777",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!_loadingTrustedContact && _trustedContact != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contacto de confianza",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tambi\u00e9n puedes llamar a ${_trustedContact!.name} si necesitas apoyo cercano ahora.",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _callTrustedContact,
                      icon: const Icon(Icons.phone_outlined),
                      label: Text("Llamar a ${_trustedContact!.name}"),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _goToImmediateSupport,
              child: Text(primaryCta),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _goHome,
              child: const Text("Volver al inicio"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
