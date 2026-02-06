import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/journal_repository.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../viewmodels/recording/recording_view_model.dart';
import '../views/rantView/rant_recording_screen.dart';

class RantScreen extends StatelessWidget {
  const RantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecordingViewModel(context)),
        ChangeNotifierProvider(
          create: (context) =>
              RantViewModel(recordingVM: context.read<RecordingViewModel>(),
                journalRepository: context.read<JournalRepository>(),
              ),
        ),
      ],
      child: const RantRecordingScreen(),
    );
  }
}
