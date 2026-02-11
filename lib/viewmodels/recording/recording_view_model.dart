import 'dart:math';

import 'package:flutter/material.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
/// - Optionally refine the final text with punctuation via a Supabase
///   Edge Function that calls Gemini (or any LLM) **after** recording stops.
class RecordingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  late final ManualSttController _speech;

  List<double> waveHeights = List.filled(20, 6);
  bool isSpeaking = false;

  final TextEditingController textController = TextEditingController();
  final ScrollController textScrollController = ScrollController();
  bool isRecording = false;
  bool isPaused = false;
  bool isInitializing = false;
  bool isTranscribing = false; // true while backend is refining punctuation
  String? lastError;
  String liveText = '';
  String finalText = '';

  /// Base text at the moment a listening session starts. Interim results
  /// are layered on top of this.
  String _baseTextAtSessionStart = '';

  /// When true, [stopRecording] / [pauseRecording] skip the backend
  /// punctuation refinement so text appears immediately (e.g. reflect/history).
  final bool skipPunctuationRefinement;

  RecordingViewModel(BuildContext context, {this.skipPunctuationRefinement = false}) {
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

  /// Call before [startRecording] when using this VM for reflect/history so
  /// existing content is preserved and new speech appends to it.
  void setSessionText(String text) {
    finalText = text;
    textController.text = text;
    liveText = '';
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );
    notifyListeners();
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

    // Optional: also refine on pause so the user sees punctuation even if
    // they don't fully stop the rant.
    if (!skipPunctuationRefinement) await _refineTranscriptWithBackend();
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

    // When the user fully stops, call the backend once to improve punctuation
    // and casing (unless disabled for reflect/history).
    if (!skipPunctuationRefinement) await _refineTranscriptWithBackend();
  }

  void _resetWaveform() {
    waveHeights = List.filled(20, 6);
  }

  String get displayText =>
      liveText.isNotEmpty ? '$finalText $liveText'.trim() : finalText;

  /// Send the final transcript to a Supabase Edge Function that uses Gemini
  /// (or any LLM) to:
  /// - add punctuation
  /// - fix casing
  /// - keep Hinglish words exactly as-is
  ///
  /// This runs **after** we have collected speech-to-text, so real-time
  /// performance is not impacted.
  Future<void> _refineTranscriptWithBackend() async {
    final raw = finalText.trim();
    if (raw.isEmpty) return;

    if (isTranscribing) return; // avoid double-calls

    isTranscribing = true;
    lastError = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'punctuate-transcript',
        body: {'transcript': raw},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final refined = (data['text'] as String?)?.trim();
        if (refined != null && refined.isNotEmpty && refined != raw) {
          finalText = refined;
        }
      } else {
        // Unexpected response shape – surface a hint so you can debug.
        lastError =
            'Punctuation refine: unexpected response type ${data.runtimeType}';
      }
    } catch (e) {
      // On any error we keep the original text and just surface the error.
      lastError = 'Punctuation refine failed: $e';
    } finally {
      liveText = '';
      isTranscribing = false;
      _updateFromSpeech();
    }
  }

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

