import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../config/supabase_config.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_spacing.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/app_input_field.dart';
import '../../widgets/app_text.dart';
import '../../widgets/primary_button.dart';

class LoginMagicLinkScreen extends ConsumerStatefulWidget {
  const LoginMagicLinkScreen({super.key});

  @override
  ConsumerState<LoginMagicLinkScreen> createState() =>
      _LoginMagicLinkScreenState();
}

class _LoginMagicLinkScreenState
    extends ConsumerState<LoginMagicLinkScreen> {
  final _emailController = TextEditingController();
  String? _errorMessage;
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }

    final valid =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (!valid) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendMagicLink(email, SupabaseConfig.authRedirectUrl);
      ref.read(pendingEmailProvider.notifier).state = email;
      if (mounted) context.go('/magic-link-sent');
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.tight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/Group 13.svg'),
              const SizedBox(height: AppSpacing.large),
              AppText(
                'Login to Journal',
                style: AppTextStyle.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              AppInputField(
                controller: _emailController,
                label: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.large),
              if (_errorMessage != null) ...[
                AppText(
                  _errorMessage!,
                  style: AppTextStyle.bodySmall,
                  color: AppColors.errorBase,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
              ],
              PrimaryButton(
                label: _isSending ? 'Sending…' : 'Get Magic Link',
                onPressed: _isSending ? null : _sendMagicLink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
