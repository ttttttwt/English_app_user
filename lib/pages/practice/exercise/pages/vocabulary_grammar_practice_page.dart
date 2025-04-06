import 'package:do_an_test/common/constant/const_class.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/continue_button.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/exercise_type_card.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/items_section.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/question_count_section.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/search_section.dart';
import 'package:do_an_test/pages/practice/exercise/pages/exercise_session_page.dart';
import 'package:do_an_test/services/grammar_service.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:do_an_test/services/vocabulary_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Add this import
import 'package:do_an_test/common/widget/navigation_animation.dart'; // Add this import at the top

class VocabularyGrammarPracticePage extends StatefulWidget {
  const VocabularyGrammarPracticePage({super.key});

  @override
  State<VocabularyGrammarPracticePage> createState() =>
      _VocabularyGrammarPracticePageState();
}

class _VocabularyGrammarPracticePageState
    extends State<VocabularyGrammarPracticePage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedItems = {};
  final Set<String> _selectedExerciseTypes = {};
  int _selectedQuestionCount = 10;

  final UserService _userService = UserService();
  final VocabularyService _vocabularyService = VocabularyService();
  final GrammarService _grammarService = GrammarService();
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic> _vocabularyData = {};
  Map<String, dynamic> _grammarData = {};
  bool _isLoading = true;
  Timer? _debounceTimer;
  Map<String, dynamic> _filteredVocabularyData = {};
  Map<String, dynamic> _filteredGrammarData = {};
  bool _isSearching = false;

  final Map<String, Map<String, dynamic>> _searchCache = {};
  

  // Add these new fields
  final Map<String, Map<String, dynamic>> _cachedVocabularyItems = {};
  final Map<String, Map<String, dynamic>> _cachedGrammarItems = {};
  bool _isItemsLoaded = false;

  List<ExerciseType> _exerciseTypes = [];
  List<int> _availableQuestionCounts = ExerciseType.defaultQuestionCounts;

  @override
  void initState() {
    super.initState();
    _exerciseTypes =
        ExerciseType.defaultTypes.map((e) => e.copyWith()).toList();
    _loadLearnedItems();
  }

  Future<void> _loadLearnedItems() async {
    try {
      setState(() => _isLoading = true);
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final vocabData = await _userService.getUserLearnedVocabulary(userId);
        final grammarData = await _userService.getUserLearnedGrammar(userId);

        // Pre-load all vocabulary and grammar items
        await Future.wait([
          _preloadVocabularyItems(vocabData ?? {}),
          _preloadGrammarItems(grammarData ?? {}),
        ]);

        setState(() {
          _vocabularyData = vocabData ?? {};
          _grammarData = grammarData ?? {};
          _isItemsLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading learned items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadVocabularyItems(Map<String, dynamic> vocabData) async {
    for (var entry in vocabData.entries) {
      final vocab = await _vocabularyService.getVocabularyById(entry.key);
      if (vocab != null) {
        _cachedVocabularyItems[entry.key] = vocab;
      }
    }
  }

  Future<void> _preloadGrammarItems(Map<String, dynamic> grammarData) async {
    for (var entry in grammarData.entries) {
      final grammar = await _grammarService.getGrammarById(entry.key);
      if (grammar != null) {
        _cachedGrammarItems[entry.key] = grammar;
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (_isLoading) return;

    setState(() => _isSearching = true);

    try {
      final normalizedQuery = query.trim().toLowerCase();

      // Check cache first
      if (_searchCache.containsKey(normalizedQuery)) {
        setState(() {
          _filteredVocabularyData = _searchCache[normalizedQuery]!['vocabulary']
              as Map<String, dynamic>;
          _filteredGrammarData =
              _searchCache[normalizedQuery]!['grammar'] as Map<String, dynamic>;
          _isSearching = false;
        });
        return;
      }

      if (normalizedQuery.isEmpty) {
        setState(() {
          _filteredVocabularyData = Map.from(_vocabularyData);
          _filteredGrammarData = Map.from(_grammarData);
          _isSearching = false;
        });
        return;
      }

      final matchedVocab = await _searchVocabulary(normalizedQuery);
      final matchedGrammar = await _searchGrammar(normalizedQuery);

      // Cache the results
      _searchCache[normalizedQuery] = {
        'vocabulary': matchedVocab,
        'grammar': matchedGrammar,
      };

      if (mounted) {
        setState(() {
          _filteredVocabularyData = matchedVocab;
          _filteredGrammarData = matchedGrammar;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error during search: $e');
    }
  }

  Future<Map<String, dynamic>> _searchVocabulary(String query) async {
    final Map<String, dynamic> matchedVocab = {};
    for (var entry in _vocabularyData.entries) {
      final vocab = await _vocabularyService.getVocabularyById(entry.key);
      if (vocab != null && _matchesVocabularySearch(vocab, query)) {
        matchedVocab[entry.key] = entry.value;
      }
    }
    return matchedVocab;
  }

  Future<Map<String, dynamic>> _searchGrammar(String query) async {
    final Map<String, dynamic> matchedGrammar = {};
    for (var entry in _grammarData.entries) {
      final grammar = await _grammarService.getGrammarById(entry.key);
      if (grammar != null && _matchesGrammarSearch(grammar, query)) {
        matchedGrammar[entry.key] = entry.value;
      }
    }
    return matchedGrammar;
  }

  bool _matchesVocabularySearch(Map<String, dynamic> vocab, String query) {
    return (vocab['englishWord']?.toString().toLowerCase() ?? '')
            .contains(query) ||
        (vocab['vietnameseWord']?.toString().toLowerCase() ?? '')
            .contains(query);
  }

  bool _matchesGrammarSearch(Map<String, dynamic> grammar, String query) {
    return (grammar['name']?.toString().toLowerCase() ?? '').contains(query) ||
        (grammar['description']?.toString().toLowerCase() ?? '')
            .contains(query);
  }

  void _handleExerciseTypeSelection(ExerciseType type) {
    if (type.isDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Other exercise types are disabled when Reading is selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (type.id == 'reading') {
        if (_selectedExerciseTypes.contains(type.id)) {
          // Unselecting reading
          _selectedExerciseTypes.remove(type.id);
          _exerciseTypes =
              ExerciseType.defaultTypes.map((e) => e.copyWith()).toList();
          _availableQuestionCounts = ExerciseType.defaultQuestionCounts;
          if (!_availableQuestionCounts.contains(_selectedQuestionCount)) {
            _selectedQuestionCount = _availableQuestionCounts[0];
          }
        } else {
          // Selecting reading
          _selectedExerciseTypes.clear();
          _selectedExerciseTypes.add(type.id);
          _exerciseTypes = _exerciseTypes
              .map((e) => e.copyWith(isDisabled: e.id != 'reading'))
              .toList();
          _availableQuestionCounts = ExerciseType.readingQuestionCounts;
          _selectedQuestionCount = _availableQuestionCounts[0];
        }
      } else if (!_selectedExerciseTypes.contains('reading')) {
        if (_selectedExerciseTypes.contains(type.id)) {
          _selectedExerciseTypes.remove(type.id);
        } else {
          _selectedExerciseTypes.add(type.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final double cardPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Vocabulary & Grammar Practice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchSection(
                    controller: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 24),
                  ItemsSection(
                    isLoading: _isLoading,
                    isItemsLoaded: _isItemsLoaded,
                    items: _buildLearnedItemsList(),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      childAspectRatio: isSmallScreen ? 0.9 : 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _exerciseTypes.length,
                    itemBuilder: (context, index) {
                      final type = _exerciseTypes[index];
                      final isSelected =
                          _selectedExerciseTypes.contains(type.id);
                      return ExerciseTypeCard(
                        type: type,
                        isSelected: isSelected,
                        isDisabled: type.isDisabled,
                        onTap: () => _handleExerciseTypeSelection(type),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  QuestionCountSection(
                    selectedCount: _selectedQuestionCount,
                    questionCounts: _availableQuestionCounts,
                    onCountSelected: (count) {
                      setState(() {
                        _selectedQuestionCount = count;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          ContinueButton(
            canContinue:
                _selectedItems.isNotEmpty && _selectedExerciseTypes.isNotEmpty,
            selectedItemsCount: _selectedItems.length,
            onPressed: () {
              navigateWithSlide(
                context,
                ExerciseSessionPage(
                  selectedItems: _selectedItems.toList(),
                  selectedExerciseTypes: _selectedExerciseTypes.toList(),
                  questionCount: _selectedQuestionCount,
                  vocabularyItems: _cachedVocabularyItems,
                  grammarItems: _cachedGrammarItems,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLearnedItemsList() {
    if (!_isItemsLoaded) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final List<Widget> items = [];
    final searchData = _isSearching || _searchController.text.isNotEmpty
        ? _filteredVocabularyData
        : _vocabularyData;
    final searchGrammarData = _isSearching || _searchController.text.isNotEmpty
        ? _filteredGrammarData
        : _grammarData;

    // Add vocabulary items
    for (var entry in searchData.entries) {
      final vocab = _cachedVocabularyItems[entry.key];
      if (vocab != null) {
        items.add(
          _buildListItem(
              entry.key,
              '${vocab['englishWord']} - ${vocab['vietnameseWord']}',
              'VOCABULARY',
              kVocabularyColor),
        );
      }
    }

    // Add grammar items
    for (var entry in searchGrammarData.entries) {
      final grammar = _cachedGrammarItems[entry.key];
      if (grammar != null) {
        items.add(
          _buildListItem(entry.key, grammar['name'], 'GRAMMAR', kPrimaryColor),
        );
      }
    }

    if (items.isEmpty && (_isSearching || _searchController.text.isNotEmpty)) {
      items.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No matching items found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildListItem(
      String key, String title, String type, Color typeColor) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        type,
        style: TextStyle(
          color: typeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      value: _selectedItems.contains(key),
      onChanged: (bool? value) {
        setState(() {
          if (value == true) {
            _selectedItems.add(key);
          } else {
            _selectedItems.remove(key);
          }
        });
      },
      activeColor: kPrimaryColor,
    );
  }

  @override
  void dispose() {
    _searchCache.clear();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
