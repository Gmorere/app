import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../models/emotional_pulse_record.dart';
import '../services/emotional_pulse_service.dart';
import 'emotion_screen.dart';
import 'conversation_screen.dart';

class EmotionalPulseScreen extends StatefulWidget {
  const EmotionalPulseScreen({super.key});

  @override
  State<EmotionalPulseScreen> createState() => _EmotionalPulseScreenState();
}

class _EmotionalPulseScreenState extends State<EmotionalPulseScreen> {
  static const Color _primaryBlue = Color(0xFF7FA8B8);
  static const Color _cardBg = Color(0xFFF5F9FB);

  int step = -1;

  String? energy;
  String? overload;
  String? sleepQuality;
  String? irritability;
  String? connection;
  String? copingCapacity;

  final List<String> energyOptions = [
    "Muy baja",
    "Baja",
    "Media",
    "Alta",
    "Muy alta",
  ];

  final List<String> overloadOptions = [
    "Nada",
    "Poco",
    "Medio",
    "Bastante",
    "Mucho",
  ];

  final List<String> sleepOptions = [
    "Muy malo",
    "Malo",
    "Regular",
    "Bueno",
    "Muy bueno",
  ];

  final List<String> irritabilityOptions = [
    "Nada",
    "Poco",
    "Medio",
    "Bastante",
    "Mucho",
  ];

  final List<String> connectionOptions = [
    "Muy solo",
    "Algo solo",
    "Neutro",
    "Acompañado",
    "Muy acompañado",
  ];

  final List<String> copingOptions = [
    "Muy baja",
    "Baja",
    "Media",
    "Alta",
    "Muy alta",
  ];

  void _startPulse() {
    setState(() {
      step = 0;
    });
  }

  Future<void> _selectAnswer(String value) async {
    switch (step) {
      case 0:
        energy = value;
        break;
      case 1:
        overload = value;
        break;
      case 2:
        sleepQuality = value;
        break;
      case 3:
        irritability = value;
        break;
      case 4:
        connection = value;
        break;
      case 5:
        copingCapacity = value;
        break;
    }

    if (step < 5) {
      setState(() {
        step++;
      });
    } else {
      await _savePulse();
      setState(() {
        step = 6;
      });
    }
  }

  Future<void> _savePulse() async {
    await EmotionalPulseService.addRecord(
      EmotionalPulseRecord(
        timestamp: DateTime.now(),
        energy: _normalizeValue(energy!),
        overload: _normalizeValue(overload!),
        sleepQuality: _normalizeValue(sleepQuality!),
        irritability: _normalizeValue(irritability!),
        connection: _normalizeValue(connection!),
        copingCapacity: _normalizeValue(copingCapacity!),
      ),
    );
  }

  String _normalizeValue(String value) {
    return value.toLowerCase().trim();
  }

  String _getQuestionTitle() {
    switch (step) {
      case 0:
        return "¿Cómo sientes tu energía hoy?";
      case 1:
        return "¿Qué tan sobrecargada sientes tu mente hoy?";
      case 2:
        return "¿Cómo ha estado tu descanso recientemente?";
      case 3:
        return "¿Qué tanta tensión o irritabilidad sientes hoy?";
      case 4:
        return "¿Qué tan acompañado te sientes hoy?";
      case 5:
        return "¿Cómo sientes tu capacidad para enfrentar el día hoy?";
      default:
        return "";
    }
  }

  List<String> _getCurrentOptions() {
    switch (step) {
      case 0:
        return energyOptions;
      case 1:
        return overloadOptions;
      case 2:
        return sleepOptions;
      case 3:
        return irritabilityOptions;
      case 4:
        return connectionOptions;
      case 5:
        return copingOptions;
      default:
        return [];
    }
  }

  String _buildPulseSummary() {
    final overloadHigh = overload == "Bastante" || overload == "Mucho";
    final lowEnergy = energy == "Muy baja" || energy == "Baja";
    final poorSleep = sleepQuality == "Muy malo" || sleepQuality == "Malo";
    final highIrritability =
        irritability == "Bastante" || irritability == "Mucho";
    final lowConnection = connection == "Muy solo" || connection == "Algo solo";
    final lowCoping =
        copingCapacity == "Muy baja" || copingCapacity == "Baja";

    if ((overloadHigh && lowEnergy) || (poorSleep && lowCoping)) {
      return "Hoy se ve una combinación de carga alta y poca reserva. Te conviene bajar exigencia y buscar apoyo más directo, no empujarte más.";
    }

    if (highIrritability || overloadHigh) {
      return "Hoy aparece bastante activación. Lo más útil probablemente sea bajar tensión antes de intentar resolver todo.";
    }

    if (lowConnection || lowCoping) {
      return "Hoy necesitas más contención que presión. Tiene más sentido acompañarte con calma que exigirte resultados rápidos.";
    }

    return "Hoy tu pulso se ve relativamente más estable. Aun así, voy a considerar cómo vienes para ajustar mejor las ayudas cuando las necesites.";
  }

  List<String> _buildHighlights() {
    final List<String> highSignals = [];
    final List<String> lowSignals = [];

    if ((overload == "Bastante") || (overload == "Mucho")) {
      highSignals.add("sobrecarga");
    }
    if ((irritability == "Bastante") || (irritability == "Mucho")) {
      highSignals.add("tensión");
    }

    if ((energy == "Muy baja") || (energy == "Baja")) {
      lowSignals.add("energía");
    }
    if ((sleepQuality == "Muy malo") || (sleepQuality == "Malo")) {
      lowSignals.add("descanso");
    }
    if ((connection == "Muy solo") || (connection == "Algo solo")) {
      lowSignals.add("conexión");
    }
    if ((copingCapacity == "Muy baja") || (copingCapacity == "Baja")) {
      lowSignals.add("capacidad de afrontamiento");
    }

    final List<String> result = [];

    if (highSignals.isNotEmpty) {
      result.add("Hoy destaca más: ${_joinNatural(highSignals)}.");
    }

    if (lowSignals.isNotEmpty) {
      result.add("Más bajo hoy: ${_joinNatural(lowSignals)}.");
    }

    if (result.isEmpty) {
      result.add("No aparece una señal dominante clara en este momento.");
    }

    return result;
  }

  String _joinNatural(List<String> items) {
    if (items.isEmpty) return "";
    if (items.length == 1) return items.first;
    if (items.length == 2) return "${items[0]} y ${items[1]}";
    return "${items.sublist(0, items.length - 1).join(", ")} y ${items.last}";
  }

  int _valueToLevel(String value, List<String> options) {
    final index = options.indexOf(value);
    return index == -1 ? 3 : index + 1;
  }

  int _reverseLevel(int rawLevel) {
    return 6 - rawLevel;
  }

  List<_PulseMetricData> _buildRadarMetrics() {
    return [
      _PulseMetricData(
        label: "Energía",
        valueLabel: energy!,
        level: _valueToLevel(energy!, energyOptions),
        color: const Color(0xFFA9D6E5),
      ),
      _PulseMetricData(
        label: "Sobrecarga",
        valueLabel: overload!,
        level: _valueToLevel(overload!, overloadOptions),
        color: const Color(0xFFEFD8A2),
      ),
      _PulseMetricData(
        label: "Descanso",
        valueLabel: sleepQuality!,
        level: _valueToLevel(sleepQuality!, sleepOptions),
        color: const Color(0xFFC9B6E4),
      ),
      _PulseMetricData(
        label: "Tensión",
        valueLabel: irritability!,
        level: _valueToLevel(irritability!, irritabilityOptions),
        color: const Color(0xFFE8B4A2),
      ),
      _PulseMetricData(
        label: "Conexión",
        valueLabel: connection!,
        level: _valueToLevel(connection!, connectionOptions),
        color: const Color(0xFFB9D6A3),
      ),
    ];
  }

  int _copingLevel() {
    return _valueToLevel(copingCapacity!, copingOptions);
  }

  String _copingLabel() {
    return copingCapacity!;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Pulso emocional",
      child: Container(
        color: const Color(0xFFF8FAFB),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (step == -1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 42,
                      color: _primaryBlue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tu Pulso Emocional",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "Vamos a revisar brevemente cómo vienes hoy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _startPulse,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Comenzar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (step >= 0 && step <= 5) {
      final options = _getCurrentOptions();

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _getQuestionTitle(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pregunta ${step + 1} de 6",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 20),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PulseOptionCard(
                label: option,
                onTap: () => _selectAnswer(option),
              ),
            ),
          ),
        ],
      );
    }

    final metrics = _buildRadarMetrics();
    final highlights = _buildHighlights();

    return ListView(
      children: [
        const Text(
          "Tu pulso de hoy",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Así se ve tu estado reciente.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Vista general",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 300,
                child: _PulseRadarChart(metrics: metrics),
              ),
              const SizedBox(height: 10),
              _CopingSummaryCard(
                label: "Capacidad de afrontar",
                valueLabel: _copingLabel(),
                level: _copingLevel(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lectura rápida",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...highlights.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.arrow_right_alt,
                          size: 17,
                          color: _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _buildPulseSummary(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmotionScreen(),
                ),
                (route) => route.isFirst,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Necesito apoyo ahora",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConversationScreen(
                    emotion: "general",
                    intensity: "medio",
                    briefContext: "",
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: _primaryBlue,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Hablar con ArmonIA",
              style: TextStyle(
                fontSize: 16,
                color: _primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                step = -1;
                energy = null;
                overload = null;
                sleepQuality = null;
                irritability = null;
                connection = null;
                copingCapacity = null;
              });
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFB7CCD5),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Registrar de nuevo",
              style: TextStyle(
                fontSize: 15,
                color: _primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFB7CCD5),
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Volver al inicio",
              style: TextStyle(
                fontSize: 15,
                color: _primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseOptionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PulseOptionCard({
    required this.label,
    required this.onTap,
  });

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.radio_button_unchecked,
                color: _primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _primaryBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseMetricData {
  final String label;
  final String valueLabel;
  final int level;
  final Color color;

  const _PulseMetricData({
    required this.label,
    required this.valueLabel,
    required this.level,
    required this.color,
  });
}

class _CopingSummaryCard extends StatelessWidget {
  final String label;
  final String valueLabel;
  final int level;

  const _CopingSummaryCard({
    required this.label,
    required this.valueLabel,
    required this.level,
  });

  String _normalizeLabel(String value) {
    return "${value[0].toUpperCase()}${value.substring(1)}";
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeLabel(valueLabel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            normalized,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          _MiniLevelBar(level: level),
        ],
      ),
    );
  }
}

class _MiniLevelBar extends StatelessWidget {
  final int level;

  const _MiniLevelBar({
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
            decoration: BoxDecoration(
              color: index < level
                  ? const Color(0xFF9BB8C3)
                  : const Color(0xFF9BB8C3).withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRadarChart extends StatelessWidget {
  final List<_PulseMetricData> metrics;

  const _PulseRadarChart({
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final chartSize = size * 0.78;

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: chartSize,
              height: chartSize,
              child: CustomPaint(
                painter: _RadarPainter(metrics: metrics),
              ),
            ),
            ..._buildLabels(chartSize / 2),
          ],
        );
      },
    );
  }

  List<Widget> _buildLabels(double radius) {
    final total = metrics.length;
    const center = Offset(0, 0);
    const labelRadiusFactor = 1.28;

    return List.generate(total, (index) {
      final angle = (-math.pi / 2) + (2 * math.pi * index / total);
      final dx = center.dx + math.cos(angle) * radius * labelRadiusFactor;
      final dy = center.dy + math.sin(angle) * radius * labelRadiusFactor;

      return Transform.translate(
        offset: Offset(dx, dy),
        child: SizedBox(
          width: 86,
          child: Text(
            metrics[index].label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              height: 1.2,
            ),
          ),
        ),
      );
    });
  }
}

class _RadarPainter extends CustomPainter {
  final List<_PulseMetricData> metrics;

  _RadarPainter({
    required this.metrics,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;
    final total = metrics.length;

    final gridPaint = Paint()
      ..color = const Color(0xFFDCE7EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = const Color(0xFFE5EDF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 5; ring++) {
      final ringRadius = radius * (ring / 5);
      final path = Path();

      for (int i = 0; i < total; i++) {
        final angle = (-math.pi / 2) + (2 * math.pi * i / total);
        final point = Offset(
          center.dx + math.cos(angle) * ringRadius,
          center.dy + math.sin(angle) * ringRadius,
        );

        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < total; i++) {
      final angle = (-math.pi / 2) + (2 * math.pi * i / total);
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, point, axisPaint);
    }

    final valuePath = Path();
    final pointPaint = Paint()
      ..color = const Color(0xFF7FE0C6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < total; i++) {
      final normalizedLevel = metrics[i].level / 5;
      final pointRadius = radius * normalizedLevel;
      final angle = (-math.pi / 2) + (2 * math.pi * i / total);
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );

      if (i == 0) {
        valuePath.moveTo(point.dx, point.dy);
      } else {
        valuePath.lineTo(point.dx, point.dy);
      }
    }

    valuePath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF7FE0C6).withOpacity(0.45)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF53C8A9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    for (int i = 0; i < total; i++) {
      final normalizedLevel = metrics[i].level / 5;
      final pointRadius = radius * normalizedLevel;
      final angle = (-math.pi / 2) + (2 * math.pi * i / total);
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );

      canvas.drawCircle(
        point,
        4.2,
        Paint()..color = const Color(0xFFFFD453),
      );
      canvas.drawCircle(point, 4.2, pointPaint);
    }

    final centerPaint = Paint()
      ..color = const Color(0xFF53C8A9).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 16, centerPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: "IA",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF53C8A9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}