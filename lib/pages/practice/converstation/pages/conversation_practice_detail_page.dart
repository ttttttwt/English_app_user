// Flutter framework imports
import 'package:flutter/material.dart';
import 'dart:ui';

// Third-party package imports
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

// Local imports
import 'package:do_an_test/common/constant/const_value.dart';
import 'package:do_an_test/services/chat_service.dart';
import 'package:do_an_test/services/conversation_service.dart';
import 'package:do_an_test/services/message_cache.dart';
import 'package:do_an_test/services/suggestion_service.dart';
import 'package:do_an_test/pages/practice/converstation/compoments/message_bubble.dart';
import '../models/chat_message.dart';

class ConversationPracticeDetailPage extends StatefulWidget {
  final String topic;
  final String subtitle;

  const ConversationPracticeDetailPage({
    super.key,
    required this.topic,
    required this.subtitle,
  });

  @override
  State<ConversationPracticeDetailPage> createState() =>
      _ConversationPracticeDetailPageState();
}

class _ConversationPracticeDetailPageState
    extends State<ConversationPracticeDetailPage>
    with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _currentTranscription = '';
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;
  Map<String, String>? _scenario;
  bool _isLoadingScenario = true;
  late final ConversationService _conversationService;
  late final ChatService _chatService;
  bool _isInitialized = false;
  bool _isGeneratingResponse = false;
  bool _showConfirmationDialog = true;
  late final MessageCache _messageCache;
  late final SuggestionService _suggestionService;
  List<String> _currentSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isScenarioExpanded = true;
  late final AnimationController _scenarioAnimationController;
  late final Animation<double> _scenarioAnimation;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(apiKey);
    _initializeServices();
    _suggestionService = SuggestionService();

    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _micAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _micAnimationController.repeat(reverse: true);

    _scenarioAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scenarioAnimation = CurvedAnimation(
      parent: _scenarioAnimationController,
      curve: Curves.easeInOut,
    );

    _scenarioAnimationController.value = 1.0;
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _scenarioAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _conversationService = ConversationService(prefs);
      _messageCache = MessageCache(prefs);

      // Check if it's a new conversation or not
      if (_showConfirmationDialog) {
        await _showConversationConfirmationDialog();
      } else {
        // Load scenario first for existing conversations
        await _loadScenarioWithoutStarting();
      }

      await _initializeSpeech();

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      // Handle initialization error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing: $e')),
        );
      }
    }
  }

  // Tách riêng việc load scenario và bắt đầu hội thoại
  Future<void> _loadScenarioWithoutStarting() async {
    try {
      setState(() => _isLoadingScenario = true);
      final scenario = await _conversationService.getScenario(widget.topic);
      
      if (mounted) {
        setState(() {
          _scenario = scenario;
          _isLoadingScenario = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingScenario = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading scenario: $e')),
        );
      }
    }
  }

  // Dùng cho cuộc hội thoại mới
  Future<void> _loadScenarioAndStart() async {
    try {
      setState(() => _isLoadingScenario = true);
      final scenario = await _conversationService.getScenario(widget.topic);
      
      if (mounted) {
        setState(() {
          _scenario = scenario;
          _isLoadingScenario = false;
        });
        
        // Chỉ thêm tin nhắn mới cho cuộc hội thoại mới
        _addMessage(scenario['opening_line']!, MessageType.ai);
        _addMessage(
          'Situation: ${scenario['situation']!}',
          MessageType.system,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingScenario = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading scenario: $e')),
        );
      }
    }
  }

  Future<void> _showConversationConfirmationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conversation Options'),
          content: const Text('Would you like to continue with the previous conversation or start a new one?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue Conversation'),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _showConfirmationDialog = false;
                });
                // Load cached messages and scenario without starting new conversation
                await _loadScenarioWithoutStarting();
                final cachedMessages = await _messageCache.loadMessages(widget.topic);
                if (cachedMessages != null && cachedMessages.isNotEmpty) {
                  setState(() {
                    _messages.addAll(cachedMessages);
                  });
                  _chatService.restoreHistory(
                    cachedMessages.map((msg) => Content.text(msg.text)).toList(),
                  );
                }
              },
            ),
            ElevatedButton(
              child: const Text('Start New Conversation'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _messageCache.clearCache();
                await _conversationService.clearCache();
                setState(() {
                  _showConfirmationDialog = false;
                  _messages.clear();
                });
                _chatService.clearHistory();
                // Start new conversation with AI opening
                await _loadScenarioAndStart();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }
  
  Future<void> _startListening() async {
    if (!_isListening) {
      final bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _currentTranscription = result.recognizedWords;
            });
          },
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_currentTranscription.isNotEmpty) {
        _showTranscriptionDialog();
      }
    }
  }

  void _showTranscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currentTranscription),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _currentTranscription = '');
                  },
                  child: const Text('Re-record'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addMessage(_currentTranscription, MessageType.user);
                    Navigator.pop(context);
                    _generateAIResponse();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addMessage(String text, MessageType type) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        type: type,
        timestamp: DateTime.now(),
      ));
      _currentTranscription = '';
    });
    // Save messages after each new message
    _messageCache.saveMessages(widget.topic, _messages);
    
    // Load suggestions after AI responds
    if (type == MessageType.ai) {
      _loadSuggestions();
    }
  }

  Future<void> _speakMessage(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _generateAIResponse() async {
    if (_scenario == null) return;

    setState(() => _isGeneratingResponse = true);
    try {
      // Ensure we have the complete conversation history
      final completeHistory = _messages.map((msg) => Content.text(msg.text)).toList();
      _chatService.restoreHistory(completeHistory);

      final response = await _chatService.generateResponse(
        _currentTranscription,
        widget.topic,
        _scenario!,
      );
      
      if (mounted) {
        _addMessage(response, MessageType.ai);
        _speakMessage(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate response. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingResponse = false);
      }
    }
  }

  Future<void> _loadSuggestions() async {
    if (_messages.isEmpty || _scenario == null) return;

    final lastAiMessage = _messages.lastWhere(
      (msg) => msg.type == MessageType.ai,
      orElse: () => ChatMessage(text: '', type: MessageType.system, timestamp: DateTime.now()),
    );

    setState(() => _isLoadingSuggestions = true);
    try {
      final suggestions = await _suggestionService.generateSuggestions(
        lastAiMessage.text,
        widget.topic,
        _scenario!,
      );
      if (mounted) {
        setState(() {
          _currentSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Widget _buildScenarioCard() {
    if (_isLoadingScenario) {
      return Container(
        height: 200, // Fixed height for loading state
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading scenario...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_scenario == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        children: [
          // Header section - always visible
          InkWell(
            onTap: () {
              setState(() {
                _isScenarioExpanded = !_isScenarioExpanded;
                if (_isScenarioExpanded) {
                  _scenarioAnimationController.forward();
                } else {
                  _scenarioAnimationController.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are talking to: ${_scenario!['role']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_scenarioAnimation),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          SizeTransition(
            sizeFactor: _scenarioAnimation,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Objective',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_scenario!['objective']!),
                      const Divider(height: 24),
                      const Text(
                        'Useful Phrases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _scenario!['key_phrases']!
                            .split('|')
                            .map((phrase) => _buildPhraseChip(phrase.trim()))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhraseChip(String phrase) {
    return InkWell(
      onTap: () => _speakMessage(phrase),
      child: Chip(
        label: Text(
          phrase,
          style: const TextStyle(fontSize: 12),
        ),
        avatar: const Icon(
          Icons.volume_up,
          size: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF008062),
          title: Text(widget.topic),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing conversation...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008062),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show tutorial or help dialog
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF008062).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildScenarioCard(),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return AnimatedSlide(
                        duration: const Duration(milliseconds: 300),
                        offset: Offset.zero,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: MessageBubble(
                            message: message,
                            onTap: () => _speakMessage(message.text),
                            role: message.type == MessageType.ai ? 
                                  (_scenario != null ? _scenario!['role'] : null) : null,
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isGeneratingResponse)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Generating response...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isLoadingSuggestions)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
              ),
            _buildSuggestionChips(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      _isListening
                          ? _currentTranscription.isEmpty
                              ? 'Listening...'
                              : _currentTranscription
                          : 'Tap and hold microphone to speak',
                      style: TextStyle(
                        color:
                            _isListening ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapUp: (_) => _stopListening(),
                  onTapCancel: () => _stopListening(),
                  child: ScaleTransition(
                    scale: _micAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(0xFF008062)
                            : const Color(0xFF008062).withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008062).withOpacity(0.3),
                            blurRadius: _isListening ? 12 : 0,
                            spreadRadius: _isListening ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    if (_currentSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _currentSuggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: Colors.grey.shade100,
                onPressed: () {
                  _addMessage(suggestion, MessageType.user);
                  _generateAIResponse();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}