import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_colors.dart';

/// Reusable two-button row for bottom sheets and dialogs.
/// Secondary (outline) on the left, primary (coral) on the right.
class BottomSheetActionButtons extends StatelessWidget {
  const BottomSheetActionButtons({
    super.key,
    required this.secondaryLabel,
    required this.secondaryOnPressed,
    required this.primaryLabel,
    required this.primaryOnPressed,
  });

  final String secondaryLabel;
  final VoidCallback secondaryOnPressed;
  final String primaryLabel;
  final VoidCallback primaryOnPressed;

  static TextStyle _buttonTextStyle(FontWeight weight) => TextStyle(
        fontWeight: weight,
        color: AppColors.textPrimary,
        fontFamily: GoogleFonts.syneMono().fontFamily,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WhiteOutlineButton(
            onPressed: secondaryOnPressed,
            child: Text(secondaryLabel, style: _buttonTextStyle(FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShadowButton(
            onPressed: primaryOnPressed,
            child: Text(primaryLabel, style: _buttonTextStyle(FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

/// Coral primary button with border and shadow (reflect, history).
class ShadowButton extends StatelessWidget {
  const ShadowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 36,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFFF6E5A),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White outline secondary button (dialogs).
class WhiteOutlineButton extends StatelessWidget {
  const WhiteOutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Center(
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
