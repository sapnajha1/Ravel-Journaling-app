
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:journal_app/views/rantView/rant_ai_output_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/rantViewModel/rant_view_model.dart';
import '../../viewmodels/recording/recording_view_model.dart';
import '../home_view.dart';

class RantHistoryScreen extends StatefulWidget {
  const RantHistoryScreen({super.key});

  @override
  State<RantHistoryScreen> createState() => _RantHistoryScreenState();
}

class _RantHistoryScreenState extends State<RantHistoryScreen>  {


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final recordingVM = context.watch<RecordingViewModel>();
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

                            /// TEXT AREA
                            // if (recordingVM.displayText.isNotEmpty)
                            //   Positioned(
                            //     top: 140 * scaleH,
                            //     left: 16 * scaleW,
                            //     right: 16 * scaleW,
                            //     bottom: 40 * scaleH,
                            //     child: SingleChildScrollView(
                            //       reverse: true,
                            //       padding: EdgeInsets.only(
                            //         bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                            //       ),
                            //       child: TextField(
                            //         controller: recordingVM.textController,
                            //         maxLines: null,
                            //         keyboardType: TextInputType.multiline,
                            //         textAlignVertical: TextAlignVertical.top,
                            //         style:
                            //         GoogleFonts.gochiHand(
                            //           // fontFamily: 'SyneMono',
                            //           fontSize: 18 * scaleW,
                            //           height: 1.7,
                            //         ),
                            //         decoration: const InputDecoration(
                            //           border: InputBorder.none,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                          ],
                        ),
                      ),
                    ]
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

                  /// 🗑 DELETE ICON
                  InkWell(
                    onTap: () => showDeleteRantDialog(context),
                    child: SvgPicture.asset(
                      'assets/delete.svg',
                      width: 20 * scaleW,
                      height: 20 * scaleW,
                    ),
                  ),
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



void _onDeletePressed(BuildContext context) async {
  final rantVM = context.read<RantViewModel>();

  /// 1. delete transcription
  await rantVM.deleteCurrentRant();

  /// 2. navigate to home
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomeView()),
        (route) => false,
  );

  /// 3. optional snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Transcription deleted'),
    ),
  );
}

void showDeleteRantDialog(BuildContext context) {
  final date = DateFormat('d MMM').format(DateTime.now());

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.zero, // square box
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔴 TITLE
              Text(
                'Delete Rant',
                style: GoogleFonts.syneMono(
                  color: const Color(0xFFFF7B6B),
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              /// ⚫ DESCRIPTION
              Text(
                'Please confirm if you want to delete rant dated $date',
                style: GoogleFonts.syneMono(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 28),

              /// 🔘 ACTION BUTTONS (BOTTOM RIGHT)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  /// CANCEL BUTTON
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset(
                      'assets/Frame 177.svg',
                      height: 36,
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// DELETE BUTTON
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);

                      final rantVM = context.read<RantViewModel>();
                      await rantVM.deleteCurrentRant();

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeView(),
                        ),
                            (route) => false,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rant deleted'),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/Frame 22(2).svg',
                      height: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

