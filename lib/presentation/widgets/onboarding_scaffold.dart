import 'package:flutter/material.dart';

import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import 'app_text.dart';
import 'dotted_background_painter.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.onSkipPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.showSkip = true,
    this.showBack = false,
  });

  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback onSkipPressed;
  final bool showSkip;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DottedBackgroundPainter(
                dotColor: AppColors.textTertiary.withOpacity(0.3),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.micro),
                  Row(
                    children: [
                      const Spacer(),
                      if (showSkip)
                        GestureDetector(
                          onTap: onSkipPressed,
                          child: AppText(
                            'Skip to Login',
                            style: AppTextStyle.bodySmall,
                            color: AppColors.primaryBase,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Expanded(child: child),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      if (showBack && secondaryLabel != null)
                        Expanded(
                          child: SecondaryButton(
                            label: secondaryLabel!,
                            onPressed: onSecondaryPressed,
                          ),
                        ),
                      if (showBack && secondaryLabel != null)
                        const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: PrimaryButton(
                          label: primaryLabel,
                          onPressed: onPrimaryPressed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
