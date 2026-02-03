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
          backgroundColor: const Color(0xFFFFE9CC),
          body: SafeArea(
            child: Stack(
              children: [
                /// ===== DOTTED BACKGROUND =====
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DottedBackgroundPainter(
                      dotColor: const Color(0x18FF6E5A),
                      spacing: 18,
                      radius: 1.4,
                    ),
                  ),
                ),

                /// ===== MAIN CONTENT =====
                Column(
                  children: [
                    SizedBox(height: 20 * scaleH),

                    /// APP BAR
                    figmaAppBar(context,scaleH),

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
                    GestureDetector(
                      onTap: () => context
                          .read<RantViewModel>()
                          .endRanting(context),
                      child: SvgPicture.asset(
                        'assets/Frame 22.svg',
                        width: 136 * scaleW,
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
Widget figmaAppBar(BuildContext context, double scaleW) {
  final todayDate = DateFormat('d MMM').format(DateTime.now());

  return SizedBox(
    height: 64 * scaleW + 5,
    width: double.infinity,
    child: Stack(
      children: [
        /// MAIN TRANSPARENT APP BAR
        Container(
          height: 64 * scaleW,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white54,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleW),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20 * scaleW,
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Today · ',
                        style: TextStyle(
                          fontFamily: 'SyneMono',
                          fontSize: 14 * scaleW,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        todayDate,
                        style: TextStyle(
                          fontFamily: 'SyneMono',
                          fontSize: 14 * scaleW,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(width: 24 * scaleW),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              height: 5,
              color: const Color(0xFF201B18),
            ),
          ),
        ),
      ],
    ),
  );
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

/// ================= BACKGROUND PAINTER =================
class _DottedBackgroundPainter extends CustomPainter {
  const _DottedBackgroundPainter({
    required this.dotColor,
    required this.spacing,
    required this.radius,
  });

  final Color dotColor;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}

