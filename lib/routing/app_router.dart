// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import 'app_routes.dart';
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

  int? _resolveSubjectId(GoRouterState state) {
    final fromPathParam = int.tryParse(
      state.pathParameters[AppRoutes.subjectIdParam] ?? '',
    );
    if (fromPathParam != null) {
      return fromPathParam;
    }

    final segments = state.uri.pathSegments;
    if (segments.length >= 2 && segments.first == 'subject-lessons') {
      return int.tryParse(segments[1]);
    }

    return null;
  }

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authProvider,

    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final location = state.matchedLocation;

      final isSplashRoute = location == AppRoutes.splash;
      final isRootRoute = location == AppRoutes.authGate;
      final bool isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;

      // Always allow splash presentation first.
      if (isSplashRoute) {
        return null;
      }

      // Root route is the auth gate: decide explicitly.
      if (isRootRoute) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.authGate,
        builder: (context, state) => SizedBox.shrink(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeScreen(key: state.pageKey),
      ),

      GoRoute(
        path: AppRoutes.subjectLessonsPattern,
        builder: (context, state) {
          final subjectId = _resolveSubjectId(state);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          if (subjectId == null) {
            return Scaffold(
              key: state.pageKey,
              body: Center(child: Text('تعذر فتح المادة: معرف غير صالح')),
            );
          }
          return SubjectLessonsScreen(
            key: state.pageKey,
            subjectId: subjectId,
            subjectName: extra['subjectName'] as String? ?? 'المادة',
            subjectColor: extra['subjectColor'] as Color? ?? Colors.blue,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.lessonPattern,
        builder: (context, state) {
          final lessonId = int.tryParse(
            state.pathParameters[AppRoutes.lessonIdParam] ?? '',
          );
          final extra = state.extra as Map<String, dynamic>? ?? {};
          if (lessonId == null) {
            return HomeScreen(key: state.pageKey);
          }
          return LearningScreen(
            key: state.pageKey,
            lessonId: lessonId,
            lessonTitle: extra['lessonTitle'] as String? ?? 'الدرس',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.lessonCompletePattern,
        builder: (context, state) {
          final lessonId = int.tryParse(
            state.pathParameters[AppRoutes.lessonIdParam] ?? '',
          );
          final extra = state.extra as Map<String, dynamic>? ?? {};
          if (lessonId == null) {
            return HomeScreen(key: state.pageKey);
          }
          return LearningCompletionScreen(
            key: state.pageKey,
            lessonId: lessonId,
            lessonTitle: extra['lessonTitle'] as String? ?? 'الدرس',
          );
        },
      ),

      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => ProgressScreen(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => LeaderboardScreen(key: state.pageKey),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => SettingsScreen(key: state.pageKey),
      ),
    ],
  );
}
