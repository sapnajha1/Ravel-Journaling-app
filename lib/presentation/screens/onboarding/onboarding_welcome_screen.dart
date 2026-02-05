import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../widgets/app_text.dart';
import '../../widgets/onboarding_scaffold.dart';

class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      primaryLabel: "Let's Begin",
      onPrimaryPressed: () => context.go('/onboarding/actions'),
      onSkipPressed: () => context.go('/login'),
      child: Column(
        children: [
          const Spacer(),
          SvgPicture.asset(
            'assets/Group 6.svg',
            height: AppSpacing.section * 3,
          ),
          const SizedBox(height: AppSpacing.large),
          const AppText(
            'Welcome to your space\nfor honest feelings',
            style: AppTextStyle.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          AppText(
            'A safe place to process emotions, vent frustrations, and express yourself without judgment.',
            style: AppTextStyle.bodySmall,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
