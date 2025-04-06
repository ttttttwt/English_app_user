import 'package:do_an_test/common/constant/const_class.dart';
import 'package:do_an_test/pages/practice/converstation/pages/conversation_practice_detail_page.dart';
import 'package:do_an_test/pages/practice/converstation/compoments/topic_card.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:flutter/material.dart';

class ConversationPracticePage extends StatelessWidget {
  final List<Map<String, dynamic>> _topics = const [
    {
      'title': 'Daily Conversations',
      'subtitle': 'Practice common everyday dialogues',
      'icon': Icons.chat_bubble,
    },
    {
      'title': 'At the Restaurant',
      'subtitle': 'Learn to order food and make reservations',
      'icon': Icons.restaurant,
    },
    {
      'title': 'Travel & Directions',
      'subtitle': 'Navigate and ask for directions',
      'icon': Icons.map,
    },
    {
      'title': 'Shopping',
      'subtitle': 'Practice shopping conversations',
      'icon': Icons.shopping_bag,
    },
    {
      'title': 'Business English',
      'subtitle': 'Professional workplace conversations',
      'icon': Icons.business,
    },
    {
      'title': 'Social Events',
      'subtitle': 'Social gathering and party dialogues',
      'icon': Icons.groups,
    },
  ];

  const ConversationPracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ConversationUI.primaryColor,
        title: const Text(
          'Conversation Practice',
          style: ConversationUI.headerStyle,
        ),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(ConversationUI.defaultPadding),
        itemCount: _topics.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Select a topic to practice',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          
          final topic = _topics[index - 1];
          return TopicCard(
            title: topic['title'] as String,
            subtitle: topic['subtitle'] as String,
            icon: topic['icon'] as IconData,
            onTap: () {
              navigateWithSlide(
                context,
                ConversationPracticeDetailPage(
                  topic: topic['title'] as String,
                  subtitle: topic['subtitle'] as String,
                ),
              );
            },
          );
        },
      ),
    );
  }
}