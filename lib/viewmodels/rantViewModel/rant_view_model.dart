
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';
import '../recording/recording_view_model.dart';

class RantViewModel extends ChangeNotifier {
  final RecordingViewModel recordingVM;
  final JournalRepository journalRepository;
  bool isRecording = false;
  TextEditingController textController = TextEditingController();


  RantViewModel({
    required this.recordingVM,
  required this.journalRepository,
  });

  // Current stopRecording
  void stopRecording() {
    if (!isRecording) return;
    isRecording = false;
    notifyListeners();
  }
  // Future version for async/await
  Future<void> stopRecordingAsync() async {
    stopRecording(); // existing logic
    await Future.delayed(const Duration(milliseconds: 50)); // optional, for async safety
  }

  /// Rant specific action. Saves the rant and returns the saved entry (or null if not saved).
  Future<JournalEntry?> endRanting(BuildContext context) async {
    recordingVM.stopRecording();

    final content = recordingVM.textController.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return null;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your rant.')),
      );
      Navigator.pop(context);
      return null;
    }

    final entry = await journalRepository.saveRantEntry(
      userId: userId,
      content: content,
    );
    Navigator.pop(context);
    return entry;
  }

  Future<void> deleteCurrentRant() async {
    // API call OR local delete logic
    // example:
    // await repository.deleteRant(currentRantId);

    notifyListeners();
  }
  Future<void> deleteRant(JournalEntry entry) async {
    await journalRepository.deleteEntry(entry);
    notifyListeners();
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
