// // import 'package:flutter/material.dart';
// // import 'package:flutter_svg/flutter_svg.dart';
// // import 'package:provider/provider.dart';
// // import '../../viewmodels/rantViewModel/rant_view_model.dart';
// // import '../../viewmodels/recording/recording_view_model.dart';
// // import '../../widgets/dotted_background.dart';
// // import '../../utils/date_formatters.dart';
// //
// // class RantRecordingScreen extends StatelessWidget {
// //   const RantRecordingScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final recordingVM = context.watch<RecordingViewModel>();
// //     final rantVM = context.read<RantViewModel>();
// //     final size = MediaQuery.of(context).size;
// //
// //     return GestureDetector(
// //       behavior: HitTestBehavior.translucent,
// //       onTap: () {
// //         FocusScope.of(context).unfocus();
// //       },
// //       child: Scaffold(
// //         resizeToAvoidBottomInset: false,
// //         backgroundColor: Colors.white,
// //         body: SafeArea(
// //           child: Stack(
// //             children: [
// //               const Positioned.fill(child: DottedBackground()),
// //               Column(
// //                 children: [
// //                   const SizedBox(height: 20),
// //
// //                   /// ===== TOP BAR =====
// //                   figmaAppBar(context),
// //
// //                   /// ===== CENTER FRAME =====
// //                   Expanded(
// //                     child: Center(
// //                       child: Stack(children: [
// //                         // Background frame
// //                         if (!recordingVM.isRecording && !recordingVM.isPaused)
// //                           Center(
// //                             child: SvgPicture.asset(
// //                               'assets/Frame 156.svg',
// //                               width: size.width * 0.75,
// //                             ),
// //                           ),
// //
// //                         // Audio Wave Form when recording
// //                         if (recordingVM.isRecording || recordingVM.isPaused)
// //                           Positioned(
// //                             top: 112,
// //                             left: 60,
// //                             // right: 24,
// //                             child: simulatedWaveform(
// //                               recordingVM,
// //                             ),
// //                           ),
// //
// //                         // Voice input text
// //                         if (recordingVM.displayText.isNotEmpty)
// //                           Positioned(
// //                             top: 224,
// //                             left: 16,
// //                             right: 16,
// //                             child: Container(
// //                               width: 328,
// //                               height: 376,
// //                               padding: const EdgeInsets.symmetric(
// //                                 horizontal: 12,
// //                                 vertical: 12,
// //                               ),
// //                               decoration: BoxDecoration(
// //                                 color: Colors.transparent, // Figma ka background
// //                                 borderRadius:
// //                                     BorderRadius.circular(16), // curved corners
// //                               ),
// //                               child: TextField(
// //                                 controller: recordingVM.textController,
// //                                 scrollController:
// //                                     recordingVM.textScrollController,
// //                                 maxLines: null,
// //                                 keyboardType: TextInputType.multiline,
// //                                 textAlignVertical: TextAlignVertical.top,
// //                                 decoration: const InputDecoration(
// //                                   border: InputBorder.none,
// //                                 ),
// //                                 style:
// //                                     const TextStyle(fontSize: 20, height: 1.4),
// //                                 onChanged: (_) {
// //                                   // Scroll automatically when text grows
// //                                   WidgetsBinding.instance
// //                                       .addPostFrameCallback((_) {
// //                                     if (recordingVM
// //                                         .textScrollController.hasClients) {
// //                                       recordingVM.textScrollController.jumpTo(
// //                                         recordingVM.textScrollController.position
// //                                             .minScrollExtent,
// //                                       );
// //                                     }
// //                                   });
// //                                 },
// //                               ),
// //                             ),
// //                           ),
// //                       ]),
// //                     ),
// //                   ),
// //
// //                   /// ===== BOTTOM MIC / STOP =====
// //                   Padding(
// //                     padding: const EdgeInsets.only(bottom: 24),
// //                     child: GestureDetector(
// //                       onTap: () {
// //                         if (recordingVM.isRecording) {
// //                           // ⏸ pause
// //                           recordingVM.pauseRecording();
// //                         } else {
// //                           // ▶️ start OR resume
// //                           recordingVM.startRecording();
// //                         }
// //                       },
// //                       child: SvgPicture.asset(
// //                         recordingVM.isRecording
// //                             ? 'assets/Group 13(1).svg' // STOP
// //                             : 'assets/Group 13.svg', // MIC
// //                         width: 72,
// //                       ),
// //                     ),
// //                   ),
// //
// //                   const SizedBox(height: 16),
// //
// //                   /// END RANT BUTTON
// //                   SizedBox(
// //                     width: 150,
// //                     child: _ShadowButton(
// //                       onPressed: () =>
// //                           context.read<RantViewModel>().endRanting(context),
// //                       child: const Text(
// //                         'End Rant',
// //                         style: TextStyle(fontWeight: FontWeight.w700),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// // Widget figmaAppBar(BuildContext context) {
// //   return Container(
// //     height: 60,
// //     width: double.infinity,
// //     padding: const EdgeInsets.symmetric(horizontal: 8),
// //     decoration: BoxDecoration(
// //       color: Colors.white,
// //       borderRadius: BorderRadius.circular(6),
// //       border: const Border(
// //         left: BorderSide(color: Colors.black, width: 2),
// //         right: BorderSide(color: Colors.black, width: 2),
// //         bottom: BorderSide(color: Colors.black, width: 2),
// //       ),
// //       boxShadow: const [
// //         BoxShadow(
// //           color: Color(0x33000000),
// //           blurRadius: 0,
// //           offset: Offset(0, 2),
// //         ),
// //       ],
// //     ),
// //     child: Row(
// //       children: [
// //         IconButton(
// //           icon: const Icon(Icons.arrow_back_ios_new),
// //           onPressed: () => Navigator.pop(context),
// //           padding: EdgeInsets.zero,
// //           constraints: const BoxConstraints(),
// //         ),
// //         const Spacer(),
// //         Text(
// //           'Today · ${formatDayMonth(DateTime.now())}',
// //           style: const TextStyle(
// //             fontSize: 12,
// //             fontWeight: FontWeight.w700,
// //           ),
// //         ),
// //         const Spacer(),
// //         const SizedBox(width: 24),
// //       ],
// //     ),
// //   );
// // }
// //
// // class _ShadowButton extends StatelessWidget {
// //   const _ShadowButton({required this.onPressed, required this.child});
// //
// //   final VoidCallback? onPressed;
// //   final Widget child;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return DecoratedBox(
// //       decoration: BoxDecoration(
// //         borderRadius: BorderRadius.circular(6),
// //         border: const Border(
// //           right: BorderSide(color: Colors.black, width: 1.5),
// //           bottom: BorderSide(color: Colors.black, width: 1.5),
// //         ),
// //         boxShadow: const [
// //           BoxShadow(
// //             color: Color(0xFF2A2A2A),
// //             blurRadius: 0,
// //             offset: Offset(2, 2),
// //           ),
// //         ],
// //       ),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.circular(6),
// //         child: Material(
// //           color: const Color(0xFFFF6E5A),
// //           child: InkWell(
// //             onTap: onPressed,
// //             child: SizedBox(
// //               height: 36,
// //               child: Padding(
// //                 padding:
// //                     const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
// //                 child: Center(child: DefaultTextStyle.merge(child: child)),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // Widget simulatedWaveform(RecordingViewModel vm) {
// //   return SizedBox(
// //     height: 60,
// //     child: Row(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: vm.waveHeights.map((h) {
// //         return Center(
// //           child: AnimatedContainer(
// //             duration: const Duration(milliseconds: 120),
// //             margin: const EdgeInsets.symmetric(horizontal: 2),
// //             width: 10,
// //             height: h,
// //             decoration: BoxDecoration(
// //               color: const Color(0xffEF5350),
// //               borderRadius: BorderRadius.circular(2),
// //             ),
// //           ),
// //         );
// //       }).toList(),
// //     ),
// //   );
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import '../../viewmodels/rantViewModel/rant_view_model.dart';
// import '../../viewmodels/recording/recording_view_model.dart';
// import '../../widgets/dotted_background.dart';
// import '../../utils/date_formatters.dart';
//
// class RantRecordingScreen extends StatelessWidget {
//   const RantRecordingScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final recordingVM = context.watch<RecordingViewModel>();
//     final rantVM = context.read<RantViewModel>();
//     final size = MediaQuery.of(context).size;
//
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTap: () {
//         FocusScope.of(context).unfocus();
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: false,
//         backgroundColor: Colors.white,
//         body: SafeArea(
//           child: Stack(
//             children: [
//               const Positioned.fill(child: DottedBackground()),
//               Column(
//                 children: [
//                   const SizedBox(height: 20),
//
//                   /// ===== TOP BAR =====
//                   figmaAppBar(context),
//
//                   /// ===== CENTER FRAME =====
//                   Expanded(
//                     child: Center(
//                       child: Stack(children: [
//                         // Background frame
//                         if (!recordingVM.isRecording && !recordingVM.isPaused)
//                           Center(
//                             child: SvgPicture.asset(
//                               'assets/Frame 156.svg',
//                               width: size.width * 0.75,
//                             ),
//                           ),
//
//                         // Audio Wave Form when recording
//                         if (recordingVM.isRecording || recordingVM.isPaused)
//                           Positioned(
//                             top: 112,
//                             left: 60,
//                             child: simulatedWaveform(
//                               recordingVM,
//                             ),
//                           ),
//
//                         // 🔥 FIXED: Voice input text - ab upar se start hoga
//                         if (recordingVM.displayText.isNotEmpty)
//                           Positioned(
//                             top: 224,
//                             left: 16,
//                             right: 16,
//                             bottom: 120, // Add bottom constraint
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 12,
//                                 vertical: 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.transparent,
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               child: SingleChildScrollView(
//                                 // 🔥 REMOVED: reverse: true
//                                 // Reverse false ya remove karo to text upar se start hoga
//                                 controller: recordingVM.textScrollController,
//                                 child: TextField(
//                                   controller: recordingVM.textController,
//                                   maxLines: null,
//                                   keyboardType: TextInputType.multiline,
//                                   // 🔥 FIXED: textAlignVertical ko top set karo
//                                   textAlignVertical: TextAlignVertical.top,
//                                   decoration: const InputDecoration(
//                                     border: InputBorder.none,
//                                     contentPadding: EdgeInsets.zero, // Remove extra padding
//                                   ),
//                                   style: const TextStyle(
//                                     fontSize: 20,
//                                     height: 1.4,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ]),
//                     ),
//                   ),
//
//                   /// ===== BOTTOM MIC / STOP =====
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 24),
//                     child: GestureDetector(
//                       onTap: () {
//                         if (recordingVM.isRecording) {
//                           // ⏸ pause
//                           recordingVM.pauseRecording();
//                         } else if (recordingVM.isPaused) {
//                           // ▶️ resume
//                           recordingVM.pauseRecording();
//                         } else {
//                           // ▶️ start
//                           recordingVM.startRecording();
//                         }
//                       },
//                       child: SvgPicture.asset(
//                         recordingVM.isRecording
//                             ? 'assets/Group 13(1).svg' // STOP
//                             : 'assets/Group 13.svg', // MIC
//                         width: 72,
//                       ),
//                     ),
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   /// END RANT BUTTON
//                   SizedBox(
//                     width: 150,
//                     child: _ShadowButton(
//                       onPressed: () =>
//                           context.read<RantViewModel>().endRanting(context),
//                       child: const Text(
//                         'End Rant',
//                         style: TextStyle(fontWeight: FontWeight.w700),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
// Widget figmaAppBar(BuildContext context) {
//   return Container(
//     height: 60,
//     width: double.infinity,
//     padding: const EdgeInsets.symmetric(horizontal: 8),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(6),
//       border: const Border(
//         left: BorderSide(color: Colors.black, width: 2),
//         right: BorderSide(color: Colors.black, width: 2),
//         bottom: BorderSide(color: Colors.black, width: 2),
//       ),
//       boxShadow: const [
//         BoxShadow(
//           color: Color(0x33000000),
//           blurRadius: 0,
//           offset: Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Row(
//       children: [
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new),
//           onPressed: () => Navigator.pop(context),
//           padding: EdgeInsets.zero,
//           constraints: const BoxConstraints(),
//         ),
//         const Spacer(),
//         Text(
//           'Today · ${formatDayMonth(DateTime.now())}',
//           style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         const Spacer(),
//         const SizedBox(width: 24),
//       ],
//     ),
//   );
// }
//
// class _ShadowButton extends StatelessWidget {
//   const _ShadowButton({required this.onPressed, required this.child});
//
//   final VoidCallback? onPressed;
//   final Widget child;
//
//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(6),
//         border: const Border(
//           right: BorderSide(color: Colors.black, width: 1.5),
//           bottom: BorderSide(color: Colors.black, width: 1.5),
//         ),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0xFF2A2A2A),
//             blurRadius: 0,
//             offset: Offset(2, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(6),
//         child: Material(
//           color: const Color(0xFFFF6E5A),
//           child: InkWell(
//             onTap: onPressed,
//             child: SizedBox(
//               height: 36,
//               child: Padding(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
//                 child: Center(child: DefaultTextStyle.merge(child: child)),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// Widget simulatedWaveform(RecordingViewModel vm) {
//   return SizedBox(
//     height: 60,
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: vm.waveHeights.map((h) {
//         return Center(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 120),
//             margin: const EdgeInsets.symmetric(horizontal: 2),
//             width: 10,
//             height: h,
//             decoration: BoxDecoration(
//               color: const Color(0xffEF5350),
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//         );
//       }).toList(),
//     ),
//   );
// }





import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/views/rantView/rant_ai_output_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';
import '../home_view.dart';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {

      if (_navigated) return;
      _navigated = true;

      final recordingVM =
      context.read<RecordingViewModel>();
      final rantVM =
      context.read<RantViewModel>();

      if (recordingVM.isRecording) {
        recordingVM.stopRecording();
      }

      rantVM.endRanting(context);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeView()),
            (route) => false,
      );
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
                              recordingVM.displayText.isEmpty)
                            Center(
                              child: SvgPicture.asset(
                                'assets/Frame 156(2).svg',
                                width: 281 * scaleW,
                              ),
                            ),

                          /// WAVEFORM
                          if (recordingVM.isRecording ||
                              recordingVM.displayText.isNotEmpty)
                            Positioned(
                              top: 40 * scaleH,
                              left: 60 * scaleW,
                              child: simulatedWaveform(
                                recordingVM,
                                width: 240 * scaleW,
                              ),
                            ),

                          /// TEXT AREA
                          if (recordingVM.displayText.isNotEmpty)
                            Positioned(
                              top: 140 * scaleH,
                              left: 16 * scaleW,
                              right: 16 * scaleW,
                              bottom: 40 * scaleH,
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
                                  style:
                                  GoogleFonts.gochiHand(
                                    // fontFamily: 'SyneMono',
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

                    /// END RANT BUTTON
                    // GestureDetector(
                    //   onTap: () => context
                    //       .read<RantViewModel>()
                    //       .endRanting(context),
                    //   child: SvgPicture.asset(
                    //     'assets/Frame 22.svg',
                    //     width: 136 * scaleW,
                    //   ),
                    // ),

                    GestureDetector(
                      onTap: () {
                        final recordingVM = context.read<RecordingViewModel>();


                        if (recordingVM.isRecording ) {
                          recordingVM.stopRecording();
                        }


                        context.read<RantViewModel>().endRanting(context);

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AIscreen(),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/Frame 22(1).svg',
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
            color:
            Color(0xFFFFF7F0),            // Colors.white54,
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
                        style: GoogleFonts.syneMono(
                          fontSize: 14 * scaleW,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        todayDate,
                        style: GoogleFonts.syneMono(
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