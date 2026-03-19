import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/main_layout.dart';

class FonoAyudaScreen extends StatelessWidget {
  const FonoAyudaScreen({super.key});

  static const Color _primaryBlue = Color(0xFF7FA8B8);
  static const Color _cardBg = Color(0xFFF5F9FB);

  Future<void> _callNumber(BuildContext context, String number) async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No fue posible abrir la llamada en este dispositivo."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Fono Ayuda",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _helpCard(
              context: context,
              title:
                  "Línea gratuita y confidencial de prevención del suicidio en Chile.",
              details:
                  "Disponible 24/7 desde celulares.\nAtendido por profesionales capacitados.",
              number: "*4141",
            ),
            const SizedBox(height: 16),
            _helpCard(
              context: context,
              title: "Salud Responde",
              details: "Orientación y apoyo en salud.\nDisponible 24/7.",
              number: "600 360 7777",
              dialNumber: "6003607777",
            ),
            const SizedBox(height: 24),
            const Text(
              "Si sientes que estás en riesgo o podrías hacerte daño, busca ayuda ahora. No tienes que pasar por esto solo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              details,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _callNumber(context, dialNumber ?? number),
              icon: const Icon(
                Icons.call_outlined,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Llamar ahora",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}