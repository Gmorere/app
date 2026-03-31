import '../core/intervention_origin.dart';
import '../core/emotion_normalizer.dart';
import '../models/emotion_record.dart';
import 'history_service.dart';

class HistoryRecommendation {
  final String intervention;
  final String message;
  final bool hasRecommendation;
  final Set<String> blockedInterventions;

  const HistoryRecommendation({
    required this.intervention,
    required this.message,
    required this.hasRecommendation,
    this.blockedInterventions = const {},
  });
}

class ToolboxRecommendation {
  final String intervention;
  final String reason;

  const ToolboxRecommendation({
    required this.intervention,
    required this.reason,
  });
}

class HistoryRecommendationService {
  // Si la intervencion fue usada en las ultimas 48 horas, no la reforzamos
  // como sesgo aunque haya funcionado bien.
  static const Duration _recencyWindow = Duration(hours: 48);
  // Si una ayuda salio mal hace poco para el mismo estado, no la repetimos
  // como primera opcion durante una semana.
  static const Duration _negativeCooldown = Duration(days: 7);
  // Senal estructurada de escritura: solo entra como desempate suave si se
  // repite y ya hubo utilidad.
  static const Duration _themeSignalWindow = Duration(days: 21);
  static const Set<String> _toolboxEligibleInterventions = {
    'breathing',
    'grounding',
    'clench_fists',
    'movement',
    'sensory_pause',
    'reframe',
    'expressive_writing',
    'micro_action',
  };

  static HistoryRecommendation getRecommendation({
    required String emotion,
    required String intensity,
  }) {
    final normalizedEmotion = EmotionNormalizer.normalizeEmotion(emotion);
    final normalizedIntensity = EmotionNormalizer.normalizeIntensity(intensity);

    final records = HistoryService.getRecords().reversed.toList();

    final exactMatches = records.where(
      (r) =>
          EmotionNormalizer.normalizeEmotion(r.emotion) == normalizedEmotion &&
          EmotionNormalizer.normalizeIntensity(r.intensity) == normalizedIntensity &&
          InterventionOrigin.shouldInfluenceRecommendation(
            r.interventionOrigin,
          ) &&
          r.intervention != 'support_path',
    ).toList();

    if (exactMatches.isEmpty) {
      return const HistoryRecommendation(
        intervention: '',
        hasRecommendation: false,
        message: '',
      );
    }

    final blockedInterventions = _blockedInterventions(exactMatches);
    final preferred = _selectPreferredIntervention(
      exactMatches: exactMatches,
      allRecords: records,
      blockedInterventions: blockedInterventions,
    );

    if (preferred == null) {
      return HistoryRecommendation(
        intervention: '',
        hasRecommendation: false,
        message: '',
        blockedInterventions: blockedInterventions,
      );
    }

    return HistoryRecommendation(
      intervention: preferred,
      hasRecommendation: true,
      message:
          'Antes te ayudo ${_readableIntervention(preferred)} en un momento parecido. Lo tomo como referencia, no como regla fija.',
      blockedInterventions: blockedInterventions,
    );
  }

  static List<ToolboxRecommendation> getToolboxRecommendations({
    int limit = 2,
  }) {
    final records = HistoryService.getRecords().reversed.toList();
    final eligibleRecords = records
        .where((record) => _toolboxEligibleInterventions.contains(record.intervention))
        .toList();

    final positiveSignals =
        eligibleRecords.where((record) => _scoreForRecord(record) > 0).length;

    if (positiveSignals < 2) {
      return const [];
    }

    final blockedInterventions = _blockedInterventions(eligibleRecords);
    final scores = <String, int>{};
    final latestByIntervention = <String, DateTime>{};

    for (final record in eligibleRecords) {
      final intervention = record.intervention;
      scores.update(
        intervention,
        (value) => value + _scoreForRecord(record),
        ifAbsent: () => _scoreForRecord(record),
      );

      final latestSeen = latestByIntervention[intervention];
      if (latestSeen == null || record.timestamp.isAfter(latestSeen)) {
        latestByIntervention[intervention] = record.timestamp;
      }
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;

        final latestA = latestByIntervention[a.key];
        final latestB = latestByIntervention[b.key];
        if (latestA != null && latestB != null) {
          final dateCompare = latestB.compareTo(latestA);
          if (dateCompare != 0) return dateCompare;
        }

        return a.key.compareTo(b.key);
      });

    final recommendations = <ToolboxRecommendation>[];

    for (final candidate in ranked) {
      if (recommendations.length >= limit) break;
      if (candidate.value <= 0) continue;
      if (blockedInterventions.contains(candidate.key)) continue;

      recommendations.add(
        ToolboxRecommendation(
          intervention: candidate.key,
          reason: _toolboxReason(candidate.key),
        ),
      );
    }

    return recommendations;
  }

  static bool _usedRecently(String intervention, List<EmotionRecord> records) {
    final cutoff = DateTime.now().subtract(_recencyWindow);
    return records.any(
      (r) => r.intervention == intervention && r.timestamp.isAfter(cutoff),
    );
  }

  static Set<String> _blockedInterventions(List<EmotionRecord> exactMatches) {
    final cutoff = DateTime.now().subtract(_negativeCooldown);
    final latestByIntervention = <String, EmotionRecord>{};

    for (final record in exactMatches) {
      latestByIntervention.putIfAbsent(record.intervention, () => record);
    }

    final blocked = <String>{};
    for (final entry in latestByIntervention.entries) {
      final record = entry.value;
      if (_isBlockedOutcome(record) && record.timestamp.isAfter(cutoff)) {
        blocked.add(entry.key);
      }
    }

    return blocked;
  }

  static String? _selectPreferredIntervention({
    required List<EmotionRecord> exactMatches,
    required List<EmotionRecord> allRecords,
    required Set<String> blockedInterventions,
  }) {
    final scores = <String, int>{};

    for (final record in exactMatches) {
      final score = _scoreForRecord(record);
      scores.update(
        record.intervention,
        (value) => value + score,
        ifAbsent: () => score,
      );
    }

    final themeAlignedInterventions = _themeAlignedInterventions(exactMatches);
    for (final intervention in themeAlignedInterventions) {
      if (!scores.containsKey(intervention)) continue;
      scores.update(intervention, (value) => value + 1);
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });

    for (final candidate in ranked) {
      if (candidate.value <= 0) continue;
      if (blockedInterventions.contains(candidate.key)) continue;
      if (_usedRecently(candidate.key, allRecords)) continue;
      return candidate.key;
    }

    return null;
  }

  static bool _isBlockedOutcome(EmotionRecord record) {
    return record.feedback == 'bad';
  }

  static int _scoreForRecord(EmotionRecord record) {
    if (record.hasDualFeedback) {
      int score = 0;

      if (record.utilityFeedback == true) {
        score += 3;
      } else if (record.utilityFeedback == false) {
        score -= 3;
      }

      if (record.reliefFeedback == true) {
        score += 1;
      } else if (record.reliefFeedback == false) {
        score -= 1;
      }

      return score;
    }

    return _scoreForLegacyFeedback(record.feedback);
  }

  static int _scoreForLegacyFeedback(String feedback) {
    switch (feedback) {
      case 'good':
        // Legacy "good" solo confirma que la intervencion fue positiva
        // en conjunto, sin separar alivio y utilidad. Lo alineamos con el
        // mejor caso dual para no mezclar dos escalas distintas.
        return 4;
      case 'neutral':
        // Legacy "neutral" no distingue entre "util sirvio poco" y
        // "alivio algo pero no fue util". Lo tratamos como ambiguo.
        return 0;
      case 'bad':
        return -4;
      default:
        return 0;
    }
  }

  static String _readableIntervention(String intervention) {
    switch (intervention) {
      case 'breathing':
        return 'una respiracion breve';
      case 'grounding':
        return 'volver al presente';
      case 'clench_fists':
        return 'soltar tension en el cuerpo';
      case 'micro_action':
        return 'dar un paso pequeno';
      case 'reframe':
        return 'mirarlo desde otro angulo';
      case 'expressive_writing':
        return 'escribir para ordenarlo';
      case 'movement':
        return 'mover el cuerpo un momento';
      case 'sensory_pause':
        return 'una pausa sensorial breve';
      default:
        return 'esa ayuda';
    }
  }

  static String _toolboxReason(String intervention) {
    switch (intervention) {
      case 'breathing':
        return 'Te sirvi\u00f3 antes para bajar un poco la intensidad.';
      case 'grounding':
        return 'Te sirvi\u00f3 antes para volver al presente m\u00e1s r\u00e1pido.';
      case 'clench_fists':
        return 'Te sirvi\u00f3 antes para soltar tensi\u00f3n acumulada.';
      case 'movement':
        return 'Te sirvi\u00f3 antes para descargar activaci\u00f3n en el cuerpo.';
      case 'sensory_pause':
        return 'Te sirvi\u00f3 antes para bajar ruido y saturaci\u00f3n.';
      case 'micro_action':
        return 'Te sirvi\u00f3 antes para destrabarte con algo concreto.';
      case 'reframe':
        return 'Te sirvi\u00f3 antes para mirar esto con m\u00e1s espacio.';
      case 'expressive_writing':
        return 'Te sirvi\u00f3 antes para sacar peso y ordenarlo.';
      default:
        return 'Ya te sirvi\u00f3 antes. Puedes volver directo si lo necesitas.';
    }
  }

  static Set<String> _themeAlignedInterventions(List<EmotionRecord> exactMatches) {
    final cutoff = DateTime.now().subtract(_themeSignalWindow);
    final helpfulSignals = exactMatches.where((record) {
      if (record.intervention != 'expressive_writing') return false;
      if (record.timestamp.isBefore(cutoff)) return false;
      if ((record.possibleTheme ?? '').isEmpty) return false;
      return record.utilityFeedback == true || _scoreForRecord(record) > 0;
    }).toList();

    if (helpfulSignals.length < 2) {
      return const {};
    }

    final themeWeights = <String, int>{};
    final themeCounts = <String, int>{};

    for (final record in helpfulSignals) {
      final theme = record.possibleTheme;
      if (theme == null || theme.isEmpty) continue;

      themeCounts.update(theme, (value) => value + 1, ifAbsent: () => 1);
      themeWeights.update(
        theme,
        (value) => value + (record.themeConfidence == 'medium' ? 2 : 1),
        ifAbsent: () => record.themeConfidence == 'medium' ? 2 : 1,
      );
    }

    final repeatedThemes = themeCounts.entries
        .where((entry) => entry.value >= 2)
        .toList();

    if (repeatedThemes.isEmpty) {
      return const {};
    }

    repeatedThemes.sort((a, b) {
      final weightA = themeWeights[a.key] ?? 0;
      final weightB = themeWeights[b.key] ?? 0;
      final weightCompare = weightB.compareTo(weightA);
      if (weightCompare != 0) return weightCompare;
      return b.value.compareTo(a.value);
    });

    return _interventionsForTheme(repeatedThemes.first.key);
  }

  static Set<String> _interventionsForTheme(String theme) {
    switch (theme) {
      case 'rumiacion':
      case 'autocritica':
      case 'culpa_post_reaccion':
      case 'tristeza_desconexion':
        return const {'expressive_writing', 'reframe'};
      case 'desborde_reactivo':
      case 'miedo_a_perder_control':
        return const {'grounding', 'movement', 'breathing'};
      case 'bloqueo_decisional':
      case 'evitacion':
      case 'desorganizacion':
        return const {'micro_action'};
      case 'agotamiento':
        return const {'sensory_pause', 'grounding'};
      case 'impulso_antojo':
        return const {'grounding', 'micro_action'};
      default:
        return const {};
    }
  }
}
