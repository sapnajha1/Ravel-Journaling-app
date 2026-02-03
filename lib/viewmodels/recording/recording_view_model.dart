import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class RecordingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  late ManualSttController _speech;
  List<double> waveHeights = List.filled(20, 6);
  bool isSpeaking = false;

  final TextEditingController textController = TextEditingController();
  final ScrollController textScrollController = ScrollController();
  bool isRecording = false;
  bool isPaused = false;
  String liveText = '';
  String finalText = '';

  RecordingViewModel(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    _speech = ManualSttController(context);

    _speech.listen(
        onListeningTextChanged: (text) {
          updateFromSpeech(text);
          // notifyListeners();
        },
        onListeningStateChanged: (state) {}
    );

    _speech.localId = 'en-US';
    _speech.pauseIfMuteFor = const Duration(seconds: 60);
  }

    /// 🔥 APP LIFE CYCLE HANDLE
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
        notifyListeners();
      }
    }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    isPaused = false;
    isRecording = true;
    _resetWaveform();
    notifyListeners();

    _speech.startStt();
  }

  void pauseRecording() {
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }

    _speech.pauseStt();
    isPaused = true;
    isRecording = false;
    _resetWaveform();
    notifyListeners();
  }

  void stopRecording() {
    if (liveText.isNotEmpty) {
      finalText = '$finalText $liveText'.trim();
      liveText = '';
    }

    _speech.stopStt();
    isRecording = false;
    isPaused = false;
    _resetWaveform();
    notifyListeners();
  }


  void _resetWaveform() {
    waveHeights = List.filled(20, 6);
  }
  String get displayText =>
      liveText.isNotEmpty ? '$finalText $liveText' : finalText;

  void updateFromSpeech(String text) {
    liveText = text;

    textController.text = displayText;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: textController.text.length),
    );


    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (textScrollController.hasClients) {
    //     textScrollController.jumpTo(
    //       textScrollController.position.maxScrollExtent,
    //     );
    //   }
    // }
    // );

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

    // 👇 SPEAKING DETECTED
    isSpeaking = text.trim().isNotEmpty;

    _updateWaveform();
    notifyListeners();
  }
  void _updateWaveform() {
    if (!isRecording && !isPaused) return;

    final random = Random();

    waveHeights = List.generate(
      20,
          (_) => isSpeaking
          ? random.nextDouble() * 30 + 8   // speaking
          : random.nextDouble() * 4 + 4,   // silence
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stopStt();
    _speech.dispose();
    super.dispose();
  }

  // void disposeController() { _speech.dispose(); }
}

