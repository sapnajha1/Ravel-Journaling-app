import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized auth state for the app.
///
/// - Exposes current session and user
/// - Listens to [Supabase] auth state changes
/// - Handles sign out and session errors
class AuthController extends ChangeNotifier {
  AuthController() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      onError: _onAuthError,
    );
    _session = Supabase.instance.client.auth.currentSession;
    _user = Supabase.instance.client.auth.currentUser;
  }

  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;
  User? _user;

  /// Current Supabase session, or null if not signed in.
  Session? get session => _session;

  /// Current user, or null if not signed in.
  User? get user => _user;

  /// True if there is a valid session.
  bool get isSignedIn => _session != null;

  /// Current user email for display (e.g. on Home and Profile).
  String? get userEmail => _user?.email;

  /// Display name from user metadata (e.g. full_name), or email prefix, or empty.
  String get displayName {
    if (_user == null) return '';
    final meta = _user!.userMetadata;
    if (meta != null) {
      final name = meta['full_name']?.toString();
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    final email = _user!.email;
    if (email != null && email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }
    return '';
  }

  /// Update display name in Supabase user metadata.
  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    final trimmed = name.trim();
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'full_name': trimmed.isEmpty ? null : trimmed}),
    );
    _user = Supabase.instance.client.auth.currentUser;
    notifyListeners();
  }

  /// Set when session was cleared due to error (expired/revoked), not user logout.
  /// AuthGate can show this once on LoginScreen then clear it.
  String? sessionExpiredMessage;

  void _onAuthStateChange(AuthState state) {
    final newSession = state.session;
    final newUser = newSession?.user;

    if (state.event == AuthChangeEvent.signedOut ||
        state.event == AuthChangeEvent.userDeleted) {
      _session = null;
      _user = null;
    } else {
      _session = newSession;
      _user = newUser;
    }
    notifyListeners();
  }

  void _onAuthError(Object error, StackTrace stackTrace) {
    // Session revoked, token invalid, or network error — treat as signed out
    sessionExpiredMessage =
        'Your session expired or was revoked. Please sign in again.';
    _session = null;
    _user = null;
    notifyListeners();
  }

  /// Clear the session-expired message after showing it (e.g. on LoginScreen).
  void clearSessionExpiredMessage() {
    if (sessionExpiredMessage != null) {
      sessionExpiredMessage = null;
      notifyListeners();
    }
  }

  /// Sign out and clear local session.
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _session = null;
    _user = null;
    notifyListeners();
  }

  /// Call when the app detects an invalid/expired session (e.g. from API 401).
  void clearSession() {
    _session = null;
    _user = null;
    notifyListeners();
  }

  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
