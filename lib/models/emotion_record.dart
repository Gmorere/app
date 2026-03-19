class EmotionRecord {
  final String emotion;
  final String intensity;
  final String intervention;
  final String feedback;
  final DateTime timestamp;

  const EmotionRecord({
    required this.emotion,
    required this.intensity,
    required this.intervention,
    required this.feedback,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'intensity': intensity,
      'intervention': intervention,
      'feedback': feedback,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      emotion: (json['emotion'] ?? '').toString(),
      intensity: (json['intensity'] ?? '').toString(),
      intervention: (json['intervention'] ?? '').toString(),
      feedback: (json['feedback'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}