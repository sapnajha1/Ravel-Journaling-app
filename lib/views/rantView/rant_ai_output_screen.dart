import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AIscreen extends StatelessWidget {
  const AIscreen({super.key});

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

                    const Spacer(),
                    SvgPicture.asset(
                      'assets/Frame 155.svg',
                      width: 328 * scaleW,
                      height: 156 * scaleH,
                      fit: BoxFit.contain,
                    ),

                    const Spacer(),

                    /// 🔘 BOTTOM BUTTONS
                    Padding(
                      padding: EdgeInsets.only(bottom: 24 * scaleH),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgPicture.asset(
                            'assets/Frame 156(1).svg',
                            width: 156 * scaleW,
                            height: 48 * scaleH,
                          ),
                          SvgPicture.asset(
                            'assets/Frame 155(1).svg',
                            width: 156 * scaleW,
                            height: 48 * scaleH,
                          ),
                        ],
                      ),
                      )
                        ]),
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
