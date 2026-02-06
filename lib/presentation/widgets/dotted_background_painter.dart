import 'package:flutter/material.dart';

import '../../design_system/app_spacing.dart';

class DottedBackgroundPainter extends CustomPainter {
  DottedBackgroundPainter({required this.dotColor});

  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final spacing = AppSpacing.tight;
    final radius = AppSpacing.micro / 4;

    for (double y = 0; y <= size.height; y += spacing) {
      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedBackgroundPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor;
  }
}
