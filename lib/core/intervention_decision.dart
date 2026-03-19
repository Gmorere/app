import 'intervention_type.dart';

class InterventionDecision {

  final InterventionType primary;
  final InterventionType secondary;

  const InterventionDecision({
    required this.primary,
    required this.secondary,
  });

}