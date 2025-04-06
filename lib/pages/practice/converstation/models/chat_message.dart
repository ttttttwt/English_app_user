enum MessageType { ai, user, system }

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final String? audioUrl;

  const ChatMessage({
    required this.text,
    required this.type,
    required this.timestamp,
    this.audioUrl,
  });
}
