import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:google_speech/generated/google/cloud/speech/v1p1beta1/cloud_speech.pb.dart'
    show StreamingRecognizeResponse;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  static const int _sampleRate = 16000;
  /// Primary: English (India); alternatives for mixed speech.
  static const String _primaryLanguageCode = 'en-IN';
  static const List<String> _alternativeLanguageCodes = ['hi-IN', 'en-US'];
  static const String _serviceAccountAsset =
      'assets/google_service_account.json';

  final AudioRecorder _recorder = AudioRecorder();
  SpeechToTextBeta? _speechToText;
  StreamSubscription<List<int>>? _micStreamSubscription;
  StreamController<List<int>>? _streamForStt;
  StreamSubscription<StreamingRecognizeResponse>? _sttSubscription;
  /// PCM bytes collected while recording; sent to API on pause/stop for clear multi-language result.
  final List<int> _audioBuffer = [];
  static const int _maxAudioBytesForRecognize = 16000 * 2 * 60; // 60 sec at 16kHz 16-bit

  /// Voice activity: require this many silent chunks before setting isSpeaking = false.
  static const int _silentChunksToStop = 3;
  int _silentChunkCount = 0;
  static const double _speechLevelThreshold = 400; // RMS threshold for 16-bit PCM

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
      _stopRecordingStream();
      _stopStreamingStt();
      liveText = '';
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
      await _ensureSpeechReady();

      isPaused = false;
      isRecording = true;
      isSpeaking = false;
      _silentChunkCount = 0;
      _resetWaveform();
      notifyListeners();

      await _startRecordingStream();
    } catch (error) {
      lastError = error.toString();
      isRecording = false;
      isPaused = false;
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> pauseRecording() async {
    await _stopRecordingStreamAndRecognize();

    isPaused = true;
    isRecording = false;
    isSpeaking = false;
    _resetWaveform();
    notifyListeners();
  }

  Future<void> stopRecording() async {
    await _stopRecordingStreamAndRecognize();

    isRecording = false;
    isPaused = false;
    isSpeaking = false;
    _resetWaveform();
    notifyListeners();
  }


  void _resetWaveform() {
    waveHeights = List.filled(20, 6);
  }
  String get displayText =>
      liveText.isNotEmpty ? '$finalText $liveText' : finalText;

  void _updateTextController() {
    textController.text = displayText.trim();
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
  }

  Future<void> _ensureSpeechReady() async {
    if (_speechToText != null) return;

    final json = await rootBundle.loadString(_serviceAccountAsset);
    final serviceAccount = ServiceAccount.fromString(json);
    _speechToText = SpeechToTextBeta.viaServiceAccount(serviceAccount);
  }

  Future<void> _startRecordingStream() async {
    _audioBuffer.clear();
    liveText = '';

    _streamForStt = StreamController<List<int>>();

    final config = RecognitionConfigBeta(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.latest_long,
      enableAutomaticPunctuation: true,
      sampleRateHertz: _sampleRate,
      languageCode: _primaryLanguageCode,
      alternativeLanguageCodes: _alternativeLanguageCodes,
    );
    final streamingConfig = StreamingRecognitionConfigBeta(
      config: config,
      interimResults: true,
    );
    final responseStream = _speechToText!.streamingRecognize(
      streamingConfig,
      _streamForStt!.stream,
    );
    _sttSubscription = responseStream.listen(
      (response) {
        for (final result in response.results) {
          if (result.alternatives.isEmpty) continue;
          final transcript = result.alternatives.first.transcript.trim();
          if (transcript.isEmpty) continue;
          liveText = transcript;
          _updateWaveform();
          _updateTextController();
          notifyListeners();
        }
      },
      onError: (error) {
        lastError = error.toString();
        notifyListeners();
      },
    );

    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ),
    );

    _micStreamSubscription = micStream.listen((data) {
      _audioBuffer.addAll(data);
      if (!(_streamForStt?.isClosed ?? true)) _streamForStt?.add(data);
      _updateSpeakingFromAudioChunk(data);
    });
  }

  /// Updates [isSpeaking] from PCM chunk level so the waveform reflects voice activity.
  void _updateSpeakingFromAudioChunk(List<int> pcmBytes) {
    if (pcmBytes.length < 2) return;

    double sumSq = 0;
    int count = 0;
    for (int i = 0; i + 1 < pcmBytes.length; i += 2) {
      int s = pcmBytes[i] | (pcmBytes[i + 1] << 8);
      if (s >= 0x8000) s -= 0x10000;
      sumSq += (s * s).toDouble();
      count++;
    }
    if (count == 0) return;
    double rms = (sumSq / count) > 0 ? sqrt(sumSq / count) : 0;

    if (rms >= _speechLevelThreshold) {
      _silentChunkCount = _silentChunksToStop;
      if (!isSpeaking) isSpeaking = true;
      _updateWaveform();
      notifyListeners();
    } else {
      if (_silentChunkCount > 0) _silentChunkCount--;
      if (_silentChunkCount <= 0 && isSpeaking) {
        isSpeaking = false;
        _updateWaveform();
        notifyListeners();
      }
    }
  }

  void _stopStreamingStt() {
    _sttSubscription?.cancel();
    _sttSubscription = null;
    _streamForStt?.close();
    _streamForStt = null;
  }

  Future<void> _stopRecordingStream() async {
    await _micStreamSubscription?.cancel();
    _micStreamSubscription = null;
    await _recorder.stop();
    _stopStreamingStt();
  }

  /// Stops the mic and streaming, runs recognize() on buffered audio for clear multi-language text.
  Future<void> _stopRecordingStreamAndRecognize() async {
    await _stopRecordingStream();

    if (_audioBuffer.isEmpty) {
      _updateTextController();
      notifyListeners();
      return;
    }

    isTranscribing = true;
    lastError = null;
    notifyListeners();

    try {
      final config = RecognitionConfigBeta(
        encoding: AudioEncoding.LINEAR16,
        model: RecognitionModel.latest_long,
        enableAutomaticPunctuation: true,
        sampleRateHertz: _sampleRate,
        languageCode: _primaryLanguageCode,
        alternativeLanguageCodes: _alternativeLanguageCodes,
      );

      List<int> audioToSend;
      if (_audioBuffer.length > _maxAudioBytesForRecognize) {
        audioToSend = _audioBuffer.sublist(
          _audioBuffer.length - _maxAudioBytesForRecognize,
        );
      } else {
        audioToSend = List<int>.from(_audioBuffer);
      }
      _audioBuffer.clear();

      final response = await _speechToText!.recognize(config, audioToSend);

      final parts = <String>[];
      for (final result in response.results) {
        if (result.alternatives.isEmpty) continue;
        final t = result.alternatives.first.transcript.trim();
        if (t.isNotEmpty) parts.add(t);
      }
      if (parts.isNotEmpty) {
        final transcript = parts.join(' ');
        finalText = [finalText, transcript].where((t) => t.isNotEmpty).join(' ');
        liveText = '';
        _updateTextController();
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      isTranscribing = false;
      notifyListeners();
    }
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
    _stopRecordingStream();
    _stopStreamingStt();
    _recorder.dispose();
    super.dispose();
  }

  // void disposeController() { _speech.dispose(); }
}

