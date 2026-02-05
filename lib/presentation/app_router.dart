import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/auth_state.dart';
import '../screens/home_screen.dart';
import 'app_providers.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/magic_link_sent_screen.dart';
import 'screens/onboarding/onboarding_actions_screen.dart';
import 'screens/onboarding/onboarding_privacy_screen.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final isOnboarded = ref.watch(onboardingStatusProvider);
  final authState = authAsync.value ?? AuthState.unauthenticated();

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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/magic-link-sent',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return MagicLinkSentScreen(email: email);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final authController = ref.read(authControllerProvider);
          return HomeScreen(authController: authController);
        },
      ),
    ],
    redirect: (context, state) {
      final isSignedIn = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isOnboarding = location.startsWith('/onboarding');
      final isLoginFlow =
          location == '/login' || location == '/magic-link-sent';

      if (!isOnboarded && !isOnboarding) {
        return '/onboarding/welcome';
      }

      if (isOnboarded && !isSignedIn && !isLoginFlow) {
        return '/login';
      }

      if (isSignedIn && (isOnboarding || isLoginFlow)) {
        return '/home';
      }

      return null;
    },
  );
});
