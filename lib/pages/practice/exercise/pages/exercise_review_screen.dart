import 'package:do_an_test/pages/practice/exercise/pages/exercise_session_page.dart';
import 'package:flutter/material.dart';
import 'package:do_an_test/common/constant/const_value.dart';

class ExerciseReviewScreen extends StatelessWidget {
  final List<ExerciseResult> results;
  final double totalScore;
  final int totalQuestions;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const ExerciseReviewScreen({
    super.key,
    required this.results,
    required this.totalScore,
    required this.totalQuestions,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final averageScore = totalScore / totalQuestions;
    final correctCount = results.where((r) => r.isCorrect).length;

    return Column(
      children: [
        _buildScoreSummary(averageScore, correctCount),
        Expanded(
          child: _buildResultsList(),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildScoreSummary(double averageScore, int correctCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kPrimaryColor.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCard(
                'Total Score',
                '${totalScore.toStringAsFixed(1)}/${(totalQuestions * 10)}',
                Icons.star,
              ),
              _buildScoreCard(
                'Correct Answers',
                '$correctCount/$totalQuestions',
                Icons.check_circle,
              ),
              _buildScoreCard(
                'Average',
                '${averageScore.toStringAsFixed(1)}/10',
                Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final questionText = result.exercise.data['question']?.toString() ?? 
                           result.exercise.data['questions']?[0]?['data']?['question']?.toString() ?? 
                           'No question text available';
        final correctAnswer = result.exercise.data['answer']?.toString() ?? 
                            result.exercise.data['questions']?[0]?['data']?['answer']?.toString() ?? 
                            'No answer available';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              result.isCorrect ? Icons.check_circle : Icons.cancel,
              color: result.isCorrect ? Colors.green : Colors.red,
            ),
            title: Text('Question ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(questionText),
                if (!result.isCorrect && result.userAnswer != null) ...[
                  Text(
                    'Your answer: ${result.userAnswer}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  Text(
                    'Correct answer: $correctAnswer',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ],
            ),
            trailing: Text(
              '${result.score}/10',
              style: TextStyle(
                color: result.isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}