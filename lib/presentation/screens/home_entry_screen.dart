import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../screens/home_screen.dart';

class HomeEntryScreen extends StatefulWidget {
  const HomeEntryScreen({super.key});

  @override
  State<HomeEntryScreen> createState() => _HomeEntryScreenState();
}

class _HomeEntryScreenState extends State<HomeEntryScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(authController: _authController);
  }
}
