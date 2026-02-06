import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_onboarding_status.dart';
import '../../domain/usecases/set_onboarding_complete.dart';
import 'app_providers.dart';

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingNotifier(
    getOnboardingStatus: GetOnboardingStatus(repository),
    setOnboardingComplete: SetOnboardingComplete(repository),
  )..load();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier({
    required GetOnboardingStatus getOnboardingStatus,
    required SetOnboardingComplete setOnboardingComplete,
  })  : _getOnboardingStatus = getOnboardingStatus,
        _setOnboardingComplete = setOnboardingComplete,
        super(false);

  final GetOnboardingStatus _getOnboardingStatus;
  final SetOnboardingComplete _setOnboardingComplete;

  Future<void> load() async {
    state = await _getOnboardingStatus();
  }

  Future<void> complete() async {
    await _setOnboardingComplete();
    state = true;
  }
}
