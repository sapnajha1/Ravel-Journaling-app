import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.syneMono(
        fontSize: 48,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => GoogleFonts.syneMono(
        fontSize: 40,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.syneMono(
        fontSize: 32,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.syneMono(
        fontSize: 24,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.syneMono(
        fontSize: 20,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.syneMono(
        fontSize: 18,
        height: 1.7,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.syneMono(
        fontSize: 16,
        height: 1.7,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.syneMono(
        fontSize: 14,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get label => GoogleFonts.syneMono(
        fontSize: 12,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get handwritten => GoogleFonts.gochiHand(
        fontSize: 20,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        headlineLarge: headlineLarge,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelSmall: label,
      );
}
