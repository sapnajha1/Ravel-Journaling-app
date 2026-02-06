import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../domain/entities/auth_state.dart';

class AuthRepository {
  AuthRepository(this._client);

  final supabase.SupabaseClient _client;

  AuthState get currentState {
    final session = _client.auth.currentSession;
    if (session == null) {
      return AuthState.unauthenticated();
    }
    return AuthState.authenticated(session.user.email);
  }

  Stream<AuthState> authStateChanges() async* {
    yield currentState;
    await for (final supaState in _client.auth.onAuthStateChange) {
      final session = supaState.session;
      if (session == null) {
        yield AuthState.unauthenticated();
      } else {
        yield AuthState.authenticated(session.user.email);
      }
    }
  }

  Future<void> sendMagicLink({
    required String email,
    required String redirectUrl,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }
}
