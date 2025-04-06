import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/practice/converstation/models/chat_message.dart';

class MessageCache {
  static const String _messagesCacheKey = 'chat_messages';
  final SharedPreferences _prefs;

  MessageCache(this._prefs);

  Future<void> saveMessages(String topic, List<ChatMessage> messages) async {
    final messagesMap = messages.map((msg) => {
      'text': msg.text,
      'type': msg.type.toString(),
      'timestamp': msg.timestamp.toIso8601String(),
      'context': _generateMessageContext(msg, messages), // Thêm context
    }).toList();

    final cache = {
      'topic': topic,
      'messages': messagesMap,
      'timestamp': DateTime.now().toIso8601String(),
      'lastMessageIndex': messages.length - 1,
    };

    await _prefs.setString(_messagesCacheKey, json.encode(cache));
  }

  Future<List<ChatMessage>?> loadMessages(String topic) async {
    final String? cached = _prefs.getString(_messagesCacheKey);
    if (cached == null) return null;

    try {
      final Map<String, dynamic> cache = json.decode(cached);
      
      // Check if cache is for current topic
      if (cache['topic'] != topic) return null;

      final List<dynamic> messagesData = cache['messages'];
      return messagesData.map((msg) => ChatMessage(
        text: msg['text'],
        type: _parseMessageType(msg['type'] as String),
        timestamp: DateTime.parse(msg['timestamp']),
      )).toList();
    } catch (e) {
      await clearCache();
      return null;
    }
  }

  MessageType _parseMessageType(String type) {
    switch (type) {
      case 'MessageType.user':
        return MessageType.user;
      case 'MessageType.system':
        return MessageType.system;
      default:
        return MessageType.ai;
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_messagesCacheKey);
  }

  String _generateMessageContext(ChatMessage message, List<ChatMessage> allMessages) {
    final messageIndex = allMessages.indexOf(message);
    if (messageIndex < 2) return '';

    // Lấy 2 tin nhắn trước đó để làm context
    final previousMessages = allMessages
        .sublist(messageIndex - 2, messageIndex)
        .map((m) => m.text)
        .join(' -> ');
    return previousMessages;
  }
}
