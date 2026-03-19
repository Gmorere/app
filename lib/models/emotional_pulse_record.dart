class EmotionalPulseRecord {
  final DateTime timestamp;
  final String energy;
  final String overload;
  final String sleepQuality;
  final String irritability;
  final String connection;
  final String copingCapacity;

  const EmotionalPulseRecord({
    required this.timestamp,
    required this.energy,
    required this.overload,
    required this.sleepQuality,
    required this.irritability,
    required this.connection,
    required this.copingCapacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'energy': energy,
      'overload': overload,
      'sleepQuality': sleepQuality,
      'irritability': irritability,
      'connection': connection,
      'copingCapacity': copingCapacity,
    };
  }

  factory EmotionalPulseRecord.fromJson(Map<String, dynamic> json) {
    return EmotionalPulseRecord(
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
      energy: (json['energy'] ?? '').toString(),
      overload: (json['overload'] ?? '').toString(),
      sleepQuality: (json['sleepQuality'] ?? '').toString(),
      irritability: (json['irritability'] ?? '').toString(),
      connection: (json['connection'] ?? '').toString(),
      copingCapacity: (json['copingCapacity'] ?? '').toString(),
    );
  }
}