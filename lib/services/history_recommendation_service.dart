import 'history_service.dart';

class HistoryRecommendation {
  final String intervention;
  final String message;
  final bool hasRecommendation;

  const HistoryRecommendation({
    required this.intervention,
    required this.message,
    required this.hasRecommendation,
  });
}

class HistoryRecommendationService {
  static HistoryRecommendation getRecommendation({
    required String emotion,
    required String intensity,
  }) {
    final records = HistoryService.getRecords().reversed.toList();

    final exactMatches = records.where(
      (record) =>
          record.emotion.toLowerCase() == emotion.toLowerCase() &&
          record.intensity.toLowerCase() == intensity.toLowerCase(),
    );

    final helpfulExact =
        exactMatches.where((record) => record.feedback == "good");

    if (helpfulExact.isNotEmpty) {
      final best = helpfulExact.first;
      return HistoryRecommendation(
        intervention: best.intervention,
        hasRecommendation: true,
        message:
            "La última vez que te sentiste así, te ayudó ${_readableIntervention(best.intervention)}. ¿Quieres repetirlo?",
      );
    }

    final sameEmotionMatches = records.where(
      (record) => record.emotion.toLowerCase() == emotion.toLowerCase(),
    );

    final helpfulSameEmotion =
        sameEmotionMatches.where((record) => record.feedback == "good");

    if (helpfulSameEmotion.isNotEmpty) {
      final best = helpfulSameEmotion.first;
      return HistoryRecommendation(
        intervention: best.intervention,
        hasRecommendation: true,
        message:
            "Antes, cuando te sentiste parecido, te ayudó ${_readableIntervention(best.intervention)}. Podemos empezar por ahí.",
      );
    }

    return const HistoryRecommendation(
      intervention: "",
      hasRecommendation: false,
      message: "",
    );
  }

  static String _readableIntervention(String intervention) {
    switch (intervention) {
      case "breathing":
        return "una respiración breve";
      case "grounding":
        return "volver al presente";
      case "clench_fists":
        return "soltar tensión en el cuerpo";
      case "micro_action":
        return "dar un paso pequeño";
      case "reframe":
        return "mirarlo desde otro ángulo";
      default:
        return "esa ayuda";
    }
  }
}