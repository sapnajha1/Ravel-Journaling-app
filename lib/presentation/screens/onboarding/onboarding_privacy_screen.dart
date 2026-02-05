import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_radius.dart';
import '../../../design_system/app_spacing.dart';
import '../../app_providers.dart';
import '../../widgets/app_text.dart';
import '../../widgets/onboarding_scaffold.dart';

class OnboardingPrivacyScreen extends ConsumerWidget {
  const OnboardingPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingScaffold(
      primaryLabel: 'Next',
      onPrimaryPressed: () async {
        await ref.read(onboardingStatusProvider.notifier).complete();
        if (context.mounted) {
          context.go('/login');
        }
      },
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.go('/onboarding/actions'),
      onSkipPressed: () => context.go('/login'),
      showBack: true,
      child: Column(
        children: [
          const Spacer(),
          Container(
            height: AppSpacing.section,
            width: AppSpacing.section,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.circular),
              border: Border.all(
                color: AppColors.textPrimary,
                width: AppRadius.borderWidth,
              ),
            ),
            child: const Icon(
              Icons.lock_outline,
              color: AppColors.textPrimary,
              size: AppSpacing.large,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          const AppText(
            'Your Safe Space',
            style: AppTextStyle.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          AppText(
            'We never read your entries, ever.\nYour data is protected end to end.',
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
