import 'package:do_an_test/common/constant/const_value.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:do_an_test/common/constant/const_class.dart';

class SuggestionService {
  final GenerativeModel model;

  SuggestionService()
      : model = GenerativeModel(
          model: AIServiceConfig.defaultModel,
          apiKey: apiKey,
        );

  Future<List<String>> generateSuggestions(
    String lastAiMessage,
    String topic,
    Map<String, String> scenario,
  ) async {
    try {
      final prompt = AIServiceConstants.suggestionPrompt
          .replaceAll('{role}', scenario['role']!)
          .replaceAll('{message}', lastAiMessage)
          .replaceAll('{topic}', topic)
          .replaceAll('{situation}', scenario['situation']!)
          .replaceAll('{objective}', scenario['objective']!)
          .replaceAll('{key_phrases}', scenario['key_phrases']!);

      final response = await model.generateContent([Content.text(prompt)]);
      final suggestions = response.text?.split('\n') ?? [];

      if (suggestions.length < AIServiceConstants.defaultSuggestionCount) {
        return AIServiceConstants.defaultSuggestions;
      }

      return suggestions.take(AIServiceConstants.defaultSuggestionCount).toList();
    } catch (e) {
      return AIServiceConstants.defaultSuggestions;
    }
  }
}
