import 'package:do_an_test/common/constant/const_class.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/pages/practice/converstation/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onTap;
  final String? role;

  const MessageBubble({
    super.key,
    required this.message,
    this.onTap,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.type == MessageType.user;

    if (message.type == MessageType.system) {
      return _SystemMessage(text: message.text);
    }

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isUser && role != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(role!, style: _getSystemTextStyle()),
          ),
        MessageBubbleContent(
          text: message.text,
          isUser: isUser,
          onTap: onTap,
        ),
      ],
    );
  }

  TextStyle _getSystemTextStyle() {
    return const TextStyle(
      fontSize: 12,
      color: Colors.grey,
      fontStyle: FontStyle.italic,
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;

  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: ConversationUI.defaultPadding,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class MessageBubbleContent extends StatelessWidget {
  final String text;
  final bool isUser;
  final VoidCallback? onTap;

  const MessageBubbleContent({
    super.key,
    required this.text,
    required this.isUser,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: _buildBubble(),
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      decoration: BoxDecoration(
        color: isUser ? ConversationUI.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(ConversationUI.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ConversationUI.borderRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.volume_up,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Flexible(
                  child: Text(
                    text,
                    style: ConversationUI.messageStyle.copyWith(
                      color: isUser ? Colors.white : Colors.black87,
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
}
