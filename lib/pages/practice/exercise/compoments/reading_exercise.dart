import 'package:do_an_test/services/exercise_generator.dart';
import 'package:flutter/material.dart';

class ReadingExercise extends StatefulWidget {
  final Exercise exercise;
  final Function(bool, [String?]) onAnswered;  // Modified callback signature

  const ReadingExercise({
    super.key,
    required this.exercise,
    required this.onAnswered,
  });

  @override
  State<ReadingExercise> createState() => _ReadingExerciseState();
}

class _ReadingExerciseState extends State<ReadingExercise> {
  int _currentQuestionIndex = 0;
  final List<bool?> _answers = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _fillBlankController = TextEditingController();
  final List<Map<String, dynamic>> _questionResults = [];

  // Add new controllers and cached data
  final Map<int, Widget> _cachedQuestions = {};
  late final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  late final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    final questions = widget.exercise.data['questions'] as List?;
    if (questions != null) {
      _answers.length = questions.length;
      // Initialize question results
      _questionResults.clear();
      for (var i = 0; i < questions.length; i++) {
        _questionResults.add({
          'question': questions[i],
          'isCorrect': false,
          'userAnswer': null,
        });
      }
    }
    
    // Pre-cache first question
    _cacheQuestion(0);
    
    // Listen to scroll progress
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void didUpdateWidget(ReadingExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when exercise changes
    if (oldWidget.exercise != widget.exercise) {
      setState(() {
        _currentQuestionIndex = 0;
        _answers.clear();
        _questionResults.clear();
        _cachedQuestions.clear();
        
        final questions = widget.exercise.data['questions'] as List?;
        if (questions != null) {
          _answers.length = questions.length;
          for (var i = 0; i < questions.length; i++) {
            _questionResults.add({
              'question': questions[i],
              'isCorrect': false,
              'userAnswer': null,
            });
          }
        }
      });
      
      // Pre-cache first question of new exercise
      _cacheQuestion(0);
    }
  }

  void _updateScrollProgress() {
    if (_scrollController.position.maxScrollExtent > 0) {
      _scrollProgress.value = _scrollController.offset / 
                            _scrollController.position.maxScrollExtent;
    }
  }

  Widget _buildReadingText() {
    final text = widget.exercise.data['text'] as String? ?? '';
    final highlightWords =
        widget.exercise.data['highlight_words'] as List? ?? [];

    List<TextSpan> spans = [];
    String remaining = text;

    for (String word in highlightWords) {
      final index = remaining.toLowerCase().indexOf(word.toLowerCase());
      if (index != -1) {
        if (index > 0) {
          spans.add(TextSpan(text: remaining.substring(0, index)));
        }
        spans.add(TextSpan(
          text: remaining.substring(index, index + word.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ));
        remaining = remaining.substring(index + word.length);
      }
    }

    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }

  Widget _buildQuestion() {
    final questions = widget.exercise.data['questions'] as List?;

    if (questions == null || questions.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    // Ensure current index is valid
    if (_currentQuestionIndex >= questions.length) {
      setState(() {
        _currentQuestionIndex = 0;
      });
    }

    final currentQuestion =
        questions[_currentQuestionIndex] as Map<String, dynamic>?;
    if (currentQuestion == null) {
      return const Center(child: Text('Invalid question format'));
    }

    final questionType = currentQuestion['type'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question ${_currentQuestionIndex + 1}/${questions.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        if (questionType == 'multipleChoice')
          _buildMultipleChoiceQuestion(currentQuestion['data'])
        else if (questionType == 'fillBlank')
          _buildFillBlankQuestion(currentQuestion['data']),
      ],
    );
  }

  Widget _buildQuestionWithCache() {
    if (_cachedQuestions.containsKey(_currentQuestionIndex)) {
      return _cachedQuestions[_currentQuestionIndex]!;
    }

    final widget = _buildQuestion();
    _cachedQuestions[_currentQuestionIndex] = widget;
    return widget;
  }

  void _cacheQuestion(int index) {
    if (!_cachedQuestions.containsKey(index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cachedQuestions[index] = _buildQuestion();
        }
      });
    }
  }

  Widget _buildMultipleChoiceQuestion(Map<String, dynamic> questionData) {
    final questionText = questionData['question'] as String? ?? '';
    final options = questionData['options'] as List? ?? [];
    final answer = questionData['answer'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          questionText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...options.map((option) {
          if (option == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () => _handleAnswer(option == answer, option.toString()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(option.toString())),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFillBlankQuestion(Map<String, dynamic> questionData) {
    final questionText = questionData['question'] as String? ?? '';
    final answer = questionData['answer'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          questionText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _fillBlankController,
          decoration: const InputDecoration(
            hintText: 'Type your answer here',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            final userAnswer = _fillBlankController.text.trim();
            final isCorrect = userAnswer.toLowerCase() == answer.toLowerCase();
            _handleAnswer(isCorrect, userAnswer);
            _fillBlankController.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Submit Answer'),
        ),
      ],
    );
  }

  void _handleAnswer(bool isCorrect, [String? userAnswer]) {
    if (_currentQuestionIndex >= _questionResults.length) {
      return;
    }

    // Store result for current question
    _questionResults[_currentQuestionIndex]['isCorrect'] = isCorrect;
    _questionResults[_currentQuestionIndex]['userAnswer'] = userAnswer;
    
    setState(() {
      _answers[_currentQuestionIndex] = isCorrect;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Correct!' : 'Incorrect'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentQuestionIndex < _questionResults.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        // Call onAnswered with overall exercise result
        final totalCorrect = _questionResults.where((r) => r['isCorrect'] as bool).length;
        final overallScore = totalCorrect / _questionResults.length;
        widget.onAnswered(overallScore >= 0.5, null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reading Progress Indicator
        ValueListenableBuilder<double>(
          valueListenable: _scrollProgress,
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 2,
            );
          },
        ),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    elevation: 2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildReadingText(),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    elevation: 2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildQuestionWithCache(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollProgress.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _fillBlankController.dispose();
    super.dispose();
  }
}
