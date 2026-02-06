import '../../data/repositories/auth_repository.dart';

class SendMagicLink {
  const SendMagicLink(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String redirectUrl,
  }) {
    return _repository.sendMagicLink(
      email: email,
      redirectUrl: redirectUrl,
    );
  }
}
