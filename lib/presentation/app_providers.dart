import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../auth/auth_controller.dart';
import '../config/supabase_config.dart';
import '../data/local/local_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/onboarding_repository.dart';
import '../domain/entities/auth_state.dart';
import '../domain/usecases/complete_onboarding.dart';
import '../domain/usecases/get_onboarding_status.dart';
import '../domain/usecases/send_magic_link.dart';

// Riverpod is already in the app; we reuse it for scalable state + DI.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(supabase.Supabase.instance.client),
);

final sendMagicLinkProvider = Provider<SendMagicLink>(
  (ref) => SendMagicLink(ref.read(authRepositoryProvider)),
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.read(authRepositoryProvider).authStateChanges(),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(LocalStore.appSettingsBox()),
);

final onboardingStatusProvider =
    StateNotifierProvider<OnboardingController, bool>(
  (ref) {
    final repo = ref.read(onboardingRepositoryProvider);
    return OnboardingController(
      getOnboardingStatus: GetOnboardingStatus(repo),
      completeOnboarding: CompleteOnboarding(repo),
    );
  },
);

class OnboardingController extends StateNotifier<bool> {
  OnboardingController({
    required GetOnboardingStatus getOnboardingStatus,
    required CompleteOnboarding completeOnboarding,
  })  : _getOnboardingStatus = getOnboardingStatus,
        _completeOnboarding = completeOnboarding,
        super(false) {
    state = _getOnboardingStatus();
  }

  final GetOnboardingStatus _getOnboardingStatus;
  final CompleteOnboarding _completeOnboarding;

  Future<void> complete() async {
    await _completeOnboarding();
    state = true;
  }
}

final authControllerProvider = Provider<AuthController>(
  (ref) {
    final controller = AuthController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

final redirectUrlProvider = Provider<String>(
  (ref) => SupabaseConfig.authRedirectUrl,
);
