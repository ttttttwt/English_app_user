import 'package:do_an_test/pages/reviewpage/list_page_grammar.dart';
import 'package:do_an_test/pages/reviewpage/list_page_vocabulary.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:do_an_test/services/vocabulary_service.dart';
import 'package:do_an_test/services/grammar_service.dart';
import 'package:do_an_test/pages/reviewpage/compoment/tabbar_grammar.dart';
import 'package:do_an_test/pages/reviewpage/compoment/tabbar_vocabulary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final UserService _userService = UserService();
  final VocabularyService _vocabularyService = VocabularyService();
  final GrammarService _grammarService = GrammarService();

  Map<String, dynamic> _vocabularyData = {};
  Map<String, dynamic> _grammarData = {};

  // Search-related state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredVocabulary = [];
  List<Map<String, dynamic>> _filteredGrammar = [];

  final userId = FirebaseAuth.instance.currentUser;

  void _onTotalGrammarCardTap(String level, Map<String, dynamic> data) {
    navigateWithSlide(
        context,
        ListPageGrammar(
          level: level,
          title: level,
          data: data,
        ));
  }

  void _onTotalVocabularyCardTap(String level, Map<String, dynamic> data) {
    navigateWithSlide(
        context,
        ListPageVocabulary(
          level: level,
          title: level,
          data: data,
        ));
  }

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      final currentUser = userId!.uid;
      _fetchVocabularyData(currentUser);
      _fetchGrammarData(currentUser);
    } else {
      print('User is not logged in');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVocabularyData(String userId) async {
    try {
      final learnedVocabulary =
          await _userService.getUserLearnedVocabulary(userId);
      setState(() {
        _vocabularyData = learnedVocabulary!;
      });
    } catch (e) {
      print('Error fetching learned vocabulary: $e');
    }
  }

  Future<void> _fetchGrammarData(String userId) async {
    try {
      final learnedGrammar = await _userService.getUserLearnedGrammar(userId);
      setState(() {
        _grammarData = learnedGrammar!;
      });
    } catch (e) {
      print('Error fetching learned grammar: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredVocabulary = [];
        _filteredGrammar = [];
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    List<Map<String, dynamic>> vocabularyResults = [];
    List<Map<String, dynamic>> grammarResults = [];

    // Search in vocabulary
    for (var entry in _vocabularyData.entries) {
      try {
        final vocabularyItem =
            await _vocabularyService.getVocabularyById(entry.key);
        if (vocabularyItem != null) {
          final englishWord =
              vocabularyItem['englishWord'].toString().toLowerCase();
          final vietnameseWord =
              vocabularyItem['vietnameseWord'].toString().toLowerCase();

          if (englishWord.contains(lowercaseQuery) ||
              vietnameseWord.contains(lowercaseQuery)) {
            vocabularyResults.add({
              'id': entry.key,
              ...vocabularyItem,
              'learnedAt': entry.value['learnedAt'],
            });
          }
        }
      } catch (e) {
        print('Error searching vocabulary: $e');
      }
    }

    // Search in grammar
    for (var entry in _grammarData.entries) {
      try {
        final grammarItem = await _grammarService.getGrammarById(entry.key);
        if (grammarItem != null) {
          final name = grammarItem['name'].toString().toLowerCase();
          final description =
              grammarItem['description'].toString().toLowerCase();

          if (name.contains(lowercaseQuery) ||
              description.contains(lowercaseQuery)) {
            grammarResults.add({
              'id': entry.key,
              ...grammarItem,
              'learnedAt': entry.value['learnedAt'],
            });
          }
        }
      } catch (e) {
        print('Error searching grammar: $e');
      }
    }

    setState(() {
      _filteredVocabulary = vocabularyResults;
      _filteredGrammar = grammarResults;
    });
  }

  Widget _buildSearchResults(TabController tabController) {
    final currentIndex = tabController.index;

    if (currentIndex == 0) {
      // Vocabulary tab
      return ListView.builder(
        itemCount: _filteredVocabulary.length,
        itemBuilder: (context, index) {
          final item = _filteredVocabulary[index];
          return ListTile(
            title: Text(item['englishWord']),
            subtitle: Text(item['vietnameseWord']),
            trailing: Text(item['partOfSpeech']),
            onTap: () {
              // Handle vocabulary item tap
            },
          );
        },
      );
    } else {
      // Grammar tab
      return ListView.builder(
        itemCount: _filteredGrammar.length,
        itemBuilder: (context, index) {
          final item = _filteredGrammar[index];
          return ListTile(
            title: Text(item['name']),
            subtitle: Text(item['description']),
            onTap: () {
              // Handle grammar item tap
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const TabBar(
              tabs: [
                Tab(text: 'Vocabulary'),
                Tab(text: 'Grammar'),
              ],
            ).preferredSize,
            child: Material(
              color: Colors.white,
              child: _isSearching
                  ? const TabBar(
                      labelStyle: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(46, 64, 83, 1),
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: [
                        Tab(text: 'Vocabulary'),
                        Tab(text: 'Grammar'),
                      ],
                    )
                  : const TabBar(
                      labelStyle: TextStyle(
                        fontSize: 16,
                        color: Color.fromRGBO(46, 64, 83, 1),
                        fontWeight: FontWeight.w400,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 2.0,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.lightGreen, width: 3.0),
                        ),
                      ),
                      tabs: [
                        Tab(text: 'Vocabulary'),
                        Tab(text: 'Grammar'),
                      ],
                    ),
            ),
          ),
          backgroundColor: const Color.fromRGBO(0, 128, 98, 1),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: _performSearch,
                )
              : const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          actions: [
            IconButton(
              color: Colors.white,
              iconSize: 30,
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    _filteredVocabulary = [];
                    _filteredGrammar = [];
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _isSearching
                ? _buildSearchResults(DefaultTabController.of(context))
                : TabbarVocabulary(
                    vocabularyData: _vocabularyData,
                    onTotalVocabularyCardTap: _onTotalVocabularyCardTap,
                  ),
            _isSearching
                ? _buildSearchResults(DefaultTabController.of(context))
                : TabbarGrammar(
                    grammarData: _grammarData,
                    onTotalGrammarCardTap: _onTotalGrammarCardTap,
                  ),
          ],
        ),
      ),
    );
  }
}
