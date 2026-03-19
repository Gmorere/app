import 'dart:async';
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
  static const Duration _timeout = Duration(seconds: 40);

  static Future<AiResponse> getConversationResponse({
    required String emotion,
    required String intensity,
    required String briefContext,
    required String userMessage,
    String recentHistorySummary = "",
  }) async {
    try {
      return await _sendRequest(
        emotion: emotion,
        intensity: intensity,
        briefContext: briefContext,
        userMessage: userMessage,
        recentHistorySummary: recentHistorySummary,
      );
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 2));

      try {
        return await _sendRequest(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          recentHistorySummary: recentHistorySummary,
        );
      } on TimeoutException {
        throw Exception(
          'Estoy tardando más de lo normal en responder. Respira un momento y vuelve a intentarlo.',
        );
      } on http.ClientException {
        throw Exception(
          'No pude conectarme bien ahora. Revisemos la conexión e intentemos otra vez.',
        );
      } catch (_) {
        throw Exception(
          'Ahora mismo me está costando responderte. Probemos otra vez con calma.',
        );
      }
    } on http.ClientException {
      await Future.delayed(const Duration(seconds: 2));

      try {
        return await _sendRequest(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          recentHistorySummary: recentHistorySummary,
        );
      } on TimeoutException {
        throw Exception(
          'Estoy tardando más de lo normal en responder. Respira un momento y vuelve a intentarlo.',
        );
      } on http.ClientException {
        throw Exception(
          'No pude conectarme bien ahora. Revisemos la conexión e intentemos otra vez.',
        );
      } catch (_) {
        throw Exception(
          'Ahora mismo me está costando responderte. Probemos otra vez con calma.',
        );
      }
    } on FormatException {
      throw Exception(
        'Tuve un problema para responderte bien. Intentémoslo de nuevo en un momento.',
      );
    } catch (_) {
      throw Exception(
        'Ahora mismo me está costando responderte. Probemos otra vez con calma.',
      );
    }
  }

  static Future<AiResponse> _sendRequest({
    required String emotion,
    required String intensity,
    required String briefContext,
    required String userMessage,
    required String recentHistorySummary,
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
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Ahora mismo no pude responder como esperaba. Probemos nuevamente en un momento.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'No pude ordenar bien la respuesta. Intentémoslo otra vez en un momento.',
      );
    }

    return AiResponse.fromJson(decoded);
  }
}