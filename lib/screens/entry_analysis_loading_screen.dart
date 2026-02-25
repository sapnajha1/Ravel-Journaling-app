import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../widgets/dotted_background.dart';

class EntryAnalysisLoadingScreen extends StatelessWidget {
  const EntryAnalysisLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Center(
              child: Lottie.asset(
                'assets/book_loader.json',
                width: 120,
                height: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
