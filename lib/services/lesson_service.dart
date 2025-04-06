import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/constant/const_class.dart';

class LessonService extends BaseFirestoreService {
  Future<List<DocumentSnapshot>> getAllLevels() async {
    try {
      final QuerySnapshot levelsSnapshot = await getCollection(FirestoreCollections.levels)
          .orderBy('order')
          .get();
      return levelsSnapshot.docs;
    } catch (e) {
      throw Exception("Failed to get levels: $e");
    }
  }

  Future<Map<String, dynamic>?> getLevelById(String levelId) async {
    return getDocumentById(FirestoreCollections.levels, levelId);
  }

  // get chapter by level reference
  Future<List<DocumentSnapshot>> getChaptersByLevel(String levelId) async {
    try {
      // Lấy DocumentReference cho level dựa trên levelId
      final DocumentReference levelRef = getDocument(FirestoreCollections.levels, levelId);

      // Truy vấn chapter dựa trên levelId là reference
      final QuerySnapshot chaptersSnapshot =
          await getCollection(FirestoreCollections.chapters).where('levelId', isEqualTo: levelRef).get();
      return chaptersSnapshot.docs;
    } catch (e) {
      throw Exception("Failed to get chapters: $e");
    }
  }

  Future<List<DocumentSnapshot>> getLessonsByChapter(String chapterId) async {
    try {
      final DocumentReference chapterRef = getDocument(FirestoreCollections.chapters, chapterId);
      final QuerySnapshot lessonsSnapshot = await getCollection(FirestoreCollections.lessons)
          .where('chapterId', isEqualTo: chapterRef)
          .orderBy('order')
          .get();
      return lessonsSnapshot.docs;
    } catch (e) {
      throw Exception("Failed to get lessons: $e");
    }
  }

  Future<Map<String, dynamic>?> getLessonById(String lessonId) async {
    return getDocumentById(FirestoreCollections.lessons, lessonId);
  }

  // Phương thức lấy danh sách nội dung (content) của bài học
  Future<List<Map<String, dynamic>>> getLessonContent(String lessonId) async {
    try {
      final DocumentSnapshot lessonSnapshot =
          await getDocument(FirestoreCollections.lessons, lessonId).get();

      if (!lessonSnapshot.exists) {
        throw Exception('Lesson with ID $lessonId not found.');
      }

      final QuerySnapshot contentSnapshot = await getCollection(FirestoreCollections.lessons)
          .doc(lessonId)
          .collection('content')
          .orderBy('order')
          .get();

      return contentSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final activity = data['activity'] as String;

        // Base content fields common to all activities
        final Map<String, dynamic> contentMap = {
          'order': data['order'] as int,
          'activity': activity,
          'description': data['description'],
          'typeMedia': data['typeMedia'],
          'urlMedia': data['urlMedia'],
        };

        // Add specific fields based on activity type
        switch (activity) {
          case 'vocabulary':
            contentMap['vocabularyRefs'] = data['vocabularyRefs'];
            break;
          case 'multichoice':
            contentMap['question'] = data['question'];
            // Handle the answer field properly
            if (data['answer'] is String) {
              // If it's a string, split it into a list
              contentMap['answer'] = (data['answer'] as String).split(', ');
            } else if (data['answer'] is List) {
              // If it's already a list, use it as is
              contentMap['answer'] = data['answer'];
            } else {
              // Fallback to empty list if neither
              contentMap['answer'] = <String>[];
            }
            contentMap['correctAnswer'] = data['correctAnswer'];
            break;
          case 'speaking':
            contentMap['text'] = data['text'];
            break;
          case 'reading':
            contentMap['text'] = data['text'];
            break;
          default:
            debugPrint('Unknown activity type: $activity');
        }

        return contentMap;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch content for lesson $lessonId: $e');
    }
  }

  Future<Map<String, dynamic>> getVocabularyFromRef(
      DocumentReference ref) async {
    try {
      final DocumentSnapshot vocabDoc = await ref.get();
      if (!vocabDoc.exists) {
        throw Exception('Vocabulary reference not found');
      }
      return vocabDoc.data() as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to fetch vocabulary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getVocabulariesFromRefs(
      List<DocumentReference> refs) async {
    try {
      List<Map<String, dynamic>> vocabularies = [];
      for (var ref in refs) {
        final vocab = await getVocabularyFromRef(ref);
        vocabularies.add(vocab);
      }
      return vocabularies;
    } catch (e) {
      throw Exception('Failed to fetch vocabularies: $e');
    }
  }
}
