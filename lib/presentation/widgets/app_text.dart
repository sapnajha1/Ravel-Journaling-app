import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_text_styles.dart';

enum AppTextStyle {
  display,
  headlineLarge,
  headlineSmall,
  titleLarge,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  label,
  handwritten,
}

class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      style: _resolveStyle().copyWith(
        color: color ?? AppColors.textPrimary,
      ),
    );
  }

  TextStyle _resolveStyle() {
    switch (style) {
      case AppTextStyle.display:
        return AppTextStyles.display;
      case AppTextStyle.headlineLarge:
        return AppTextStyles.headlineLarge;
      case AppTextStyle.headlineSmall:
        return AppTextStyles.headlineSmall;
      case AppTextStyle.titleLarge:
        return AppTextStyles.titleLarge;
      case AppTextStyle.titleSmall:
        return AppTextStyles.titleSmall;
      case AppTextStyle.bodyLarge:
        return AppTextStyles.bodyLarge;
      case AppTextStyle.bodyMedium:
        return AppTextStyles.bodyMedium;
      case AppTextStyle.bodySmall:
        return AppTextStyles.bodySmall;
      case AppTextStyle.label:
        return AppTextStyles.label;
      case AppTextStyle.handwritten:
        return AppTextStyles.handwritten;
    }
  }
}
