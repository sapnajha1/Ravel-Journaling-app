import '../entities/auth_state.dart';

abstract class AuthRepository {
  Stream<AuthState> watchAuthState();
  Future<void> sendMagicLink(String email, String redirectUrl);
}
