import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_shadows.dart';
import '../../design_system/app_spacing.dart';
import 'app_text.dart';

/// Onboarding card for Reflect/Rant/Scribble. Icon has no border; optional background SVG for Rant.
class OnboardingActionCard extends StatelessWidget {
  const OnboardingActionCard({
    super.key,
    required this.title,
    required this.description,
    this.iconAsset,
    this.iconTint,
    this.backgroundSvg,
  }) : assert(iconAsset != null || backgroundSvg != null,
            'Provide iconAsset or backgroundSvg');

  final String title;
  final String description;
  final String? iconAsset;
  final Color? iconTint;
  final String? backgroundSvg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.textPrimary,
          width: AppRadius.borderWidth,
        ),
        boxShadow: const [AppShadows.shadow5],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: backgroundSvg != null
            ? Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      backgroundSvg!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                title,
                                style: AppTextStyle.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.micro),
                              AppText(
                                description,
                                style: AppTextStyle.bodySmall,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(AppSpacing.small),
                child: Row(
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
                              ? ColorFilter.mode(
                                  iconTint!,
                                  BlendMode.srcIn,
                                )
                              : const ColorFilter.mode(
                                  AppColors.textPrimary,
                                  BlendMode.srcIn,
                                ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            title,
                            style: AppTextStyle.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.micro),
                          AppText(
                            description,
                            style: AppTextStyle.bodySmall,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
