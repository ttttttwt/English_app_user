import 'package:do_an_test/pages/lesson/lesson_content.dart';
import 'package:do_an_test/common/widget/navigation_animation.dart';
import 'package:flutter/material.dart';

class Lesson extends StatefulWidget {
  final String levelId;
  final String chapterId;
  final String lessonId;
  final String name;
  final bool secondBorder;
  final bool isCompleted;
  final double borderWidth;
  final int order;

  const Lesson({
    super.key,
    required this.lessonId,
    required this.name,
    this.secondBorder = false,
    this.isCompleted = false,
    this.borderWidth = 2,
    required this.levelId,
    required this.chapterId,
    required this.order,
  });

  @override
  State<Lesson> createState() => _LessonState();
}

class _LessonState extends State<Lesson> {
  bool _isLoading = false;

  Future<void> _handleLessonTap(BuildContext context) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      // Retrieve lesson content

      if (!mounted) return;

      // Navigate to lesson content screen by slide animation
      navigateWithSlide(
        context,
        LessonContent(
            lessonId: widget.lessonId,
            title: widget.name,
            levelId: widget.levelId,
            chapterId: widget.chapterId),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading lesson content: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final double paddingHorizontal = isSmallScreen ? 20 : 30;
        final double paddingVertical = isSmallScreen ? 15 : 20;
        final double imageSize = isSmallScreen ? 50 : 60;
        final double spacing = isSmallScreen ? 40 : 64;
        final double fontSize = isSmallScreen ? 14 : 16;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _isLoading ? null : () => _handleLessonTap(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: paddingHorizontal,
                  vertical: paddingVertical,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isCompleted
                      ? const LinearGradient(
                          colors: [
                            Color.fromRGBO(193, 243, 118, 0.2),
                            Color.fromRGBO(2, 235, 53, 0.2),
                          ],
                          stops: [0, 1],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  border: widget.secondBorder
                      ? Border.symmetric(
                          horizontal: _getBorderSide(),
                        )
                      : Border(top: _getBorderSide()),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLessonImage(imageSize),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lesson ${widget.order}:',
                            style: _getLessonTextStyle(fontSize),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.name,
                            style: _getLessonTextStyle(fontSize),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
            if (widget.isCompleted && !widget.secondBorder)
              Positioned(
                bottom: -widget.borderWidth,
                left: 0,
                right: 0,
                child: Container(
                  height: widget.borderWidth,
                  color: const Color.fromRGBO(2, 235, 53, 1),
                ),
              ),
          ],
        );
      },
    );
  }

  BorderSide _getBorderSide() => BorderSide(
        color: widget.isCompleted
            ? const Color.fromRGBO(2, 235, 53, 1)
            : const Color(0x332D3749),
        width: widget.borderWidth,
      );

  TextStyle _getLessonTextStyle(double fontSize) => TextStyle(
        color: const Color(0xFF2E4053),
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: 1,
      );

  Widget _buildLessonImage(double imageSize) => Container(
        width: imageSize,
        height: imageSize,
        decoration: const ShapeDecoration(
          image: DecorationImage(
            image: NetworkImage("https://via.placeholder.com/60x60"),
            fit: BoxFit.fill,
          ),
          shape: OvalBorder(
            side: BorderSide(
              width: 3,
              strokeAlign: BorderSide.strokeAlignOutside,
              color: Color(0x4C2E4053),
            ),
          ),
        ),
      );
}
