import 'package:do_an_test/common/constant/const_class.dart';
import 'package:flutter/material.dart';

class TopicCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: ConversationUI.cardElevation,
      margin: const EdgeInsets.symmetric(
        horizontal: ConversationUI.defaultPadding,
        vertical: 8,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(ConversationUI.defaultPadding),
        leading: CircleAvatar(
          backgroundColor: ConversationUI.primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: ConversationUI.roleStyle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle, style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          )),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: ConversationUI.primaryColor,
        ),
        onTap: onTap,
      ),
    );
  }
}
