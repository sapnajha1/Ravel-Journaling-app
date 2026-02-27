import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../design_system/app_colors.dart';
import '../widgets/dotted_background.dart';

class EntryAnalysisLoadingScreen extends StatefulWidget {
  const EntryAnalysisLoadingScreen({super.key});

  @override
  State<EntryAnalysisLoadingScreen> createState() =>
      _EntryAnalysisLoadingScreenState();
}

class _EntryAnalysisLoadingScreenState
    extends State<EntryAnalysisLoadingScreen> {
  static const _timeoutSeconds = 15;

  Timer? _timer;
  bool _showSkip = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: _timeoutSeconds), () {
      if (mounted) setState(() => _showSkip = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/book_loader.json',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing your entry...',
                    style: TextStyle(
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_showSkip) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Skip analysis',
                        style: TextStyle(
                          fontFamily: GoogleFonts.syneMono().fontFamily,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
