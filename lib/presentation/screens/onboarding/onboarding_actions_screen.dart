import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../widgets/app_text.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/onboarding_action_card.dart';

class OnboardingActionsScreen extends ConsumerWidget {
  const OnboardingActionsScreen({super.key});

  static const String _backgroundSvg = 'assets/cards/rant_history_bg.svg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      primaryLabel: 'Next',
      onPrimaryPressed: () => context.push('/onboarding/privacy'),
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.pop(),
      onSkipPressed: () => context.go('/login'),
      showBack: true,
      backButtonFlex: 3,
      nextButtonFlex: 7,
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              _backgroundSvg,
              fit: BoxFit.cover,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Three Ways to Process\nYour Feelings',
                style: AppTextStyle.titleLarge,
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
                      ),
                      const SizedBox(height: AppSpacing.small),
                      OnboardingActionCard(
                        title: 'Rant',
                        description:
                            'Get it off your chest, feel lighter in 2 minutes - no filter, no judgment',
                        iconAsset: 'assets/cards/cloud-storm-svgrepo-com 1.svg',
                        iconTint: AppColors.releaseBase,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      OnboardingActionCard(
                        title: 'Scribble',
                        description:
                            'Feelings don\'t always fit into words. Draw, paint, doodle - however it needs to come out',
                        iconAsset: 'assets/cards/scribble-svgrepo-com 1.svg',
                        iconTint: AppColors.expressBase,
                      ),
                      const SizedBox(height: AppSpacing.micro),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
