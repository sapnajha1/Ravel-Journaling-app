import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_colors.dart';
import '../widgets/dotted_background.dart';
import '../widgets/shared_buttons.dart';

/// Shown after a reflection is saved when the user has opted out of AI analysis.
class EntryCompletionScreen extends StatelessWidget {
  const EntryCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    SvgPicture.asset(
                      'assets/analysis-icons/reflect-icon.svg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'That must have felt good. Come back again',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gochiHand(
                        fontSize: 22,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: 200,
                        child: ShadowButton(
                          height: 44,
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          },
                          child: Text(
                            'Go to Home',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.syneMono().fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
