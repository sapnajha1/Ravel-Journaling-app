import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

class FireAnimation extends StatelessWidget {
  const FireAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE9CC),
      body: SafeArea(
          child:
          Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DottedBackgroundPainter(
                    dotColor: const Color(0x18FF6E5A),
                    spacing: 18,
                    radius: 1.4,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/fire.json',
                            width: 80 * scaleW,
                            height: 80 * scaleH,
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                          SizedBox(height: 24 * scaleH),


                          SvgPicture.asset(
                            'assets/fireText.svg',
                            width: 320 * scaleW,
                            // height: 90 * scaleH,
                            fit: BoxFit.contain,
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
            ],)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}
