import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_radius.dart';
import '../../../design_system/app_spacing.dart';
import '../../app_providers.dart';
import '../../widgets/app_text.dart';
import '../../widgets/dotted_background_painter.dart';

class MagicLinkSentScreen extends ConsumerStatefulWidget {
  const MagicLinkSentScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<MagicLinkSentScreen> createState() =>
      _MagicLinkSentScreenState();
}

class _MagicLinkSentScreenState extends ConsumerState<MagicLinkSentScreen> {
  bool _isResending = false;
  String? _error;

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      final usecase = ref.read(sendMagicLinkProvider);
      final redirectUrl = ref.read(redirectUrlProvider);
      await usecase(email: widget.email, redirectUrl: redirectUrl);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not resend. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

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
                  AppText(
                    'To continue, please check and click the link sent to ${widget.email}.',
                    style: AppTextStyle.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  const AppText(
                    "Didn't receive the email?",
                    style: AppTextStyle.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  GestureDetector(
                    onTap: _isResending ? null : _resend,
                    child: AppText(
                      _isResending ? 'Resending...' : 'Resend Email',
                      style: AppTextStyle.bodySmall,
                      color: AppColors.primaryBase,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.small),
                    AppText(
                      _error!,
                      style: AppTextStyle.bodySmall,
                      color: AppColors.errorBase,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
