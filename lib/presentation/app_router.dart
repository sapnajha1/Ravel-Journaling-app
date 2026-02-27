import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/entities/auth_state.dart';
import '../screens/ask_name_screen.dart';
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
        path: '/ask-name',
        builder: (context, state) {
          final authController = ref.read(authControllerProvider);
          return AskNameScreen(authController: authController);
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
      final hasName = ref.read(authControllerProvider).hasChosenDisplayName;

      if (kDebugMode) {
        debugPrint('[ROUTER] location=$location isSignedIn=$isSignedIn '
            'isOnboarded=$isOnboarded hasName=$hasName');
      }

      // Allow "Skip to Login" to go directly to email screen; don't force back to onboarding
      if (!isOnboarded && !isOnboarding && !isLoginFlow) {
        return '/onboarding/welcome';
      }

      if (isOnboarded && !isSignedIn && !isLoginFlow) {
        return '/login';
      }

      // Signed in with name already set → go to home (skip ask-name).
      if (isSignedIn && hasName) {
        return '/home';
      }

      // Signed in but no name yet → ask-name is required (first time after verification).
      if (isSignedIn && (isOnboarding || isLoginFlow)) {
        return '/ask-name';
      }

      return null;
    },
  );
});
