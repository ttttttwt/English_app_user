import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/constant/const_class.dart';

class VocabularyService extends BaseFirestoreService {
  final CollectionReference _vocabularyCollection =
      FirebaseFirestore.instance.collection(FirestoreCollections.vocabulary);

  Future<Map<String, dynamic>?> getVocabularyById(String vocabularyId) async {
    return getDocumentById(FirestoreCollections.vocabulary, vocabularyId);
  }

  Future<List<Map<String, dynamic>>> searchVocabulary(String keyword) async {
    return searchDocuments(
        FirestoreCollections.vocabulary, 'englishWord', keyword);
  }

  Future<List<Map<String, dynamic>>> getVocabulariesByLesson(
      String lessonId) async {
    try {
      final querySnapshot = await _vocabularyCollection
          .where('lessonRef',
              isEqualTo: getDocument(FirestoreCollections.lessons, lessonId))
          .get();

      return querySnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }).toList();
    } catch (e) {
      throw Exception("Failed to get vocabularies by lesson: $e");
    }
  }
}
