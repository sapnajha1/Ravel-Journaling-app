import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/auth/login_magic_link_screen.dart';
import '../presentation/screens/auth/magic_link_sent_screen.dart';
import '../presentation/screens/onboarding/onboarding_actions_screen.dart';
import '../presentation/screens/onboarding/onboarding_privacy_screen.dart';
import '../presentation/screens/onboarding/onboarding_welcome_screen.dart';
import '../presentation/state/auth_notifier.dart';
import '../presentation/state/onboarding_notifier.dart';
import '../presentation/screens/home_entry_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final onboardingComplete = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    initialLocation: '/onboarding/welcome',
    routes: [
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/actions',
        builder: (context, state) => const OnboardingActionsScreen(),
      ),
      GoRoute(
        path: '/onboarding/privacy',
        builder: (context, state) => const OnboardingPrivacyScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginMagicLinkScreen(),
      ),
      GoRoute(
        path: '/magic-link-sent',
        builder: (context, state) => const MagicLinkSentScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeEntryScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnboarding = location.startsWith('/onboarding');
      final isLogin = location == '/login' || location == '/magic-link-sent';

      if (!onboardingComplete && !isOnboarding) {
        return '/onboarding/welcome';
      }

      if (onboardingComplete && !authState.isAuthenticated && !isLogin) {
        return '/login';
      }

      if (authState.isAuthenticated && (isOnboarding || isLogin)) {
        return '/home';
      }

      return null;
    },
  );
});
