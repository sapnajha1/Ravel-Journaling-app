import 'dart:math';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Real-time transcription using Deepgram (Nova-2 + language=multi for English + Hinglish).
class RecordingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  static const String _deepgramApiKey =
      String.fromEnvironment('DEEPGRAM_API_KEY');

  static const String _deepgramModel = 'nova-2';
  static const String _deepgramLanguage = 'multi';

  final AudioRecorder _recorder = AudioRecorder();
  Deepgram? _deepgram;
  DeepgramLiveListener? _listener;

  List<double> waveHeights = List.filled(20, 6);
  bool isSpeaking = false;

  final TextEditingController textController = TextEditingController();
  final ScrollController textScrollController = ScrollController();
  bool isRecording = false;
  bool isPaused = false;
  bool isInitializing = false;
  bool isTranscribing = false;
  String? lastError;
  String liveText = '';
  String finalText = '';

  RecordingViewModel(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _initializeStt();
  }

  Future<void> _initializeStt() async {
    if (_deepgramApiKey.isEmpty) {
      debugPrint(
          'DEEPGRAM_API_KEY not set. Pass via --dart-define for STT.');
      return;
    }
    _deepgram ??= Deepgram(_deepgramApiKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _forceStopRecording();
    }
  }

  void _forceStopRecording() {
    if (isRecording || isPaused) {
      _stopStreaming();
      isRecording = false;
      isPaused = false;
      _resetWaveform();
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    if (isInitializing) return;
    isInitializing = true;
    lastError = null;
    notifyListeners();

    try {
      await _initializeStt();
      if (_deepgram == null) {
        lastError = 'DEEPGRAM_API_KEY not set';
        isInitializing = false;
        notifyListeners();
        return;
      }

      isPaused = false;
      isRecording = true;
      _resetWaveform();
      notifyListeners();

      final micStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _listener?.close();
      _listener = _deepgram!.listen.liveListener(
        micStream,
        queryParams: {
          'model': _deepgramModel,
          'language': _deepgramLanguage,
          'punctuate': true,
          'smart_format': true,
          'interim_results': true,
          'vad_events': true,
          'endpointing': 100,
          'encoding': 'linear16',
          'sample_rate': 16000,
        },
      );

      _listener!.stream.listen(
        (res) {
          final transcript = _extractTranscript(res);
          if (transcript.trim().isEmpty) return;
          final isFinal =
              res.map['is_final'] == true || res.map['speech_final'] == true;
          if (isFinal) {
            finalText = '$finalText $transcript'.trim();
            liveText = '';
          } else {
            liveText = transcript;
          }
          isSpeaking = displayText.trim().isNotEmpty;
          _updateWaveform();
          _updateFromSpeech();
        },
        onError: (e) {
          lastError = e.toString();
          notifyListeners();
        },
      );

      _listener!.start();
    } catch (e) {
      lastError = e.toString();
      isRecording = false;
      notifyListeners();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> pauseRecording() async {
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }
    _stopStreaming();
    isPaused = true;
    isRecording = false;
    _resetWaveform();
    _updateFromSpeech();
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }
    _stopStreaming();
    isRecording = false;
    isPaused = false;
    _resetWaveform();
    _updateFromSpeech();
    notifyListeners();
  }

  void _stopStreaming() {
    _listener?.close();
    _listener = null;
    _recorder.stop();
  }

  String _extractTranscript(dynamic res) {
    final direct = res?.transcript as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct;
    final map = res?.map as Map?;
    final channel = map?['channel'];
    if (channel is Map) {
      final alternatives = channel['alternatives'];
      if (alternatives is List && alternatives.isNotEmpty) {
        final alt = alternatives.first;
        if (alt is Map && alt['transcript'] is String) {
          return alt['transcript'] as String;
        }
      }
    }
    return '';
  }

  void _resetWaveform() {
    waveHeights = List.filled(20, 6);
  }

  String get displayText =>
      liveText.isNotEmpty ? '$finalText $liveText' : finalText;

  void _updateFromSpeech() {
    textController.text = displayText;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!textScrollController.hasClients) return;

      final position = textScrollController.position;
      final isUserAtBottom =
          position.pixels >= position.maxScrollExtent - 20;

      if (isUserAtBottom) {
        textScrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });

    _updateWaveform();
    notifyListeners();
  }

  void _updateWaveform() {
    if (!isRecording && !isPaused) return;

    final random = Random();
    waveHeights = List.generate(
      20,
      (_) => isSpeaking
          ? random.nextDouble() * 30 + 8
          : random.nextDouble() * 4 + 4,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopStreaming();
    _recorder.dispose();
    super.dispose();
  }
}
