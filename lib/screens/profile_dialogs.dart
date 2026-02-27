import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_controller.dart';
import '../design_system/app_colors.dart';
import '../widgets/shared_buttons.dart';

/// Result of the in-profile "Delete Account" bottom sheet (keep journal data choice).
class DeleteAccountResult {
  const DeleteAccountResult({required this.clearLocalData});
  final bool clearLocalData;
}

/// Shows a bottom sheet for deleting account (with keep data option).
/// Matches the reflect screen analysis bottom sheet style.
Future<DeleteAccountResult?> showDeleteAccountBottomSheet(
  BuildContext context,
) {
  return showModalBottomSheet<DeleteAccountResult>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _DeleteAccountBottomSheet(),
  );
}

class _DeleteAccountBottomSheet extends StatefulWidget {
  const _DeleteAccountBottomSheet();

  @override
  State<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends State<_DeleteAccountBottomSheet> {
  bool _keepJournalData = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Are you sure you want to delete your account? Data can be saved in local files and accessed again later.',
            style: GoogleFonts.syneMono(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _keepJournalData = !_keepJournalData),
            child: Row(
              children: [
                Icon(
                  _keepJournalData
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: const Color(0xFFFF7B6B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep my journal data in phone',
                    style: GoogleFonts.syneMono(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BottomSheetActionButtons(
            secondaryLabel: 'Cancel',
            secondaryOnPressed: () => Navigator.of(context).pop(),
            primaryLabel: 'Delete',
            primaryOnPressed: () => Navigator.of(context).pop(
              DeleteAccountResult(clearLocalData: !_keepJournalData),
            ),
          ),
        ],
      ),
    );
  }
}

void showLogoutDialog(BuildContext context, AuthController authController) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Log out',
        style: GoogleFonts.syneMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: GoogleFonts.syneMono(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: GoogleFonts.syneMono(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await authController.signOut();
          },
          child: Text(
            'Log out',
            style: GoogleFonts.syneMono(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBase,
            ),
          ),
        ),
      ],
    ),
  );
}

