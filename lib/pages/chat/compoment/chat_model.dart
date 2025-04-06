import 'package:google_generative_ai/google_generative_ai.dart';

class ChatModel {
  final String id;
  final List<Content> messages;
  final int order; // Add order field to maintain sequence
  final DateTime createdAt; // Add creation timestamp

  ChatModel({
    required this.id,
    required this.messages,
    required this.order,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      messages: (json['messages'] as List)
          .map((m) => Content(
                m['role'],
                [TextPart(m['text'])],
              ))
          .toList(),
      order: json['order'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'messages': messages
            .map((m) => {
                  'role': m.role,
                  'text': (m.parts.first as TextPart).text,
                })
            .toList(),
        'order': order,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}