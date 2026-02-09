import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../app_providers.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/onboarding_action_card.dart';

class OnboardingActionsScreen extends ConsumerWidget {
  const OnboardingActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      primaryLabel: 'Next',
      onPrimaryPressed: () => context.push('/onboarding/privacy'),
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.pop(),
      onSkipPressed: () async {
        await ref.read(onboardingStatusProvider.notifier).complete();
        if (context.mounted) context.go('/login');
      },
      showBack: true,
      backButtonFlex: 3,
      nextButtonFlex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Three Ways to Process\nYour Feelings',
            style: TextStyle(
              fontSize: 24,
              height: 1.3,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.syneMono().fontFamily,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OnboardingActionCard(
                    title: 'Reflect',
                    description: 'Turn messy thoughts into clear next steps',
                    iconAsset: 'assets/cards/mirror-3.svg',
                    iconTint: AppColors.purpleBase,
                    titleColor: AppColors.purpleBase,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OnboardingActionCard(
                    title: 'Rant',
                    description:
                        'Get it off your chest, feel lighter in 2 minutes - no filter, no judgment',
                    iconAsset: 'assets/cards/cloud-storm-svgrepo-com 1.svg',
                    iconTint: AppColors.releaseBase,
                    titleColor: AppColors.releaseBase,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OnboardingActionCard(
                    title: 'Scribble',
                    description:
                        'Feelings don\'t always fit into words. Draw, paint, doodle - however it needs to come out',
                    iconAsset: 'assets/cards/scribble-svgrepo-com 1.svg',
                    iconTint: AppColors.expressBase,
                    titleColor: AppColors.expressBase,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
