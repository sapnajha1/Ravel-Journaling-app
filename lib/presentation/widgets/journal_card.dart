import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_shadows.dart';
import '../../design_system/app_spacing.dart';
import 'app_text.dart';

class JournalCard extends StatelessWidget {
  const JournalCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String iconAsset;
  final Color accentColor;

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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: AppSpacing.xl,
              width: AppSpacing.xl,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(AppRadius.circular),
                border: Border.all(
                  color: AppColors.textPrimary,
                  width: AppRadius.borderWidth,
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  height: AppSpacing.small,
                  width: AppSpacing.small,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
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
    );
  }
}
