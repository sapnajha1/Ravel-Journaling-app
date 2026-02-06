import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../../widgets/dotted_background.dart';

class FireAnimation extends StatelessWidget {
  const FireAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleW = size.width / 360;
    final scaleH = size.height / 800;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            Positioned.fill(
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }
}
