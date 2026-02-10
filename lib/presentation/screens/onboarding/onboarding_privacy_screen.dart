import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
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
        try {
          await ref.read(onboardingStatusProvider.notifier).complete();
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('Onboarding complete (privacy primary) failed: $e\n$st');
          }
        }
        if (context.mounted) {
          context.push('/login');
        }
      },
      secondaryLabel: 'Back',
      onSecondaryPressed: () => context.pop(),
      onSkipPressed: () async {
        try {
          await ref.read(onboardingStatusProvider.notifier).complete();
        } catch (e, st) {
          if (kDebugMode) {
            debugPrint('Onboarding skip (privacy) failed: $e\n$st');
          }
        }
        if (context.mounted) context.go('/login');
      },
      showBack: true,
      backButtonFlex: 3,
      nextButtonFlex: 7,
      child: Column(
        children: [
          const Spacer(),
          SvgPicture.asset(
            'assets/cards/login-2.svg',
            height: AppSpacing.section,
            width: AppSpacing.section,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.large),
          const AppText(
            'Your Safe Space',
            style: AppTextStyle.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          AppText(
            'We never read your entries, ever.\nYour data is protected end to end.',
            style: AppTextStyle.bodyMedium,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
