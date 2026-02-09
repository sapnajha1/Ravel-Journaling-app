import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_state.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<domain.AuthState> watchAuthState() async* {
    final initialSession = _client.auth.currentSession;
    final initial = domain.AuthState(
      isAuthenticated: initialSession != null,
      email: initialSession?.user.email,
    );

    final stream = _client.auth.onAuthStateChange.map((event) {
      final session = event.session;
      return domain.AuthState(
        isAuthenticated: session != null,
        email: session?.user.email,
      );
    });

    yield initial;
    yield* stream;
  }

  @override
  Future<void> sendMagicLink(String email, String redirectUrl) {
    return _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectUrl,
    );
  }
}
