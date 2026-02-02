import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';

class RantRecordingScreen extends StatelessWidget {
  const RantRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingVM = context.watch<RecordingViewModel>();
    final rantVM = context.read<RantViewModel>();
    final size = MediaQuery.of(context).size;
    final today = DateFormat('d MMM').format(DateTime.now());

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFFE9CC),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              /// ===== TOP BAR =====
              figmaAppBar(context),

              /// ===== CENTER FRAME =====
              Expanded(
                child: Center(
                  child: Stack(
                      children: [
                        // Background frame
                        if (!recordingVM.isRecording && !recordingVM.isPaused)
                          Center(
                            child: SvgPicture.asset(
                              'assets/Frame 156.svg',
                              width: size.width * 0.75,
                            ),
                          ),

                        // Audio Wave Form when recording
                        if (recordingVM.isRecording || recordingVM.isPaused)
                          Positioned(
                            top: 112,
                            left: 60,
                            // right: 24,
                            child: simulatedWaveform(recordingVM,),
                          ),

                        // Voice input text
                        if (recordingVM.displayText.isNotEmpty)
                          Positioned(
                            top: 224,
                            left: 16,
                            right: 16,
                            child: Container(
                              width: 328,
                              height: 376,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent, // Figma ka background
                                borderRadius: BorderRadius.circular(16), // curved corners
                              ),
                              child: TextField(
                                controller: recordingVM.textController,
                                scrollController: recordingVM.textScrollController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(fontSize: 20, height: 1.4),
                                onChanged: (_) {
                                  // Scroll automatically when text grows
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (recordingVM.textScrollController.hasClients) {
                                      recordingVM.textScrollController.jumpTo(
                                        recordingVM.textScrollController.position.minScrollExtent,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                      ]
                  ),
                ),
              ),

              /// ===== BOTTOM MIC / STOP =====
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GestureDetector(
                  onTap: () {
                    if (recordingVM.isRecording) {
                      // ⏸ pause
                      recordingVM.pauseRecording();
                    } else {
                      // ▶️ start OR resume
                      recordingVM.startRecording();
                    }
                  },
                  child: SvgPicture.asset(
                    recordingVM.isRecording
                        ? 'assets/Group 13(1).svg' // STOP
                        : 'assets/Group 13.svg', // MIC
                    width: 72,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// END RANT BUTTON
              GestureDetector(
                onTap: () => context.read<RantViewModel>().endRanting(context),
                child: SvgPicture.asset(
                  'assets/Frame 22.svg',
                  width: 150,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget figmaAppBar(BuildContext context) {
  return ClipRRect(
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // MAIN APPBAR
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
              bottom: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),

              const Spacer(),

              const Text(
                'Today · 16 Jan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // const SizedBox(width: 8),
            ],
          ),
        ),

        // 👇 BLACK THICK LINE
        Container(
          height: 4, // 🔥 thickness
          color: Colors.black,
          width: double.infinity,
        ),
      ],
    ),
  );
}

Widget simulatedWaveform(RecordingViewModel vm) {
  return SizedBox(
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: vm.waveHeights.map((h) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 10,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xffEF5350),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    ),
  );
}