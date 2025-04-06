import 'package:do_an_test/common/constant/const_class.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class ReadingComprehension extends StatefulWidget {
  const ReadingComprehension({
    super.key,
    required this.text,
    this.textFontSize = 16.0,
    this.mediaData,
  });

  final String text;
  final double textFontSize;
  final MediaData? mediaData;

  @override
  State<ReadingComprehension> createState() => _ReadingComprehensionState();
}

class _ReadingComprehensionState extends State<ReadingComprehension> {
  static const double _aspectRatio = 3 / 2;
  static const Duration _animationDuration = Duration(milliseconds: 200);

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
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
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
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Read the text below:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (widget.mediaData != null) ...[
            _buildMediaContent(),
            const SizedBox(height: 24.0),
          ],
          _buildDivider(),
          const SizedBox(height: 24.0),
          Expanded(
            child: _buildReadingText(),
          ),
          const SizedBox(height: 56),
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

  Widget _buildReadingText() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.textFontSize,
            height: 1.5,
            color: Colors.black87,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
