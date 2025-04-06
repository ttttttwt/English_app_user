import 'package:do_an_test/services/grammar_service.dart';
import 'package:do_an_test/pages/reviewpage/compoment/vocabulary_page.dart';
import 'package:do_an_test/pages/reviewpage/compoment/vocabulary_card.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';


class ListPageGrammar extends StatelessWidget {
  final String title;
  final String level;
  final Map<String, dynamic> data;

  const ListPageGrammar({
    super.key,
    required this.title,
    required this.level,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final GrammarService grammarService = GrammarService();
    final bool isSmallScreen = MediaQuery.of(context).size.width < 400;

    final double horizontalPadding = isSmallScreen ? 12 : 16;
    final double iconSize = isSmallScreen ? 24 : 30;
    final TextStyle titleTextStyle = TextStyle(
      color: Colors.white,
      fontSize: isSmallScreen ? 22 : 26,
      fontWeight: FontWeight.w600,
    );

    void onTap(BuildContext context, String englishWord, String vietnameseWord,
        String? example, String? exampleTranslation, String? imageUrl) {
      navigateWithSlide(
        context,
        Scaffold(
          appBar: AppBar(
        backgroundColor: const Color.fromRGBO(193, 243, 118, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
          color: Color.fromRGBO(46, 64, 83, 1), size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
          color: const Color.fromRGBO(46, 64, 83, 1),
          iconSize: 30,
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Implement settings functionality
          },
            ),
          ),
        ],
          ),
          body: VocabularyPage(
        mediaUrl: imageUrl ??
            'https://images.squarespace-cdn.com/content/v1/61c4da8eb1b30a201b9669f2/e2e0e62f-0064-4f86-b9d8-5a55cb7110ca/Korembi-January-2024.jpg',
        english: englishWord,
        vietnamese: vietnameseWord,
        example: example, // Không cần giá trị mặc định
        exampleTranslation:
            exampleTranslation, // Không cần giá trị mặc định
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
        centerTitle: true,
        title: Padding(
          padding: EdgeInsets.only(left: horizontalPadding),
          child: Text(title, style: titleTextStyle),
        ),
        leading: IconButton(
          color: Colors.white,
          iconSize: iconSize,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: FutureBuilder<List<Map<String, dynamic>?>>(
          future: _fetchAllVocabularies(grammarService),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No vocabulary data found'));
            }

            final vocabularies = snapshot.data!;
            return ListView.builder(
              itemCount: vocabularies.length,
              itemBuilder: (context, index) {
                final vocab = vocabularies[index];
                
                // Check if the grammar item exists
                if (vocab == null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: VocabularyCard(
                      imageUrl: 'https://images.squarespace-cdn.com/content/v1/61c4da8eb1b30a201b9669f2/e2e0e62f-0064-4f86-b9d8-5a55cb7110ca/Korembi-January-2024.jpg',
                      englishWord: 'Deleted Grammar',
                      vietnameseWord: 'This grammar item has been deleted',
                      level: level,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This grammar item is no longer available'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: VocabularyCard(
                    imageUrl: vocab['imageUrl'] ??
                        'https://images.squarespace-cdn.com/content/v1/61c4da8eb1b30a201b9669f2/e2e0e62f-0064-4f86-b9d8-5a55cb7110ca/Korembi-January-2024.jpg',
                    englishWord: vocab['name'] ?? 'Word',
                    vietnameseWord: vocab['description'] ?? 'Từ',
                    level: vocab['memoryLevel'] ?? 'Basic',
                    onTap: () => onTap(
                      context,
                      vocab['name'] ?? 'Word',
                      vocab['description'] ?? 'Từ', 
                      vocab['example'],
                      vocab['exampleTranslation'],
                      vocab['imageUrl'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Helper function to fetch all vocabulary data
  Future<List<Map<String, dynamic>?>> _fetchAllVocabularies(
      GrammarService service) async {
    return await Future.wait(
      data.keys.map((key) => service.getGrammarById(key)),
    );
  }
}
