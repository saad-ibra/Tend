import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/coach_action.dart';
import '../models/coach_message.dart';
import '../models/habit.dart';

enum AiProvider {
  auto,
  groq,
  gemini,
}

class GeminiCoachService {
  String? customApiKey; // Gemini API key
  String? groqApiKey; // Groq API key
  AiProvider activeProvider = AiProvider.auto;
  String? lastError;
  String _lastUsedModel = 'On-Device';

  GeminiCoachService({
    this.customApiKey,
    this.groqApiKey,
    this.activeProvider = AiProvider.auto,
  });

  String get activeModelLabel => _lastUsedModel;

  bool get isCloudConfigured {
    final hasGemini = customApiKey?.trim().isNotEmpty ?? false;
    final hasGroq = groqApiKey?.trim().isNotEmpty ?? false;
    return hasGemini || hasGroq;
  }

  void setApiKey(String? key) {
    final trimmed = key?.trim();
    if (trimmed != null && trimmed.startsWith('gsk_')) {
      groqApiKey = trimmed;
    } else {
      customApiKey = trimmed;
    }
  }

  void setGeminiApiKey(String? key) {
    customApiKey = key?.trim();
  }

  void setGroqApiKey(String? key) {
    groqApiKey = key?.trim();
  }

  void setProvider(AiProvider provider) {
    activeProvider = provider;
  }

  void clearError() {
    lastError = null;
  }

  static Map<String, dynamic>? cleanAndParseJson(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    clean = clean.trim();

    final firstBrace = clean.indexOf('{');
    final lastBrace = clean.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace >= firstBrace) {
      clean = clean.substring(firstBrace, lastBrace + 1);
    }

    try {
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      // Attempt sanitization for common LLM syntax issues (e.g., trailing commas)
      try {
        final sanitized = clean.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
        return jsonDecode(sanitized) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('Error parsing JSON from LLM: $e\nRaw was: $raw');
        return null;
      }
    }
  }

  String _formatHttpError(String provider, int statusCode, String responseBody) {
    if (statusCode == 401) {
      return '$provider API key is invalid or expired (HTTP 401). Please check your key in Profile.';
    } else if (statusCode == 429) {
      return '$provider API rate limit reached (HTTP 429). Temporarily using on-device mode.';
    } else if (statusCode == 404) {
      return '$provider model is unavailable (HTTP 404). Tried fallbacks.';
    } else if (statusCode >= 500) {
      return '$provider cloud service temporary outage (HTTP $statusCode). Switched to on-device mode.';
    } else {
      final snippet = _truncate(responseBody, 70);
      return '$provider API error (HTTP $statusCode): ${snippet.isNotEmpty ? snippet : 'No error details'}';
    }
  }

  String _formatExceptionError(String provider, dynamic e) {
    final str = e.toString();
    if (str.contains('TimeoutException') || str.contains('Timeout') || str.contains('timed out')) {
      return 'Network timeout connecting to $provider (15s limit). Check internet connection.';
    } else if (str.contains('SocketException') || str.contains('host lookup') || str.contains('Failed host lookup')) {
      return 'Network error: Unable to reach $provider. Check internet connection.';
    } else {
      return 'Could not connect to $provider: ${_truncate(str, 80)}';
    }
  }

  static String _truncate(String text, int maxLen) {
    final clean = text.replaceAll('\n', ' ').trim();
    if (clean.length <= maxLen) return clean;
    return '${clean.substring(0, maxLen)}...';
  }

  Future<CoachMessage> generateAdvice({
    required String userPrompt,
    required Map<String, dynamic> contextData,
  }) async {
    lastError = null;

    final trimmedGroq = groqApiKey?.trim() ?? '';
    final trimmedGemini = customApiKey?.trim() ?? '';

    // Check specific configuration warnings when provider is explicitly selected
    if (activeProvider == AiProvider.groq && trimmedGroq.isEmpty) {
      if (trimmedGemini.isNotEmpty) {
        lastError = 'Groq Cloud selected, but no Groq key set. Trying Gemini fallback.';
      } else {
        lastError = 'Groq Cloud selected as provider, but no API key is set in Profile.';
      }
    } else if (activeProvider == AiProvider.gemini && trimmedGemini.isEmpty) {
      if (trimmedGroq.isNotEmpty) {
        lastError = 'Google Gemini selected, but no Gemini key set. Trying Groq fallback.';
      } else {
        lastError = 'Google Gemini selected as provider, but no API key is set in Profile.';
      }
    } else if (trimmedGroq.isEmpty && trimmedGemini.isEmpty) {
      lastError = 'No AI API keys configured. Running on-device contextual intelligence.';
    }

    final bool preferGroq = activeProvider == AiProvider.groq ||
        (activeProvider == AiProvider.auto && trimmedGroq.isNotEmpty);

    if (preferGroq && trimmedGroq.isNotEmpty) {
      final groqResponse = await _callGroqApi(
        apiKey: trimmedGroq,
        userPrompt: userPrompt,
        contextData: contextData,
      );
      if (groqResponse != null) {
        lastError = null;
        return groqResponse;
      }
    }

    if (trimmedGemini.isNotEmpty) {
      final geminiResponse = await _callGeminiApi(
        apiKey: trimmedGemini,
        userPrompt: userPrompt,
        contextData: contextData,
      );
      if (geminiResponse != null) {
        lastError = null;
        return geminiResponse;
      }
    }

    if (!preferGroq && trimmedGroq.isNotEmpty) {
      final groqResponse = await _callGroqApi(
        apiKey: trimmedGroq,
        userPrompt: userPrompt,
        contextData: contextData,
      );
      if (groqResponse != null) {
        lastError = null;
        return groqResponse;
      }
    }

    // Fallback: Context-Aware Deterministic Analysis Engine
    _lastUsedModel = 'On-Device';
    return _generateDeterministicAnalysis(
      userPrompt: userPrompt,
      contextData: contextData,
    );
  }

  Future<CoachMessage?> _callGroqApi({
    required String apiKey,
    required String userPrompt,
    required Map<String, dynamic> contextData,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final contextJson = jsonEncode(contextData);

    const systemPrompt = '''
You are Tend's AI Habit Coach. Tend is a mindful habit application rooted in Japanese wabi-sabi principles and Scandinavian simplicity. It prioritizes deliberate attention, gentle consistency, and sustainable rhythms over aggressive metric exploitation.

Respond ONLY in valid JSON matching this schema:
{
  "message": "Conversational, empathetic, grounded answer providing clear observations and actionable guidance (2-4 paragraphs).",
  "weekly_summary": {
    "completion_rate": "e.g. 75%",
    "highlight": "Key consistency achievement or strength observed",
    "growth_area": "A gentle improvement focus or friction point"
  },
  "suggested_action": {
    "type": "create_habit | modify_habit | none",
    "target_habit_id": "habit_id if modify_habit, otherwise null",
    "title": "Title of the new or modified rhythm",
    "description": "Short intention or reminder (under 60 chars)",
    "frequency_type": "daily | weekdays",
    "target_weekdays": [1, 2, 3, 4, 5, 6, 7],
    "color_hex": "#744127",
    "reason": "Clear explanation of why this action is suggested based on their data"
  }
}
''';

    final models = [
      'openai/gpt-oss-120b',
      'openai/gpt-oss-20b',
      'qwen/qwen3.8-27b',
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
    ];

    for (final model in models) {
      try {
        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {
                    'role': 'user',
                    'content': 'User Question/Prompt: "$userPrompt"\n\nUser Context:\n$contextJson'
                  }
                ],
                'response_format': {'type': 'json_object'},
                'temperature': 0.3,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final content = data['choices']?[0]?['message']?['content'] as String?;
          if (content != null) {
            final parsed = cleanAndParseJson(content);
            if (parsed != null) {
              _lastUsedModel = 'Groq ($model)';
              return _buildMessageFromJson(parsed);
            } else {
              lastError = 'Groq Cloud returned a response, but JSON format was unparseable. Switched to fallback.';
            }
          } else {
            lastError = 'Groq Cloud response contained no message text.';
          }
        } else {
          lastError = _formatHttpError('Groq Cloud', response.statusCode, response.body);
          debugPrint(lastError);
        }
      } catch (e) {
        lastError = _formatExceptionError('Groq Cloud', e);
        debugPrint(lastError);
      }
    }
    return null;
  }

  Future<CoachMessage?> _callGeminiApi({
    required String apiKey,
    required String userPrompt,
    required Map<String, dynamic> contextData,
  }) async {
    final contextJson = jsonEncode(contextData);

    final prompt = '''
You are Tend's AI Habit Coach. Tend is a mindful habit application rooted in Japanese wabi-sabi principles and Scandinavian simplicity. It prioritizes deliberate attention, gentle consistency, and sustainable rhythms over aggressive metric exploitation.

User Question/Prompt:
"$userPrompt"

User's Actual Habit & Check-in Data:
$contextJson

Respond ONLY in valid JSON matching this schema:
{
  "message": "Conversational, empathetic, grounded answer providing clear observations and actionable guidance (2-4 paragraphs).",
  "weekly_summary": {
    "completion_rate": "e.g. 75%",
    "highlight": "Key consistency achievement or strength observed",
    "growth_area": "A gentle improvement focus or friction point"
  },
  "suggested_action": {
    "type": "create_habit | modify_habit | none",
    "target_habit_id": "habit_id if modify_habit, otherwise null",
    "title": "Title of the new or modified rhythm",
    "description": "Short intention or reminder (under 60 chars)",
    "frequency_type": "daily | weekdays",
    "target_weekdays": [1, 2, 3, 4, 5, 6, 7],
    "color_hex": "#744127",
    "reason": "Clear explanation of why this action is suggested based on their data"
  }
}
''';

    // Model fallback sequence: 2.5 Flash -> 2.0 Flash -> 1.5 Flash -> 1.5 Pro
    final models = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Uri.encodeComponent(apiKey)}',
        );

        final response = await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt}
                    ]
                  }
                ],
                'generationConfig': {
                  'responseMimeType': 'application/json',
                  'temperature': 0.3,
                }
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          String? candidateText;
          final parts = data['candidates']?[0]?['content']?['parts'] as List<dynamic>?;
          if (parts != null) {
            final buffer = StringBuffer();
            for (final part in parts) {
              if (part is Map<String, dynamic> && part['text'] is String) {
                buffer.write(part['text']);
              }
            }
            if (buffer.isNotEmpty) {
              candidateText = buffer.toString();
            }
          }
          if (candidateText != null) {
            final parsed = cleanAndParseJson(candidateText);
            if (parsed != null) {
              _lastUsedModel = 'Gemini ($model)';
              return _buildMessageFromJson(parsed);
            } else {
              lastError = 'Google Gemini returned a response, but JSON format was unparseable. Switched to fallback.';
            }
          } else {
            lastError = 'Google Gemini response contained no text content.';
          }
        } else {
          lastError = _formatHttpError('Google Gemini', response.statusCode, response.body);
          debugPrint(lastError);
        }
      } catch (e) {
        lastError = _formatExceptionError('Google Gemini', e);
        debugPrint(lastError);
      }
    }

    return null;
  }

  Future<String?> testGroqApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return 'Groq API key cannot be empty.';
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $trimmed',
            },
            body: jsonEncode({
              'model': 'openai/gpt-oss-20b',
              'messages': [
                {'role': 'user', 'content': 'hi'}
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return null; // Success!
      } else {
        return _formatHttpError('Groq Cloud', response.statusCode, response.body);
      }
    } catch (e) {
      return _formatExceptionError('Groq Cloud', e);
    }
  }

  Future<String?> testGeminiApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return 'Gemini API key cannot be empty.';
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${Uri.encodeComponent(trimmed)}',
      );
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': trimmed,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'hi'}
                  ]
                }
              ],
              'generationConfig': {'maxOutputTokens': 5},
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return null; // Success!
      } else {
        return _formatHttpError('Google Gemini', response.statusCode, response.body);
      }
    } catch (e) {
      return _formatExceptionError('Google Gemini', e);
    }
  }

  CoachMessage _buildMessageFromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final messageText =
        json['message'] as String? ?? 'Here are my observations based on your rhythm data.';
    final weeklySummary = json['weekly_summary'] as Map<String, dynamic>?;

    CoachAction? action;
    final actionJson = json['suggested_action'] as Map<String, dynamic>?;
    if (actionJson != null) {
      final typeStr = actionJson['type'] as String? ?? 'none';
      if (typeStr == 'create_habit' ||
          typeStr == 'modify_habit' ||
          typeStr == 'createHabit' ||
          typeStr == 'modifyHabit') {
        action = CoachAction.fromJson(actionJson);
      }
    }

    return CoachMessage(
      id: 'coach_${now.millisecondsSinceEpoch}',
      sender: CoachSender.coach,
      text: messageText,
      timestamp: now,
      action: action,
      metricsSummary: weeklySummary,
    );
  }

  CoachMessage _generateDeterministicAnalysis({
    required String userPrompt,
    required Map<String, dynamic> contextData,
  }) {
    final now = DateTime.now();
    final activeHabits = (contextData['active_habits'] as List<dynamic>?) ?? [];
    final weeklyAdherence = contextData['weekly_completion_percentage'] as num? ?? 0;
    final currentStreak = contextData['top_streak'] as num? ?? 0;
    final recentMood = contextData['today_mood'] as String? ?? 'Steady';
    final recentEnergy = contextData['today_energy'] as String? ?? 'Gentle';

    final lower = userPrompt.toLowerCase();
    String message = '';
    Map<String, dynamic>? weeklySummary;
    CoachAction? suggestedAction;

    if (lower.contains('week') || lower.contains('summary') || lower.contains('progress')) {
      final habitCount = activeHabits.length;
      message =
          'Looking across your rhythm ledger for the past 7 days, your overall completion rate is $weeklyAdherence% across $habitCount active rhythms.\n\n'
          'Your longest continuous rhythm streak currently stands at $currentStreak days. Today your inner climate was checked in as $recentMood with $recentEnergy energy.\n\n'
          'Remember: tending to a habit is not about perfection, but returning to center when life creates turbulence.';

      weeklySummary = {
        'completion_rate': '$weeklyAdherence%',
        'highlight': currentStreak > 0
            ? '$currentStreak-day streak active'
            : 'Steady rhythm foundation',
        'growth_area': weeklyAdherence < 70 ? 'Midweek consistency' : 'Sustaining evening rest',
      };

      if (habitCount < 3) {
        suggestedAction = CoachAction(
          id: 'sug_${now.millisecondsSinceEpoch}',
          type: CoachActionType.createHabit,
          title: 'Evening stillness',
          description: '5 minutes of quiet breathwork before sleep',
          frequencyType: HabitFrequencyType.daily,
          targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
          colorHex: '#55614E',
          reason:
              'Adding an evening unwinding anchor complements your morning rhythms and nurtures restful sleep.',
        );
      }
    } else if (lower.contains('new') ||
        lower.contains('suggest') ||
        lower.contains('create') ||
        lower.contains('routine')) {
      message =
          'Based on your current patterns and $recentEnergy energy level, I recommend anchoring a light, restorative practice rather than adding heavy tasks.\n\n'
          'A sustainable rhythm should feel small enough that missing it feels harder than doing it.';

      suggestedAction = CoachAction(
        id: 'sug_${now.millisecondsSinceEpoch}',
        type: CoachActionType.createHabit,
        title: 'Midday breath',
        description: '3 conscious deep breaths between tasks',
        frequencyType: HabitFrequencyType.weekdays,
        targetWeekdays: const [1, 2, 3, 4, 5],
        colorHex: '#744127',
        reason:
            'A short workday anchor helps release accumulated screen tension and resets cognitive focus.',
      );
    } else if (lower.contains('struggle') ||
        lower.contains('miss') ||
        lower.contains('fail') ||
        lower.contains('hard') ||
        lower.contains('why')) {
      message =
          'When a rhythm falls off, it is rarely a failure of will — it is almost always friction in the transition or an oversized expectation.\n\n'
          'Check your daily context: on days when your energy is $recentEnergy, high-friction habits naturally feel overwhelming. Shrink the habit scope to a 2-minute version on low-energy days.';

      if (activeHabits.isNotEmpty) {
        final first = activeHabits.first as Map<String, dynamic>;
        suggestedAction = CoachAction(
          id: 'sug_${now.millisecondsSinceEpoch}',
          type: CoachActionType.modifyHabit,
          targetHabitId: first['id'] as String?,
          title: first['title'] as String? ?? 'Rhythm',
          description: 'Scaled to 2 mindful minutes',
          frequencyType: HabitFrequencyType.daily,
          targetWeekdays: const [1, 2, 3, 4, 5, 6, 7],
          colorHex: first['color_hex'] as String? ?? '#744127',
          reason:
              'Reducing the scope prevents broken streaks and preserves mental momentum on low-energy days.',
        );
      }
    } else {
      message =
          'I have reviewed your active rhythms and consistency ledger. You currently maintain ${activeHabits.length} daily rhythms with a $weeklyAdherence% completion rate.\n\n'
          'What part of your daily flow would you like to explore together? We can review weekly consistency, adjust an existing habit, or explore adding a focused new rhythm.';
    }

    return CoachMessage(
      id: 'coach_${now.millisecondsSinceEpoch}',
      sender: CoachSender.coach,
      text: message,
      timestamp: now,
      action: suggestedAction,
      metricsSummary: weeklySummary,
    );
  }
}
