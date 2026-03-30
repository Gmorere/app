import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/backend_config.dart';
import '../core/emotion_normalizer.dart';
import '../core/intervention_type.dart';
import 'intervention_selector.dart';

class AiResponse {
  final int sessionId;
  final String validation;
  final String nextMessage;
  final String recommendedCategory;
  final String recommendedTool;
  final String riskLevel;
  final bool longitudinalConcern;
  final bool shouldOfferHumanSupport;
  final String? dominantState;

  const AiResponse({
    required this.sessionId,
    required this.validation,
    required this.nextMessage,
    required this.recommendedCategory,
    required this.recommendedTool,
    required this.riskLevel,
    this.longitudinalConcern = false,
    required this.shouldOfferHumanSupport,
    this.dominantState,
  });
}

class ExpressiveWritingOutput {
  final String reflection;
  final String nextStep;
  final String riskLevel;
  final bool shouldOfferHumanSupport;

  const ExpressiveWritingOutput({
    required this.reflection,
    required this.nextStep,
    required this.riskLevel,
    required this.shouldOfferHumanSupport,
  });
}

class SessionFeedbackResponse {
  final bool ok;
  final int sessionId;
  final bool helped;

  SessionFeedbackResponse({
    required this.ok,
    required this.sessionId,
    required this.helped,
  });

  factory SessionFeedbackResponse.fromJson(Map<String, dynamic> json) {
    return SessionFeedbackResponse(
      ok: json['ok'] == true,
      sessionId: (json['session_id'] as num?)?.toInt() ?? 0,
      helped: json['helped'] == true,
    );
  }
}

class SessionItem {
  final int id;
  final String emotion;
  final String intensity;
  final String recommendedCategory;
  final String recommendedTool;
  final String riskLevel;
  final bool shouldOfferHumanSupport;
  final String? dominantState;
  final bool? helped;
  final DateTime? createdAt;

  SessionItem({
    required this.id,
    required this.emotion,
    required this.intensity,
    required this.recommendedCategory,
    required this.recommendedTool,
    required this.riskLevel,
    required this.shouldOfferHumanSupport,
    required this.dominantState,
    required this.helped,
    required this.createdAt,
  });

  factory SessionItem.fromJson(Map<String, dynamic> json) {
    return SessionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      emotion: (json['emotion'] ?? '').toString(),
      intensity: (json['intensity'] ?? '').toString(),
      recommendedCategory: (json['recommended_category'] ?? '').toString(),
      recommendedTool: (json['recommended_tool'] ?? '').toString(),
      riskLevel: (json['risk_level'] ?? '').toString(),
      shouldOfferHumanSupport: json['should_offer_human_support'] == true,
      dominantState: _normalizeSessionDominantState(
        (json['dominant_state'] ?? '').toString(),
      ),
      helped: json['helped'] is bool ? json['helped'] as bool : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  static String? _normalizeSessionDominantState(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    const allowedStates = {
      'hiperactivado',
      'bloqueado',
      'rumiativo',
      'agotado',
      'desconectado',
      'desbordado',
    };

    return allowedStates.contains(normalized) ? normalized : null;
  }
}

class AiService {
  static const Duration _timeout = Duration(seconds: 40);

  static const Set<String> _validCategories = {
    'conversation',
    'physical_regulation',
    'mental_reframe',
    'concrete_action',
    'support_path',
  };

  static const Set<String> _validTools = {
    'conversation',
    'breathing',
    'grounding',
    'clench_fists',
    'movement',
    'sensory_pause',
    'reframe',
    'expressive_writing',
    'micro_action',
    'support_path',
  };

  static const Set<String> _validRiskLevels = {
    'normal',
    'vulnerability_high',
    'crisis',
  };

  static Future<AiResponse> getConversationResponse({
    required String token,
    required String emotion,
    required String intensity,
    required String userMessage,
    String briefContext = '',
  }) async {
    final immediateSafetyResponse = _buildImmediateSafetyResponse(
      emotion: emotion,
      intensity: intensity,
      briefContext: briefContext,
      userMessage: userMessage,
    );
    if (immediateSafetyResponse != null) {
      return immediateSafetyResponse;
    }

    try {
      return await _sendConversationRequest(
        token: token,
        emotion: emotion,
        intensity: intensity,
        userMessage: userMessage,
        briefContext: briefContext,
      );
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 2));

      try {
        return await _sendConversationRequest(
          token: token,
          emotion: emotion,
          intensity: intensity,
          userMessage: userMessage,
          briefContext: briefContext,
        );
      } on TimeoutException {
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'Estoy tardando mas de lo normal en responder, asi que voy a proponerte una ayuda breve para este momento.',
        );
      } on http.ClientException {
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'No pude conectarme bien ahora, pero igual puedo ofrecerte una ayuda breve para este momento.',
        );
      } catch (e) {
        if (_isAuthException(e)) rethrow;
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'Ahora mismo me esta costando responderte, asi que voy a ofrecerte una ayuda breve y clara para seguir.',
        );
      }
    } on http.ClientException {
      await Future.delayed(const Duration(seconds: 2));

      try {
        return await _sendConversationRequest(
          token: token,
          emotion: emotion,
          intensity: intensity,
          userMessage: userMessage,
          briefContext: briefContext,
        );
      } on TimeoutException {
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'Estoy tardando mas de lo normal en responder, asi que voy a proponerte una ayuda breve para este momento.',
        );
      } on http.ClientException {
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'No pude conectarme bien ahora, pero igual puedo ofrecerte una ayuda breve para este momento.',
        );
      } catch (e) {
        if (_isAuthException(e)) rethrow;
        return _buildLocalFallbackResponse(
          emotion: emotion,
          intensity: intensity,
          briefContext: briefContext,
          userMessage: userMessage,
          calmMessage:
              'Ahora mismo me esta costando responderte, asi que voy a ofrecerte una ayuda breve y clara para seguir.',
        );
      }
    } on FormatException {
      return _buildLocalFallbackResponse(
        emotion: emotion,
        intensity: intensity,
        briefContext: briefContext,
        userMessage: userMessage,
        calmMessage:
            'No pude ordenar bien la respuesta esta vez, pero igual voy a proponerte una ayuda breve para este momento.',
      );
    } catch (e) {
      if (_isAuthException(e)) rethrow;
      return _buildLocalFallbackResponse(
        emotion: emotion,
        intensity: intensity,
        briefContext: briefContext,
        userMessage: userMessage,
        calmMessage:
            'Ahora mismo me esta costando responderte, pero igual puedo orientarte con una ayuda breve para seguir.',
      );
    }
  }

  static Future<ExpressiveWritingOutput> generateExpressiveWritingOutput({
    required String token,
    required String writtenText,
    String? emotion,
    String? intensity,
    String briefContext = '',
  }) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/armonia/expressive-writing');

    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: jsonEncode({
            'written_text': writtenText,
            'emotion': emotion,
            'intensity': intensity,
            'brief_context': briefContext.trim(),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw Exception('Tu sesion expiro. Ingresa nuevamente.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No pude generar una salida breve para este texto en este momento.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'La salida de escritura no llego en un formato valido.',
      );
    }

    final reflection = (decoded['reflection'] ?? '').toString().trim();
    final nextStep = (decoded['next_step'] ?? '').toString().trim();
    final riskLevel = (decoded['risk_level'] ?? '').toString().trim().toLowerCase();
    final shouldOfferHumanSupport = decoded['should_offer_human_support'] == true;

    if (reflection.isEmpty || nextStep.isEmpty) {
      throw Exception('La salida breve llego incompleta.');
    }

    if (!_validRiskLevels.contains(riskLevel)) {
      throw Exception('La salida breve llego con un riesgo invalido.');
    }

    return ExpressiveWritingOutput(
      reflection: reflection,
      nextStep: nextStep,
      riskLevel: riskLevel,
      shouldOfferHumanSupport: shouldOfferHumanSupport,
    );
  }

  static AiResponse? _buildImmediateSafetyResponse({
    required String emotion,
    required String intensity,
    required String briefContext,
    required String userMessage,
  }) {
    final decision = InterventionSelector.select(
      emotion: emotion,
      intensity: intensity,
      briefContext: briefContext,
      userMessage: userMessage,
    );

    if (!decision.requiresSupportPath &&
        decision.intervention != 'support_path') {
      return null;
    }

    return AiResponse(
      sessionId: 0,
      validation: decision.validationMessage,
      nextMessage:
          'Quiero priorizar apoyo humano ahora mismo. No voy a seguir por chat con esto.',
      recommendedCategory: 'support_path',
      recommendedTool: 'support_path',
      riskLevel: 'crisis',
      longitudinalConcern: false,
      shouldOfferHumanSupport: true,
      dominantState: decision.dominantState,
    );
  }

  static Future<SessionFeedbackResponse> sendFeedback({
    required String token,
    required int sessionId,
    required bool helped,
    bool? reliefFeedback,
    bool? utilityFeedback,
  }) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/sessions/$sessionId/feedback');

    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: jsonEncode({
            'helped': helped,
            'relief_feedback': reliefFeedback,
            'utility_feedback': utilityFeedback,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw Exception('Tu sesion expiro. Ingresa nuevamente.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No pude guardar como te fue esta vez. Intentemoslo nuevamente.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'No pude procesar bien la respuesta del servidor.',
      );
    }

    return SessionFeedbackResponse.fromJson(decoded);
  }

  static Future<List<SessionItem>> getRecentSessions({
    required String token,
  }) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/sessions/recent');

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw Exception('Tu sesion expiro. Ingresa nuevamente.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'No pude cargar tu historial en este momento.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('La respuesta del historial no llego en un formato valido.');
    }

    final items = decoded['items'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(SessionItem.fromJson)
        .toList();
  }

  static Future<AiResponse> _sendConversationRequest({
    required String token,
    required String emotion,
    required String intensity,
    required String userMessage,
    required String briefContext,
  }) async {
    final uri = Uri.parse('${BackendConfig.baseUrl}/armonia/respond');

    final response = await http
        .post(
          uri,
          headers: _buildHeaders(token),
          body: jsonEncode({
            'user_message': userMessage,
            'brief_context': briefContext.trim(),
            'emotion': EmotionNormalizer.toBackendEmotion(emotion),
            'intensity': EmotionNormalizer.normalizeIntensity(intensity),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 401) {
      throw Exception('Tu sesion expiro. Ingresa nuevamente.');
    }

    if (response.statusCode != 200) {
      return _buildLocalFallbackResponse(
        emotion: emotion,
        intensity: intensity,
        briefContext: briefContext,
        userMessage: userMessage,
        calmMessage:
            'Ahora mismo no pude responder como esperaba, pero igual voy a proponerte una ayuda breve para este momento.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      return _buildLocalFallbackResponse(
        emotion: emotion,
        intensity: intensity,
        briefContext: briefContext,
        userMessage: userMessage,
        calmMessage:
            'No pude ordenar bien la respuesta esta vez, pero igual voy a proponerte una ayuda breve para seguir.',
      );
    }

    return _parseConversationResponse(
      decoded,
      emotion: emotion,
      intensity: intensity,
    );
  }

  static AiResponse _parseConversationResponse(
    Map<String, dynamic> json, {
    required String emotion,
    required String intensity,
  }) {
    final sessionId = (json['session_id'] as num?)?.toInt() ?? 0;
    final validation = (json['validation'] ?? '').toString().trim();
    final nextMessage = (json['next_message'] ?? '').toString().trim();

    final rawCategory = (json['recommended_category'] ?? '').toString().trim();
    final rawTool = (json['recommended_tool'] ?? '').toString().trim();

    final normalizedCategory = _normalizeCategoryValue(rawCategory);
    final normalizedTool = _normalizeToolValue(rawTool);
    final rawRiskLevel = (json['risk_level'] ?? '').toString().trim().toLowerCase();
    final riskLevel = _validRiskLevels.contains(rawRiskLevel)
        ? rawRiskLevel
        : 'normal';
    final longitudinalConcern = json['longitudinal_concern'] == true;
    final shouldOfferHumanSupport = json['should_offer_human_support'] == true;
    final dominantState = _normalizeDominantState(
      (json['dominant_state'] ?? '').toString(),
    );

    var effectiveCategory = normalizedCategory.isNotEmpty
        ? normalizedCategory
        : _mapLegacyToolToCategory(normalizedTool);

    if (shouldOfferHumanSupport && riskLevel == 'crisis') {
      effectiveCategory = 'support_path';
    }

    if (validation.isEmpty ||
        nextMessage.isEmpty ||
        effectiveCategory.isEmpty) {
      return _buildLocalFallbackResponse(
        emotion: emotion,
        intensity: intensity,
        briefContext: '',
        userMessage: '',
        calmMessage:
            'No pude ordenar completamente esta respuesta, asi que voy a ofrecerte una ayuda breve y clara para este momento.',
      );
    }

    final effectiveTool = normalizedTool.isNotEmpty
        ? normalizedTool
        : _resolveToolFromCategory(
            category: effectiveCategory,
            emotion: emotion,
            intensity: intensity,
          );

    return AiResponse(
      sessionId: sessionId,
      validation: validation,
      nextMessage: nextMessage,
      recommendedCategory: effectiveCategory,
      recommendedTool: effectiveTool,
      riskLevel: riskLevel,
      longitudinalConcern: longitudinalConcern,
      shouldOfferHumanSupport: shouldOfferHumanSupport,
      dominantState: dominantState,
    );
  }

  static AiResponse _buildLocalFallbackResponse({
    required String emotion,
    required String intensity,
    required String calmMessage,
    String briefContext = '',
    String userMessage = '',
  }) {
    final decision = InterventionSelector.select(
      emotion: emotion,
      intensity: intensity,
      briefContext: briefContext,
      userMessage: userMessage,
    );
    final category = decision.requiresSupportPath || decision.intervention == 'support_path'
        ? 'support_path'
        : _categoryFromDecisionType(decision.type);

    return AiResponse(
      sessionId: 0,
      validation: decision.validationMessage,
      nextMessage: decision.requiresSupportPath
          ? 'Quiero priorizar apoyo humano ahora mismo. No voy a seguir por chat con esto.'
          : calmMessage,
      recommendedCategory: category,
      recommendedTool: decision.intervention,
      riskLevel: decision.requiresSupportPath
          ? 'crisis'
          : decision.shouldOfferHumanSupport
              ? 'vulnerability_high'
              : 'normal',
      longitudinalConcern: decision.longitudinalConcern,
      shouldOfferHumanSupport:
          decision.requiresSupportPath || decision.shouldOfferHumanSupport,
      dominantState: decision.dominantState,
    );
  }

  static String? _normalizeDominantState(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    const allowedStates = {
      'hiperactivado',
      'bloqueado',
      'rumiativo',
      'agotado',
      'desconectado',
      'desbordado',
    };

    return allowedStates.contains(normalized) ? normalized : null;
  }

  static String _normalizeCategoryValue(String value) {
    final normalized = value.toLowerCase().trim();
    return _validCategories.contains(normalized) ? normalized : '';
  }

  static String _normalizeToolValue(String value) {
    final normalized = value.toLowerCase().trim();
    return _validTools.contains(normalized) ? normalized : '';
  }

  static String _mapLegacyToolToCategory(String tool) {
    switch (tool) {
      case 'breathing':
      case 'grounding':
      case 'clench_fists':
      case 'movement':
      case 'sensory_pause':
        return 'physical_regulation';
      case 'reframe':
      case 'expressive_writing':
        return 'mental_reframe';
      case 'micro_action':
        return 'concrete_action';
      case 'support_path':
        return 'support_path';
      case 'conversation':
        return 'conversation';
      default:
        return '';
    }
  }

  static String _resolveToolFromCategory({
    required String category,
    required String emotion,
    required String intensity,
  }) {
    final selectorDecision = InterventionSelector.select(
      emotion: emotion,
      intensity: intensity,
    );
    final selectorCategory = _categoryFromDecisionType(selectorDecision.type);

    if (selectorCategory == category) {
      return selectorDecision.intervention;
    }

    switch (category) {
      case 'physical_regulation':
        return 'grounding';
      case 'mental_reframe':
        return 'reframe';
      case 'concrete_action':
        return 'micro_action';
      case 'support_path':
        return 'support_path';
      case 'conversation':
      default:
        return 'conversation';
    }
  }

  static String _categoryFromDecisionType(InterventionType type) {
    switch (type) {
      case InterventionType.physicalRegulation:
        return 'physical_regulation';
      case InterventionType.mentalReframe:
        return 'mental_reframe';
      case InterventionType.concreteAction:
        return 'concrete_action';
      case InterventionType.conversation:
        return 'conversation';
    }
  }

  static bool _isAuthException(Object error) {
    return error is Exception &&
        error.toString().contains('Tu sesion expiro. Ingresa nuevamente.');
  }

  static Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
