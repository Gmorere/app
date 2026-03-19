import 'dart:convert';
import 'package:http/http.dart' as http;

class AiResponse {
  final String validation;
  final String nextMessage;
  final String recommendedTool;
  final String riskLevel;
  final bool shouldOfferHumanSupport;

  AiResponse({
    required this.validation,
    required this.nextMessage,
    required this.recommendedTool,
    required this.riskLevel,
    required this.shouldOfferHumanSupport,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      validation: (json['validation'] ?? '').toString(),
      nextMessage: (json['next_message'] ?? '').toString(),
      recommendedTool: (json['recommended_tool'] ?? '').toString(),
      riskLevel: (json['risk_level'] ?? '').toString(),
      shouldOfferHumanSupport: json['should_offer_human_support'] == true,
    );
  }
}

class AiService {
  static const String _baseUrl = 'https://armonia-yvx6.onrender.com';

  static Future<AiResponse> getConversationResponse({
    required String emotion,
    required String intensity,
    required String briefContext,
    required String userMessage,
    String recentHistorySummary = "",
  }) async {
    final uri = Uri.parse('$_baseUrl/armonia/respond');

    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'emotion': emotion,
            'intensity': intensity,
            'brief_context': briefContext,
            'user_message': userMessage,
            'recent_history_summary': recentHistorySummary,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception(
        'Error IA (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del backend IA');
    }

    return AiResponse.fromJson(decoded);
  }
}