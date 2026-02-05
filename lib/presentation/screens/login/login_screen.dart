import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_radius.dart';
import '../../../design_system/app_spacing.dart';
import '../../app_providers.dart';
import '../../widgets/app_input_field.dart';
import '../../widgets/app_text.dart';
import '../../widgets/dotted_background_painter.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usecase = ref.read(sendMagicLinkProvider);
      final redirectUrl = ref.read(redirectUrlProvider);
      await usecase(email: email, redirectUrl: redirectUrl);
      if (mounted) {
        context.go('/magic-link-sent?email=$email');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                  const AppText(
                    'Login to Journal',
                    style: AppTextStyle.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  AppInputField(
                    controller: _emailController,
                    label: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_error != null) {
                        setState(() => _error = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  if (_error != null) ...[
                    AppText(
                      _error!,
                      style: AppTextStyle.bodySmall,
                      color: AppColors.errorBase,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  PrimaryButton(
                    label: _isLoading ? 'Sending...' : 'Get Magic Link',
                    onPressed: _isLoading ? null : _sendMagicLink,
                  ),
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
