import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/intervention_origin.dart';
import '../services/auth_service.dart';
import '../widgets/main_layout.dart';

class FonoAyudaScreen extends StatefulWidget {
  final String interventionOrigin;

  const FonoAyudaScreen({
    super.key,
    this.interventionOrigin = InterventionOrigin.manualLibrary,
  });

  @override
  State<FonoAyudaScreen> createState() => _FonoAyudaScreenState();
}

class _FonoAyudaScreenState extends State<FonoAyudaScreen> {
  static const Color _primaryBlue = Color(0xFF7FA8B8);
  static const Color _cardBg = Color(0xFFF5F9FB);

  TrustedContact? _trustedContact;
  bool _loading = true;

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
      _loading = false;
    });
  }

  Future<void> _callNumber(BuildContext context, String number) async {
    final uri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No fue posible abrir la llamada en este dispositivo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Fono Ayuda',
      showHomeButton: false,
      showBottomNavigation:
          widget.interventionOrigin != InterventionOrigin.crisis,
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF0F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Si sientes que est\u00e1s superado y necesitas apoyo inmediato, aqu\u00ed tienes opciones claras para pedir ayuda ahora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _helpCard(
                    context: context,
                    title:
                        'L\u00ednea gratuita y confidencial de prevenci\u00f3n del suicidio en Chile.',
                    details:
                        'Disponible 24/7 desde celulares.\nAtendido por profesionales capacitados.',
                    number: '*4141',
                  ),
                  const SizedBox(height: 14),
                  _helpCard(
                    context: context,
                    title: 'Salud Responde',
                    details: 'Orientaci\u00f3n y apoyo en salud.\nDisponible 24/7.',
                    number: '600 360 7777',
                    dialNumber: '6003607777',
                  ),
                  if (_trustedContact != null) ...[
                    const SizedBox(height: 14),
                    _helpCard(
                      context: context,
                      title: 'Contacto de confianza',
                      details:
                          'Puedes llamar a ${_trustedContact!.name} si necesitas apoyo r\u00e1pido y cercano.',
                      number: _trustedContact!.phone,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

  Widget _helpCard({
    required BuildContext context,
    required String title,
    required String details,
    required String number,
    String? dialNumber,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _callNumber(context, dialNumber ?? number),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    color: _primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Llamar',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
