import 'package:flutter/material.dart';

import '../viewmodels/recording/recording_view_model.dart';

/// Reusable waveform visualization for recording screens (rant, reflect, history).
/// [vm] drives bar heights; [barColor] is the bar color (e.g. red for rant, purple for reflect).
Widget recordingWaveform(
  RecordingViewModel vm, {
  required double width,
  Color barColor = const Color(0xffEF5350),
}) {
  const double barWidth = 2;
  const double spacing = 1.5;

  final barCount = (width / (barWidth + spacing)).floor().clamp(1, 200);

  return SizedBox(
    width: width,
    height: 80,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final h = vm.waveHeights[i % vm.waveHeights.length];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: barWidth,
            height: h,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    ),
  );
}
