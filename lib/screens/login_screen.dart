import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';

/// Login screen: email input and "Send Magic Link" via Supabase OTP.
///
/// Handles loading, success, and error states (no internet, expired OTP,
/// invalid token, etc.).
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.redirectUrl,
    this.authController,
  });

  /// Redirect URL for magic link (must be in Supabase Dashboard redirect URLs).
  final String redirectUrl;

  /// Optional: for showing session-expired message and clearing it.
  final AuthController? authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }

    // Basic email format check
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Optional: check connectivity for clearer error message
      final results = await Connectivity().checkConnectivity();
      final hasNoConnectivity = results.length == 1 &&
          results.first == ConnectivityResult.none;
      if (hasNoConnectivity) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No internet connection. Please check your network and try again.';
        });
        return;
      }
    } catch (_) {
      // Ignore connectivity errors; let Supabase call fail with network error
    }

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: widget.redirectUrl,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successMessage =
            'Check your inbox! We sent a magic link to $email. Tap the link to sign in.';
        _errorMessage = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = _authErrorMessage(e);
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('SocketException') ||
                e.toString().contains('Connection')
            ? 'No internet connection. Please check your network and try again.'
            : 'Something went wrong. Please try again.';
      });
      debugPrint('Login error: $e\n$st');
    }
  }

  String _authErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (msg.contains('invalid') || msg.contains('expired')) {
      return 'This link is invalid or has expired. Request a new magic link.';
    }
    if (msg.contains('email') && msg.contains('confirm')) {
      return 'Please use the latest magic link we sent. Older links may have expired.';
    }
    return e.message.isNotEmpty ? e.message : 'Sign-in failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final sessionExpiredMessage =
        widget.authController?.sessionExpiredMessage;
    if (sessionExpiredMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.authController?.clearSessionExpiredMessage();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(sessionExpiredMessage),
              backgroundColor: Colors.orange.shade800,
            ),
          );
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Journal App',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with a magic link sent to your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    onChanged: (_) {
                      if (_errorMessage != null || _successMessage != null) {
                        setState(() {
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _sendMagicLink,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? 'Sending…' : 'Send Magic Link'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
