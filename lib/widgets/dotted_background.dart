import 'package:flutter/material.dart';

class DottedBackground extends StatelessWidget {
  const DottedBackground({
    super.key,
    this.dotColor = const Color(0x18FF6E5A),
    this.spacing = 18,
    this.radius = 1.4,
  });

  final Color dotColor;
  final double spacing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBackgroundPainter(
        dotColor: dotColor,
        spacing: spacing,
        radius: radius,
      ),
    );
  }
}

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
  bool shouldRepaint(covariant _DottedBackgroundPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        oldDelegate.spacing != spacing ||
        oldDelegate.radius != radius;
  }
}
