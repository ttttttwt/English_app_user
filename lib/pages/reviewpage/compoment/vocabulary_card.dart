import 'package:flutter/material.dart';

const Color basicColor = Color.fromRGBO(255, 111, 97, 1);
const Color intermediateColor = Color.fromRGBO(255, 222, 33, 1);
const Color advancedColor = Color.fromRGBO(74, 144, 226, 1);
const Color expertColor = Color.fromRGBO(0, 128, 98, 1);

class VocabularyCard extends StatelessWidget {
  final String imageUrl;
  final String englishWord;
  final String vietnameseWord;
  final String level;
  final double cardHeight;
  final VoidCallback? onTap;

  const VocabularyCard({
    super.key,
    required this.imageUrl,
    required this.englishWord,
    required this.vietnameseWord,
    required this.level,
    this.cardHeight = 100,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Text Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // English Word Text with flexible size
                    Flexible(
                      child: Text(
                        englishWord,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Vietnamese Word Text with flexible size
                    Flexible(
                      child: Text(
                        vietnameseWord,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Level Indicator
            Text(
              level,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: level == 'Basic'
                    ? basicColor
                    : level == 'Intermediate'
                        ? intermediateColor
                        : level == 'Advanced'
                            ? advancedColor
                            : expertColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
