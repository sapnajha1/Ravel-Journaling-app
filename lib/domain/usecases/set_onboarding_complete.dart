import '../repositories/onboarding_repository.dart';

class SetOnboardingComplete {
  const SetOnboardingComplete(this._repository);

  final OnboardingRepository _repository;

  Future<void> call() => _repository.setCompleted();
}
