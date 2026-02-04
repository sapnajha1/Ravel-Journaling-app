import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';
import '../../widgets/dotted_background.dart';
import '../../utils/date_formatters.dart';

class RantRecordingScreen extends StatelessWidget {
  const RantRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingVM = context.watch<RecordingViewModel>();
    final rantVM = context.read<RantViewModel>();
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: DottedBackground()),
              Column(
                children: [
                  const SizedBox(height: 20),

                  /// ===== TOP BAR =====
                  figmaAppBar(context),

                  /// ===== CENTER FRAME =====
                  Expanded(
                    child: Center(
                      child: Stack(children: [
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
                            child: simulatedWaveform(
                              recordingVM,
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent, // Figma ka background
                                borderRadius:
                                    BorderRadius.circular(16), // curved corners
                              ),
                              child: TextField(
                                controller: recordingVM.textController,
                                scrollController:
                                    recordingVM.textScrollController,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style:
                                    const TextStyle(fontSize: 20, height: 1.4),
                                onChanged: (_) {
                                  // Scroll automatically when text grows
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (recordingVM
                                        .textScrollController.hasClients) {
                                      recordingVM.textScrollController.jumpTo(
                                        recordingVM.textScrollController.position
                                            .minScrollExtent,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                      ]),
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
                  SizedBox(
                    width: 150,
                    child: _ShadowButton(
                      onPressed: () =>
                          context.read<RantViewModel>().endRanting(context),
                      child: const Text(
                        'End Rant',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget figmaAppBar(BuildContext context) {
  return Container(
    height: 60,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: const Border(
        left: BorderSide(color: Colors.black, width: 2),
        right: BorderSide(color: Colors.black, width: 2),
        bottom: BorderSide(color: Colors.black, width: 2),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 0,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        Text(
          'Today · ${formatDayMonth(DateTime.now())}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 24),
      ],
    ),
  );
}

class _ShadowButton extends StatelessWidget {
  const _ShadowButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: const Border(
          right: BorderSide(color: Colors.black, width: 1.5),
          bottom: BorderSide(color: Colors.black, width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2A2A2A),
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: const Color(0xFFFF6E5A),
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 36,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Center(child: DefaultTextStyle.merge(child: child)),
              ),
            ),
          ),
        ),
      ),
    );
  }
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