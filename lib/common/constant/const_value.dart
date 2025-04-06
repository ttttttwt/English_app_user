import 'package:flutter/material.dart';

const kPrimaryColor = Color.fromRGBO(0, 128, 98, 1);
const kVocabularyColor = Color.fromRGBO(74, 144, 226, 1);
const kDefaultPadding = 16.0;

// Get API key from environment variable
const apiKey = String.fromEnvironment('GEMINI_API_KEY');

const String readingPromptTemplate = '''
You are an expert English teaching assistant. Generate a reading comprehension exercise following these specifications:

Context Parameters:
- Target Words: {{words}}
- Grammar Points: {{grammar}}
- Required Count: 1 reading exercise
- Order: {{start_order}}

STRICT OUTPUT REQUIREMENTS:

Reading Comprehension Exercise:
- Text length: 150-200 words exactly
- Must include:
  * 2-3 paragraphs
  * Natural integration of at least 2 target vocabulary words
  * Clear narrative or expository structure
  * Appropriate complexity for intermediate learners
  * 2 multiple choice questions và 2 fill-in-the-blank questions about the text

Structure must exactly match:
{
  "practices": [
    {
      "order": {{start_order}},
      "type": "reading",
      "data": {
        "text": "<engaging passage>",
        "highlight_words": ["<used target word 1>", "<used target word 2>", ...],
        "questions": [
          {
            "order": 1,
            "type": "multipleChoice",
            "data": {
              "question": "<question about the text>",
              "options": ["<option1>", "<option2>", "<option3>", "<option4>"],
              "answer": "<exact match with correct option>"
            }
          },
          {
            "order": 2,
            "type": "multipleChoice",
            "data": {
              "question": "<question about the text>",
              "options": ["<option1>", "<option2>", "<option3>", "<option4>"],
              "answer": "<exact match with correct option>"
            }
          },
          {
            "order": 3,
            "type": "multipleChoice",
            "data": {
              "question": "<question about the text>",
              "options": ["<option1>", "<option2>", "<option3>", "<option4>"],
              "answer": "<exact match with correct option>"
            }
          },
          {
            "order": 4,
            "type": "fillBlank",
            "data": {
              "question": "<sentence from text with ___ for blank>",
              "answer": "<correct word from text>"
            }
          },
          {
            "order": 5,
            "type": "fillBlank",
            "data": {
              "question": "<sentence from text with ___ for blank>",
              "answer": "<correct word from text>"
            }
          }
        ]
      }
    }
  ]
}

QUALITY CRITERIA:
1. Questions must test comprehension, not just vocabulary
2. Questions should cover different parts of the text
3. Multiple choice options must be plausible but clearly incorrect
4. Fill-in-blank questions should test key comprehension points
5. Text must naturally incorporate target vocabulary
6. All JSON must be valid with no missing fields

OUTPUT FORMAT: Return ONLY valid JSON. No explanations or additional text.
''';

const String defaultPromptTemplate = '''
You are an expert English teaching assistant. Generate precise, pedagogically sound exercises following these specifications:

Context Parameters:
- Target Words: {{words}}
- Grammar Points: {{grammar}}
- Exercise Types: {{practice_types}}
- Required Count: {{remaining}} new exercises
- Starting Order: {{start_order}}

STRICT OUTPUT REQUIREMENTS:

1. Multiple Choice Questions:
- Must have exactly 4 options
- One clearly correct answer
- Distractors should be plausible but unambiguously incorrect
- Question structure:
{
  "order": <number>,
  "type": "multipleChoice",
  "data": {
    "question": "<clear, concise question>",
    "options": ["<option1>", "<option2>", "<option3>", "<option4>"],
    "answer": "<exact match with correct option>"
  }
}

2. Fill in the Blank:
- Clear context clues
- Single, unambiguous correct answer
- Structure:
{
  "order": <number>,
  "type": "fillBlank",
  "data": {
    "question": "<sentence with ___ for blank>",
    "answer": "<single correct answer>"
  }
}

3. Speaking Practice:
- Natural model sentences for speaking practice
- Appropriate length (15-25 words) 
- Focus on clear pronunciation and natural speech rhythm
- Structure:
{
  "order": <number>,
  "type": "speaking",
  "data": {
    "text_to_speech": "<model sentence for user to repeat and practice>"
  }
}

QUALITY CRITERIA:
1. Exercises must progress in difficulty
2. Each exercise must use target vocabulary/grammar naturally
3. No duplicate or very similar exercises
4. All content must be appropriate for learners
5. Questions must be unambiguous
6. All JSON must be valid with no missing fields

OUTPUT FORMAT:
{
  "practices": [
    <exercise objects following above structures>
  ]
}

CRITICAL: Return ONLY valid JSON. No explanations or additional text.
''';

const chatPageSystemContext = '''
You are an AI assistant named Gemini. You are helpful, creative, clever, and very friendly.
You should:
1. Provide accurate and helpful information
2. Be conversational and engaging
3. Avoid harmful or inappropriate content
4. Express empathy and understanding
5. Be direct in your responses
6. Use markdown formatting when appropriate
7. Maintain a friendly and professional tone

If you're unsure about something, acknowledge the uncertainty and suggest alternatives or ask for clarification.
''';
