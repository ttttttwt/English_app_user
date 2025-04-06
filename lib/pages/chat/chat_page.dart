import 'package:do_an_test/common/constant/const_value.dart';
import 'package:do_an_test/pages/chat/compoment/chat_model.dart';
import 'package:do_an_test/pages/chat/compoment/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  static const _apiKey = apiKey;
  late GenerativeModel _model;
  late ChatSession _chat;

  // Add context for the chatbot
  static const String _systemContext = chatPageSystemContext;

  ChatService() {
    _initializeGemini();
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    // Initialize with system context
    _chat.sendMessage(Content.text(_systemContext));
  }

  void resetChat() {
    _chat = _model.startChat();
    // Reinitialize with system context
    _chat.sendMessage(Content.text(_systemContext));
  }

  Stream<String> sendMessage(String message) async* {
    var response = _chat.sendMessageStream(Content.text(message));
    await for (var item in response) {
      if (item.text != null) {
        yield item.text!;
      }
    }
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final ChatService _chatService = ChatService();

  List<Content> history = [];
  bool _loading = false;
  String? _currentChatId;
  List<String> _chatIds = [];
  Map<String, ChatModel> _chats = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _textFieldFocus.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    final ids = await StorageService.loadChatIds();
    final loadedChats = <String, ChatModel>{};

    for (final id in ids) {
      final chat = await StorageService.loadChat(id);
      if (chat != null) {
        loadedChats[id] = chat;
      }
    }

    setState(() {
      _chatIds = ids;
      _chats = loadedChats;
      // Load the most recent chat if available
      if (ids.isNotEmpty) {
        _currentChatId = ids.last;
        _loadCurrentChat();
      }
    });
  }

  Future<void> _loadCurrentChat() async {
    if (_currentChatId == null) return;

    final chat = _chats[_currentChatId];
    if (chat != null) {
      setState(() {
        history = chat.messages;
      });
      _chatService.resetChat();
    }
  }

  Future<void> _saveCurrentChat() async {
    if (_currentChatId == null) return;

    final currentChat = _chats[_currentChatId];
    if (currentChat != null) {
      final updatedChat = ChatModel(
        id: _currentChatId!,
        messages: history,
        order: currentChat.order,
        createdAt: currentChat.createdAt,
      );
      _chats[_currentChatId!] = updatedChat;
      await StorageService.saveChat(updatedChat);
    }
  }

  Future<void> _createNewChat() async {
    if (_currentChatId != null && history.isEmpty) return;

    final newChatId = DateTime.now().millisecondsSinceEpoch.toString();
    final order = await StorageService.getNextOrder();
    final newChat = ChatModel(
      id: newChatId,
      messages: [],
      order: order,
      createdAt: DateTime.now(),
    );

    setState(() {
      _currentChatId = newChatId;
      history = [];
      _chatIds.add(newChatId);
      _chats[newChatId] = newChat;
    });

    await StorageService.saveChatIds(_chatIds);
    await StorageService.saveChat(newChat);
    _chatService.resetChat();
  }

  Future<void> _switchChat(String chatId) async {
    if (chatId == _currentChatId) return;

    await _saveCurrentChat();

    setState(() {
      _currentChatId = chatId;
      history = _chats[chatId]?.messages ?? [];
    });

    _chatService.resetChat();
  }

  Future<void> _deleteChat(String chatId) async {
    await StorageService.deleteChat(chatId);

    setState(() {
      _chatIds.remove(chatId);
      _chats.remove(chatId);

      if (chatId == _currentChatId) {
        _currentChatId = _chatIds.isNotEmpty ? _chatIds.last : null;
        history = _currentChatId != null
            ? _chats[_currentChatId]?.messages ?? []
            : [];
      }
    });

    await StorageService.saveChatIds(_chatIds);
  }

  String _getChatTitle(String chatId) {
    final chat = _chats[chatId];
    if (chat == null) return 'Chat';
    return 'Chat ${chat.order}';
  }

  // Rest of the UI code remains the same, just update the title display
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
      title: Text(
        _currentChatId != null ? _getChatTitle(_currentChatId!) : 'New Chat',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [_buildChatMenu()],
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Create new chat if needed
    if (_currentChatId == null) {
      await _createNewChat();
    }

    setState(() {
      _loading = true;
      history.add(Content('user', [TextPart(message)]));
      _textController.clear();
    });
    _scrollToBottom();

    try {
      String fullResponse = '';
      await for (final response in _chatService.sendMessage(message)) {
        setState(() {
          fullResponse += response;
          if (history.last.role == 'model') {
            history.last = Content('model', [TextPart(fullResponse)]);
          } else {
            history.add(Content('model', [TextPart(fullResponse)]));
          }
        });
        _scrollToBottom();
      }
      await _saveCurrentChat();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          if (_loading) const LinearProgressIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (String value) {
        if (value == 'new') {
          _createNewChat();
        } else if (value.startsWith('delete_')) {
          _deleteChat(value.substring(7));
        } else {
          _switchChat(value);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'new',
          child: Text('New Chat'),
        ),
        if (_chatIds.isNotEmpty) const PopupMenuDivider(),
        ..._chatIds.map((chatId) => PopupMenuItem<String>(
              value: chatId,
              child: Row(
                children: [
                  Expanded(
                    child: Text(_getChatTitle(chatId)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      Navigator.pop(context, 'delete_$chatId');
                    },
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.separated(
      padding: const EdgeInsets.all(15),
      controller: _scrollController,
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: _buildChatMessage,
    );
  }

  Widget _buildChatMessage(BuildContext context, int index) {
    final content = history[index];
    final text =
        content.parts.whereType<TextPart>().map<String>((e) => e.text).join('');

    return ListTile(
      title: Align(
        alignment: content.role == 'user'
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: content.role == 'user'
                ? Colors.blueAccent
                : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFieldFocus,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: _sendMessage,
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.send,
              color: Color.fromRGBO(0, 128, 98, 1),
            ),
            onPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
