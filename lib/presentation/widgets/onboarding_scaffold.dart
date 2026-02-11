import 'package:flutter/material.dart';

import '../../../widgets/dotted_background.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import 'app_text.dart';
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
    this.backButtonFlex = 3,
    this.nextButtonFlex = 7,
    this.title,
  });

  final Widget child;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final VoidCallback onSkipPressed;
  final bool showSkip;
  final bool showBack;
  /// Back:Next width ratio (e.g. 3:7 for 30:70).
  final int backButtonFlex;
  final int nextButtonFlex;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: Stack(
        children: [
          const Positioned.fill(child: DottedBackground()),
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
                          behavior: HitTestBehavior.translucent,
                          onTap: onSkipPressed,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.small),
                            child: AppText(
                              'Skip to Login',
                              style: AppTextStyle.bodySmall,
                              color: AppColors.primaryBase,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (title != null) ...[
                    const SizedBox(height: AppSpacing.small),
                    title!,
                  ],
                  const SizedBox(height: AppSpacing.large),
                  Expanded(child: child),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      if (showBack && secondaryLabel != null)
                        Expanded(
                          flex: backButtonFlex,
                          child: SecondaryButton(
                            label: secondaryLabel!,
                            onPressed: onSecondaryPressed,
                          ),
                        ),
                      if (showBack && secondaryLabel != null)
                        const SizedBox(width: AppSpacing.small),
                      Expanded(
                        flex: nextButtonFlex,
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
