import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_state.dart';
import '../../domain/usecases/send_magic_link.dart';
import '../../domain/usecases/watch_auth_state.dart';
import 'app_providers.dart';

// Riverpod chosen for lightweight, testable state control with minimal boilerplate.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final watchAuthState = WatchAuthState(repository);
  final sendMagicLink = SendMagicLink(repository);
  return AuthNotifier(
    watchAuthState: watchAuthState,
    sendMagicLink: sendMagicLink,
  );
});

final pendingEmailProvider = StateProvider<String?>((ref) => null);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required WatchAuthState watchAuthState,
    required SendMagicLink sendMagicLink,
  })  : _watchAuthState = watchAuthState,
        _sendMagicLink = sendMagicLink,
        super(AuthState.signedOut) {
    _subscription = _watchAuthState().listen((event) {
      state = event;
    });
  }

  final WatchAuthState _watchAuthState;
  final SendMagicLink _sendMagicLink;
  StreamSubscription<AuthState>? _subscription;

  Future<void> sendMagicLink(String email, String redirectUrl) async {
    await _sendMagicLink(email, redirectUrl);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
