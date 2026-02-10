import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around the `speech_to_text` plugin.
///
/// Responsibilities:
/// - Request microphone permission.
/// - Initialise the STT engine once.
/// - Start / stop listening.
/// - Emit partial + final results via callbacks.
class SttService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool get isListening => _speechToText.isListening;

  String _localeId = 'en_US';
  String get localeId => _localeId;

  /// Initialise the STT engine and request microphone permission.
  ///
  /// Throws a [SttException] if permission is denied or STT is unavailable.
  Future<void> initialize({String localeId = 'en_US'}) async {
    // Request microphone permission explicitly so we can surface a clear error.
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw SttException('Microphone permission is required for speech recognition.');
    }

    final available = await _speechToText.initialize(
      onStatus: _onStatus,
      onError: (error) {
        // We only log here; ViewModels should surface errors via callbacks.
        // ignore: avoid_print
        print('STT error: ${error.errorMsg}');
      },
    );

    if (!available) {
      throw SttException('Speech recognition is not available on this device.');
    }

    _isInitialized = true;

    // Try to pick the requested locale if available; otherwise keep default.
    final locales = await _speechToText.locales();
    final match = locales.where((l) => l.localeId == localeId).toList();
    if (match.isNotEmpty) {
      _localeId = match.first.localeId;
    } else {
      _localeId = localeId;
    }
  }

  /// Start listening and forward interim + final results.
  ///
  /// [onResult] receives the full recognised text for the current session
  /// and whether the result is final.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      await initialize(localeId: localeId ?? _localeId);
    }

    await _speechToText.listen(
      onResult: (stt.SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      localeId: localeId ?? _localeId,
    );

    // Expose initial status upwards.
    onStatus('listening');
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<void> cancel() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }

  void _onStatus(String status) {
    // For now we just log; higher layers track state via [startListening]/[stopListening].
    // ignore: avoid_print
    print('STT status: $status');
  }

  void dispose() {
    _speechToText.stop();
  }
}

class SttException implements Exception {
  final String message;
  SttException(this.message);

  @override
  String toString() => 'SttException: $message';
}

