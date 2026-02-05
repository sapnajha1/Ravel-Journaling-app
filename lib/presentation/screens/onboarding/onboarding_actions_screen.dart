import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../widgets/app_text.dart';
import '../../widgets/journal_card.dart';
import '../../widgets/onboarding_scaffold.dart';

class OnboardingActionsScreen extends ConsumerWidget {
  const OnboardingActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      primaryLabel: 'Next',
      onPrimaryPressed: () => context.go('/onboarding/privacy'),
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/onboarding/welcome'),
      onSkipPressed: () => context.go('/login'),
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Three Ways to Process\nYour Feelings',
            style: AppTextStyle.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.large),
          JournalCard(
            title: 'Reflect',
            description: 'Turn messy thoughts into next steps.',
            iconAsset: 'assets/cards/mirror-3.svg',
            accentColor: AppColors.purpleLight,
          ),
          const SizedBox(height: AppSpacing.small),
          SvgPicture.asset(
            'assets/cards/rant_history_bg.svg',
            width: double.infinity,
          ),
          const SizedBox(height: AppSpacing.small),
          JournalCard(
            title: 'Scribble',
            description: 'Feelings don\'t always fit into words.',
            iconAsset: 'assets/cards/scribble-svgrepo-com 1.svg',
            accentColor: AppColors.expressLight,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
