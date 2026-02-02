
import 'package:flutter/material.dart';
import 'package:journal_app/viewmodels/rantViewModel/rant_history_viewmodel.dart';
import '../recording/recording_view_model.dart';

class RantViewModel extends ChangeNotifier {
  final RecordingViewModel recordingVM;
  // final RantHistoryViewModel historyVM;

  RantViewModel({required this.recordingVM,});

  /// rant specific action
  void endRanting(BuildContext context) async {
    recordingVM.stopRecording(); // ✅ wait
    // historyVM.addRant(recordingVM.displayText);
    Navigator.pop(context);
  }

}


// import 'package:flutter/material.dart';
// import 'package:manual_speech_to_text/manual_speech_to_text.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class RantViewModel extends ChangeNotifier {
//   late ManualSttController _speech;
//
//   bool isRecording = false;
//   bool isPaused = false;
//   String liveText = '';
//
//   RantViewModel(BuildContext context) {
//     _speech = ManualSttController(context);
//     _initSpeech();
//   }
//
//   void _initSpeech() {
//     _speech.listen(
//       onListeningStateChanged: (state) {
//         isRecording = state == ManualSttState.listening;
//         notifyListeners();
//       },
//       onListeningTextChanged: (text) {
//         liveText = text;
//         notifyListeners();
//       },
//     );
//
//     _speech.localId = 'en-US';
//     _speech.enableHapticFeedback = true;
//     _speech.pauseIfMuteFor = const Duration(seconds: 60);
//   }
//
//   /// 🎙 Start Recording
//   Future<void> startRecording() async {
//     final status = await Permission.microphone.request();
//     if (!status.isGranted) return;
//
//     liveText = '';
//     isRecording = true;
//     isPaused = false;
//
//     _speech.startStt();
//     notifyListeners();
//   }
//
//   /// ⏸ Pause Recording (Stop button)
//   void pauseRecording() {
//     _speech.pauseStt();
//     isRecording = false;
//     isPaused = true;
//     notifyListeners();
//   }
//
//   /// ⏹ End Ranting
//   void endRanting() {
//     _speech.stopStt();
//     isRecording = false;
//     isPaused = false;
//     notifyListeners();
//
//     // later: save to history
//   }
//
//   @override
//   void dispose() {
//     _speech.stopStt();
//     _speech.dispose();
//     super.dispose();
//   }
// }
