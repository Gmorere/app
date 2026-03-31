import '../core/intervention_origin.dart';

class EmotionRecord {
  final String emotion;
  final String intensity;
  final String intervention;
  final String? legacyFeedback;
  final bool? reliefFeedback;
  final bool? utilityFeedback;
  final String interventionOrigin;
  final String? contextTag;
  final String? possibleTheme;
  final String? themeConfidence;
  final DateTime timestamp;

  const EmotionRecord({
    required this.emotion,
    required this.intensity,
    required this.intervention,
    String? feedback,
    this.reliefFeedback,
    this.utilityFeedback,
    this.interventionOrigin = InterventionOrigin.motor,
    this.contextTag,
    this.possibleTheme,
    this.themeConfidence,
    required this.timestamp,
  }) : legacyFeedback = feedback;

  String get feedback {
    final derived = _deriveLegacyFeedback(
      reliefFeedback: reliefFeedback,
      utilityFeedback: utilityFeedback,
    );
    return derived ?? (legacyFeedback ?? '');
  }

  bool get hasDualFeedback =>
      reliefFeedback != null || utilityFeedback != null;

  bool get helped {
    if (hasDualFeedback) {
      return reliefFeedback == true || utilityFeedback == true;
    }
    return feedback == 'good';
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'intensity': intensity,
      'intervention': intervention,
      'feedback': feedback,
      'relief_feedback': reliefFeedback,
      'utility_feedback': utilityFeedback,
      'intervention_origin': interventionOrigin,
      'context_tag': contextTag,
      'possible_theme': possibleTheme,
      'theme_confidence': themeConfidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      emotion: (json['emotion'] ?? '').toString(),
      intensity: (json['intensity'] ?? '').toString(),
      intervention: (json['intervention'] ?? '').toString(),
      feedback: (json['feedback'] ?? '').toString(),
      reliefFeedback: json['relief_feedback'] is bool
          ? json['relief_feedback'] as bool
          : null,
      utilityFeedback: json['utility_feedback'] is bool
          ? json['utility_feedback'] as bool
          : null,
      interventionOrigin: InterventionOrigin.normalize(
        json['intervention_origin']?.toString(),
        intervention: (json['intervention'] ?? '').toString(),
        emotion: (json['emotion'] ?? '').toString(),
      ),
      contextTag: _normalizeOptionalValue(json['context_tag']),
      possibleTheme: _normalizeOptionalValue(json['possible_theme']),
      themeConfidence: _normalizeOptionalValue(json['theme_confidence']),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  static String? _normalizeOptionalValue(Object? value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static String? _deriveLegacyFeedback({
    required bool? reliefFeedback,
    required bool? utilityFeedback,
  }) {
    if (reliefFeedback == null || utilityFeedback == null) {
      return null;
    }

    if (reliefFeedback && utilityFeedback) {
      return 'good';
    }

    if (!reliefFeedback && !utilityFeedback) {
      return 'bad';
    }

    return 'neutral';
  }
}
