// First, let's define our models
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:do_an_test/common/constant/const_value.dart';

enum PracticeType { multipleChoice, fillBlank, speaking, reading }

class Exercise {
  final int order;
  final String type;
  final Map<String, dynamic> data;

  Exercise({
    required this.order,
    required this.type,
    required this.data,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      order: json['order'],
      type: json['type'],
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'type': type,
      'data': data,
    };
  }
}

class ExerciseGenerator {
  final GenerativeModel model;

  // Templates as static const strings

  ExerciseGenerator(String apiKey)
      : model = GenerativeModel(
          model: 'gemini-1.5-pro',
          apiKey: apiKey,
          // Add configuration parameters
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: 8192,
          ),
        );

  bool _validateExerciseStructure(Map<String, dynamic> exercise) {
    try {
      final requiredFields = {
        'multipleChoice': ['question', 'options', 'answer'],
        'fillBlank': ['question', 'answer'],
        'speaking': ['text_to_speech'],
        'reading': ['text', 'highlight_words', 'questions']
      };

      if (!exercise.containsKey('order') ||
          !exercise.containsKey('type') ||
          !exercise.containsKey('data')) {
        return false;
      }

      final type = exercise['type'];
      if (!requiredFields.containsKey(type)) {
        return false;
      }

      final data = exercise['data'] as Map<String, dynamic>;
      final required = requiredFields[type]!;

      if (!required.every((field) => data.containsKey(field))) {
        return false;
      }

      if (type == 'multipleChoice') {
        final options = data['options'] as List;
        if (options.length != 4 || !options.contains(data['answer'])) {
          return false;
        }
      }

      if (type == 'reading') {
        if (data['questions'] is! List) return false;
        final text = data['text'] as String;
        final wordCount = text.split(' ').length;
        if (wordCount < 250 || wordCount > 300) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  String _cleanResponse(String text) {
    // Remove code blocks
    text = text.replaceAll(RegExp(r'```json\s*'), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');

    try {
      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}') + 1;

      if (startIndex == -1 || endIndex == -1) {
        throw Exception('Could not find valid JSON structure in response');
      }

      text = text.substring(startIndex, endIndex);
      // Normalize quotes
      text = text.replaceAll(RegExp(r'(?<!\\)"'), '"');
      // Remove unwanted characters
      text = text.replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');

      return text;
    } catch (e) {
      throw Exception('Could not find valid JSON structure in response');
    }
  }

  Future<Map<String, dynamic>> generateReadingExercise(
    Map<String, dynamic> metadata,
    int startOrder,
  ) async {
    try {
      final prompt = readingPromptTemplate
          .replaceAll('{{words}}', (metadata['words'] as List).join(', '))
          .replaceAll('{{grammar}}', (metadata['grammar'] as List).join(', '))
          .replaceAll('{{start_order}}', startOrder.toString());

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final cleanedResponse = _cleanResponse(response.text ?? '');
      return json.decode(cleanedResponse) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error generating reading exercise: $e');
    }
  }

  bool _isSinglePracticeType(List practiceTypes) {
    return practiceTypes.length == 1;
  }

  Future<Map<String, dynamic>> generateExercises(
    Map<String, dynamic> metadata,
  ) async {
    final targetCount = metadata['num_of_practice'] as int;
    final exercises = {'practices': <Map<String, dynamic>>[]};
    const maxAttempts = 5;
    var attempt = 0;

    final practiceTypes = metadata['practice_types'] as List;
    var currentTypeIndex = 0;
    final isSingleType = _isSinglePracticeType(practiceTypes);

    while (exercises['practices']!.length < targetCount && attempt < maxAttempts) {
      try {
        final remaining = targetCount - exercises['practices']!.length;
        final currentStart = exercises['practices']!.length + 1;
        final currentType = practiceTypes[currentTypeIndex];

        if (currentType == PracticeType.reading) {
          // Generate multiple reading exercises based on remaining count
          for (var i = 0; i < remaining; i++) {
            final readingExercise = await generateReadingExercise(
              metadata,
              currentStart + i,
            );

            if (readingExercise.containsKey('practices')) {
              final practicesList = (readingExercise['practices'] as List)
                  .map((practice) => practice as Map<String, dynamic>)
                  .toList();
              exercises['practices']!.addAll(practicesList);
            }
            
            // Add delay between generations
            if (i < remaining - 1) {
              await Future.delayed(const Duration(seconds: 1));
            }
          }
        } else {
          final generationMetadata = Map<String, dynamic>.from(metadata)
            ..['remaining'] = remaining
            ..['start_order'] = currentStart
            // For single type, keep using only that type
            ..['practice_types'] = isSingleType 
                ? [currentType] 
                : metadata['practice_types'];

          final prompt = generatePrompt(generationMetadata);
          final content = [Content.text(prompt)];
          final response = await model.generateContent(content);

          final cleanedResponse = _cleanResponse(response.text ?? '');
          final newExercises = json.decode(cleanedResponse) as Map<String, dynamic>;

          if (newExercises.containsKey('practices')) {
            final newPracticesList = (newExercises['practices'] as List)
                .map((practice) => practice as Map<String, dynamic>)
                .toList();

            // Filter exercises to keep only the requested type when in single type mode
            final filteredPractices = isSingleType
                ? newPracticesList.where((p) => p['type'] == currentType.toString().split('.').last).toList()
                : newPracticesList;

            exercises['practices'] = _mergeExercises(
              exercises['practices'] as List<Map<String, dynamic>>,
              filteredPractices,
            );
          }
        }

        // Only rotate practice types if using multiple types
        if (!isSingleType) {
          currentTypeIndex = (currentTypeIndex + 1) % practiceTypes.length;
        }

        if (exercises['practices']!.length >= targetCount) {
          exercises['practices'] = exercises['practices']!.sublist(0, targetCount);
          break;
        }

        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('Attempt ${attempt + 1} failed: $e');
        attempt++;
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }
    }

    if (exercises['practices']!.length < targetCount) {
      throw Exception(
        'Generated only ${exercises['practices']!.length}/$targetCount exercises after $maxAttempts attempts',
      );
    }

    return exercises;
  }

  List<Map<String, dynamic>> _mergeExercises(
    List<Map<String, dynamic>> existingExercises,
    List<Map<String, dynamic>> newExercises,
  ) {
    final seenQuestions = <String>{};
    final merged = <Map<String, dynamic>>[];

    String getExerciseKey(Map<String, dynamic> exercise) {
      final data = exercise['data'] as Map<String, dynamic>;
      if (exercise['type'] == 'reading') {
        return 'reading_${data['text'].hashCode}';
      }
      return json.encode(data);
    }

    for (final exercise in [...existingExercises, ...newExercises]) {
      if (_validateExerciseStructure(exercise)) {
        final key = getExerciseKey(exercise);
        if (!seenQuestions.contains(key)) {
          seenQuestions.add(key);
          merged.add(exercise);
        }
      }
    }

    // Reorder
    for (var i = 0; i < merged.length; i++) {
      merged[i]['order'] = i + 1;
    }

    return merged;
  }

  String generatePrompt(Map<String, dynamic> metadata) {
    try {
      final prompt = metadata['prompt_template'] ?? defaultPromptTemplate;
      return prompt
          .replaceAll('{{words}}', (metadata['words'] as List).join(', '))
          .replaceAll('{{grammar}}', (metadata['grammar'] as List).join(', '))
          .replaceAll(
            '{{practice_types}}',
            (metadata['practice_types'] as List).join(', '),
          )
          .replaceAll(
            '{{remaining}}',
            (metadata['remaining'] ?? metadata['num_of_practice']).toString(),
          )
          .replaceAll(
            '{{start_order}}',
            (metadata['start_order'] ?? 1).toString(),
          );
    } catch (e) {
      throw Exception('Error generating prompt: $e');
    }
  }
}

Future<void> saveExercises(
    Map<String, dynamic> exercises, String filename) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(json.encode(exercises), flush: true);
  } catch (e) {
    debugPrint('Error saving exercises: $e');
    // Backup save attempt
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/$filename.backup');
      await backupFile.writeAsString(json.encode(exercises), flush: true);
      debugPrint('Exercises saved to backup file: ${backupFile.path}');
    } catch (backupError) {
      debugPrint('Backup save also failed: $backupError');
    }
  }
}
