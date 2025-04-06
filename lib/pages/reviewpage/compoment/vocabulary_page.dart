import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VocabularyPage extends StatefulWidget {
  final String english;
  final String vietnamese;
  final String? example;
  final String? exampleTranslation;
  final String? mediaUrl;
  final bool isVideo;
  final bool isAssetImage;
  final VoidCallback? onCardTap;

  const VocabularyPage({
    super.key,
    required this.english,
    required this.vietnamese,
    this.example,
    this.exampleTranslation,
    this.mediaUrl,
    this.isVideo = false,
    this.isAssetImage = false,
    this.onCardTap,
  });

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVoice({"name": "en-us-x-tpf-network", "locale": "en-US"});
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onCardTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.mediaUrl != null) ...[
              const SizedBox(height: 16),
              _buildMedia(),
            ],
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            _buildMainWord(),
            const SizedBox(height: 8),
            _buildTranslation(),
            if (widget.example != null) ...[_buildExample()],
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: widget.isVideo ? _buildVideo() : _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.isAssetImage) {
      return Image.asset(
        widget.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorContainer();
        },
      );
    } else {
      return Image.network(
        widget.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorContainer();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingContainer();
        },
      );
    }
  }

  Widget _buildErrorContainer() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildVideo() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 50,
        ),
      ),
    );
  }

  Widget _buildMainWord() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.english,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () => _speak(widget.english), // Phát âm từ vựng
          iconSize: 24,
        ),
      ],
    );
  }

  Widget _buildTranslation() {
    return Text(
      widget.vietnamese,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(
          color: Color.fromRGBO(0, 0, 0, 0.6),
        ),
        const SizedBox(height: 16),
        const Text(
          'Example:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.example!,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () => _speak(widget.example!), // Phát âm ví dụ
              iconSize: 24,
            ),
          ],
        ),
        if (widget.exampleTranslation != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.exampleTranslation!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
