import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/routes.dart';
import 'app/theme.dart';
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

  runApp(ManhajiApp(
    localStorage: localStorage,
    authService: authService,
    lessonService: lessonService,
    quizService: quizService,
    progressService: progressService,
    audioService: audioService,
  ));
}

class ManhajiApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final AuthService authService;
  final LessonApiService lessonService;
  final QuizApiService quizService;
  final ProgressApiService progressService;
  final AudioApiService audioService;

  const ManhajiApp({
    super.key,
    required this.localStorage,
    required this.authService,
    required this.lessonService,
    required this.quizService,
    required this.progressService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: localStorage),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, localStorage),
        ),
        ChangeNotifierProvider(
          create: (_) => LessonProvider(lessonService),
        ),
        ChangeNotifierProvider(
          create: (_) => LearningProvider(quizService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(progressService),
        ),
        Provider<AudioApiService>.value(value: audioService),
      ],
      child: MaterialApp(
        title: 'منهجي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.splash,
      ),
    );
  }
}
