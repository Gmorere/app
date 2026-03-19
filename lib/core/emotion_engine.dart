import '../models/intervention_decision.dart';
import '../services/intervention_selector.dart';

class EmotionEngine {
  static InterventionDecision decide({
    required String emotion,
    required String intensity,
    bool crisisDetected = false,
    String? lastIntervention,
    bool lastInterventionFailed = false,
  }) {
    return InterventionSelector.select(
      emotion: emotion,
      intensity: intensity,
      crisisDetected: crisisDetected,
      lastIntervention: lastIntervention,
      lastInterventionFailed: lastInterventionFailed,
    );
  }
}