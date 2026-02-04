import 'package:flutter/material.dart';
import 'auth_controller.dart';

import '../config/supabase_config.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

/// Root widget that shows Login or Home based on auth state.
///
/// - If session exists → [HomeScreen]
/// - If no session → [LoginScreen]
/// Listens to [AuthController] so magic link sign-in redirects to Home.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Show login until we have a session
    if (!_auth.isSignedIn) {
      return MaterialApp(
        title: 'Journal App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: LoginScreen(
          redirectUrl: SupabaseConfig.authRedirectUrl,
          authController: _auth,
        ),
      );
    }

    return MaterialApp(
      title: 'Journal App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: HomeScreen(authController: _auth),
    );
  }
}
