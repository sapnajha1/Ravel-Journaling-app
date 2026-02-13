import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/views/rantView/rant_ai_output_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';
import '../../widgets/dotted_background.dart';
import '../../widgets/recording_waveform.dart';
// import '../shared_widgets/dotted_background.dart';


class RantRecordingScreen extends StatefulWidget {
  const RantRecordingScreen({super.key});

  @override
  State<RantRecordingScreen> createState() => _RantRecordingScreenState();
}

class _RantRecordingScreenState extends State<RantRecordingScreen> with WidgetsBindingObserver  {

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.inactive) {
  //
  //     if (_navigated) return;
  //     _navigated = true;
  //
  //     final recordingVM =
  //     context.read<RecordingViewModel>();
  //     final rantVM =
  //     context.read<RantViewModel>();
  //
  //     if (recordingVM.isRecording) {
  //       recordingVM.stopRecording();
  //     }
  //
  //     rantVM.endRanting(context);
  //     Navigator.of(context).popUntil((route) => route.isFirst);
  //
  //
  //     // Navigator.of(context).pushAndRemoveUntil(
  //     //   MaterialPageRoute(builder: (_) => const HomeView()),
  //     //       (route) => false,
  //     // );
  //   }
  // }


  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   final recordingVM = context.read<RecordingViewModel>();
  //
  //   if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
  //       recordingVM.isRecording) {
  //     recordingVM.stopRecording(); // sirf recording stop
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_navigated) return; // already navigated, ignore
    final recordingVM = context.read<RecordingViewModel>();

    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) &&
        recordingVM.isRecording) {
      recordingVM.stopRecording();
    }
  }



  @override
  Widget build(BuildContext context) {
    final recordingVM = context.watch<RecordingViewModel>();
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;


    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (_navigated) return;
        if (didPop) {
          context.read<RecordingViewModel>().stopRecording();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned.fill(child: DottedBackground()),
                /// ===== MAIN CONTENT =====
                Positioned.fill(
                  child: Column(
                  children: [
                    /// APP BAR – at top like reflect screen (no gap)
                    FigmaAppBar(
                      entryDate: DateTime.now(),
                      onBack: () => Navigator.of(context).pop(),
                    ),


                    /// CENTER AREA – waveform only; transcription on background (no box)
                    Expanded(
                      child: !recordingVM.isRecording &&
                              recordingVM.displayText.isEmpty
                          ? Center(
                              child: SvgPicture.asset(
                                'assets/Frame 156(2).svg',
                                width: 281 * scaleW,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                /// Waveform only at top
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 40 * scaleH,
                                    left: 60 * scaleW,
                                    right: 60 * scaleW,
                                  ),
                                  child: Center(
                                    child: recordingWaveform(
                                      recordingVM,
                                      width: 240 * scaleW,
                                      barColor: const Color(0xffEF5350),
                                    ),
                                  ),
                                ),
                                /// Transcription from top, just below waveform – no box
                                if (recordingVM.displayText.isNotEmpty)
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: SingleChildScrollView(
                                            reverse: false,
                                            padding: EdgeInsets.only(
                                              top: 12 * scaleH,
                                              left: 16 * scaleW,
                                              right: 16 * scaleW,
                                              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                                            ),
                                            child: TextField(
                                              controller: recordingVM.textController,
                                              maxLines: null,
                                              keyboardType: TextInputType.multiline,
                                              textAlignVertical: TextAlignVertical.top,
                                              style: GoogleFonts.gochiHand(
                                                fontSize: 18 * scaleW,
                                                height: 1.7,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                enabledBorder: InputBorder.none,
                                                focusedBorder: InputBorder.none,
                                                filled: false,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (recordingVM.isTranscribing)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                                      ),
                                                    ),
                                                    SizedBox(height: 12),
                                                    Text(
                                                      'Processing...',
                                                      style: GoogleFonts.syneMono(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),

                    /// MIC / STOP BUTTON
                    Padding(
                      padding:
                      EdgeInsets.only(bottom: 10 * scaleH),
                      child: GestureDetector(
                        onTap: () {
                          if (recordingVM.isRecording) {
                            recordingVM.stopRecording();
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

                    // GestureDetector(
                    //   onTap: () {
                    //     final recordingVM = context.read<RecordingViewModel>();
                    //
                    //
                    //     if (recordingVM.isRecording ) {
                    //       recordingVM.stopRecording();
                    //     }
                    //
                    //
                    //     context.read<RantViewModel>().endRanting(context);
                    //
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (_) => const AIscreen(),
                    //       ),
                    //     );
                    //   },
                    //   child: SvgPicture.asset(
                    //     'assets/Frame 22(1).svg',
                    //     width: 136 * scaleW,
                    //   ),
                    // ),


                    // GestureDetector(
                    //   onTap: () async {
                    //     final recordingVM = context.read<RecordingViewModel>();
                    //
                    //     // Agar recording chal rahi hai to stop karo
                    //     if (recordingVM.isRecording) {
                    //        recordingVM.stopRecording();
                    //     }
                    //
                    //     // End ranting
                    //     context.read<RantViewModel>().endRanting(context);
                    //
                    //     // Mark as navigated so lifecycle/PopScope doesn't interfere
                    //     _navigated = true;
                    //
                    //     // Navigate to AI screen
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (_) => const AIscreen(),
                    //       ),
                    //     );
                    //   },
                    //   child: SvgPicture.asset(
                    //     'assets/Frame 22(1).svg',
                    //     width: 136 * scaleW,
                    //   ),
                    // ),

                    GestureDetector(
                      onTap: () async {
                        final rantVM = context.read<RantViewModel>();

                        // End ranting (does not save; content passed to AI screen so "Let it Go" = never stored)
                        final content = await rantVM.endRanting(context);

                        // Mark as navigated so PopScope/lifecycle doesn't interfere
                        _navigated = true;

                        if (!context.mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AIscreen(
                              savedEntry: null,
                              rantContent: content,
                              journalRepository: rantVM.journalRepository,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              offset: Offset(3, 3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/Frame 22(1).svg',
                          width: 136 * scaleW,
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * scaleH),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class FigmaAppBar extends StatelessWidget {
  const FigmaAppBar({
    required this.entryDate,
    required this.onBack,
    super.key,
  });

  final DateTime entryDate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F7), // background
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF201B18), // bottom shadow
            offset: Offset(0, 5),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1️⃣ Back arrow
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 24,
            ),
          ),

          const SizedBox(width: 8),

          // 2️⃣ Center dynamic date
          Expanded(
            child: Center(
              child: Text(
                'Today, ${_formatDateWithOrdinal(entryDate)}',
                style: GoogleFonts.syneMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: const Color(0xFF52443F),
                ),
              ),
            ),
          ),

          // 3️⃣ No delete icon
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  String _formatDateWithOrdinal(DateTime date) {
    final day = date.day;
    final suffix = _getDaySuffix(day);
    final month = DateFormat('MMM').format(date); // Jan, Feb...
    return '$day$suffix $month';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

/// ================= BACKGROUND PAINTER =================
// ignore: unused_element
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