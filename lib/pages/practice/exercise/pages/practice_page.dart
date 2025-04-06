import 'package:do_an_test/pages/practice/converstation/pages/coversation_practice_page.dart';
import 'package:do_an_test/pages/practice/exercise/pages/vocabulary_grammar_practice_page.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 400;

    // Define responsive measurements
    final double cardPadding = isSmallScreen ? 12.0 : 16.0;
    final double iconSize = isSmallScreen ? 32.0 : 40.0;
    final double titleSize = isSmallScreen ? 16.0 : 18.0;
    final double descriptionSize = isSmallScreen ? 12.0 : 14.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
        title: const Text(
          'Practice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85, // Điều chỉnh tỷ lệ khung cho card
                    children: [
                      // Vocabulary and Grammar Practice Card
                      _buildPracticeCard(
                        context: context,
                        icon: Icons.book,
                        title: 'Vocabulary & Grammar',
                        description: 'Practice your learned content',
                        color: const Color.fromRGBO(74, 144, 226, 0.9),
                        iconSize: iconSize,
                        titleSize: titleSize,
                        descriptionSize: descriptionSize,
                        onTap: () {
                          navigateWithSlide(
                            context,
                            const VocabularyGrammarPracticePage(),
                          );
                        },
                      ),

                      // Conversation Practice Card
                      _buildPracticeCard(
                        context: context,
                        icon: Icons.mic,
                        title: 'Conversation',
                        description: 'Practice speaking skills',
                        color: const Color.fromRGBO(255, 221, 85, 0.9),
                        iconSize: iconSize,
                        titleSize: titleSize,
                        descriptionSize: descriptionSize,
                        blackText: true,
                        onTap: () {
                          navigateWithSlide(
                            context,
                            const ConversationPracticePage(),
                          );
                        },
                      ),

                      // // Placeholder cards for future features
                      // _buildComingSoonCard(
                      //   context: context,
                      //   icon: Icons.headphones,
                      //   title: 'Listening',
                      //   description: 'Coming soon',
                      //   color: Colors.grey.withOpacity(0.5),
                      //   iconSize: iconSize,
                      //   titleSize: titleSize,
                      //   descriptionSize: descriptionSize,
                      // ),

                      // _buildComingSoonCard(
                      //   context: context,
                      //   icon: Icons.edit_document,
                      //   title: 'Writing',
                      //   description: 'Coming soon',
                      //   color: Colors.grey.withOpacity(0.5),
                      //   iconSize: iconSize,
                      //   titleSize: titleSize,
                      //   descriptionSize: descriptionSize,
                      // ),

                      // _buildComingSoonCard(
                      //   context: context,
                      //   icon: Icons.emoji_emotions,
                      //   title: 'Role Play',
                      //   description: 'Coming soon',
                      //   color: Colors.grey.withOpacity(0.5),
                      //   iconSize: iconSize,
                      //   titleSize: titleSize,
                      //   descriptionSize: descriptionSize,
                      // ),

                      // _buildComingSoonCard(
                      //   context: context,
                      //   icon: Icons.quiz,
                      //   title: 'Quiz Game',
                      //   description: 'Coming soon',
                      //   color: Colors.grey.withOpacity(0.5),
                      //   iconSize: iconSize,
                      //   titleSize: titleSize,
                      //   descriptionSize: descriptionSize,
                      // ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double iconSize,
    required double titleSize,
    required double descriptionSize,
    required VoidCallback onTap,
    bool blackText = false,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: blackText ? Colors.black : Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: blackText ? Colors.black : Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color:
                      blackText ? Colors.black : Colors.white.withOpacity(0.9),
                  fontSize: descriptionSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double iconSize,
    required double titleSize,
    required double descriptionSize,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: color,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: descriptionSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}




