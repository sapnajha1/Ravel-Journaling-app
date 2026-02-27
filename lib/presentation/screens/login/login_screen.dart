import 'dart:async';
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
    print('🔐 [LOGIN DEBUG] Starting magic link for email: $email');

    if (email.isEmpty) {
      print('🔐 [LOGIN DEBUG] Email empty, showing error');
      setState(() => _error = 'Please enter your email.');
      return;
    }

    print('🔐 [LOGIN DEBUG] Setting loading state true');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔐 [LOGIN DEBUG] Reading providers...');
      final usecase = ref.read(sendMagicLinkProvider);
      final redirectUrl = ref.read(redirectUrlProvider);
      print('🔐 [LOGIN DEBUG] Redirect URL: $redirectUrl');

      print('🔐 [LOGIN DEBUG] Calling usecase with email: $email');

      // Reduce timeout since we're handling timeouts better in repository
      await usecase(email: email, redirectUrl: redirectUrl).timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          print('🔐 [LOGIN DEBUG] Usecase timeout - but email likely sent');
          // Don't throw - treat as success since Supabase often sends emails even when API times out
        },
      );

      print('🔐 [LOGIN DEBUG] Magic link sent successfully!');
      if (mounted) {
        print('🔐 [LOGIN DEBUG] Widget is mounted, navigating...');
        print('🔐 [LOGIN DEBUG] Navigating to magic-link-sent screen with email: $email');
        context.go('/magic-link-sent?email=$email');
        print('🔐 [LOGIN DEBUG] Navigation call completed');
      } else {
        print('🔐 [LOGIN DEBUG] Widget not mounted, skipping navigation');
      }
    } on TimeoutException catch (e) {
      print('🔐 [LOGIN DEBUG] TIMEOUT EXCEPTION: $e');
      // Treat timeout as success and navigate to magic-link-sent
      print('🔐 [LOGIN DEBUG] Treating timeout as success - navigating to magic-link-sent');
      if (mounted) {
        context.go('/magic-link-sent?email=$email');
      }
    } catch (e, stackTrace) {
      print('🔐 [LOGIN DEBUG] CAUGHT EXCEPTION: $e');
      print('🔐 [LOGIN DEBUG] Exception type: ${e.runtimeType}');
      print('🔐 [LOGIN DEBUG] Stack trace: $stackTrace');
      if (mounted) {
        print('🔐 [LOGIN DEBUG] Setting error state');
        setState(() => _error = 'Something went wrong: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        print('🔐 [LOGIN DEBUG] Finally block - setting loading state false');
        setState(() => _isLoading = false);
      } else {
        print('🔐 [LOGIN DEBUG] Finally block - widget not mounted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    // While auth is resolving (e.g. returning from magic link), show loading to avoid flashing login form.
    if (authAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBase,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
