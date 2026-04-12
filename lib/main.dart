// lib/main.dart
//
// Run examples:
// flutter run
// flutter run --dart-define=APP_ENV=dev
// flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.example.com/api
// flutter run --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com/api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/utils/size_config.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/learning_provider.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/lesson_service.dart';
import 'services/progress_service.dart';
import 'services/quiz_service.dart';
import 'services/audio_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = LocalStorageService();
  await localStorage.init();

  final apiService = ApiService(localStorage);
  final authService = AuthService(apiService);
  final lessonService = LessonApiService(apiService);
  final quizService = QuizApiService(apiService);
  final progressService = ProgressApiService(apiService);
  final audioService = AudioApiService(apiService);

  final authProvider = AuthProvider(authService, localStorage);
  final appRouter = AppRouter(authProvider);

  runApp(
    ManhajiApp(
      localStorage: localStorage,
      authProvider: authProvider,
      lessonService: lessonService,
      quizService: quizService,
      progressService: progressService,
      audioService: audioService,
      appRouter: appRouter,
    ),
  );
}

class ManhajiApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final AuthProvider authProvider;
  final LessonApiService lessonService;
  final QuizApiService quizService;
  final ProgressApiService progressService;
  final AudioApiService audioService;
  final AppRouter appRouter;

  const ManhajiApp({
    super.key,
    required this.localStorage,
    required this.authProvider,
    required this.lessonService,
    required this.quizService,
    required this.progressService,
    required this.audioService,
    required this.appRouter,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => LessonProvider(lessonService)),
        ChangeNotifierProvider(create: (_) => LearningProvider(quizService)),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(progressService),
        ),
        Provider<AudioApiService>.value(value: audioService),
      ],
      child: Builder(
        builder: (context) {
          SizeConfig.init(context);

          return MaterialApp.router(
            title: 'منهجي',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            locale: const Locale('ar'),
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
