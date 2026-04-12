// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/subject/subject_lessons_screen.dart';
import '../screens/learning/learning_screen.dart';
import '../screens/learning/learning_completion_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/progress/leaderboard_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authProvider,

    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final location = state.matchedLocation;

      final isSplashRoute = location == '/splash';
      final isRootRoute = location == '/';
      final bool isAuthRoute =
          location == '/login' || location == '/register';

      // Always allow splash presentation first.
      if (isSplashRoute) {
        return null;
      }

      // Root route is the auth gate: decide explicitly.
      if (isRootRoute) {
        return isLoggedIn ? '/home' : '/login';
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      GoRoute(
        path: '/subject-lessons/:subjectId',
        builder: (context, state) {
          final subjectId = int.parse(state.pathParameters['subjectId']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SubjectLessonsScreen(
            subjectId: subjectId,
            subjectName: extra['subjectName'] as String? ?? 'المادة',
            subjectColor: extra['subjectColor'] as Color? ?? Colors.blue,
          );
        },
      ),

      GoRoute(
        path: '/lesson/:lessonId',
        builder: (context, state) {
          final lessonId = int.parse(state.pathParameters['lessonId']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return LearningScreen(
            lessonId: lessonId,
            lessonTitle: extra['lessonTitle'] as String? ?? 'الدرس',
          );
        },
      ),

      GoRoute(
        path: '/lesson-complete/:lessonId',
        builder: (context, state) {
          final lessonId = int.parse(state.pathParameters['lessonId']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return LearningCompletionScreen(
            lessonId: lessonId,
            lessonTitle: extra['lessonTitle'] as String? ?? 'الدرس',
          );
        },
      ),

      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
