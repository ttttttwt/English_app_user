import 'package:do_an_test/common/constant/const_class.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  final GenerativeModel model;
  final List<Content> _history = [];

  ChatService(String apiKey)
      : model = GenerativeModel(
          model: AIServiceConfig.defaultModel,
          apiKey: apiKey,
        ) {
    _history.add(Content.text(AIServiceConstants.defaultSystemPrompt));
  }

  Future<String> generateResponse(
    String userMessage,
    String topic,
    Map<String, String> scenario,
  ) async {
    try {
      final contextPrompt = ChatServiceUtils.buildContextPrompt(
        role: scenario['role']!,
        topic: topic,
        scenario: scenario,
        contextSummary: ChatServiceUtils.generateContextSummary(_history),
        userMessage: userMessage,
      );

      _addToHistory(Content.text(userMessage));

      final chat = model.startChat(history: _history);
      final response = await chat.sendMessage(Content.text(contextPrompt));

      final aiResponse = response.text ?? 'I apologize, I cannot respond right now.';
      _addToHistory(Content.text(aiResponse));

      return aiResponse;
    } catch (e) {
      return 'I apologize, I encountered an error. Could you please try again?';
    }
  }

  void _addToHistory(Content content) {
    _history.add(content);
    if (_history.length > AIServiceConfig.maxHistoryLength) {
      final systemContext = _history.first;
      final trimmedHistory = ChatServiceUtils.trimHistory(_history, systemContext);
      _history
        ..clear()
        ..addAll(trimmedHistory);
    }
  }

  void clearHistory() {
    _history.clear();
    _history.add(Content.text(AIServiceConstants.defaultSystemPrompt));
  }

  void restoreHistory(List<Content> history) {
    _history.clear();
    _history.add(Content.text(AIServiceConstants.defaultSystemPrompt));
    _history.addAll(history);
  }

  List<Content> get currentHistory => List.unmodifiable(_history);
}
