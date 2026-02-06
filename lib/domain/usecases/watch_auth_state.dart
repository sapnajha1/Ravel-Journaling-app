import '../entities/auth_state.dart';
import '../repositories/auth_repository.dart';

class WatchAuthState {
  const WatchAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AuthState> call() => _repository.watchAuthState();
}
