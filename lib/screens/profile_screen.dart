import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_controller.dart';
import '../data/local/local_store.dart';
import '../design_system/app_colors.dart';
import '../services/delete_account_service.dart';
import 'profile_dialogs.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  late String _analysisPreference;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authController.displayName);
    _analysisPreference = LocalStore.appSettingsBox().get(
          LocalStore.analysisPreferenceKey,
          defaultValue: LocalStore.analysisPreferenceAlways,
        ) as String;
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

  Future<void> _saveAnalysisPreference(String value) async {
    await LocalStore.appSettingsBox().put(LocalStore.analysisPreferenceKey, value);
    setState(() => _analysisPreference = value);
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDeleteAccountBottomSheet(context);
    if (confirmed == null || !mounted) return;

    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting account...')),
    );

    final result = await DeleteAccountService().deleteAccount();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    switch (result) {
      case DeleteAccountSuccess():
        if (confirmed.clearLocalData) {
          try {
            LocalStore.journalBox().clear();
            LocalStore.promptBox().clear();
          } catch (_) {}
        }
        try {
          await widget.authController.signOut();
        } catch (_) {
          // User already deleted; signOut may fail. Clear local state anyway.
        }
        if (!mounted) return;
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      case DeleteAccountFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete account: $message')),
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
                    Color(0x00201B18),
                    Color(0xFF201B18),
                    Color(0x00201B18),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Analysis Permission',
              style: GoogleFonts.syneMono(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.7,
                color: const Color(0xFF52443F),
              ),
            ),
            const SizedBox(height: 12),
            _AnalysisRadioOption(
              label: 'Analyze my reflection everytime',
              value: LocalStore.analysisPreferenceAlways,
              groupValue: _analysisPreference,
              onChanged: _saveAnalysisPreference,
            ),
            const SizedBox(height: 8),
            _AnalysisRadioOption(
              label: 'Ask me everytime',
              value: LocalStore.analysisPreferenceAsk,
              groupValue: _analysisPreference,
              onChanged: _saveAnalysisPreference,
            ),
            const SizedBox(height: 8),
            _AnalysisRadioOption(
              label: 'Don\'t analyze my reflection',
              value: LocalStore.analysisPreferenceNever,
              groupValue: _analysisPreference,
              onChanged: _saveAnalysisPreference,
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
                    Color(0x00201B18),
                    Color(0xFF201B18),
                    Color(0x00201B18),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => showLogoutDialog(context, authController),
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
              onTap: _showDeleteAccountDialog,
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

class _AnalysisRadioOption extends StatelessWidget {
  const _AnalysisRadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              activeColor: AppColors.purpleBase,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.syneMono(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF201B18),
            ),
          ),
        ],
      ),
    );
  }
}

