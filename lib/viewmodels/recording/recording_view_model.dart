import 'dart:math';

import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// Recording / transcription view model backed by `manual_speech_to_text`.
///
/// This keeps the public surface that the rant screen expects:
/// - `startRecording` / `stopRecording`
/// - `displayText` + `textController`
/// - waveform via `waveHeights` + `isSpeaking`
///
/// Under the hood we:
/// - Use OS speech recognition via [ManualSttController] for real-time text
/// - Request microphone permission explicitly
/// - Maintain `liveText` (interim) + `finalText` (confirmed)
class RecordingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  late final ManualSttController _speech;

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

  /// Base text at the moment a listening session starts. Interim results
  /// are layered on top of this.
  String _baseTextAtSessionStart = '';

  RecordingViewModel(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _speech = ManualSttController(context);
    _initSpeech();
  }

  void _initSpeech() {
    _speech.listen(
      onListeningStateChanged: (state) {
        isRecording = state == ManualSttState.listening;
        notifyListeners();
      },
      onListeningTextChanged: (text) {
        // `text` is the current recognised text in this session.
        liveText = text;
        isSpeaking = liveText.trim().isNotEmpty;
        _updateFromSpeech();
      },
      onSoundLevelChanged: (level) {
        isSpeaking = level > 10.0;
        _updateWaveform();
        notifyListeners();
      },
    );

    // Configure defaults – you can tweak these later if needed.
    _speech.localId = 'en-US';
    _speech.enableHapticFeedback = true;
    _speech.pauseIfMuteFor = const Duration(seconds: 60);
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
      _speech.stopStt();
      isRecording = false;
      isPaused = false;
      _resetWaveform();
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (isInitializing || isRecording) return;

    isInitializing = true;
    lastError = null;
    notifyListeners();

    // Explicitly request microphone permission so we can surface a clear error.
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      lastError = 'Microphone permission is required for speech.';
      isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      isPaused = false;
      isRecording = true;
      _baseTextAtSessionStart = finalText.isNotEmpty
          ? finalText
          : textController.text; // preserve any typed text
      liveText = '';
      _resetWaveform();
      notifyListeners();

      _speech.startStt();
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
    _speech.pauseStt();
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }
    isPaused = true;
    isRecording = false;
    _resetWaveform();
    _updateFromSpeech();
    notifyListeners();
  }

  Future<void> stopRecording() async {
    _speech.stopStt();
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }
    isRecording = false;
    isPaused = false;
    _resetWaveform();
    _updateFromSpeech();
    notifyListeners();
  }

  void _resetWaveform() {
    waveHeights = List.filled(20, 6);
  }

  String get displayText =>
      liveText.isNotEmpty ? '$finalText $liveText'.trim() : finalText;

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
    _speech.dispose();
    super.dispose();
  }
}

