import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../viewmodels/rantViewModel/rant_view_model.dart';
import '../views/home_view.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.authController, });

  final AuthController authController;


  @override
  Widget build(BuildContext context) {
    final email = authController.userEmail ?? '';
    final userName =
        authController.userEmail?.split('@').first ?? 'User';

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

                Text(
                  userName,
                  style: GoogleFonts.syneMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: const Color(0xFF201B18),
                  ),
                ),

                /// PUSH TO EXTREME RIGHT
                const Spacer(),

                GestureDetector(
                  onTap:
                  // nEdit,
                      () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(authController: authController,),
                      ),
                    );
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
              onTap: () async {
                await authController.signOut();
              },
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
}




void showDeleteRantDialog(BuildContext context) {

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1.5),
            borderRadius: BorderRadius.zero, // square box
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔴 TITLE
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

              /// ⚫ DESCRIPTION
              Text(
                'Please confirm to delete your account. Data can be saved in local files and accessed again later',
                style: GoogleFonts.syneMono(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 28),

              const KeepJournalCheckbox(),


              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  /// CANCEL BUTTON
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: SvgPicture.asset(
                      'assets/Frame 22(2).svg',
                      height: 48,
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// DELETE BUTTON
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);

                      final rantVM = context.read<RantViewModel>();
                      await rantVM.deleteCurrentRant();

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeView(),
                        ),
                            (route) => false,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account Deleted'),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/Frame 177(1).svg',
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
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

          /// TEXT
          Text(
            'Keep my journal data in phone',
            style: GoogleFonts.syneMono(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

