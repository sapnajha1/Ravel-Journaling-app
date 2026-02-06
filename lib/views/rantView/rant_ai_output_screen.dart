import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'fire_animation.dart';

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

                            /// FRAME 188
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FireAnimation(),
                                  ),
                                );
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
