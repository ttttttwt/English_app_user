import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_test/services/grammar_service.dart';
import 'package:do_an_test/services/lesson_service.dart';
import 'package:do_an_test/services/vocabulary_service.dart';
import 'package:do_an_test/common/constant/const_class.dart';

class UserService extends BaseFirestoreService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.users);
  final CollectionReference _usersLearnedCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.userLearned);
  final CollectionReference _userProgressCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.userProgress);
  final LessonService _lessonService = LessonService();
  final VocabularyService _vocabularyService = VocabularyService();
  final GrammarService _grammarService = GrammarService();

  // create user
  Future<void> createUser(
      {required String email,
      required String name,
      required String userId}) async {
    try {
      await _usersCollection.doc(userId).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await initializeUserData(userId);
    } catch (e) {
      throw Exception("Failed to create user: $e");
    }
  }

  // update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to update user: $e");
    }
  }

  // get user
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      return userDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception("Failed to get user: $e");
    }
  }

  // delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      await _usersLearnedCollection.doc(userId).delete();
      await _userProgressCollection.doc(userId).delete();
    } catch (e) {
      throw Exception("Failed to delete user: $e");
    }
  }

  // get user learned by user id
  Future<Map<String, dynamic>?> getUserLearned(String userId) async {
    try {
      final DocumentSnapshot userLearnedSnapshot =
          await _usersLearnedCollection.doc(userId).get();
      return userLearnedSnapshot.exists
          ? userLearnedSnapshot.data() as Map<String, dynamic>?
          : null;
    } catch (e) {
      throw Exception("Failed to get user learned: $e");
    }
  }

  // get user learned vocabulary by user id
  Future<Map<String, dynamic>?> getUserLearnedVocabulary(String userId) async {
    return _getUserLearnedField(userId, 'vocabulary');
  }

  // get user learned grammar by user id
  Future<Map<String, dynamic>?> getUserLearnedGrammar(String userId) async {
    return _getUserLearnedField(userId, 'grammar');
  }

  Future<Map<String, dynamic>?> _getUserLearnedField(
      String userId, String field) async {
    try {
      Map<String, dynamic>? result = await getUserLearned(userId);
      return result != null && result.containsKey(field)
          ? result[field] as Map<String, dynamic>?
          : null;
    } catch (e) {
      throw Exception("Failed to get user learned $field: $e");
    }
  }

  // get user progress by user id
  Future<Map<String, dynamic>?> getUserProgress(String userId) async {
    try {
      final DocumentSnapshot userProgressSnapshot =
          await _userProgressCollection.doc(userId).get();
      return userProgressSnapshot.exists
          ? userProgressSnapshot.data() as Map<String, dynamic>?
          : null;
    } catch (e) {
      throw Exception("Failed to get user progress: $e");
    }
  }

  // get completed lessons by user id
  Future<Map<String, List<String>>> getFilteredProgressByStatus(
      String userId, String desiredStatus) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        throw Exception("User progress not found for userId: $userId");
      }
      return {
        'levels': _filterItemsByStatus(
            userProgress['levels'] as Map<String, dynamic>?, desiredStatus),
        'chapters': _filterItemsByStatus(
            userProgress['chapters'] as Map<String, dynamic>?, desiredStatus),
        'lessons': _filterItemsByStatus(
            userProgress['lessons'] as Map<String, dynamic>?, desiredStatus),
      };
    } catch (e) {
      throw Exception("Failed to filter progress by status: $e");
    }
  }

  // Phương thức lọc levels, chapters, lessons theo status
  Future<List<String>> getFilteredItemsByStatus(
      String userId, String category, String desiredStatus) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        throw Exception("User progress not found for userId: $userId");
      }
      final items = userProgress[category] as Map<String, dynamic>?;
      return _filterItemsByStatus(items, desiredStatus);
    } catch (e) {
      throw Exception("Failed to filter $category by status: $e");
    }
  }

  Future<List<String>> getFilteredLevelsByStatus(
      String userId, String desiredStatus) {
    return getFilteredItemsByStatus(userId, 'levels', desiredStatus);
  }

  Future<List<String>> getFilteredChaptersByStatus(
      String userId, String desiredStatus) {
    return getFilteredItemsByStatus(userId, 'chapters', desiredStatus);
  }

  Future<List<String>> getFilteredLessonsByStatus(
      String userId, String desiredStatus) {
    return getFilteredItemsByStatus(userId, 'lessons', desiredStatus);
  }

  // Phương thức tìm progressPercentage của levels, chapters, lessons
  Future<Map<String, double>> getProgressPercentage(
      String userId, String category) async {
    try {
      final userProgress = await getUserProgress(userId);
      if (userProgress == null) {
        throw Exception("User progress not found for userId: $userId");
      }
      final items = userProgress[category] as Map<String, dynamic>?;
      if (items == null) return {};
      return items.map((key, value) {
        final percentage = value['progressPercentage']?.toDouble() ?? 0.0;
        return MapEntry(key, percentage);
      });
    } catch (e) {
      throw Exception("Failed to get $category progressPercentage: $e");
    }
  }

  Future<Map<String, double>> getLevelsProgressPercentage(String userId) {
    return getProgressPercentage(userId, 'levels');
  }

  Future<Map<String, double>> getChaptersProgressPercentage(String userId) {
    return getProgressPercentage(userId, 'chapters');
  }

  Future<Map<String, double>> getLessonsProgressPercentage(String userId) {
    return getProgressPercentage(userId, 'lessons');
  }

  Future<double?> getLevelProgressPercentage(
      String userId, String levelId) async {
    return _getItemProgressPercentage(userId, 'levels', levelId);
  }

  Future<double?> _getItemProgressPercentage(
      String userId, String category, String itemId) async {
    try {
      final userProgressSnapshot =
          await _userProgressCollection.doc(userId).get();
      if (userProgressSnapshot.exists) {
        final data = userProgressSnapshot.data() as Map<String, dynamic>;
        final items = data[category] as Map<String, dynamic>?;
        if (items != null && items.containsKey(itemId)) {
          final progress = items[itemId]['progressPercentage'];
          return progress?.toDouble();
        }
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get progressPercentage for $category: $e");
    }
  }

  Future<String?> getLessonStatus(String userId, String lessonId) async {
    return _getItemStatus(userId, 'lessons', lessonId);
  }

  Future<String?> getChapterStatus(String userId, String chapterId) async {
    return _getItemStatus(userId, 'chapters', chapterId);
  }

  Future<String?> _getItemStatus(
      String userId, String category, String itemId) async {
    try {
      final userProgressSnapshot =
          await _userProgressCollection.doc(userId).get();
      if (userProgressSnapshot.exists) {
        final data = userProgressSnapshot.data() as Map<String, dynamic>;
        final items = data[category] as Map<String, dynamic>?;
        if (items != null && items.containsKey(itemId)) {
          return items[itemId]['status'] as String?;
        }
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get status for $category $itemId: $e");
    }
  }

  Future<void> updateLevelStatus({
    required String userId,
    required String levelId,
    required String newStatus,
  }) async {
    await _updateItemStatus(userId, 'levels', levelId, newStatus);
  }

  Future<void> updateChapterStatus({
    required String userId,
    required String chapterId,
    required String newStatus,
  }) async {
    await _updateItemStatus(userId, 'chapters', chapterId, newStatus);
  }

  Future<void> updateLessonStatus({
    required String userId,
    required String lessonId,
    required String newStatus,
  }) async {
    await _updateItemStatus(userId, 'lessons', lessonId, newStatus);
  }

  Future<void> _updateItemStatus(
      String userId, String category, String itemId, String newStatus) async {
    try {
      final docRef = _userProgressCollection.doc(userId);
      await docRef.update({
        '$category.$itemId.status': newStatus,
      });
      await updateTimestamp(docRef, '$category.$itemId.lastAccessed');
    } catch (e) {
      throw Exception('Failed to update $category status: $e');
    }
  }

  Future<void> updateChapterStatusIfCompleted({
    required String userId,
    required String chapterId,
  }) async {
    await _updateItemStatusIfCompleted(userId, chapterId, 'lessons', 'chapters',
        _lessonService.getLessonsByChapter);
  }

  Future<void> updateLevelStatusIfCompleted({
    required String userId,
    required String levelId,
  }) async {
    await _updateItemStatusIfCompleted(userId, levelId, 'chapters', 'levels',
        _lessonService.getChaptersByLevel);
  }

  Future<void> _updateItemStatusIfCompleted(
      String userId,
      String parentId,
      String childCategory,
      String parentCategory,
      Future<List<dynamic>> Function(String) getChildren) async {
    try {
      final children = await getChildren(parentId);
      for (var child in children) {
        final childId = child.id;
        final userProgressSnapshot =
            await _userProgressCollection.doc(userId).get();
        final userProgress =
            userProgressSnapshot.data() as Map<String, dynamic>?;
        if (userProgress == null ||
            userProgress[childCategory] == null ||
            userProgress[childCategory][childId]['status'] != 'completed') {
          return;
        }
      }
      await _userProgressCollection.doc(userId).update({
        '$parentCategory.$parentId.status': 'completed',
        '$parentCategory.$parentId.lastAccessed': FieldValue.serverTimestamp(),
      });
      print('$parentCategory $parentId status updated to completed.');
    } catch (e) {
      throw Exception('Failed to update $parentCategory status: $e');
    }
  }

  Future<void> calculateAndUpdateLevelProgress({
    required String userId,
    required String levelId,
  }) async {
    try {
      final userProgressSnapshot =
          await _userProgressCollection.doc(userId).get();
      final userProgress = userProgressSnapshot.data() as Map<String, dynamic>?;
      if (userProgress == null) {
        throw Exception("User progress not found.");
      }
      final chapters = await _lessonService.getChaptersByLevel(levelId);
      if (chapters.isEmpty) {
        throw Exception("No chapters found for level $levelId.");
      }
      int totalChapters = chapters.length;
      int completedChapters = chapters.where((chapter) {
        final chapterId = chapter.id;
        final chapterProgress = userProgress['chapters']?[chapterId];
        return chapterProgress != null &&
            chapterProgress['status'] == 'completed';
      }).length;
      double progressPercentage = (completedChapters / totalChapters) * 100;
      final updatedLevelProgress = {
        'status': userProgress['levels']?[levelId]?['status'] ?? 'in-progress',
        'progressPercentage': progressPercentage,
        'lastAccessed': FieldValue.serverTimestamp(),
      };
      await _userProgressCollection.doc(userId).update({
        'levels.$levelId': updatedLevelProgress,
      });
      print('Level $levelId progress updated: $progressPercentage%.');
    } catch (e) {
      throw Exception("Failed to calculate and update level progress: $e");
    }
  }

  Future<void> initializeUserData(String userId) async {
    try {
      final progressData = {
        UserDataCategories.levels: {},
        UserDataCategories.chapters: {},
        UserDataCategories.lessons: {},
      };

      final learnedData = {
        UserDataCategories.grammar: {},
        UserDataCategories.vocabulary: {},
      };

      await setWithMerge(_userProgressCollection.doc(userId), progressData);
      await setWithMerge(_usersLearnedCollection.doc(userId), learnedData);
    } catch (e) {
      throw Exception('Failed to initialize user data: $e');
    }
  }

  Future<void> updateLearnedItemsFromLessons(String userId) async {
    try {
      final completedLessons =
          await getFilteredLessonsByStatus(userId, 'completed');
      print('Completed lessons: $completedLessons');
      await _updateLearnedItems(userId, completedLessons, 'vocabulary',
          _vocabularyService.getVocabulariesByLesson);
      await _updateLearnedItems(userId, completedLessons, 'grammar',
          _grammarService.getGrammarByLesson);
    } catch (e) {
      throw Exception('Failed to update learned items: $e');
    }
  }

  Future<void> _updateLearnedItems(
      String userId,
      List<String> completedLessons,
      String category,
      Future<List<Map<String, dynamic>>> Function(String)
          getItemsByLesson) async {
    try {
      final learnedItems = <Map<String, dynamic>>[];
      for (final lessonId in completedLessons) {
        final items = await getItemsByLesson(lessonId);
        learnedItems.addAll(items);
      }
      if (learnedItems.isEmpty) {
        print('No $category found for completed lessons.');
        return;
      }
      final userLearnedDoc = _usersLearnedCollection.doc(userId);
      final userLearnedSnapshot = await userLearnedDoc.get();
      final userLearnedData =
          userLearnedSnapshot.data() as Map<String, dynamic>? ?? {};
      final existingItems =
          userLearnedData[category] as Map<String, dynamic>? ?? {};
      final updatedItems = Map<String, dynamic>.from(existingItems);
      final learnedAt = FieldValue.serverTimestamp();
      for (final item in learnedItems) {
        final itemId = item['id'] as String?;
        if (itemId != null && !updatedItems.containsKey(itemId)) {
          updatedItems[itemId] = {
            'learnedAt': learnedAt,
            'memoryLevel': 'Basic'
          };
        }
      }
      if (updatedItems.length == existingItems.length) {
        print('No new $category to update for user $userId.');
        return;
      }
      await userLearnedDoc
          .set({category: updatedItems}, SetOptions(merge: true));
      print('$category learned items updated for user $userId.');
    } catch (e) {
      throw Exception('Failed to update $category learned: $e');
    }
  }
}

List<String> _filterItemsByStatus(
    Map<String, dynamic>? items, String desiredStatus) {
  if (items == null) return [];
  return items.entries
      .where((entry) => entry.value['status'] == desiredStatus)
      .map((entry) => entry.key)
      .toList();
}
