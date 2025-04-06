import 'dart:convert';
import 'package:do_an_test/pages/chat/compoment/chat_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _chatIdsKey = 'chatIds';
  static const String _chatPrefix = 'chat_';
  static const String _lastOrderKey = 'lastOrder';

  static Future<List<String>> loadChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_chatIdsKey) ?? [];
  }

  static Future<void> saveChatIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_chatIdsKey, ids);
  }

  static Future<int> getNextOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOrder = prefs.getInt(_lastOrderKey) ?? 0;
    await prefs.setInt(_lastOrderKey, lastOrder + 1);
    return lastOrder + 1;
  }

  static Future<ChatModel?> loadChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatData = prefs.getString('$_chatPrefix$chatId');
    if (chatData != null) {
      return ChatModel.fromJson(jsonDecode(chatData));
    }
    return null;
  }

  static Future<void> saveChat(ChatModel chat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_chatPrefix${chat.id}',
      jsonEncode(chat.toJson()),
    );
  }

  static Future<void> deleteChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_chatPrefix$chatId');
  }
}
