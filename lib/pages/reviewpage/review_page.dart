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

class _ReviewPageState extends State<ReviewPage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final VocabularyService _vocabularyService = VocabularyService();
  final GrammarService _grammarService = GrammarService();

  late TabController _tabController;
  Map<String, dynamic> _vocabularyData = {};
  Map<String, dynamic> _grammarData = {};

  // Search-related state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredVocabulary = [];
  List<Map<String, dynamic>> _filteredGrammar = [];

  final userId = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
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

  void _onTotalVocabularyCardTap(String level, Map<String, dynamic> data) {
    navigateWithSlide(
        context,
        ListPageVocabulary(
          level: level,
          title: level,
          data: data,
        ));
  }

  void _onTotalGrammarCardTap(String level, Map<String, dynamic> data) {
    navigateWithSlide(
        context,
        ListPageGrammar(
          level: level,
          title: level,
          data: data,
        ));
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

  Widget _buildSearchResults() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _tabController.index == 0
                ? _filteredVocabulary.length
                : _filteredGrammar.length,
            itemBuilder: (context, index) {
              if (_tabController.index == 0) {
                final item = _filteredVocabulary[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      item['englishWord'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item['vietnameseWord']),
                    trailing: Text(
                      item['partOfSpeech'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    onTap: () {
                      final level = item['difficulty'] ?? 'Unknown';
                      _onTotalVocabularyCardTap(level, {item['id']: item});
                    },
                  ),
                );
              } else {
                final item = _filteredGrammar[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      final level = item['difficulty'] ?? 'Unknown';
                      _onTotalGrammarCardTap(level, {item['id']: item});
                    },
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: _isSearching
            ? null // Ẩn TabBar khi đang tìm kiếm
            : PreferredSize(
                preferredSize: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Vocabulary'),
                    Tab(text: 'Grammar'),
                  ],
                ).preferredSize,
                child: Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      color: Color.fromRGBO(46, 64, 83, 1),
                      fontWeight: FontWeight.w400,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 2.0,
                    dividerColor: Colors.transparent,
                    indicator: const BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.lightGreen, width: 3.0),
                      ),
                    ),
                    tabs: const [
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
                autofocus: true, // Tự động focus khi hiện search bar
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSearching
            ? _buildSearchResults()
            : TabBarView(
                controller: _tabController,
                children: [
                  TabbarVocabulary(
                    vocabularyData: _vocabularyData,
                    onTotalVocabularyCardTap: _onTotalVocabularyCardTap,
                  ),
                  TabbarGrammar(
                    grammarData: _grammarData,
                    onTotalGrammarCardTap: _onTotalGrammarCardTap,
                  ),
                ],
              ),
      ),
    );
  }
}
