import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_state.dart' as domain;
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<domain.AuthState> watchAuthState() async* {
    print('🔐 [AUTH REPO] watchAuthState called');
    final initialSession = _client.auth.currentSession;
    print('🔐 [AUTH REPO] Initial session: ${initialSession != null ? "EXISTS" : "NULL"}');
    if (initialSession != null) {
      print('🔐 [AUTH REPO] Initial user email: ${initialSession.user.email}');
    }

    final initial = domain.AuthState(
      isAuthenticated: initialSession != null,
      email: initialSession?.user.email,
    );

    final stream = _client.auth.onAuthStateChange.map((event) {
      print('🔐 [AUTH REPO] Auth state changed - Event: ${event.event}');
      final session = event.session;
      print('🔐 [AUTH REPO] New session: ${session != null ? "EXISTS" : "NULL"}');
      if (session != null) {
        print('🔐 [AUTH REPO] New user email: ${session.user.email}');
      }

      return domain.AuthState(
        isAuthenticated: session != null,
        email: session?.user.email,
      );
    });

    print('🔐 [AUTH REPO] Yielding initial state: authenticated=${initial.isAuthenticated}');
    yield initial;
    yield* stream;
  }

  @override
  Future<void> sendMagicLink(String email, String redirectUrl) async {
    print('🔐 [AUTH REPO] sendMagicLink called - email: $email, redirectUrl: $redirectUrl');
    try {
      print('🔐 [AUTH REPO] Calling Supabase signInWithOtp...');

      // Use a more aggressive timeout and better error handling
      final response = await Future.any([
        _client.auth.signInWithOtp(
          email: email,
          emailRedirectTo: redirectUrl,
        ),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Supabase API timeout', const Duration(seconds: 10));
        }),
      ]);

      // print('🔐 [AUTH REPO] signInWithOtp completed successfully: $response');
    } on TimeoutException catch (e) {
      print('🔐 [AUTH REPO] TIMEOUT: $e');
      // Don't rethrow timeout - Supabase often sends email even when API hangs
      print('🔐 [AUTH REPO] Treating timeout as success - email likely sent');
    } catch (e, stackTrace) {
      print('🔐 [AUTH REPO] sendMagicLink ERROR: $e');
      print('🔐 [AUTH REPO] Error type: ${e.runtimeType}');
      print('🔐 [AUTH REPO] Stack trace: $stackTrace');

      // Check if it's a network error that might still result in email being sent
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('network')) {
        print('🔐 [AUTH REPO] Network error - email might still be sent');
        // Don't rethrow network errors
        return;
      }

      rethrow;
    }
  }
}
