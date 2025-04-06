import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// Conversation UI Constants
class ConversationUI {
  static const Color primaryColor = Color(0xFF008062);
  static const Color cardBackgroundColor = Colors.white;

  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double borderRadius = 20.0;

  static const TextStyle headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheaderStyle = TextStyle(
    color: Colors.white70,
    fontSize: 14,
  );

  static const TextStyle roleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle messageStyle = TextStyle(
    fontSize: 16,
  );
}

// Common gradient for conversation pages
class AppGradients {
  static LinearGradient conversationBackground(Color startColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        startColor.withOpacity(0.05),
        Colors.white,
      ],
    );
  }
}

// models/exercise_type.dart
class ExerciseType {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final bool isDisabled;

  const ExerciseType({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    this.isDisabled = false,
  });

  ExerciseType copyWith({bool? isDisabled}) {
    return ExerciseType(
      id: id,
      title: title,
      icon: icon,
      description: description,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  static const readingType = ExerciseType(
    id: 'reading',
    title: 'Reading',
    icon: Icons.menu_book,
    description: 'Practice reading skills',
  );

  static List<ExerciseType> defaultTypes = [
    readingType,
    const ExerciseType(
      id: 'speaking',
      title: 'Speaking',
      icon: Icons.record_voice_over,
      description: 'Practice speaking skills',
    ),
    const ExerciseType(
      id: 'multiple_choice',
      title: 'Multiple Choice',
      icon: Icons.checklist,
      description: 'Practice reading and listening skills',
    ),
    const ExerciseType(
      id: 'fill_blank',
      title: 'Fill Blank',
      icon: Icons.format_list_bulleted,
      description: 'Practice vocabulary and grammar',
    ),
  ];

  static const readingQuestionCounts = [1, 2, 3, 4];
  static const defaultQuestionCounts = [3, 5, 7, 10];
}

// Enums moved to separate file for better organization
enum MediaType { none, image, video }

enum MediaSource { network, file, asset }

// Data class using freezed or equatable for immutability
class MediaData {
  final String path;
  final MediaType type;
  final MediaSource source;

  const MediaData({
    required this.path,
    required this.type,
    required this.source,
  });
}

// AI Service Configuration
class AIServiceConfig {
  static const String defaultModel = 'gemini-1.5-pro';

  static GenerationConfig defaultGenerationConfig = GenerationConfig(
    temperature: 0.7,
    topP: 0.8,
    topK: 40,
  );

  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxRetries = 3;
  static const int maxHistoryLength = 20;
  static const int maxCacheSize = 50;
  static const int oldestEntriesToRemove = 10;
}

// AI Service Constants
class AIServiceConstants {
  static const defaultSuggestionCount = 3;
  static const defaultSystemPrompt = chatPageSystemContext;

  // Suggestion prompt template
  static const suggestionPrompt = '''
Based on this conversation in {role}'s last message:
"{message}"

Generate 3 natural and appropriate response suggestions for the user.
Requirements:
1. Keep responses concise (1 sentence each)
2. Make them sound natural and conversational
3. Align with the topic: {topic}
4. Match the situation: {situation}
5. Help achieve the objective: {objective}
6. Vary in style and content
7. Include key phrases when relevant: {key_phrases}

Format: Return exactly 3 suggestions, one per line, no numbering or extra text.
''';

  static const List<String> defaultSuggestions = [
    'I understand.',
    'Could you explain that more?',
    'That sounds interesting.',
  ];
}

// Chat Service Utilities
class ChatServiceUtils {
  static List<Content> trimHistory(
      List<Content> history, Content systemContext) {
    if (history.length <= AIServiceConfig.maxHistoryLength) return history;

    final recentMessages = history.skip(history.length - 10).toList();
    return [systemContext, ...recentMessages];
  }

  static String generateContextSummary(List<Content> history) {
    if (history.length <= 1) return 'Starting new conversation';

    final recentMessages =
        history.skip(1).take(5).map((c) => c.parts.first.toString()).toList();
    return recentMessages.join(' -> ');
  }

  static String buildContextPrompt({
    required String role,
    required String topic,
    required Map<String, String> scenario,
    required String contextSummary,
    required String userMessage,
  }) {
    return '''
You are playing the role of: $role
Current Topic: $topic
Situation: ${scenario['situation']}
Objective: ${scenario['objective']}
Key Phrases to Include: ${scenario['key_phrases']}

Previous Context Summary: $contextSummary

Character Instructions:
1. Stay consistently in character as $role
2. Remember and reference previous parts of the conversation when relevant
3. Use appropriate tone and language for your role
4. Guide the conversation naturally towards the objective
5. React appropriately to user responses
6. Use key phrases when they fit naturally
7. Show personality while maintaining professionalism
8. Help users if they seem stuck or confused
9. Maintain conversation context and continuity

User Message: $userMessage
''';
  }
}

// Cache Keys
class CacheKeys {
  static const String scenarioCache = 'scenario_cache';
}

// Debug Utilities
void aiDebugPrint(String message) {
  assert(() {
    print('[AI Service] $message');
    return true;
  }());
}

// Firestore Collections
class FirestoreCollections {
  static const String vocabulary = 'vocabulary';
  static const String lessons = 'lessons';
  static const String levels = 'levels';
  static const String chapters = 'chapters';
  static const String grammar = 'grammar';
  static const String users = 'users';
  static const String userLearned = 'userLearned';
  static const String userProgress = 'userProgress';
}

class UserStatus {
  static const String completed = 'completed';
  static const String inProgress = 'in-progress';
  static const String basic = 'Basic';
}

class UserDataCategories {
  static const String levels = 'levels';
  static const String chapters = 'chapters';
  static const String lessons = 'lessons';
  static const String grammar = 'grammar';
  static const String vocabulary = 'vocabulary';
}

// Base Firestore Service
abstract class BaseFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference getCollection(String path) => _firestore.collection(path);
  DocumentReference getDocument(String collection, String docId) =>
      getCollection(collection).doc(docId);

  Future<Map<String, dynamic>?> getDocumentById(
      String collection, String docId) async {
    try {
      final doc = await getDocument(collection, docId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception("Failed to get document: $e");
    }
  }

  Future<List<Map<String, dynamic>>> searchDocuments(
      String collection, String field, String keyword) async {
    try {
      final querySnapshot = await getCollection(collection)
          .where(field, isGreaterThanOrEqualTo: keyword)
          .where(field, isLessThanOrEqualTo: '$keyword\uf8ff')
          .get();
      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw Exception("Failed to search documents: $e");
    }
  }

  Future<void> updateTimestamp(DocumentReference doc, String field) async {
    try {
      await doc.update({field: FieldValue.serverTimestamp()});
    } catch (e) {
      throw Exception('Failed to update timestamp: $e');
    }
  }

  Future<void> setWithMerge(
      DocumentReference doc, Map<String, dynamic> data) async {
    try {
      await doc.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to set with merge: $e');
    }
  }
}

// App Theme Configuration
class AppTheme {
  static const Color primaryColor = Color.fromRGBO(46, 64, 83, 1);
  static const Color surfaceColor = Color.fromRGBO(255, 255, 255, 1);
  static const Color seedColor = Color.fromRGBO(0, 128, 98, 1);

  static TextTheme get defaultTextTheme => const TextTheme(
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      );

  static ThemeData get defaultTheme => ThemeData(
        textTheme: defaultTextTheme,
        colorScheme: ColorScheme.fromSeed(
          primary: primaryColor,
          surface: surfaceColor,
          seedColor: seedColor,
        ),
      );
}

// Auth UI Constants
class AuthUI {
  static const double defaultPadding = 24.0;
  static const double buttonHeight = 15.0;
  static const double borderRadius = 30.0;
  static const double iconSize = 40.0;
  static const double avatarRadius = 40.0;
  
  static InputDecoration getInputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  static ButtonStyle defaultButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: buttonHeight),
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Auth Error Handler
class AuthErrorHandler {
  static String getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password provided';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}

enum ConversationState { uninitialized, newConversation, continuing }
