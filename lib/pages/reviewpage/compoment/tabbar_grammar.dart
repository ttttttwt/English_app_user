import 'package:do_an_test/pages/reviewpage/compoment/vocabulary_page.dart';
import 'package:do_an_test/pages/reviewpage/compoment/vocabulary_card.dart';
import 'package:do_an_test/services/grammar_service.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:do_an_test/pages/reviewpage/compoment/total_vocabulary_card.dart';
import 'package:flutter/material.dart';

const EdgeInsets tabContainerMargin = EdgeInsets.symmetric(horizontal: 16.0);
const EdgeInsets tabContainerPadding = EdgeInsets.all(16.0);

class TabbarGrammar extends StatelessWidget {
  final Map<String, dynamic> grammarData;
  final Function(String, Map<String, dynamic>) onTotalGrammarCardTap;

  const TabbarGrammar({
    super.key,
    required this.grammarData,
    required this.onTotalGrammarCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final GrammarService grammarService = GrammarService();
    final basic = getVocabularyByMemoryLevel('Basic', grammarData);
    final intermediate =
        getVocabularyByMemoryLevel('Intermediate', grammarData);
    final advanced = getVocabularyByMemoryLevel('Advanced', grammarData);
    final expert = getVocabularyByMemoryLevel('Expert', grammarData);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TotalVocabularyCard(
                level: 'Basic',
                color: const Color.fromRGBO(255, 111, 97, 1),
                tabContainerMargin: tabContainerMargin,
                tabContainerPadding: tabContainerPadding,
                vocabularyData: grammarData,
                onTap: () => onTotalGrammarCardTap('Basic', basic),
              ),
            ),
            Expanded(
              child: TotalVocabularyCard(
                vocabularyData: grammarData,
                level: 'Intermediate',
                color: const Color.fromRGBO(255, 222, 33, 1),
                tabContainerMargin: tabContainerMargin,
                tabContainerPadding: tabContainerPadding,
                onTap: () =>
                    onTotalGrammarCardTap('Intermediate', intermediate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TotalVocabularyCard(
                level: 'Advanced',
                color: const Color.fromRGBO(74, 144, 226, 1),
                tabContainerMargin: tabContainerMargin,
                tabContainerPadding: tabContainerPadding,
                onTap: () => onTotalGrammarCardTap('Advanced', advanced),
                vocabularyData: grammarData,
              ),
            ),
            Expanded(
              child: TotalVocabularyCard(
                level: 'Expert',
                color: const Color.fromRGBO(130, 221, 85, 1),
                tabContainerMargin: tabContainerMargin,
                tabContainerPadding: tabContainerPadding,
                onTap: () => onTotalGrammarCardTap('Expert', expert),
                vocabularyData: grammarData,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Divider(
            color: Color.fromRGBO(46, 64, 83, 1),
            thickness: 1,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              itemCount: grammarData.length,
              itemBuilder: (context, index) {
                final key = grammarData.keys.elementAt(index);
                final vocabData = grammarData[key];

                // Safely extract the 'level' key, ensuring it doesn't cause a null error
                final level = vocabData != null &&
                        vocabData.containsKey('memoryLevel')
                    ? vocabData['memoryLevel']
                    : 'Basic'; // Default value if 'level' is null or missing

                // Use FutureBuilder to handle async data fetching
                return FutureBuilder<Map<String, dynamic>?>(
                  future: grammarService.getGrammarById(key),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
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

                    final vocab = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: VocabularyCard(
                        imageUrl: vocab['imageUrl'] ??
                            'https://images.squarespace-cdn.com/content/v1/61c4da8eb1b30a201b9669f2/e2e0e62f-0064-4f86-b9d8-5a55cb7110ca/Korembi-January-2024.jpg',
                        englishWord: vocab['name'] ?? 'Word',
                        vietnameseWord: vocab['description'] ?? 'Từ',
                        level: level,
                        onTap: () => onTap(
                          context,
                          vocab['name'] ?? 'Word',
                          vocab['description'] ?? 'Từ',
                          vocab['example'], // Không cần giá trị mặc định ở đây
                          vocab[
                              'exampleTranslation'], // Không cần giá trị mặc định ở đây
                          vocab['imageUrl'],
                        ), // Use the level variable (it’s either from vocabData or default)
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> getVocabularyByMemoryLevel(
    String targetMemoryLevel, Map<String, dynamic> vocabularyData) {
  try {
    // Khởi tạo map kết quả
    Map<String, dynamic> filteredVocabs = {};

    // Duyệt qua tất cả các entries trong vocabularyData
    vocabularyData.forEach((vocab, data) {
      // Kiểm tra nếu data là Map và có chứa trường memoryLevel
      if (data is Map && data.containsKey('memoryLevel')) {
        // Nếu memoryLevel khớp với target, thêm vào kết quả
        if (data['memoryLevel'] == targetMemoryLevel) {
          filteredVocabs[vocab] = data;
        }
      }
    });

    return filteredVocabs;
  } catch (e) {
    throw Exception("Failed to filter vocabulary by memory level: $e");
  }
}
