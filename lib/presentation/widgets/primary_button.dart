import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_radius.dart';
import '../../design_system/app_shadows.dart';
import '../../design_system/app_spacing.dart';
import 'app_text.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xl,
      width: double.infinity,
        child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryBase,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: AppColors.textPrimary,
            width: AppRadius.borderWidth,
          ),
          boxShadow: const [AppShadows.shadow2],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Center(
              child: AppText(
                label,
                style: AppTextStyle.bodyMedium,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
