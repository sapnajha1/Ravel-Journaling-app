import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';
import '../../widgets/dotted_background.dart';

class RantRecordingScreen extends StatelessWidget {
  const RantRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordingVM = context.watch<RecordingViewModel>();
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          context.read<RecordingViewModel>().stopRecording();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                /// ===== DOTTED BACKGROUND =====
                const Positioned.fill(child: DottedBackground()),

                /// ===== MAIN CONTENT =====
                Column(
                  children: [
                    /// APP BAR
                    figmaAppBar(context),

                    /// CENTER AREA
                    Expanded(
                      child: Stack(
                        children: [
                          if (!recordingVM.isRecording &&
                              !recordingVM.isPaused)
                            Center(
                              child: SvgPicture.asset(
                                'assets/Frame 156.svg',
                                width: 281 * scaleW,
                              ),
                            ),

                          /// WAVEFORM
                          if (recordingVM.isRecording ||
                              recordingVM.isPaused)
                            Positioned(
                              top: 88 * scaleH,
                              left: 60 * scaleW,
                              child: simulatedWaveform(
                                recordingVM,
                                width: 240 * scaleW,
                              ),
                            ),

                          /// TEXT AREA
                          if (recordingVM.displayText.isNotEmpty)
                            Positioned(
                              top: (88 + 80 + 24) * scaleH,
                              left: 16 * scaleW,
                              right: 16 * scaleW,
                              bottom: 120 * scaleH,
                              child: SingleChildScrollView(
                                reverse: true,
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                                ),
                                child: TextField(
                                  controller: recordingVM.textController,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: TextStyle(
                                    fontFamily: 'SyneMono',
                                    fontSize: 18 * scaleW,
                                    height: 1.7,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    /// MIC / STOP BUTTON
                    Padding(
                      padding:
                      EdgeInsets.only(bottom: 24 * scaleH),
                      child: GestureDetector(
                        onTap: () {
                          if (recordingVM.isRecording) {
                            recordingVM.pauseRecording();
                          } else {
                            recordingVM.startRecording();
                          }
                        },
                        child: SvgPicture.asset(
                          recordingVM.isRecording
                              ? 'assets/Group 13(1).svg'
                              : 'assets/Group 13.svg',
                          width: 64 * scaleW,
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * scaleH),

                    /// END RANT BUTTON
                    SizedBox(
                      width: 136 * scaleW,
                      child: _ShadowButton(
                        onPressed: () => context
                            .read<RantViewModel>()
                            .endRanting(context),
                        child: const Text(
                          'End Rant',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * scaleH),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ================= APP BAR =================
Widget figmaAppBar(BuildContext context) {
  final todayDate = DateFormat('d MMM').format(DateTime.now());

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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        Text(
          'Today · $todayDate',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Center(child: DefaultTextStyle.merge(child: child)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ================= WAVEFORM =================
Widget simulatedWaveform(
    RecordingViewModel vm, {
      required double width,
    }) {
  const double barWidth = 2;
  const double spacing = 1.5;

  final barCount =
  (width / (barWidth + spacing)).floor().clamp(1, 200);

  return SizedBox(
    width: width,
    height: 80,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final h = vm.waveHeights[i % vm.waveHeights.length];
        return Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: barWidth,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xffEF5350),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    ),
  );
}

// removed custom background painter; using shared DottedBackground

