import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/routes.dart';
import 'preview/preview_config.dart';
import 'app/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/learning_provider.dart';
import 'providers/parent_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/report_provider.dart';
import 'providers/student_settings_provider.dart';
import 'providers/teacher_provider.dart';
import 'services/admin_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/lesson_service.dart';
import 'services/progress_service.dart';
import 'services/quiz_service.dart';
import 'services/audio_service.dart';
import 'services/local_storage_service.dart';
import 'services/parent_service.dart';
import 'services/report_service.dart';
import 'services/teacher_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = LocalStorageService();
  await localStorage.init();

  final services = AppServices.create(localStorage);

  runApp(ManhajiApp(services: services));
}

class AppServices {
  final LocalStorageService localStorage;
  final ApiService apiService;
  final AuthService authService;
  final LessonApiService lessonService;
  final QuizApiService quizService;
  final ProgressApiService progressService;
  final AudioApiService audioService;
  final TeacherService teacherService;
  final AdminService adminService;
  final ParentApiService parentService;
  final ReportService reportService;

  AppServices({
    required this.localStorage,
    required this.apiService,
    required this.authService,
    required this.lessonService,
    required this.quizService,
    required this.progressService,
    required this.audioService,
    required this.teacherService,
    required this.adminService,
    required this.parentService,
    required this.reportService,
  });

  factory AppServices.create(LocalStorageService localStorage) {
    final apiService = ApiService(localStorage);
    return AppServices(
      localStorage: localStorage,
      apiService: apiService,
      authService: AuthService(apiService),
      lessonService: LessonApiService(apiService),
      quizService: QuizApiService(apiService),
      progressService: ProgressApiService(apiService),
      audioService: AudioApiService(apiService),
      teacherService: TeacherService(apiService),
      adminService: AdminService(apiService),
      parentService: ParentApiService(apiService),
      reportService: ReportService(apiService),
    );
  }
}

class ManhajiApp extends StatelessWidget {
  final AppServices services;

  const ManhajiApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LocalStorageService>.value(value: services.localStorage),
        Provider<ApiService>.value(value: services.apiService),
        Provider<AuthService>.value(value: services.authService),
        Provider<LessonApiService>.value(value: services.lessonService),
        Provider<ProgressApiService>.value(value: services.progressService),
        Provider<AdminService>.value(value: services.adminService),
        Provider<ParentApiService>.value(value: services.parentService),
        Provider<ReportService>.value(value: services.reportService),
        Provider<TeacherService>.value(value: services.teacherService),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(services.authService, services.localStorage),
        ),
        // Student-scoped local preferences (Silent Mode). Registered app-wide
        // like the other providers, but only student screens consume it.
        ChangeNotifierProvider(
          create: (_) => StudentSettingsProvider(services.localStorage),
        ),
        ChangeNotifierProvider(
          create: (_) => LessonProvider(services.lessonService),
        ),
        ChangeNotifierProvider(
          create: (_) => LearningProvider(services.quizService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(services.progressService),
        ),
        Provider<AudioApiService>.value(value: services.audioService),
        // Registered so the home-screen "Challenge Me" flow can call
        // generatePersonalizedQuiz / getSkillMastery directly.
        Provider<QuizApiService>.value(value: services.quizService),
        ChangeNotifierProvider(
          create: (_) => TeacherProvider(services.teacherService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(services.adminService),
        ),
        ChangeNotifierProvider(
          create: (_) => ParentProvider(services.parentService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(services.reportService),
        ),
        ChangeNotifierProvider(
          create: (_) => QuestionBankProvider(
            services.teacherService,
            services.adminService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'منهجي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        routes: AppRoutes.routes,
        initialRoute:
            kScreenshotMode ? AppRoutes.previewMenu : AppRoutes.splash,
      ),
    );
  }
}
