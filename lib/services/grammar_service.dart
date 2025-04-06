import '../common/constant/const_class.dart';

class GrammarService extends BaseFirestoreService {
  Future<Map<String, dynamic>?> getGrammarById(String grammarId) async {
    return getDocumentById(FirestoreCollections.grammar, grammarId);
  }

  Future<List<Map<String, dynamic>>> searchGrammar(String keyword) async {
    return searchDocuments(FirestoreCollections.grammar, 'name', keyword);
  }

  Future<List<Map<String, dynamic>>> getGrammarByLesson(String lessonId) async {
    try {
      final querySnapshot = await getCollection(FirestoreCollections.grammar)
          .where('lessonRef',
              isEqualTo: getDocument(FirestoreCollections.lessons, lessonId))
          .get();

      return querySnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }).toList();
    } catch (e) {
      throw Exception("Failed to get grammar by lesson: $e");
    }
  }
}
