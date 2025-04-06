import 'package:do_an_test/common/constant/const_class.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'dart:io';

class MultipleChoiceQuestion extends StatefulWidget {
  const MultipleChoiceQuestion({
    super.key,
    required this.question,
    required this.options,
    required this.onAnswer,
    required this.correctAnswer,
    this.mediaData,
    this.questionFontSize = 24.0,
    this.optionFontSize = 18.0,
  });

  final String question;
  final List<String> options;
  final Function(String) onAnswer;
  final String correctAnswer;
  final MediaData? mediaData;
  final double questionFontSize;
  final double optionFontSize;

  @override
  State<MultipleChoiceQuestion> createState() => _MultipleChoiceQuestionState();
}

class _MultipleChoiceQuestionState extends State<MultipleChoiceQuestion> {
  static const double _aspectRatio = 3 / 2;
  static const Duration _animationDuration = Duration(milliseconds: 200);
  static const _padding = EdgeInsets.all(16.0);
  static const _spacing = 24.0;
  static const _smallSpacing = 8.0;

  String? _selectedAnswer;
  bool _showResult = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isMediaLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    if (widget.mediaData?.type == MediaType.video) {
      await _initializeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_isMediaLoading || widget.mediaData == null) return;

    setState(() => _isMediaLoading = true);

    try {
      _videoController = _createVideoController();
      await _videoController?.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isMediaLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() => _isMediaLoading = false);
      }
    }
  }

  VideoPlayerController _createVideoController() {
    switch (widget.mediaData!.source) {
      case MediaSource.network:
        return VideoPlayerController.networkUrl(widget.mediaData!.path as Uri);
      case MediaSource.file:
        return VideoPlayerController.file(File(widget.mediaData!.path));
      case MediaSource.asset:
        return VideoPlayerController.asset(widget.mediaData!.path);
    }
  }

  // Media container widgets
  Widget _buildMediaContainer({required Widget child}) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  Widget _buildMediaLoadingIndicator() {
    return _buildMediaContainer(
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMediaErrorDisplay() {
    return _buildMediaContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Failed to load media', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // Image handling
  Widget _buildImageContent() {
    if (widget.mediaData == null) return const SizedBox.shrink();

    return _buildMediaContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    try {
      switch (widget.mediaData!.source) {
        case MediaSource.network:
          return Image.network(
            widget.mediaData!.path,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, loadingProgress) {
              return loadingProgress == null
                  ? child
                  : _buildMediaLoadingIndicator();
            },
            errorBuilder: (_, __, ___) => _buildMediaErrorDisplay(),
          );
        case MediaSource.file:
          return Image.file(
            File(widget.mediaData!.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildMediaErrorDisplay(),
          );
        case MediaSource.asset:
          return Image.asset(
            widget.mediaData!.path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildMediaErrorDisplay(),
          );
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return _buildMediaErrorDisplay();
    }
  }

  // Video handling
  Widget _buildVideoContent() {
    if (_isMediaLoading) return _buildMediaLoadingIndicator();
    if (!_isVideoInitialized || _videoController == null) {
      return _buildMediaErrorDisplay();
    }

    return _buildMediaContainer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
            _buildVideoControls(),
            _buildVideoProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned.fill(
      child: Center(
        child: AnimatedOpacity(
          opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
          duration: _animationDuration,
          child: IconButton(
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 50,
              color: Colors.white,
            ),
            onPressed: _toggleVideoPlayback,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoProgress() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: VideoProgressIndicator(
          _videoController!,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.blue,
            bufferedColor: Colors.grey[400]!,
            backgroundColor: Colors.grey[600]!,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  void _toggleVideoPlayback() {
    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  // Media content selection
  Widget _buildMediaContent() {
    return SizedBox(
      width: double.infinity,
      child: switch (widget.mediaData?.type) {
        MediaType.image => _buildImageContent(),
        MediaType.video => _buildVideoContent(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  // Existing UI methods
  // ...existing code...

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fill the question:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (widget.mediaData != null) ...[
            _buildMediaContent(),
            const SizedBox(height: _spacing),
          ],
          Text(
            widget.question,
            style: TextStyle(fontSize: widget.questionFontSize),
          ),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: _spacing),
          _buildOptions(),
          const SizedBox(height: _spacing),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: Colors.grey[300],
    );
  }

  Widget _buildOptions() {
    return Wrap(
      spacing: _smallSpacing,
      runSpacing: _smallSpacing,
      children: widget.options.map(_buildOptionButton).toList(),
    );
  }

  Widget _buildOptionButton(String option) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option.trim() == widget.correctAnswer;

    return IntrinsicWidth(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _getButtonColor(option, isSelected, isCorrect),
          foregroundColor: _getTextColor(option, isSelected),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onPressed: _showResult ? null : () => _handleAnswer(option),
        child: Text(
          option,
          style: TextStyle(fontSize: widget.optionFontSize),
        ),
      ),
    );
  }

  void _showFullscreenDialog(bool isCorrect) {
    // L���y kích thước màn hình
    final size = MediaQuery.of(context).size;

    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      barrierColor: Colors.transparent,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * animation.value,
            sigmaY: 5 * animation.value,
          ),
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // Bắt đầu từ dưới
                end: Offset.zero, // Kết thúc tại vị trí bình thường
              ).animate(animation),
              child: Container(
                color: Colors.black.withOpacity(0.3 * animation.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // Đẩy xuống bottom
                  children: [
                    Container(
                      width: size.width,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isCorrect ? 'Correct!' : 'Incorrect!',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? Colors.green : Colors.red,
                                decoration: TextDecoration.none),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, // Nút chiếm full width
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          // Thêm padding bottom để tránh safe area
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnswer(String option) {
    setState(() {
      _selectedAnswer = option;
      _showResult = true;
    });
    widget.onAnswer(option);
    _showFullscreenDialog(option == widget.correctAnswer);
  }

  Color _getButtonColor(String option, bool isSelected, bool isCorrect) {
    if (!_showResult) {
      return isSelected ? Colors.blue[100]! : Colors.grey[200]!;
    }
    if (option == _selectedAnswer) {
      return isCorrect ? Colors.blue : Colors.red;
    }
    return Colors.grey[200]!;
  }

  Color _getTextColor(String option, bool isSelected) {
    if (!_showResult) {
      return isSelected ? Colors.blue[900]! : Colors.black;
    }
    if (option == _selectedAnswer) {
      return Colors.white;
    }
    return Colors.black;
  }
}
