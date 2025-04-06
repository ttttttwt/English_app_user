import 'package:do_an_test/common/constant/const_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:do_an_test/common/constant/const_value.dart';

class ConversationService {
  final GenerativeModel model;
  final SharedPreferences _prefs;

  ConversationService(this._prefs)
      : model = GenerativeModel(
          model: AIServiceConfig.defaultModel,
          apiKey: apiKey,
          generationConfig: AIServiceConfig.defaultGenerationConfig,
        );

  Future<Map<String, String>> getScenario(String topic) async {
    try {
      final cachedData = await _getValidCachedScenario(topic);
      if (cachedData != null) return cachedData;

      final scenario = await _generateScenario(topic);
      _cacheScenario(topic, scenario).ignore();
      return scenario;
    } catch (e) {
      return _getFallbackScenario(topic);
    }
  }

  Future<Map<String, String>?> _getValidCachedScenario(String topic) async {
    try {
      final cachedString = _prefs.getString(CacheKeys.scenarioCache);
      if (cachedString == null) return null;

      final cached = json.decode(cachedString) as Map<String, dynamic>;
      final cacheTime = DateTime.parse(cached['timestamp'] as String);

      if (DateTime.now().difference(cacheTime) > AIServiceConfig.cacheDuration) {
        await clearCache();
        return null;
      }

      final scenarios = cached['scenarios'] as Map<String, dynamic>;
      return scenarios.containsKey(topic) 
          ? Map<String, String>.from(scenarios[topic] as Map) 
          : null;
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  Future<Map<String, String>> _generateScenario(String topic) async {
    final prompt = '''
Create an engaging English conversation scenario for: $topic

Requirements:
1. A specific character role for the AI assistant (e.g. waiter, shop assistant)
2. A detailed situation description (2-3 sentences)
3. A clear objective for the learner
4. 2-3 example phrases they might need
5. A welcoming opening line that:
   - Introduces the character's role
   - Is friendly and inviting
   - Sets the scene naturally
   - Encourages user participation

Format the response as JSON with these exact keys:
{
  "role": "specific character role (e.g. waiter at an Italian restaurant)",
  "situation": "detailed description of the context",
  "objective": "what the learner should achieve",
  "key_phrases": "useful phrases separated by | character",
  "opening_line": "natural greeting and introduction from the character"
}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final jsonStr = response.text ?? '';
    
    final match = RegExp(r'{[\s\S]*}').firstMatch(jsonStr);
    if (match == null) throw const FormatException('Invalid response format');

    final parsed = json.decode(match.group(0)!) as Map<String, dynamic>;
    return Map<String, String>.from(parsed);
  }

  Future<void> _cacheScenario(String topic, Map<String, String> scenario) async {
    try {
      final cachedString = _prefs.getString(CacheKeys.scenarioCache);
      final cached = cachedString != null
          ? json.decode(cachedString) as Map<String, dynamic>
          : {'scenarios': {}, 'timestamp': DateTime.now().toIso8601String()};

      final scenarios = cached['scenarios'] as Map<String, dynamic>;
      scenarios[topic] = scenario;
      cached['timestamp'] = DateTime.now().toIso8601String();

      await _prefs.setString(CacheKeys.scenarioCache, json.encode(cached));
    } catch (e) {
      print('Cache error: $e');
    }
  }

  Map<String, String> _getFallbackScenario(String topic) {
    return {
      'role': 'Friendly conversation partner',
      'situation': 'You\'re practicing $topic conversations.',
      'objective': 'Practice common phrases and responses related to $topic.',
      'key_phrases': 'Hello | How are you | Thank you',
      'opening_line': 'Hi there! I\'d love to help you practice $topic conversations. How are you today?',
    };
  }

  Future<void> clearCache() async {
    await _prefs.remove(CacheKeys.scenarioCache);
  }
}
