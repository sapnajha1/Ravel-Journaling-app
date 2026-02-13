import '../repositories/onboarding_repository.dart';

class GetOnboardingStatus {
  const GetOnboardingStatus(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() => _repository.isCompleted();
}
