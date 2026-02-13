import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.child,
    required this.svgAsset,
    this.padding = const EdgeInsets.all(22),
    this.backgroundColor = const Color(0x00000000),
    this.shadowOffset = const Offset(3, 3),
    this.shadowColor = const Color(0xFF000000),
  });

  final Widget child;
  final String svgAsset;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Offset shadowOffset;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (backgroundColor.a > 0)
          Positioned.fill(
            child: ColoredBox(color: backgroundColor),
          ),
        Positioned.fill(
          child: Transform.translate(
            offset: shadowOffset,
            child: SvgPicture.asset(
              svgAsset,
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(shadowColor, BlendMode.srcIn),
            ),
          ),
        ),
        Positioned.fill(
          child: SvgPicture.asset(
            svgAsset,
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}
