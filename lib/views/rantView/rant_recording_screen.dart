import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:manual_speech_to_text/manual_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

/// ✅ Singleton SpeechService for reuse
class SpeechService {
  static SpeechService? _instance;
  final ManualSttController _speech;

  SpeechService._internal(BuildContext context)
      : _speech = ManualSttController(context);

  factory SpeechService(BuildContext context) {
    _instance ??= SpeechService._internal(context);
    return _instance!;
  }

  ManualSttController get speechInstance => _speech;

  Future<void> dispose() async {
     _speech.pauseStt();
  }
}

/// ===== Journal Recording Screen =====
class rantSecondScreen extends StatefulWidget {
  const rantSecondScreen({super.key});

  @override
  State<rantSecondScreen> createState() => _RantSecondScreenState();
}

class _RantSecondScreenState extends State<rantSecondScreen> {
  bool _isRecording = false;
  String _liveText = '';
  late ManualSttController _speech;


  @override
  void initState() {
    super.initState();

    // ✅ Use singleton instance
    _speech = SpeechService(context).speechInstance;

    _initializeSpeech();
  }

  /// Initialize listeners only, no startStt here
  void _initializeSpeech() {
    _speech.listen(
      onListeningStateChanged: (state) {
        setState(() {
          _isRecording = state == ManualSttState.listening;
        });
      },
      onListeningTextChanged: (text) {
        setState(() {
          _liveText = text;
        });
      },
    );

    _speech.localId = 'en-US';
    _speech.enableHapticFeedback = true;
    _speech.pauseIfMuteFor = const Duration(seconds: 60);
  }

  /// 🎙 START RECORDING
  Future<void> _onMicPressed() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    setState(() {
      _liveText = '';
      _isRecording = true;
    });

    // print("Requesting microphone permission...");
    // print("Permission granted? ${status.isGranted}");


    _speech.startStt(); // ✅ start only after permission

    print("Requesting microphone permission...");
    print("Permission granted? ${status.isGranted}");

  }


  /// ⏹ STOP RECORDING
  Future<void> _onStopPressed() async {
     _speech.stopStt();

    setState(() {
      _isRecording = false;
    });

    debugPrint('FINAL TEXT: $_liveText');
  }

  @override
  void dispose() {
    _speech.stopStt();
    SpeechService(context).dispose(); // Dispose singleton if needed
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final today = DateFormat('d MMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFFE9CC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// ===== TOP BAR =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Today · ',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          today,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// ===== CENTER FRAME =====
            Expanded(
              child: Center(
                child: Stack(
                  children: [
                    // Background frame (Frame 156)
                    if (!_isRecording)
                      Center(
                        child: SvgPicture.asset(
                          'assets/Frame 156.svg',
                          width: size.width * 0.75,
                        ),
                      ),

                    // Cloud frame when recording
                    if (_isRecording)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 144),
                          child: SvgPicture.asset(
                            'assets/cloud-storm-svgrepo-com 2.svg',
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),

                    // Voice input text below cloud
                    if (_isRecording)
                      Positioned(
                        top: 144 + 80 + 16, // Cloud top + height + spacing
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Text(
                            _liveText.isEmpty ? '' : _liveText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                    // Default "Tap mic" text
                    // if (!_isRecording)
                    //   Positioned.fill(
                    //     child: Center(
                    //       child: Padding(
                    //         padding: const EdgeInsets.symmetric(horizontal: 28),
                    //         child: Text(
                    //           'Tap mic and let it all out',
                    //           textAlign: TextAlign.center,
                    //           style: const TextStyle(
                    //             fontSize: 16,
                    //             height: 1.4,
                    //             fontWeight: FontWeight.w500,
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),

            /// ===== BOTTOM MIC / STOP =====
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: _isRecording ? _onStopPressed : _onMicPressed,
                child: SvgPicture.asset(
                  _isRecording
                      ? 'assets/Group 13(1).svg' // STOP
                      : 'assets/Group 13.svg', // MIC
                  width: _isRecording ? 72 : 72,
                ),
              ),
            ),

            const SizedBox(height: 16),
            GestureDetector(
              onTap: _onStopPressed,
              child: SvgPicture.asset(
                'assets/Frame 22.svg', // your end ranting SVG
                width: 150,              // adjust width as needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}





