import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../views/home_view.dart';

/// Result of the in-profile "Delete Account" dialog (keep journal data choice).
class DeleteAccountResult {
  const DeleteAccountResult({required this.clearLocalData});
  final bool clearLocalData;
}

/// Dialog shown from profile to delete account (with keep data option).
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _keepJournalData = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete Account',
              style: GoogleFonts.syneMono(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF201B18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete your account?',
              style: GoogleFonts.syneMono(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF52443F),
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
                      'Keep my journal data on this device',
                      style: GoogleFonts.syneMono(
                        fontSize: 14,
                        color: const Color(0xFF201B18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.syneMono(color: const Color(0xFF52443F)),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    DeleteAccountResult(clearLocalData: !_keepJournalData),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.syneMono(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7B6B),
                    ),
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

void showLogoutDialog(BuildContext context, AuthController authController) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Log out',
        style: GoogleFonts.syneMono(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF201B18),
        ),
      ),
      content: Text(
        'Are you sure you want to log out?',
        style: GoogleFonts.syneMono(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: const Color(0xFF52443F),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: GoogleFonts.syneMono(
              fontSize: 16,
              color: const Color(0xFF52443F),
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
              color: const Color(0xFFFF7B6B),
            ),
          ),
        ),
      ],
    ),
  );
}

void showDeleteRantDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final maxWidth = screenWidth - 32;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Delete Account',
                    style: GoogleFonts.syneMono(
                      color: const Color(0xFFFF7B6B),
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please confirm to delete your account. Data can be saved in local files and accessed again later',
                    style: GoogleFonts.syneMono(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 28),
                  const KeepJournalCheckbox(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/Frame 22(2).svg',
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            final rantVM = context.read<RantViewModel>();
                            await rantVM.deleteCurrentRant();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const HomeView(),
                              ),
                              (route) => false,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account Deleted'),
                              ),
                            );
                          },
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/Frame 177(1).svg',
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Checkbox used in delete-account dialogs for keeping journal data.
class KeepJournalCheckbox extends StatefulWidget {
  const KeepJournalCheckbox({super.key});

  @override
  State<KeepJournalCheckbox> createState() => _KeepJournalCheckboxState();
}

class _KeepJournalCheckboxState extends State<KeepJournalCheckbox> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    const boxColor = Color(0xFFFF7B6B);
    return InkWell(
      onTap: () {
        setState(() {
          isChecked = !isChecked;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: boxColor, width: 2),
            ),
            child: isChecked
                ? const Center(
                    child: Icon(Icons.check, size: 16, color: boxColor),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep my journal data in phone',
              style: GoogleFonts.syneMono(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.7,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
