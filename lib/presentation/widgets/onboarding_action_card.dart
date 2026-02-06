import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_spacing.dart';

/// Onboarding card for Reflect/Rant/Scribble. Normal card with bottom shadow; title 16px (colored), description 14px.
class OnboardingActionCard extends StatelessWidget {
  const OnboardingActionCard({
    super.key,
    required this.title,
    required this.description,
    this.iconAsset,
    this.iconTint,
    this.titleColor,
  }) : assert(iconAsset != null, 'Provide iconAsset');

  final String title;
  final String description;
  final String? iconAsset;
  final Color? iconTint;
  /// Color for the card title only (Reflect=purple, Rant=orange, Scribble=teal). Description uses primary text color.
  final Color? titleColor;

  static const double _titleSize = 16;
  static const double _descriptionSize = 14;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (iconAsset != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.small),
            child: SvgPicture.asset(
              iconAsset!,
              height: AppSpacing.xl,
              width: AppSpacing.xl,
              colorFilter: iconTint != null
                  ? ColorFilter.mode(iconTint!, BlendMode.srcIn)
                  : const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: _titleSize,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? AppColors.textPrimary,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
              ),
              const SizedBox(height: AppSpacing.micro),
              Text(
                description,
                style: TextStyle(
                  fontSize: _descriptionSize,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    const padding = EdgeInsets.all(AppSpacing.small);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.textPrimary,
          width: AppRadius.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(padding: padding, child: content),
    );
  }
}
