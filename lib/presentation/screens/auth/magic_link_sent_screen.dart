import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../../design_system/app_text_styles.dart';
import '../../../config/supabase_config.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/app_text.dart';

class MagicLinkSentScreen extends ConsumerWidget {
  const MagicLinkSentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(pendingEmailProvider) ?? 'your email';
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.tight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/Group 13(1).svg'),
              const SizedBox(height: AppSpacing.large),
              AppText(
                'To continue, please check and click\n'
                'the link sent to $email',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.large),
              AppText(
                "Didn't receive the email?",
                style: AppTextStyles.bodySmall,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () async {
                  final resendEmail = ref.read(pendingEmailProvider);
                  if (resendEmail == null) return;
                  await ref
                      .read(authNotifierProvider.notifier)
                      .sendMagicLink(resendEmail, SupabaseConfig.authRedirectUrl);
                },
                child: AppText(
                  'Resend Email',
                  style: AppTextStyles.bodySmall,
                  color: AppColors.primaryBase,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
