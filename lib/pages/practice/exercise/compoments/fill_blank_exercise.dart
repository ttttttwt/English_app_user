import 'package:do_an_test/services/exercise_generator.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'dart:async';

class FillBlankExercise extends StatefulWidget {
  final Exercise exercise;
  final Function(bool, String) onAnswered;

  const FillBlankExercise({
    super.key,
    required this.exercise,
    required this.onAnswered,
  });

  @override
  State<FillBlankExercise> createState() => _FillBlankExerciseState();
}

class _FillBlankExerciseState extends State<FillBlankExercise> {
  final TextEditingController _controller = TextEditingController();
  bool _hasSubmitted = false;
  bool? _isCorrect;

  @override
  void didUpdateWidget(FillBlankExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise != widget.exercise) {
      setState(() {
        _controller.clear();
        _hasSubmitted = false;
        _isCorrect = null;
      });
    }
  }

  void _checkAnswer() {
    if (_hasSubmitted) return;

    final userAnswer = _controller.text.trim();
    final correctAnswer = widget.exercise.data['answer'].toString().trim();
    
    final isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();

    setState(() {
      _isCorrect = isCorrect;
      _hasSubmitted = true;
    });

    // Delay to show feedback before moving to next question
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onAnswered(isCorrect, userAnswer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.exercise.data['question'],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type your answer here',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabled: !_hasSubmitted,
              fillColor: _getFillColor(),
              filled: _hasSubmitted,
              prefixIcon: _hasSubmitted
                  ? Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect! ? Colors.green : Colors.red,
                    )
                  : null,
            ),
            onSubmitted: (_) => !_hasSubmitted ? _checkAnswer() : null,
          ),
          const SizedBox(height: 16),
          if (_hasSubmitted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCorrect! 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isCorrect!
                    ? 'Correct! Well done! 🎉'
                    : 'The correct answer is: ${widget.exercise.data['answer']}',
                style: TextStyle(
                  color: _isCorrect! ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Spacer(),
          if (!_hasSubmitted)
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Answer',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Color _getFillColor() {
    if (!_hasSubmitted) return Colors.transparent;
    return _isCorrect! 
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
