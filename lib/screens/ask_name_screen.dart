import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../design_system/app_colors.dart';
import '../widgets/dotted_background.dart';

/// Shown after email verification (magic link) so the user can set their display name.
/// If they already have a name, redirects to home. On "Proceed", saves name and goes to home.
class AskNameScreen extends StatefulWidget {
  const AskNameScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AskNameScreen> createState() => _AskNameScreenState();
}

class _AskNameScreenState extends State<AskNameScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Name is compulsory: user must enter name and tap Proceed (no auto-skip to home).
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      await widget.authController.updateDisplayName(name);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  SvgPicture.asset(
                    'assets/smiling-emoji.svg',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'What name should we call you',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.syneMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Your Name...',
                      hintStyle: GoogleFonts.syneMono(
                        fontSize: 16,
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryBase, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.syneMono(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: GoogleFonts.syneMono(
                        fontSize: 14,
                        color: AppColors.errorBase,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF2A2A2A),
                            blurRadius: 0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: AppColors.primaryBase,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: _isLoading ? null : _proceed,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Proceed',
                                      style: GoogleFonts.syneMono(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
