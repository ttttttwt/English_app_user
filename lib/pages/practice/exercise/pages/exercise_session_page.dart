// exercise_session_page.dart
import 'package:do_an_test/pages/practice/exercise/pages/exercise_review_screen.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/fill_blank_exercise.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/multiple_choice_exercise.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/reading_exercise.dart';
import 'package:do_an_test/pages/practice/exercise/compoments/speaking_exercise.dart';
import 'package:do_an_test/services/exercise_generator.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'dart:async';

class ExerciseSessionPage extends StatefulWidget {
  final List<String> selectedItems;
  final List<String> selectedExerciseTypes;
  final int questionCount;
  final Map<String, Map<String, dynamic>> vocabularyItems;
  final Map<String, Map<String, dynamic>> grammarItems;

  const ExerciseSessionPage({
    super.key,
    required this.selectedItems,
    required this.selectedExerciseTypes,
    required this.questionCount,
    required this.vocabularyItems,
    required this.grammarItems,
  });

  @override
  State<ExerciseSessionPage> createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  late ExerciseGenerator _exerciseGenerator;
  List<Exercise> _exercises = [];
  bool _isLoading = true;
  String? _error;
  int _currentExerciseIndex = 0;

  // Add new state variables
  final List<ExerciseResult> _results = [];
  double _currentScore = 0;
  bool _isReviewMode = false;

  @override
  void initState() {
    super.initState();
    _exerciseGenerator = ExerciseGenerator(apiKey);
    _generateExercises();
  }

  Future<void> _generateExercises() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Prepare metadata for exercise generation
      final metadata = _prepareMetadata();

      final exercises = await _exerciseGenerator.generateExercises(metadata);

      if (exercises['practices'] != null) {
        setState(() {
          _exercises = (exercises['practices'] as List)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

        // Save exercises for offline access
        await saveExercises(
          exercises,
          'session_${DateTime.now().millisecondsSinceEpoch}.json',
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to generate exercises: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _prepareMetadata() {
    // Extract vocabulary and grammar words
    final words = <String>[];
    final grammar = <String>[];

    for (final itemId in widget.selectedItems) {
      if (widget.vocabularyItems.containsKey(itemId)) {
        final vocab = widget.vocabularyItems[itemId]!;
        words.add('${vocab['englishWord']}');
      } else if (widget.grammarItems.containsKey(itemId)) {
        final grammarItem = widget.grammarItems[itemId]!;
        grammar.add(grammarItem['name']);
      }
    }

    // Convert exercise types to PracticeType enum
    final practiceTypes = widget.selectedExerciseTypes.map((type) {
      switch (type) {
        case 'multiple_choice':
          return PracticeType.multipleChoice;
        case 'fill_blank':
          return PracticeType.fillBlank;
        case 'speaking':
          return PracticeType.speaking;
        case 'reading':
          return PracticeType.reading;
        default:
          return PracticeType.multipleChoice;
      }
    }).toList();

    print('words: $words');
    print('grammar: $grammar');
    print('practice_types: $practiceTypes');
    print('num_of_practice: ${widget.questionCount}');

    return {
      'words': words,
      'grammar': grammar,
      'practice_types': practiceTypes,
      'num_of_practice': widget.questionCount,
    };
  }

  Widget _buildExerciseView(Exercise exercise) {
    switch (exercise.type) {
      case 'multipleChoice':
        return MultipleChoiceExercise(
          exercise: exercise,
          onAnswered: _handleAnswer,
        );
      case 'fillBlank':
        return FillBlankExercise(
          exercise: exercise,
          onAnswered: _handleAnswer,
        );
      case 'speaking':
        return SpeakingExercise(
          exercise: exercise,
          onAnswered: _handleAnswer,
        );
      case 'reading':
        return ReadingExercise(
          exercise: exercise,
          onAnswered: _handleAnswer,
        );
      default:
        return const Center(
          child: Text('Unsupported exercise type'),
        );
    }
  }

  void _handleAnswer(bool isCorrect, [String? userAnswer]) {
    final currentExercise = _exercises[_currentExerciseIndex];
    final isReading = currentExercise.type == 'reading';
    
    // Calculate score for this exercise
    final score = _calculateScore(isCorrect, userAnswer);

    // Store result
    _results.add(ExerciseResult(
      exercise: currentExercise,
      isCorrect: isCorrect,
      score: score,
      userAnswer: userAnswer,
    ));

    // Update total score
    _currentScore += score;

    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      _showResultsScreen();
    }
  }

  double _calculateScore(bool isCorrect, [String? userAnswer]) {
    if (!isCorrect) return 0;

    final exercise = _exercises[_currentExerciseIndex];
    switch (exercise.type) {
      case 'multipleChoice':
        return 10.0; // Full score for correct multiple choice
      case 'fillBlank':
        // Calculate similarity score for fill-in-blank
        if (userAnswer != null) {
          return _calculateSimilarityScore(
                  userAnswer, exercise.data['answer'].toString()) *
              10;
        }
        return 0;
      default:
        return isCorrect ? 10.0 : 0;
    }
  }

  double _calculateSimilarityScore(String userAnswer, String correctAnswer) {
    // Implement Levenshtein distance or similar algorithm
    // Simplified version for now
    final normalizedUser = userAnswer.toLowerCase().trim();
    final normalizedCorrect = correctAnswer.toLowerCase().trim();
    return normalizedUser == normalizedCorrect ? 1.0 : 0.0;
  }

  void _showResultsScreen() {
    setState(() => _isReviewMode = true);
  }

  void _retryExercises() {
    setState(() {
      _currentExerciseIndex = 0;
      _results.clear();
      _currentScore = 0;
      _isReviewMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Practice Session',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isReviewMode
          ? ExerciseReviewScreen(
              results: _results,
              totalScore: _currentScore,
              totalQuestions: _exercises.length,
              onRetry: _retryExercises,
              onContinue: () => Navigator.pop(context),
            )
          : _buildExerciseBody(),
    );
  }

  Widget _buildExerciseBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating exercises...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateExercises,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return const Center(
        child: Text('No exercises available'),
      );
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentExerciseIndex + 1) / _exercises.length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Question ${_currentExerciseIndex + 1} of ${_exercises.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _exercises[_currentExerciseIndex].type == 'reading'
              ? ReadingExercise(
                  exercise: _exercises[_currentExerciseIndex],
                  onAnswered: _handleAnswer,
                )
              : _buildExerciseView(_exercises[_currentExerciseIndex]),
        ),
      ],
    );
  }
}

class ExerciseResult {
  final Exercise exercise;
  final bool isCorrect;
  final double score;
  final String? userAnswer;

  ExerciseResult({
    required this.exercise,
    required this.isCorrect,
    required this.score,
    this.userAnswer,
  });
}
