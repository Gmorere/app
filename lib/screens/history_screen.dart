import 'package:flutter/material.dart';
import '../widgets/main_layout.dart';
import '../services/history_service.dart';
import '../services/emotional_pulse_service.dart';
import '../models/emotion_record.dart';
import '../models/emotional_pulse_record.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _feedbackLabel(String feedback) {
    switch (feedback) {
      case "good":
        return "Sí ayudó";
      case "neutral":
        return "Ayudó un poco";
      case "bad":
        return "No ayudó mucho";
      default:
        return "";
    }
  }

  IconData _feedbackIcon(String feedback) {
    switch (feedback) {
      case "good":
        return Icons.thumb_up_alt_outlined;
      case "neutral":
        return Icons.thumbs_up_down_outlined;
      case "bad":
        return Icons.thumb_down_alt_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _readableEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case "ansiedad":
        return "Ansiedad";
      case "sobrepasado":
        return "Sobrepasado";
      case "bloqueado":
        return "Bloqueado";
      case "rabia":
        return "Rabia";
      case "triste":
        return "Tristeza";
      default:
        return emotion;
    }
  }

  String _readableIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case "alto":
        return "Alta";
      case "medio":
        return "Media";
      case "bajo":
        return "Baja";
      default:
        return intensity;
    }
  }

  String _readableIntervention(String intervention) {
    switch (intervention) {
      case "breathing":
        return "Respiración guiada";
      case "grounding":
        return "Volver al presente";
      case "clench_fists":
        return "Liberar tensión";
      case "micro_action":
        return "Dar un pequeño paso";
      case "reframe":
        return "Mirarlo desde otro ángulo";
      case "conversation":
        return "Hablarlo un momento";
      case "support_path":
        return "Buscar apoyo";
      default:
        return "Ayuda breve";
    }
  }

  String _buildPulseSummary(EmotionalPulseRecord pulse) {
    final overloadHigh =
        pulse.overload == "bastante" || pulse.overload == "mucho";
    final lowEnergy = pulse.energy == "muy baja" || pulse.energy == "baja";
    final poorSleep =
        pulse.sleepQuality == "muy malo" || pulse.sleepQuality == "malo";
    final highIrritability =
        pulse.irritability == "bastante" || pulse.irritability == "mucho";
    final lowConnection =
        pulse.connection == "muy solo" || pulse.connection == "algo solo";
    final lowCoping =
        pulse.copingCapacity == "muy baja" || pulse.copingCapacity == "baja";

    if ((overloadHigh && lowEnergy) || (poorSleep && lowCoping)) {
      return "Sobrecarga alta";
    }

    if (highIrritability || overloadHigh) {
      return "Bastante tensión";
    }

    if (lowConnection || lowCoping) {
      return "Más contención";
    }

    return "Más estable";
  }

  int _interactionsThisWeek(List<EmotionRecord> records) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return records.where((record) {
      return record.timestamp.isAfter(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      );
    }).length;
  }

  String _mostFrequentEmotion(List<EmotionRecord> records) {
    if (records.isEmpty) return "Sin datos";

    final Map<String, int> counts = {};
    for (final record in records) {
      counts[record.emotion] = (counts[record.emotion] ?? 0) + 1;
    }

    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _readableEmotion(best);
  }

  String _mostHelpfulIntervention(List<EmotionRecord> records) {
    final helpful = records.where((r) => r.feedback == "good").toList();
    if (helpful.isEmpty) return "Sin datos";

    final Map<String, int> counts = {};
    for (final record in helpful) {
      counts[record.intervention] = (counts[record.intervention] ?? 0) + 1;
    }

    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _readableIntervention(best);
  }

  String _trendText(
    List<EmotionRecord> records,
    EmotionalPulseRecord? latestPulse,
  ) {
    final interactions = _interactionsThisWeek(records);

    if (interactions == 0 && latestPulse == null) {
      return "Todavía no hay actividad suficiente para mostrar una tendencia.";
    }

    if (latestPulse != null && interactions > 0) {
      return "Últimos 7 días: $interactions interacciones y pulso reciente ${_buildPulseSummary(latestPulse).toLowerCase()}.";
    }

    if (interactions > 0) {
      return "Últimos 7 días: $interactions interacciones registradas.";
    }

    return "Último pulso: ${_buildPulseSummary(latestPulse!)}.";
  }

  Set<int> _daysWithActivity(
    List<EmotionRecord> records,
    EmotionalPulseRecord? latestPulse,
    int year,
    int month,
  ) {
    final days = <int>{};

    for (final record in records) {
      if (record.timestamp.year == year && record.timestamp.month == month) {
        days.add(record.timestamp.day);
      }
    }

    if (latestPulse != null &&
        latestPulse.timestamp.year == year &&
        latestPulse.timestamp.month == month) {
      days.add(latestPulse.timestamp.day);
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final List<EmotionRecord> records =
        HistoryService.getRecords().reversed.toList();
    final EmotionalPulseRecord? latestPulse =
        EmotionalPulseService.getLatestRecord();

    final now = DateTime.now();
    final markedDays =
        _daysWithActivity(records, latestPulse, now.year, now.month);

    return MainLayout(
      title: "Historial",
      child: (records.isEmpty && latestPulse == null)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Todavía no hay registros aquí.\nCuando uses ArmonIA, iré guardando lo que te ayudó para acompañarte mejor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _SummaryCard(
                      icon: Icons.calendar_today_outlined,
                      title: "Esta semana",
                      value: "${_interactionsThisWeek(records)} interacciones",
                      backgroundColor: const Color(0xFFEEF8FB),
                      iconColor: _primaryBlue,
                    ),
                    _SummaryCard(
                      icon: Icons.psychology_alt_outlined,
                      title: "Emoción frecuente",
                      value: _mostFrequentEmotion(records),
                      backgroundColor: const Color(0xFFFCF7EA),
                      iconColor: const Color(0xFFE0B85C),
                    ),
                    _SummaryCard(
                      icon: Icons.favorite_border,
                      title: "Más útil",
                      value: _mostHelpfulIntervention(records),
                      backgroundColor: const Color(0xFFF1F8EC),
                      iconColor: const Color(0xFF8BB174),
                    ),
                    _SummaryCard(
                      icon: Icons.insights_outlined,
                      title: "Último pulso",
                      value: latestPulse != null
                          ? _buildPulseSummary(latestPulse)
                          : "Sin datos",
                      backgroundColor: const Color(0xFFF4EEFB),
                      iconColor: const Color(0xFF9C7CC8),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MonthActivityCard(
                  year: now.year,
                  month: now.month,
                  markedDays: markedDays,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _trendText(records, latestPulse),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Registros recientes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (latestPulse != null)
                  _RecentPulseCard(
                    pulse: latestPulse,
                    summary: _buildPulseSummary(latestPulse),
                    formatDate: _formatDate,
                  ),
                ...records.take(6).map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentInteractionCard(
                      date: _formatDate(record.timestamp),
                      emotion: _readableEmotion(record.emotion),
                      intensity: _readableIntensity(record.intensity),
                      intervention: _readableIntervention(record.intervention),
                      feedback: _feedbackLabel(record.feedback),
                      feedbackIcon: _feedbackIcon(record.feedback),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color backgroundColor;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthActivityCard extends StatelessWidget {
  final int year;
  final int month;
  final Set<int> markedDays;

  const _MonthActivityCard({
    required this.year,
    required this.month,
    required this.markedDays,
  });

  String _monthName(int month) {
    const months = [
      "",
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre"
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1 lun ... 7 dom

    final List<Widget> cells = [];

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isMarked = markedDays.contains(day);

      cells.add(
        Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isMarked ? const Color(0xFF7FA8B8) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isMarked ? FontWeight.bold : FontWeight.normal,
                  color: isMarked ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Text(
            "${_monthName(month)} $year",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("L", style: TextStyle(color: Colors.black54)),
              Text("M", style: TextStyle(color: Colors.black54)),
              Text("M", style: TextStyle(color: Colors.black54)),
              Text("J", style: TextStyle(color: Colors.black54)),
              Text("V", style: TextStyle(color: Colors.black54)),
              Text("S", style: TextStyle(color: Colors.black54)),
              Text("D", style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _RecentPulseCard extends StatelessWidget {
  final EmotionalPulseRecord pulse;
  final String summary;
  final String Function(DateTime) formatDate;

  const _RecentPulseCard({
    required this.pulse,
    required this.summary,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEFB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights_outlined,
                color: Color(0xFF9C7CC8),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pulso emocional",
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatDate(pulse.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInteractionCard extends StatelessWidget {
  final String date;
  final String emotion;
  final String intensity;
  final String intervention;
  final String feedback;
  final IconData feedbackIcon;

  const _RecentInteractionCard({
    required this.date,
    required this.emotion,
    required this.intensity,
    required this.intervention,
    required this.feedback,
    required this.feedbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$emotion, $intensity",
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  intervention,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      feedbackIcon,
                      size: 16,
                      color: const Color(0xFF7FA8B8),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      feedback,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}