// chapter.dart
import 'package:do_an_test/services/lesson_service.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_test/pages/hompage/compoment/lesson.dart';

class Chapter extends StatefulWidget {
  final String levelId;
  final String chapterId;
  final String name;
  final String? userId;

  const Chapter({
    super.key,
    required this.levelId,
    required this.chapterId,
    required this.name,
    this.userId,
  });

  @override
  State<Chapter> createState() => _ChapterState();
}

class _ChapterState extends State<Chapter> {
  final LessonService _lessonService = LessonService();
  final UserService _userService = UserService();
  List<DocumentSnapshot> _lessons = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  bool _isCompleted = false;
  List<String>? _userProgress;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final loadedLessons = await _lessonService.getLessonsByChapter(
        widget.chapterId,
      );

      if (widget.userId != null) {
        _userProgress = await _userService.getFilteredLessonsByStatus(
            widget.userId!, 'completed');
        _isCompleted = (await _userService.getChapterStatus(
                    widget.userId!, widget.chapterId)) ==
                'completed'
            ? true
            : false;
      }

      if (mounted) {
        setState(() {
          _lessons = loadedLessons;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lessons: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chapter ${widget.chapterId.split('_').last}: ${widget.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                _isCompleted ? const Color(0xFF008062) : null,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    final lessonData = lesson.data() as Map<String, dynamic>;

                    return Lesson(
                      chapterId: widget.chapterId,
                      levelId: widget.levelId,
                      lessonId: lesson.id,
                      name: lessonData['name'] ?? '',
                      order: lessonData['order'] ?? 0,
                      isCompleted: _userProgress?.contains(lesson.id) ?? false,
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
