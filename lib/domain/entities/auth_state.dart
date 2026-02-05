class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.email,
  });

  final bool isAuthenticated;
  final String? email;

  factory AuthState.unauthenticated() => const AuthState(isAuthenticated: false);

  factory AuthState.authenticated(String? email) =>
      AuthState(isAuthenticated: true, email: email);
}
