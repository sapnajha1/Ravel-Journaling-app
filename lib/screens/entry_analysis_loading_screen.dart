import 'package:flutter/material.dart';

import '../widgets/dotted_background.dart';

class EntryAnalysisLoadingScreen extends StatelessWidget {
  const EntryAnalysisLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: DottedBackground()),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
