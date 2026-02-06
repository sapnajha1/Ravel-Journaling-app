import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_controller.dart';
import '../widgets/dotted_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.authController,

  });

  final AuthController authController;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.authController.displayName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      // backgroundColor: const Color(0xFFFFF9F7),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DottedBackground(),
          ),
       SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
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
        
                /// INPUT
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF201B18),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF201B18),
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: nameController,
                    style: GoogleFonts.syneMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF201B18),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
        
                const SizedBox(height: 24),
        
                /// ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'assets/cross.svg',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () async {
                        await widget.authController.updateDisplayName(
                          nameController.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(context);
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
          ),
        ),
    ]
      ),
    );
  }
}
