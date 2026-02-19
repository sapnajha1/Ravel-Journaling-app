import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_colors.dart';

/// Tool icon for scribble toolbar (pen, eraser, undo, redo, clear).
class ScribbleToolIcon extends StatelessWidget {
  const ScribbleToolIcon({
    super.key,
    required this.asset,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  static const Color _bgBlack = Color(0xFF201B18);

  @override
  Widget build(BuildContext context) {
    final Color? iconTint = selected ? (selectedColor ?? Colors.white) : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _bgBlack,
          shape: BoxShape.circle,
          border: Border.all(color: _bgBlack, width: 0.5),
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 38,
            height: 38,
            fit: BoxFit.contain,
            colorFilter: iconTint != null
                ? ColorFilter.mode(iconTint, ui.BlendMode.srcIn)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Outline (white) button for scribble dialogs.
class ScribbleOutlineButton extends StatelessWidget {
  const ScribbleOutlineButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.fontSize = 14,
  });

  final VoidCallback onPressed;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.textPrimary, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.syneMono().fontFamily,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Coral primary button for scribble dialogs.
class ScribbleCoralButton extends StatelessWidget {
  const ScribbleCoralButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.fontSize = 14,
  });

  final VoidCallback onPressed;
  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBase,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.primaryDark, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.syneMono().fontFamily,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clear canvas confirmation dialog.
class ClearCanvasDialog extends StatelessWidget {
  const ClearCanvasDialog({
    super.key,
    required this.onClear,
    required this.onKeep,
  });

  final VoidCallback onClear;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryBase, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Clear Canvas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: GoogleFonts.syneMono().fontFamily,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Starting from clean slate will lose the current scribbling',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontFamily: GoogleFonts.syneMono().fontFamily,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ScribbleOutlineButton(
                    onPressed: onClear,
                    label: 'Clear',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ScribbleCoralButton(
                    onPressed: onKeep,
                    label: 'Keep Scribbling',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
