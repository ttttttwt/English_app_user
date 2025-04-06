import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:do_an_test/services/exercise_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';

class SpeakingExercise extends StatefulWidget {
  final Exercise exercise;
  final Function(bool, String?) onAnswered;

  const SpeakingExercise({
    super.key,
    required this.exercise,
    required this.onAnswered,
  });

  @override
  State<SpeakingExercise> createState() => _SpeakingExerciseState();
}

class _SpeakingExerciseState extends State<SpeakingExercise> {
  final FlutterTts _flutterTts = FlutterTts();
  late final AudioRecorder _audioRecorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();

  bool _isPlaying = false;
  bool _isRecording = false;
  String? _recordedPath;
  bool _hasRecorded = false;
  int _attempts = 0;
  Duration _recordDuration = Duration.zero;
  late Timer _recordingTimer;
  bool _isTtsPlaying = false;
  String _recordingStatus = '';

  String _transcribedText = '';
  double _accuracyScore = 0.0;
  bool _isProcessingTranscription = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeAudioPlayer();
    _audioRecorder = AudioRecorder();
    _initializeSpeechToText();
    _checkPermissions();
  }

  Future<void> _initializeSpeechToText() async {
    await _speechToText.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        setState(() {
          _recordingStatus = 'Speech recognition error: ${error.errorMsg}';
        });
      },
    );
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    final hasRecordPermission = await _audioRecorder.hasPermission();
    if (!hasRecordPermission) {
      setState(() {
        _recordingStatus = 'Microphone permission denied';
      });
    }
  }

  Future<void> _playTts() async {
    if (!_isTtsPlaying) {
      setState(() => _isTtsPlaying = true);
      await _flutterTts.speak(widget.exercise.data['text_to_speech']);
    } else {
      setState(() => _isTtsPlaying = false);
      await _flutterTts.stop();
    }
  }

  void _startTimer() {
    _recordDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordDuration += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _transcribeRecording() async {
    setState(() {
      _isProcessingTranscription = true;
      _recordingStatus = 'Transcribing...';
    });

    try {
      bool available = await _speechToText.initialize();

      if (available) {
        await _speechToText.listen(
          onResult: (result) {
            final transcription = result.recognizedWords;
            final originalText =
                widget.exercise.data['text_to_speech'].toLowerCase().trim();
            final similarityScore = StringSimilarity.compareTwoStrings(
                originalText, transcription.toLowerCase().trim());

            setState(() {
              _transcribedText = transcription;
              _accuracyScore = similarityScore * 100;
              _recordingStatus = 'Transcription complete';
              _isProcessingTranscription = false;
            });

            // Show accuracy feedback before proceeding
            _showAccuracyFeedback();

            _speechToText.stop();
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: false,
          localeId: 'en-US',
        );
      } else {
        setState(() {
          _recordingStatus = 'Speech recognition not available';
          _isProcessingTranscription = false;
        });
      }
    } catch (e) {
      setState(() {
        _recordingStatus = 'Transcription error: ${e.toString()}';
        _isProcessingTranscription = false;
      });
      print('Transcription error: $e');
    }
  }

  void _showAccuracyFeedback() {
    if (_accuracyScore >= 80) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Great job!'),
            content: Text(
              'Your accuracy: ${_accuracyScore.toStringAsFixed(1)}%\n'
              'You can proceed to the next question.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetStateAndProceed();
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Keep practicing'),
            content: Text(
              'Your accuracy: ${_accuracyScore.toStringAsFixed(1)}%\n'
              'Try again to achieve at least 80% accuracy.\n'
              'Attempts remaining: ${3 - _attempts}',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _resetState() {
    setState(() {
      _isPlaying = false;
      _isRecording = false;
      _recordedPath = null;
      _hasRecorded = false;
      _attempts = 0;
      _recordDuration = Duration.zero;
      _isTtsPlaying = false;
      _recordingStatus = '';
      _transcribedText = '';
      _accuracyScore = 0.0;
      _isProcessingTranscription = false;
    });
  }

  void _submitResult() {
    final bool isCompleted = _accuracyScore >= 80 || _attempts >= 3;

    if (isCompleted) {
      if (_attempts >= 3 && _accuracyScore < 80) {
        // Show dialog for maximum attempts reached
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Maximum attempts reached'),
              content: Text(
                'Final accuracy: ${_accuracyScore.toStringAsFixed(1)}%\n'
                'Moving to next question.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetStateAndProceed();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _resetStateAndProceed() {
    // Call the callback to proceed to next question
    widget.onAnswered(true, _transcribedText);
    // Reset all state variables
    _resetState();
  }

  void _stopTimer() {
    _recordingTimer.cancel();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (mounted) {
          setState(() {
            _recordingStatus = 'Initializing...';
            _isRecording = true;
          });
        }

        final directory = await getApplicationDocumentsDirectory();
        _recordedPath =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordedPath!,
        );

        _startTimer();

        if (mounted) {
          setState(() {
            _hasRecorded = false;
            _attempts++;
            _recordingStatus = 'Recording...';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recordingStatus = 'Error: ${e.toString()}';
          _isRecording = false;
        });
      }
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      _stopTimer();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _hasRecorded = true;
          _recordingStatus = '';
        });
      }

      // Auto-submit after recording
      if (_attempts >= 3) {
        _submitResult();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recordingStatus = 'Error stopping recording: ${e.toString()}';
        });
      }
      print('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    if (_recordedPath != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer.pause();
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        } else {
          await _audioPlayer.play(DeviceFileSource(_recordedPath!));
          if (mounted) {
            setState(() => _isPlaying = true);
          }
        }
      } catch (e) {
        print('Error playing recording: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Listen and repeat:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: Icon(_isTtsPlaying ? Icons.stop : Icons.play_arrow),
              title: Text(widget.exercise.data['text_to_speech']),
              trailing: IconButton(
                icon: const Icon(Icons.replay),
                onPressed: _playTts,
                tooltip: 'Replay',
              ),
              onTap: _playTts,
            ),
          ),
          const SizedBox(height: 32),
          if (_isRecording) ...[
            Text(
              'Recording: ${_recordDuration.inSeconds}s',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
          ],
          if (_recordingStatus.isNotEmpty) ...[
            Text(
              _recordingStatus,
              style: TextStyle(
                color: _recordingStatus.startsWith('Error')
                    ? Colors.red
                    : Colors.blue,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_transcribedText.isNotEmpty) ...[
            Text(
              'Your response: $_transcribedText',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              'Accuracy: ${_accuracyScore.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _accuracyScore >= 80 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRecording && !_hasRecorded)
                ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  onPressed: _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_isRecording)
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          if (_hasRecorded) ...[
            const SizedBox(height: 16),
            Text(
              'Attempts: $_attempts/3',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _playRecording,
                  tooltip: 'Play/Pause Recording',
                ),
                title: const Text('Your Recording'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isProcessingTranscription)
                      IconButton(
                        icon: const Icon(Icons.transcribe),
                        onPressed: _transcribeRecording,
                        tooltip: 'Transcribe Recording',
                      ),
                    if (_accuracyScore < 80 && _attempts < 3)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _startRecording,
                        tooltip:
                            'Record Again (${3 - _attempts} attempts left)',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _speechToText.stop();
    if (_isRecording) {
      _recordingTimer.cancel();
    }
    super.dispose();
  }
}
