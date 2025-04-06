import 'package:do_an_test/services/lesson_service.dart';
import 'package:do_an_test/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_test/pages/hompage/compoment/chapter.dart';
import 'package:do_an_test/pages/hompage/compoment/process_line.dart';

class Level extends StatefulWidget {
  final String levelId;
  final String? userId;
  final int order;

  const Level({
    super.key,
    required this.levelId,
    this.userId,
    required this.order,
  });

  @override
  State<Level> createState() => _LevelState();
}

class _LevelState extends State<Level> {
  final LessonService _lessonService = LessonService();
  final UserService _userService = UserService();
  List<DocumentSnapshot> _chapters = [];
  Map<String, dynamic>? _levelData;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isCollapsed = false;
  final int _totalLessons = 0;

  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    try {
      setState(() => _isLoading = true);

      // Load chapters and level data
      final futures = <Future>[
        _lessonService.getChaptersByLevel(widget.levelId),
        _lessonService.getLevelById(widget.levelId),
      ];

      if (widget.userId != null) {
        futures.add(_userService.getLevelProgressPercentage(
            widget.userId!, widget.levelId));
      }

      final results = await Future.wait(futures);

      _chapters = results[0] as List<DocumentSnapshot>;
      _levelData = results[1] as Map<String, dynamic>?;

      if (results.length > 2) {
        _progress = results[2] ?? 0.0;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading level data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${widget.order}: ${_levelData?['name'] ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Lessons: $_totalLessons',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: AnimatedRotation(
                  turns: _isCollapsed ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
                onPressed: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProcessLine(progress: _progress),
          AnimatedCrossFade(
            firstChild: const SizedBox(
              height: 0,
            ),
            secondChild: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final chapterData = chapter.data() as Map<String, dynamic>;

                    return Chapter(
                      levelId: widget.levelId,
                      chapterId: chapter.id,
                      name: chapterData['name'] ?? '',
                      userId: widget.userId,
                    );
                  },
                ),
              ],
            ),
            crossFadeState: _isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
