import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:journal_app/views/rantView/rant_recording_screen.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../viewmodels/recording/recording_view_model.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final size = MediaQuery.of(context).size;
    final recordingVM = RecordingViewModel(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFE9CC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            /// Today date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SvgPicture.asset(
                'assets/Frame 15.svg',
                height: 36,
              ),
            ),

            const SizedBox(height: 16),

            /// Greeting
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Good Morning, Roshan!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// ==== CARD STACK AREA ====
            SizedBox(
              height: size.height * 0.55,
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  /// SCRIBBLE – back right (green)
                  Positioned(
                    bottom: -50,
                    left: 0,
                    right: -40,
                    child: Transform.rotate(
                      angle: -0.00,
                      child: SvgPicture.asset(
                        'assets/Group 10.svg',
                        width: size.width * 0.9,
                      ),
                    ),
                  ),

                  /// RANT – back left (orange)
                  Positioned(
                    bottom: -50,
                    left: -5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (screenContext) {
                              final recordingVM = RecordingViewModel(screenContext);

                              return MultiProvider(
                                providers: [
                                  ChangeNotifierProvider.value(value: recordingVM),
                                  ChangeNotifierProvider(
                                    create: (_) => RantViewModel(
                                      recordingVM: recordingVM,
                                      // historyVM: context.read<RantHistoryViewModel>(),
                                    ),
                                  ),
                                ],
                                child: const RantRecordingScreen(),
                              );
                            },
                          ),
                        );
                      },
                      child: Transform.rotate(
                        angle: 0.00,
                        child: SvgPicture.asset(
                          'assets/Group 9.svg',
                          width: size.width * 0.84,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -140,
                    left: 50,
                    child: Transform.rotate(
                      angle: -0.00,
                      child: SvgPicture.asset(
                        'assets/Group 6.svg',
                        width: size.width * 0.82,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// Bottom navigation frame
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: SvgPicture.asset(
                  'assets/Frame 11.svg',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
