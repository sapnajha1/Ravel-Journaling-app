import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_controller.dart';
import '../data/local/local_store.dart';
import '../design_system/app_colors.dart';
import '../widgets/dotted_background.dart';

/// Profile tab: user name, email, Edit Name, Logout, Delete Account.
/// Matches design: large title, white card, Edit Name screen, Delete confirmation dialog.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthUpdate);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthUpdate);
    super.dispose();
  }

  void _onAuthUpdate() => setState(() {});

  Future<void> _logout() async {
    try {
      await widget.authController.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _openEditName() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EditNameScreen(
          authController: widget.authController,
          initialName: widget.authController.displayName,
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<_DeleteAccountResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const _DeleteAccountDialog(),
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
    final name = widget.authController.displayName;
    final email = widget.authController.userEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(title: 'Profile', subtitle: 'Profile'),
                  const SizedBox(height: 24),
                  _ProfileCard(
                    name: name.isEmpty ? 'No name' : name,
                    email: email,
                    onEditName: _openEditName,
                    onLogout: _logout,
                    onDeleteAccount: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: GoogleFonts.syneMono().fontFamily,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
            fontFamily: GoogleFonts.syneMono().fontFamily,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.onEditName,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final String name;
  final String email;
  final VoidCallback onEditName;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF2A2A2A),
            blurRadius: 0,
            offset: Offset(3, 3),
          ),
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.sentiment_satisfied_alt_rounded,
                  size: 24, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: GoogleFonts.syneMono().fontFamily,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEditName,
                icon: const Icon(Icons.edit_outlined, size: 22),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.mail_outline, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: GoogleFonts.syneMono().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          _ProfileRow(
            icon: Icons.logout_rounded,
            label: 'Logout',
            onTap: onLogout,
            trailing: Icons.arrow_forward_ios,
            size: 14,
          ),
          const SizedBox(height: 12),
          _ProfileRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Account',
            onTap: onDeleteAccount,
            trailing: null,
            iconColor: AppColors.errorBase,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.size = 22,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: size, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontFamily: GoogleFonts.syneMono().fontFamily,
                ),
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 12, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Edit Name screen: "Edit Name" header, Change Name field, cancel (X) and save (check) icons.
class _EditNameScreen extends StatefulWidget {
  const _EditNameScreen({
    required this.authController,
    required this.initialName,
  });

  final AuthController authController;
  final String initialName;

  @override
  State<_EditNameScreen> createState() => _EditNameScreenState();
}

class _EditNameScreenState extends State<_EditNameScreen> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    setState(() => _saving = true);
    try {
      await widget.authController.updateDisplayName(name);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: DottedBackground()),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(title: 'Edit Name', subtitle: 'Profile'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF2A2A2A),
                          blurRadius: 0,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Change Name',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: GoogleFonts.syneMono().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: GoogleFonts.syneMono().fontFamily,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              color: AppColors.errorBase,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: AppColors.errorBase),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              color: AppColors.expressBase,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.expressLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountResult {
  const _DeleteAccountResult({required this.clearLocalData});
  final bool clearLocalData;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _keepJournalData = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBase, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x50000000),
              blurRadius: 12,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBase,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please confirm to delete your account. Data can be saved in local files and accessed again later.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
                fontFamily: GoogleFonts.syneMono().fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () =>
                  setState(() => _keepJournalData = !_keepJournalData),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepJournalData,
                      onChanged: (v) =>
                          setState(() => _keepJournalData = v ?? true),
                      activeColor: AppColors.primaryBase,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep my journal data in phone.',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: GoogleFonts.syneMono().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop<_DeleteAccountResult?>(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBase,
                      side: BorderSide(color: AppColors.primaryBase),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _DeleteAccountResult(clearLocalData: !_keepJournalData),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBase,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.syneMono().fontFamily,
                      ),
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
