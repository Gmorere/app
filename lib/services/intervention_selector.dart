import '../core/intervention_type.dart';
import '../models/intervention_decision.dart';
import '../models/emotional_pulse_record.dart';
import 'history_recommendation_service.dart';
import 'validation_service.dart';
import 'emotional_pulse_service.dart';

class InterventionSelector {
  static InterventionDecision select({
    required String emotion,
    required String intensity,
    bool crisisDetected = false,
    String? lastIntervention,
    bool lastInterventionFailed = false,
  }) {
    final normalizedEmotion = emotion.toLowerCase().trim();
    final normalizedIntensity = intensity.toLowerCase().trim();

    if (crisisDetected) {
      return InterventionDecision(
        type: InterventionType.conversation,
        intervention: "support_path",
        validationMessage:
            "Estoy contigo. Lo más importante ahora es que no pases por esto solo.",
        fromHistory: false,
        usedFallback: false,
        requiresSupportPath: true,
        rationale: "Crisis detectada: se prioriza ruta de apoyo humano.",
      );
    }

    final historyRecommendation = HistoryRecommendationService.getRecommendation(
      emotion: normalizedEmotion,
      intensity: normalizedIntensity,
    );

    if (historyRecommendation.hasRecommendation &&
        !(lastInterventionFailed &&
            historyRecommendation.intervention == lastIntervention)) {
      final historyType =
          _mapInterventionToType(historyRecommendation.intervention);

      return InterventionDecision(
        type: historyType,
        intervention: historyRecommendation.intervention,
        validationMessage: historyRecommendation.message,
        fromHistory: true,
        usedFallback: false,
        requiresSupportPath:
            historyRecommendation.intervention == "support_path",
        rationale:
            "Se priorizó una intervención del historial que ayudó antes en un estado similar.",
      );
    }

    final pulse = EmotionalPulseService.getLatestRecentRecord();

    final selectedType = _selectType(
      emotion: normalizedEmotion,
      intensity: normalizedIntensity,
      pulse: pulse,
      lastIntervention: lastIntervention,
      lastInterventionFailed: lastInterventionFailed,
    );

    final selectedIntervention = _selectSpecificIntervention(
      emotion: normalizedEmotion,
      intensity: normalizedIntensity,
      type: selectedType,
    );

    final validationMessage =
        ValidationService.getMessage(normalizedEmotion, normalizedIntensity);

    return InterventionDecision(
      type: selectedType,
      intervention: selectedIntervention,
      validationMessage: validationMessage,
      fromHistory: false,
      usedFallback: lastInterventionFailed,
      requiresSupportPath: selectedIntervention == "support_path",
      rationale: _buildRationale(
        emotion: normalizedEmotion,
        intensity: normalizedIntensity,
        type: selectedType,
        usedFallback: lastInterventionFailed,
        pulse: pulse,
      ),
    );
  }

  static InterventionType _selectType({
    required String emotion,
    required String intensity,
    required EmotionalPulseRecord? pulse,
    String? lastIntervention,
    required bool lastInterventionFailed,
  }) {
    InterventionType baseType;

    switch (emotion) {
      case "ansiedad":
        baseType = _selectForAnxiety(intensity);
        break;
      case "bloqueado":
        baseType = _selectForBlocked(intensity);
        break;
      case "molesto":
      case "rabia":
      case "enojo":
        baseType = _selectForAnger(intensity);
        break;
      case "triste":
      case "pena":
        baseType = _selectForSadness(intensity);
        break;
      case "sobrepasado":
      case "sobrecarga":
        baseType = _selectForOverwhelmed(intensity);
        break;
      default:
        baseType = InterventionType.conversation;
    }

    baseType = _applyPulseAdjustments(
      baseType: baseType,
      emotion: emotion,
      intensity: intensity,
      pulse: pulse,
    );

    if (!lastInterventionFailed || lastIntervention == null) {
      return baseType;
    }

    return _fallbackType(
      failedIntervention: lastIntervention,
      baseType: baseType,
      emotion: emotion,
      intensity: intensity,
    );
  }

  static InterventionType _selectForAnxiety(String intensity) {
    switch (intensity) {
      case "alto":
        return InterventionType.physicalRegulation;
      case "medio":
        return InterventionType.physicalRegulation;
      case "bajo":
        return InterventionType.conversation;
      default:
        return InterventionType.conversation;
    }
  }

  static InterventionType _selectForBlocked(String intensity) {
    switch (intensity) {
      case "alto":
        return InterventionType.concreteAction;
      case "medio":
        return InterventionType.concreteAction;
      case "bajo":
        return InterventionType.conversation;
      default:
        return InterventionType.conversation;
    }
  }

  static InterventionType _selectForAnger(String intensity) {
    switch (intensity) {
      case "alto":
        return InterventionType.physicalRegulation;
      case "medio":
        return InterventionType.conversation;
      case "bajo":
        return InterventionType.conversation;
      default:
        return InterventionType.conversation;
    }
  }

  static InterventionType _selectForSadness(String intensity) {
    switch (intensity) {
      case "alto":
        return InterventionType.conversation;
      case "medio":
        return InterventionType.conversation;
      case "bajo":
        return InterventionType.conversation;
      default:
        return InterventionType.conversation;
    }
  }

  static InterventionType _selectForOverwhelmed(String intensity) {
    switch (intensity) {
      case "alto":
        return InterventionType.concreteAction;
      case "medio":
        return InterventionType.concreteAction;
      case "bajo":
        return InterventionType.conversation;
      default:
        return InterventionType.conversation;
    }
  }

  static InterventionType _applyPulseAdjustments({
    required InterventionType baseType,
    required String emotion,
    required String intensity,
    required EmotionalPulseRecord? pulse,
  }) {
    if (pulse == null) return baseType;

    final lowEnergy = pulse.energy == "muy baja" || pulse.energy == "baja";
    final highOverload =
        pulse.overload == "bastante" || pulse.overload == "mucho";
    final poorSleep =
        pulse.sleepQuality == "muy malo" || pulse.sleepQuality == "malo";
    final highIrritability =
        pulse.irritability == "bastante" || pulse.irritability == "mucho";
    final lowConnection =
        pulse.connection == "muy solo" || pulse.connection == "algo solo";
    final lowCoping =
        pulse.copingCapacity == "muy baja" || pulse.copingCapacity == "baja";

    if (highIrritability &&
        (emotion == "molesto" || emotion == "rabia" || emotion == "enojo")) {
      return InterventionType.physicalRegulation;
    }

    if (highOverload && (emotion == "sobrepasado" || emotion == "sobrecarga")) {
      return InterventionType.concreteAction;
    }

    if (highOverload && emotion == "bloqueado") {
      return InterventionType.concreteAction;
    }

    if (lowConnection && (emotion == "triste" || emotion == "pena")) {
      return InterventionType.conversation;
    }

    if ((lowEnergy || poorSleep || lowCoping) &&
        baseType == InterventionType.mentalReframe) {
      return InterventionType.conversation;
    }

    if ((lowEnergy || poorSleep) && emotion == "ansiedad") {
      return intensity == "alto"
          ? InterventionType.physicalRegulation
          : InterventionType.conversation;
    }

    if (lowCoping && baseType == InterventionType.concreteAction) {
      return InterventionType.concreteAction;
    }

    return baseType;
  }

  static InterventionType _fallbackType({
    required String failedIntervention,
    required InterventionType baseType,
    required String emotion,
    required String intensity,
  }) {
    final failedType = _mapInterventionToType(failedIntervention);

    switch (failedType) {
      case InterventionType.physicalRegulation:
        if (emotion == "ansiedad") {
          return InterventionType.conversation;
        }
        if (emotion == "rabia" || emotion == "enojo" || emotion == "molesto") {
          return InterventionType.conversation;
        }
        return baseType == InterventionType.physicalRegulation
            ? InterventionType.conversation
            : baseType;

      case InterventionType.conversation:
        if (emotion == "ansiedad" && intensity == "alto") {
          return InterventionType.physicalRegulation;
        }
        if (emotion == "bloqueado" || emotion == "sobrepasado") {
          return InterventionType.concreteAction;
        }
        if (emotion == "rabia" || emotion == "enojo" || emotion == "molesto") {
          return InterventionType.physicalRegulation;
        }
        return baseType;

      case InterventionType.mentalReframe:
        return InterventionType.conversation;

      case InterventionType.concreteAction:
        if (emotion == "ansiedad" || emotion == "rabia" || emotion == "enojo" || emotion == "molesto") {
          return InterventionType.physicalRegulation;
        }
        return InterventionType.conversation;
    }
  }

  static String _selectSpecificIntervention({
    required String emotion,
    required String intensity,
    required InterventionType type,
  }) {
    switch (type) {
      case InterventionType.physicalRegulation:
        if (emotion == "ansiedad") {
          return intensity == "alto" ? "breathing" : "grounding";
        }
        if (emotion == "molesto" || emotion == "rabia" || emotion == "enojo") {
          return intensity == "alto" ? "clench_fists" : "grounding";
        }
        if (emotion == "sobrepasado" || emotion == "sobrecarga") {
          return "grounding";
        }
        return "breathing";

      case InterventionType.concreteAction:
        return "micro_action";

      case InterventionType.mentalReframe:
        return "reframe";

      case InterventionType.conversation:
        return "conversation";
    }
  }

  static InterventionType _mapInterventionToType(String intervention) {
    switch (intervention) {
      case "breathing":
      case "grounding":
      case "clench_fists":
        return InterventionType.physicalRegulation;

      case "micro_action":
        return InterventionType.concreteAction;

      case "reframe":
        return InterventionType.mentalReframe;

      case "support_path":
      case "conversation":
      default:
        return InterventionType.conversation;
    }
  }

  static String _buildRationale({
    required String emotion,
    required String intensity,
    required InterventionType type,
    required bool usedFallback,
    required EmotionalPulseRecord? pulse,
  }) {
    final typeLabel = _typeToReadable(type);

    if (usedFallback) {
      return "Se eligió $typeLabel como vía alternativa porque la intervención anterior no ayudó.";
    }

    if (pulse != null) {
      return "Se eligió $typeLabel considerando emoción '$emotion', intensidad '$intensity' y el pulso emocional reciente.";
    }

    return "Se eligió $typeLabel para emoción '$emotion' con intensidad '$intensity'.";
  }

  static String _typeToReadable(InterventionType type) {
    switch (type) {
      case InterventionType.conversation:
        return "conversación emocional";
      case InterventionType.physicalRegulation:
        return "regulación física";
      case InterventionType.mentalReframe:
        return "reencuadre mental";
      case InterventionType.concreteAction:
        return "acción concreta";
    }
  }
}