// chat_modal.dart
import 'package:do_an_test/pages/chat/chat_page.dart';
import 'package:flutter/material.dart';

class ChatModal extends StatelessWidget {
  const ChatModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const ChatPage(),
        );
      },
    );
  }
}