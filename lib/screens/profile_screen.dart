import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../data/local/local_store.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../views/home_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authController.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ignore: unused_element
  void _openEditName() {
    setState(() => _isEditingName = true);
  }

  // ignore: unused_element
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<_DeleteAccountResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _DeleteAccountDialog(),
    );
    if (confirmed == null || !mounted) return;
    if (confirmed.clearLocalData) {
      try {
        LocalStore.journalBox().clear();
        LocalStore.promptBox().clear();
      } catch (_) {}
    }
    try {
      await widget.authController.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = widget.authController;
    final email = authController.userEmail ?? '';
    final displayName = authController.displayName;
    final userName = displayName.trim().isNotEmpty ? displayName : (authController.userEmail?.split('@').first ?? 'User');

    if (_isEditingName) {
      return _buildEditNameContent(authController);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.syneMono(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: const Color(0xFF201B18),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/smiling-emoji.svg',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    userName,
                    style: GoogleFonts.syneMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(0xFF201B18),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    _nameController.text = authController.displayName;
                    setState(() => _isEditingName = true);
                  },
                  child: SvgPicture.asset(
                    'assets/pencil-3.svg',
                    width: 26,
                    height: 24,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                SvgPicture.asset(
                  'assets/mail-open.svg',
                  width: 33,
                  height: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.syneMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(0xFF201B18),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x00201B18), // transparent left
                    Color(0xFF201B18), // solid center
                    Color(0x00201B18), // transparent right
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),





            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _showLogoutDialog(context, authController),
              child: SvgPicture.asset(
                'assets/Frame 183.svg',
                width: 91,
                height: 27,
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x00201B18), // transparent left
                    Color(0xFF201B18), // solid center
                    Color(0x00201B18), // transparent right
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),


            const SizedBox(height: 24),

            GestureDetector(
              onTap: () async {
                showDeleteRantDialog(context);
              },
              child: SvgPicture.asset(
                'assets/Frame 182.svg',
                width: 164,
                height: 27,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditNameContent(AuthController authController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit Name',
            style: GoogleFonts.syneMono(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: const Color(0xFF201B18),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Change Name',
            style: GoogleFonts.syneMono(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.7,
              color: const Color(0xFF52443F),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: GoogleFonts.syneMono(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF201B18),
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFFFF9F7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF201B18), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF201B18), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF201B18), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _isEditingName = false);
                },
                child: SvgPicture.asset(
                  'assets/cross.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () async {
                  final newName = _nameController.text.trim();
                  setState(() => _isEditingName = false);
                  await authController.updateDisplayName(newName);
                },
                child: SvgPicture.asset(
                  'assets/tick.svg',
                  width: 34,
                  height: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountResult {
  const _DeleteAccountResult({required this.clearLocalData});
  final bool clearLocalData;
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
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
                    _keepJournalData ? Icons.check_box : Icons.check_box_outline_blank,
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
                  child: Text('Cancel', style: GoogleFonts.syneMono(color: const Color(0xFF52443F))),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_DeleteAccountResult(clearLocalData: !_keepJournalData)),
                  child: Text('Delete', style: GoogleFonts.syneMono(fontWeight: FontWeight.w600, color: const Color(0xFFFF7B6B))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context, AuthController authController) {
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
          /// ⬜ CHECK BOX (outline only)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: boxColor,
                width: 2,
              ),
            ),
            child: isChecked
                ? const Center(
              child: Icon(
                Icons.check,
                size: 16,
                color: boxColor,
              ),
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

