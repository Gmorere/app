import '../core/intervention_type.dart';

class InterventionDecision {
  final InterventionType type;
  final String intervention;
  final String validationMessage;
  final bool fromHistory;
  final bool usedFallback;
  final bool requiresSupportPath;
  final String rationale;

  const InterventionDecision({
    required this.type,
    required this.intervention,
    required this.validationMessage,
    required this.fromHistory,
    required this.usedFallback,
    required this.requiresSupportPath,
    required this.rationale,
  });
}