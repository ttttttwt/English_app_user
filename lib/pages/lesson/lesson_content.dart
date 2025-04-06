import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_test/common/constant/const_class.dart';
import 'package:do_an_test/common/constant/const_value.dart';
import 'package:do_an_test/services/lesson_service.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:do_an_test/pages/lesson/compoment/multiple_choice_question.dart';
import 'package:do_an_test/pages/lesson/compoment/reading_comprehension.dart';
import 'package:do_an_test/pages/lesson/compoment/speaker.dart';
import 'package:do_an_test/pages/reviewpage/compoment/vocabulary_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class LessonContent extends StatefulWidget {
  final String lessonId;
  final String title;
  final String levelId;
  final String chapterId;

  const LessonContent({
    super.key,
    required this.lessonId,
    required this.title,
    required this.levelId,
    required this.chapterId,
  });

  @override
  _LessonContentState createState() => _LessonContentState();
}

class _LessonContentState extends State<LessonContent> {
  final _auth = auth.FirebaseAuth.instance;
  final UserService _userService = UserService();
  late LessonService _lessonService;

  List<Map<String, dynamic>> _lessonContent = [];
  int _currentContentIndex = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  late PageController _pageController;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _lessonService = LessonService();
    _pageController = PageController(initialPage: 0);
    _loadContent();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      final contents = await _lessonService.getLessonContent(widget.lessonId);
      if (mounted) {
        setState(() {
          _lessonContent = contents;
          _isLoading = false;
          // If only one content item, set _isFinished to true
          _isFinished = _lessonContent.length == 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: $e')),
        );
      }
    }
  }

  Future<void> _updateStatuses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _userService.updateLessonStatus(
        userId: userId,
        lessonId: widget.lessonId,
        newStatus: 'completed',
      );

      await _userService.updateLearnedItemsFromLessons(userId);

      await _userService.updateChapterStatusIfCompleted(
        userId: userId,
        chapterId: widget.chapterId,
      );
      await _userService.calculateAndUpdateLevelProgress(
          levelId: widget.levelId, userId: userId);
      await _userService.updateLevelStatusIfCompleted(
        userId: userId,
        levelId: widget.levelId,
      );
    } catch (e) {
      debugPrint('Error updating statuses: $e');
    }
  }

  void _handleContinue() {
    if (_isTransitioning) return;

    setState(() {
      _isTransitioning = true;
      if (_currentContentIndex < _lessonContent.length - 1) {
        _pageController
            .nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          setState(() {
            _currentContentIndex++;
            _isFinished = _currentContentIndex == _lessonContent.length - 1;
            _isTransitioning = false;
          });
        });
      } else {
        _isFinished = true;
        _updateStatuses();
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(193, 243, 118, 1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(46, 64, 83, 1), size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              color: const Color.fromRGBO(46, 64, 83, 1),
              iconSize: 30,
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Implement settings functionality
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add progress indicator
                LinearProgressIndicator(
                  value: (_currentContentIndex + 1) / _lessonContent.length,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),

                // Progress text
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Step ${_currentContentIndex + 1} of ${_lessonContent.length}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // Content area
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lessonContent.length,
                    itemBuilder: (context, index) {
                      final content = _lessonContent[index];
                      return _buildContentWidget(content);
                    },
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildContinueButton(),
                ),
              ],
            ),
    );
  }

  Widget _buildContentWidget(Map<String, dynamic> content) {
    try {
      final widget = switch (content['activity']) {
        'reading' => ReadingComprehension(
            text: content['text'] ?? '',
            textFontSize: 20.0,
            mediaData: MediaData(
                path: content['urlMedia'] ?? '',
                type: content['typeMedia'] == 'video'
                    ? MediaType.video
                    : MediaType.image,
                source: MediaSource.network),
          ),
        'vocabulary' => FutureBuilder<List<Map<String, dynamic>>>(
            future: content['vocabularyRefs'] != null
                ? _lessonService.getVocabulariesFromRefs(
                    (content['vocabularyRefs'] as List)
                        .map((ref) => ref as DocumentReference)
                        .toList(),
                  )
                : Future.value([
                    {
                      'english': content['description'],
                      'vietnamese': content['vietnamese'],
                      'mediaUrl': content['urlMedia'],
                      'typeMedia': content['typeMedia'],
                    }
                  ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No vocabulary data available'));
              }
              
              // Create a PageView for multiple vocabulary items
              return PageView.builder(
                itemCount: snapshot.data!.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final vocabData = snapshot.data![index];
                  return VocabularyPage(
                    english: vocabData['englishWord'] ?? '',
                    vietnamese: vocabData['vietnameseWord'] ?? '',
                    example: vocabData['exampleEnglish'] ?? '',
                    exampleTranslation: vocabData['exampleVietnamese'] ?? '',
                    mediaUrl: vocabData['mediaUrl'],
                    isVideo: vocabData['typeMedia'] == 'video',
                  );
                },
              );
            },
          ),
        'speaking' => Speaker(
            lessonText: content['text'] ?? '',
            mediaData: MediaData(
                path: content['urlMedia'] ?? '',
                type: content['typeMedia'] == 'video'
                    ? MediaType.video
                    : MediaType.image,
                source: MediaSource.network),
          ),
        'multichoice' => MultipleChoiceQuestion(
            mediaData: MediaData(
                path: content['urlMedia'] ?? '',
                type: content['typeMedia'] == 'video'
                    ? MediaType.video
                    : MediaType.image,
                source: MediaSource.network),
            question: content['question'] ?? '',
            options: (content['answer'] as List?)?.cast<String>() ?? [],
            onAnswer: (_) => _handleContinue(),
            correctAnswer: content['correctAnswer'] ?? '',
          ),
        _ => const Center(child: Text('Unknown activity type')),
      };

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: widget,
      );
    } catch (e) {
      return Center(
        child: Text('Error loading content: $e'),
      );
    }
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _handleContinue,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(16),
          ),
          child: Text(
            _isFinished ? 'Finish' : 'Continue',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
