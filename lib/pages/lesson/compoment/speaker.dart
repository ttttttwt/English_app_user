import 'package:do_an_test/common/constant/const_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class Speaker extends StatefulWidget {
  final String lessonText;
  final MediaData? mediaData;
  final ValueChanged<String?>? onRecordingComplete;
  final VoidCallback? onSkip;

  // Using const constructor for better performance
  const Speaker({
    super.key,
    required this.lessonText,
    this.mediaData,
    this.onRecordingComplete,
    this.onSkip,
  });

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {
  // Constants moved to static final for better memory management
  static const double _aspectRatio = 3 / 2;
  static const Duration _animationDuration = Duration(milliseconds: 200);

  late final FlutterSoundRecorder _recorder;
  VideoPlayerController? _videoController;
  bool _isRecording = false;
  String? _recordingPath;
  bool _isVideoInitialized = false;
  bool _isMediaLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
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

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();

    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission needed.');
      }
      await _recorder.openRecorder();
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  // Extracted reusable widgets
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
          Text(
            'Failed to load media',
            style: TextStyle(color: Colors.grey[600]),
          ),
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

  Future<void> _startRecording() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _recordingPath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
      );

      if (mounted) {
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();

      if (mounted) {
        setState(() => _isRecording = false);
        widget.onRecordingComplete?.call(_recordingPath);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speak the following:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (widget.mediaData != null) ...[
            _buildMediaContent(),
            const SizedBox(height: 24.0),
          ],
          _buildLessonText(),
          const SizedBox(height: 40),
          _buildControls(),
        ],
      ),
    );
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

  Widget _buildLessonText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.lessonText,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.onSkip != null) ...[
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.grey[600]),
            onPressed: widget.onSkip,
          ),
          const SizedBox(width: 20),
        ],
        GestureDetector(
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: () => _stopRecording(),
          child: AnimatedContainer(
            duration: _animationDuration,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: (_isRecording ? Colors.red : Colors.blue)
                      .withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mic,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
