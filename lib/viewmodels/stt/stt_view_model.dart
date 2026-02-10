import 'package:flutter/material.dart';

import '../../stt/stt_service.dart';

/// ViewModel that wires the [SttService] into a text field and exposes
/// simple UI state for the screen.
///
/// Responsibilities:
/// - Start/stop listening on mic button taps.
/// - Keep track of UI states (idle / listening / stopped / error).
/// - Merge live speech transcription into a [TextEditingController]
///   without clearing existing typed content.
class SttViewModel extends ChangeNotifier {
  final SttService _sttService;

  /// The controller bound to the journal text field.
  final TextEditingController textController = TextEditingController();

  /// Optional: used to auto-scroll to bottom as text grows.
  final ScrollController textScrollController = ScrollController();

  bool isListening = false;
  String status = 'idle'; // idle | listening | stopped | error
  String? errorMessage;

  /// Base text at the moment a listening session starts.
  ///
  /// Interim/final STT results are appended on top of this so that any
  /// previously typed content remains intact.
  String _baseTextAtSessionStart = '';

  SttViewModel({SttService? sttService}) : _sttService = sttService ?? SttService();

  /// Start listening for speech and streaming results into the text field.
  Future<void> startListening({String localeId = 'en_US'}) async {
    if (isListening) return;

    status = 'initializing';
    errorMessage = null;
    notifyListeners();

    try {
      await _sttService.initialize(localeId: localeId);

      _baseTextAtSessionStart = textController.text;

      await _sttService.startListening(
        onResult: _onSttResult,
        onStatus: (s) {
          status = s;
          notifyListeners();
        },
        localeId: localeId,
      );

      isListening = true;
      status = 'listening';
      notifyListeners();
    } on SttException catch (e) {
      errorMessage = e.message;
      status = 'error';
      isListening = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      status = 'error';
      isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _sttService.stopListening();
    isListening = false;
    if (status != 'error') {
      status = 'stopped';
    }
    notifyListeners();
  }

  void _onSttResult(String recognizedWords, bool isFinal) {
    // `recognizedWords` is the full transcript for this session so far.
    // We combine it with the base text that existed before the session started.
    final combined = (_baseTextAtSessionStart + ' ' + recognizedWords).trim();
    textController.text = combined;
    textController.selection = TextSelection.collapsed(offset: textController.text.length);

    // Auto-scroll to bottom if attached.
    if (textScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!textScrollController.hasClients) return;
        textScrollController.animateTo(
          textScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      });
    }

    if (isFinal) {
      // When a result is final, treat the whole text as the new base so that
      // subsequent sessions build on top of it.
      _baseTextAtSessionStart = textController.text;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    textScrollController.dispose();
    _sttService.dispose();
    super.dispose();
  }
}

