import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../app_providers.dart';
import '../../../widgets/dotted_background.dart';
import '../../widgets/app_input_field.dart';
import '../../widgets/app_text.dart';
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
          const Positioned.fill(child: DottedBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              child: Column(
                children: [
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/cards/login-page-2.svg',
                    height: AppSpacing.section,
                    width: AppSpacing.section,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  const AppText(
                    'Login to Journal',
                    style: AppTextStyle.titleLarge,
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
