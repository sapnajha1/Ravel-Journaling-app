import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/journal_entry.dart';
import '../../data/repositories/journal_repository.dart';
import '../../widgets/dotted_background.dart';
import 'fire_animation.dart';

class AIscreen extends StatelessWidget {
  const AIscreen({
    super.key,
    this.savedEntry,
    required this.journalRepository,
  });

  final JournalEntry? savedEntry;
  final JournalRepository journalRepository;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Positioned.fill(
              child: Column(
                  children: [
                    /// 🟡 CENTER BLOCK (155 + line + 188)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// FRAME 155
                            SvgPicture.asset(
                              'assets/Frame 155(3).svg',
                              width: 328 * scaleW,
                              height: 156 * scaleH,
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: 24 * scaleH),

                            /// LINE 2
                            SvgPicture.asset(
                              'assets/Line 2.svg',
                              width: 333 * scaleW,
                              height: 1,
                              fit: BoxFit.fill,
                            ),

                            SizedBox(height: 24 * scaleH),

                            /// FRAME 188
                            SvgPicture.asset(
                              'assets/fireText2.svg',
                              width: 333 * scaleW,
                              height: 34 * scaleH,
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: 24 * scaleH),

                            /// Let it go: delete the saved rant then go to fire animation
                            InkWell(
                              onTap: () async {
                                if (savedEntry != null) {
                                  await journalRepository.deleteEntry(savedEntry!);
                                }
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FireAnimation(),
                                    ),
                                  );
                                }
                              },
                              child: SvgPicture.asset(
                                'assets/letgo.svg',
                                width: 333 * scaleW,
                                height: 34 * scaleH,
                                fit: BoxFit.contain,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                    /// 🔘 BOTTOM BUTTON
                    Padding(
                      padding: EdgeInsets.only(bottom: 24 * scaleH),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);

                        },
                        child: SvgPicture.asset(
                          'assets/Frame 156(3).svg',
                          width: 136 * scaleW,
                          height: 48 * scaleH,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
