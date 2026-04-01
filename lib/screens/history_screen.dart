import 'package:flutter/material.dart';

import '../core/intervention_origin.dart';
import '../models/emotion_record.dart';
import '../models/emotional_pulse_record.dart';
import '../core/emotion_normalizer.dart';
import '../services/emotional_pulse_service.dart';
import '../services/history_service.dart';
import '../widgets/main_layout.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const Color _primaryBlue = Color(0xFF7FA8B8);

  _HistoryTab _selectedTab = _HistoryTab.interactions;

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _feedbackLabel(String feedback) {
    switch (feedback) {
      case 'good':
        return 'S\u00ed ayud\u00f3';
      case 'neutral':
        return 'Ayud\u00f3 un poco';
      case 'bad':
        return 'No ayud\u00f3 mucho';
      default:
        return 'Sin feedback';
    }
  }

  IconData _feedbackIcon(String feedback) {
    switch (feedback) {
      case 'good':
        return Icons.thumb_up_alt_outlined;
      case 'neutral':
        return Icons.thumbs_up_down_outlined;
      case 'bad':
        return Icons.thumb_down_alt_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _readableEmotion(String emotion) {
    switch (EmotionNormalizer.normalizeEmotion(emotion)) {
      case 'ansiedad':
        return 'Ansiedad';
      case 'sobrecarga':
        return 'Sobrecarga';
      case 'bloqueo':
        return 'Bloqueo';
      case 'rabia':
        return 'Rabia';
      case 'tristeza':
        return 'Tristeza';
      default:
        return emotion;
    }
  }

  String _readableIntensity(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'alto':
        return 'Alta';
      case 'medio':
        return 'Media';
      case 'bajo':
        return 'Baja';
      default:
        return intensity;
    }
  }

  String _readableIntervention(String intervention) {
    switch (intervention) {
      case 'breathing':
        return 'Respiraci\u00f3n guiada';
      case 'grounding':
        return 'Volver al presente';
      case 'clench_fists':
        return 'Liberar tensi\u00f3n';
      case 'movement':
        return 'Mover el cuerpo un momento';
      case 'sensory_pause':
        return 'Pausa sensorial breve';
      case 'micro_action':
        return 'Dar un peque\u00f1o paso';
      case 'reframe':
        return 'Mirarlo desde otro \u00e1ngulo';
      case 'expressive_writing':
        return 'Escribir para ordenarlo';
      case 'conversation':
        return 'Hablarlo un momento';
      case 'support_path':
        return 'Buscar apoyo';
      default:
        return 'Ayuda breve';
    }
  }

  double _pulseLoadAverage(EmotionalPulseRecord pulse) {
    return (pulse.overload + pulse.tension) / 2;
  }

  double _pulseSupportAverage(EmotionalPulseRecord pulse) {
    return (pulse.energy + pulse.rest + pulse.connection) / 3;
  }

  double _pulseLoadAverageForList(List<EmotionalPulseRecord> records) {
    if (records.isEmpty) return 0;
    final total = records.fold<double>(
      0,
      (sum, pulse) => sum + _pulseLoadAverage(pulse),
    );
    return total / records.length;
  }

  double _pulseSupportAverageForList(List<EmotionalPulseRecord> records) {
    if (records.isEmpty) return 0;
    final total = records.fold<double>(
      0,
      (sum, pulse) => sum + _pulseSupportAverage(pulse),
    );
    return total / records.length;
  }

  String _pulseLevelLabel(double value) {
    if (value >= 3.5) return 'Alta';
    if (value >= 2.5) return 'Media';
    return 'Baja';
  }

  String _strongestLoadLabel(EmotionalPulseRecord pulse) {
    final top = <String, int>{
      'Sobrecarga': pulse.overload,
      'Tensi\u00f3n': pulse.tension,
    }.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return top.first.key;
  }

  String _strongestSupportLabel(EmotionalPulseRecord pulse) {
    final top = <String, int>{
      'Energ\u00eda': pulse.energy,
      'Descanso': pulse.rest,
      'Conexi\u00f3n': pulse.connection,
    }.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return top.first.key;
  }

  String _strongestSupportLabelFromRecords(List<EmotionalPulseRecord> records) {
    if (records.isEmpty) return 'Sin datos';

    final totals = <String, double>{
      'Energ\u00eda': 0,
      'Descanso': 0,
      'Conexi\u00f3n': 0,
    };

    for (final pulse in records) {
      totals['Energ\u00eda'] = totals['Energ\u00eda']! + pulse.energy;
      totals['Descanso'] = totals['Descanso']! + pulse.rest;
      totals['Conexi\u00f3n'] = totals['Conexi\u00f3n']! + pulse.connection;
    }

    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.first.key;
  }

  String _buildPulseSummary(EmotionalPulseRecord pulse) {
    return 'Carga ${_pulseLevelLabel(_pulseLoadAverage(pulse))} · Ayuda ${_pulseLevelLabel(_pulseSupportAverage(pulse))}';
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

  List<EmotionRecord> _analysisInteractionRecords(List<EmotionRecord> records) {
    return records
        .where(
          (record) => record.interventionOrigin != InterventionOrigin.manualLibrary,
        )
        .toList();
  }

  int _pulseThisWeek(List<EmotionalPulseRecord> records) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return records.where((record) {
      return record.timestamp.isAfter(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      );
    }).length;
  }

  String _mostFrequentEmotion(List<EmotionRecord> records) {
    if (records.isEmpty) return 'Sin datos';
    final counts = <String, int>{};
    for (final record in records) {
      counts[record.emotion] = (counts[record.emotion] ?? 0) + 1;
    }
    final best =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _readableEmotion(best);
  }

  String _mostHelpfulIntervention(List<EmotionRecord> records) {
    final helpful = records.where(_countsAsHelpfulIntervention).toList();
    if (helpful.isEmpty) return 'Sin datos';
    final counts = <String, int>{};
    for (final record in helpful) {
      counts[record.intervention] = (counts[record.intervention] ?? 0) + 1;
    }
    final best =
        counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _readableIntervention(best);
  }

  bool _countsAsHelpfulIntervention(EmotionRecord record) {
    if (record.utilityFeedback != null) {
      return record.utilityFeedback == true;
    }
    if (record.reliefFeedback != null) {
      return record.reliefFeedback == true;
    }
    return record.feedback == 'good';
  }

  Set<int> _daysWithInteractionActivity(
    List<EmotionRecord> interactionRecords,
    int year,
    int month,
  ) {
    final days = <int>{};
    for (final record in interactionRecords) {
      if (record.timestamp.year == year && record.timestamp.month == month) {
        days.add(record.timestamp.day);
      }
    }
    return days;
  }

  Set<int> _daysWithPulseActivity(
    List<EmotionalPulseRecord> pulseRecords,
    int year,
    int month,
  ) {
    final days = <int>{};
    for (final pulse in pulseRecords) {
      if (pulse.timestamp.year == year && pulse.timestamp.month == month) {
        days.add(pulse.timestamp.day);
      }
    }
    return days;
  }

  String _buildPulseDetail(EmotionalPulseRecord pulse) {
    return 'Pesa m\u00e1s ${_strongestLoadLabel(pulse)}. Ayuda m\u00e1s ${_strongestSupportLabel(pulse)}.';
  }

  String _buildPulseSummaryV2(EmotionalPulseRecord pulse) {
    return 'Carga ${_pulseLevelLabel(_pulseLoadAverage(pulse))} \u00b7 Ayuda ${_pulseLevelLabel(_pulseSupportAverage(pulse))}';
  }

  String _buildPulseMeaningV2({
    required EmotionalPulseRecord pulse,
    required List<EmotionalPulseRecord> pulseRecords,
  }) {
    final latestLoad = _pulseLoadAverage(pulse);
    final latestSupport = _pulseSupportAverage(pulse);
    final accumulatedLoad = _pulseLoadAverageForList(pulseRecords);
    final accumulatedSupport = _pulseSupportAverageForList(pulseRecords);

    if (latestSupport >= 4 && latestLoad <= 2.5) {
      return 'Tu pulso reciente muestra varias se\u00f1ales que ayudan. En tus registros tambi\u00e9n se ve algo que te sostiene con bastante claridad.';
    }
    if (latestLoad >= 4 && latestSupport <= 2.5) {
      return 'Tu pulso reciente muestra bastante carga y pocas se\u00f1ales que ayudan. Ese desequilibrio merece una lectura m\u00e1s cuidadosa.';
    }
    if (latestSupport > latestLoad && accumulatedSupport >= accumulatedLoad) {
      return 'En este momento aparecen algo m\u00e1s de se\u00f1ales que ayudan que de carga, y esa tendencia tambi\u00e9n se alcanza a ver en tus registros recientes.';
    }
    if (latestLoad > latestSupport && accumulatedLoad >= accumulatedSupport) {
      return 'En este momento pesa algo m\u00e1s la carga, y ese mismo peso tambi\u00e9n se repite en tus registros recientes.';
    }
    if (latestSupport > latestLoad) {
      return 'Hoy aparecen algo m\u00e1s de se\u00f1ales que ayudan, aunque en tus registros recientes la carga sigue siendo relevante.';
    }
    if (latestLoad > latestSupport) {
      return 'Hoy pesa algo m\u00e1s la carga, aunque en tus registros recientes tambi\u00e9n hay se\u00f1ales que ayudan.';
    }
    return 'Tu pulso reciente muestra una mezcla bastante pareja entre carga y se\u00f1ales que ayudan.';
  }

  String _pulseTrendTextV2(List<EmotionalPulseRecord> records) {
    if (records.length < 2) {
      return 'Todav\u00eda no hay suficientes pulsos para mostrar c\u00f3mo se viene moviendo tu carga reciente.';
    }

    final chronological = records.reversed.toList();
    final half = chronological.length ~/ 2;
    if (half == 0) {
      return 'Todav\u00eda no hay suficientes pulsos para mostrar c\u00f3mo se viene moviendo tu carga reciente.';
    }

    final firstHalf = chronological.take(half).toList();
    final secondHalf = chronological.skip(half).toList();

    final firstLoad = _pulseLoadAverageForList(firstHalf);
    final secondLoad = _pulseLoadAverageForList(secondHalf);
    final firstSupport = _pulseSupportAverageForList(firstHalf);
    final secondSupport = _pulseSupportAverageForList(secondHalf);

    if (secondLoad <= firstLoad - 0.35 && secondSupport >= firstSupport) {
      return 'En tus registros recientes se ve menos carga y algo m\u00e1s de se\u00f1ales que ayudan.';
    }
    if (secondLoad >= firstLoad + 0.35 && secondSupport <= firstSupport) {
      return 'En tus registros recientes la carga viene subiendo y lo que ayuda aparece menos.';
    }
    if (secondLoad <= firstLoad - 0.35) {
      return 'En tus registros recientes la carga viene bajando.';
    }
    if (secondLoad >= firstLoad + 0.35) {
      return 'En tus registros recientes la carga viene subiendo.';
    }
    if (secondSupport >= firstSupport + 0.35) {
      return 'En tus registros recientes aparecen un poco m\u00e1s de se\u00f1ales que ayudan.';
    }
    if (secondSupport <= firstSupport - 0.35) {
      return 'En tus registros recientes aparecen menos se\u00f1ales que ayudan.';
    }
    return 'En tus registros recientes no aparece un cambio brusco entre carga y lo que ayuda.';
  }

  List<Widget> _buildSummaryCards({
    required List<EmotionRecord> interactionRecords,
    required List<EmotionalPulseRecord> pulseRecords,
  }) {
    if (_selectedTab == _HistoryTab.pulse) {
      final averageLoad = _pulseLoadAverageForList(pulseRecords);
      return [
        _SummaryCard(
          icon: Icons.track_changes_outlined,
          title: 'Carga reciente',
          value: _pulseLevelLabel(averageLoad),
          backgroundColor: const Color(0xFFF4EEFB),
          iconColor: const Color(0xFF9C7CC8),
        ),
        _SummaryCard(
          icon: Icons.hub_outlined,
          title: 'Lo que m\u00e1s ayuda',
          value: _strongestSupportLabelFromRecords(pulseRecords),
          backgroundColor: const Color(0xFFF4EEFB),
          iconColor: const Color(0xFF9C7CC8),
        ),
        _SummaryCard(
          icon: Icons.calendar_today_outlined,
          title: 'Esta semana',
          value: '${_pulseThisWeek(pulseRecords)} pulsos',
          backgroundColor: const Color(0xFFF5F9FB),
          iconColor: _primaryBlue,
        ),
        _SummaryCard(
          icon: Icons.insights_outlined,
          title: 'Pulsos registrados',
          value: '${pulseRecords.length} total',
          backgroundColor: const Color(0xFFF8F4FC),
          iconColor: const Color(0xFF9C7CC8),
        ),
      ];
    }

    return [
      _SummaryCard(
        icon: Icons.psychology_alt_outlined,
          title: 'Lo que m\u00e1s aparece',
        value: _mostFrequentEmotion(interactionRecords),
        backgroundColor: const Color(0xFFEEF8FB),
        iconColor: _primaryBlue,
      ),
      _SummaryCard(
        icon: Icons.favorite_border,
          title: 'Lo que m\u00e1s ayuda',
        value: _mostHelpfulIntervention(interactionRecords),
        backgroundColor: const Color(0xFFF1F8EC),
        iconColor: const Color(0xFF8BB174),
      ),
      _SummaryCard(
        icon: Icons.calendar_today_outlined,
        title: 'Esta semana',
        value: '${_interactionsThisWeek(interactionRecords)} interacciones',
        backgroundColor: const Color(0xFFF4F8FA),
        iconColor: _primaryBlue,
      ),
      _SummaryCard(
        icon: Icons.history_outlined,
        title: 'Interacciones registradas',
        value: '${interactionRecords.length} total',
        backgroundColor: const Color(0xFFF5F9FB),
        iconColor: _primaryBlue,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final interactionRecords = _analysisInteractionRecords(
      HistoryService.getRecords(),
    ).reversed.toList();
    final pulseRecords = EmotionalPulseService.getRecords().reversed.toList();
    final latestPulse = EmotionalPulseService.getLatestRecord();

    final now = DateTime.now();
    final markedDays = _selectedTab == _HistoryTab.pulse
        ? _daysWithPulseActivity(pulseRecords, now.year, now.month)
        : _daysWithInteractionActivity(interactionRecords, now.year, now.month);

    final hasNoData = interactionRecords.isEmpty && pulseRecords.isEmpty;

    return MainLayout(
      title: 'Historial',
      child: hasNoData
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todav\u00eda no hay registros aqu\u00ed.\nCuando uses ArmonIA, ir\u00e9 guardando tu pulso y las interacciones para acompa\u00f1ar mejor tu proceso.',
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
                _buildTabSelector(),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: _buildSummaryCards(
                    interactionRecords: interactionRecords,
                    pulseRecords: pulseRecords,
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedTab == _HistoryTab.pulse) ...[
                  const _SectionHintCard(
                    text:
                        'Aqu\u00ed puedes ver c\u00f3mo se viene moviendo tu carga reciente y qu\u00e9 se\u00f1ales te han venido ayudando m\u00e1s.',
                  ),
                  const SizedBox(height: 12),
                  _PulseTrendCard(text: _pulseTrendTextV2(pulseRecords)),
                  if (latestPulse != null) ...[
                    const SizedBox(height: 12),
                    _PulseInsightCard(
                      title: 'Qu\u00e9 significa esto',
                      text: _buildPulseMeaningV2(
                        pulse: latestPulse,
                        pulseRecords: pulseRecords,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MonthActivityCard(
                    year: now.year,
                    month: now.month,
                    markedDays: markedDays,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historial de pulso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pulseRecords.isEmpty)
                    const _EmptySectionCard(
                      text: 'Todav\u00eda no hay pulsos registrados.',
                    )
                  else ...[
                    ...pulseRecords.take(8).map(
                      (pulse) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentPulseCard(
                          pulse: pulse,
                          summary: _buildPulseSummaryV2(pulse),
                          detail: _buildPulseDetail(pulse),
                          formatDate: _formatDate,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const _SectionHintCard(
                    text:
                        'Aqu\u00ed puedes revisar qu\u00e9 te ha pasado, qu\u00e9 tipo de ayuda te sirvi\u00f3 m\u00e1s y qu\u00e9 se viene repitiendo.',
                  ),
                  const SizedBox(height: 12),
                  _InteractionInsightCard(
                    text: interactionRecords.isEmpty
                        ? 'Todav\u00eda no hay suficientes interacciones para mostrar un patr\u00f3n claro.'
                        : 'Lo que ArmonIA viene viendo: cuando aparece ${_mostFrequentEmotion(interactionRecords).toLowerCase()}, suele ayudarte m\u00e1s ${_mostHelpfulIntervention(interactionRecords).toLowerCase()}.',
                  ),
                  const SizedBox(height: 16),
                  _MonthActivityCard(
                    year: now.year,
                    month: now.month,
                    markedDays: markedDays,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Historial de interacciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (interactionRecords.isEmpty)
                    const _EmptySectionCard(
                      text: 'Todav\u00eda no hay interacciones registradas.',
                    )
                  else
                    ...interactionRecords.take(8).map(
                      (record) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecentInteractionCard(
                          date: _formatDate(record.timestamp),
                          emotion: _readableEmotion(record.emotion),
                          intensity: _readableIntensity(record.intensity),
                          intervention:
                              _readableIntervention(record.intervention),
                          feedback: _feedbackLabel(record.feedback),
                          feedbackIcon: _feedbackIcon(record.feedback),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HistoryTabButton(
              label: 'Pulso',
              selected: _selectedTab == _HistoryTab.pulse,
              onTap: () => setState(() => _selectedTab = _HistoryTab.pulse),
            ),
          ),
          Expanded(
            child: _HistoryTabButton(
              label: 'Interacciones',
              selected: _selectedTab == _HistoryTab.interactions,
              onTap: () =>
                  setState(() => _selectedTab = _HistoryTab.interactions),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryTab { pulse, interactions }

class _HistoryTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _primaryBlue = Color(0xFF7FA8B8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: selected ? _primaryBlue : Colors.black54,
          ),
        ),
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

class _SectionHintCard extends StatelessWidget {
  final String text;

  const _SectionHintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.8,
          color: Colors.black54,
          height: 1.35,
        ),
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
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final cells = <Widget>[];

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
                '$day',
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('L', style: TextStyle(color: Colors.black54)),
              Text('M', style: TextStyle(color: Colors.black54)),
              Text('M', style: TextStyle(color: Colors.black54)),
              Text('J', style: TextStyle(color: Colors.black54)),
              Text('V', style: TextStyle(color: Colors.black54)),
              Text('S', style: TextStyle(color: Colors.black54)),
              Text('D', style: TextStyle(color: Colors.black54)),
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

class _PulseTrendCard extends StatelessWidget {
  final String text;

  const _PulseTrendCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PulseInsightCard extends StatelessWidget {
  final String title;
  final String text;

  const _PulseInsightCard({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionInsightCard extends StatelessWidget {
  final String text;

  const _InteractionInsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final String text;

  const _EmptySectionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black54,
          height: 1.35,
        ),
      ),
    );
  }
}

class _RecentPulseCard extends StatelessWidget {
  final EmotionalPulseRecord pulse;
  final String summary;
  final String detail;
  final String Function(DateTime) formatDate;

  const _RecentPulseCard({
    required this.pulse,
    required this.summary,
    required this.detail,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'Pulso emocional',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDate(pulse.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
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
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emotion, $intensity',
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  intervention,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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
