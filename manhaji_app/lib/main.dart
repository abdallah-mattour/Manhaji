import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/learning_provider.dart';
import 'providers/parent_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/report_provider.dart';
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

  final apiService = ApiService(localStorage);
  final authService = AuthService(apiService);
  final lessonService = LessonApiService(apiService);
  final quizService = QuizApiService(apiService);
  final progressService = ProgressApiService(apiService);
  final audioService = AudioApiService(apiService);
  final teacherService = TeacherService(apiService);
  final adminService = AdminService(apiService);
  final parentService = ParentApiService(apiService);
  final reportService = ReportService(apiService);

  runApp(ManhajiApp(
    localStorage: localStorage,
    authService: authService,
    lessonService: lessonService,
    quizService: quizService,
    progressService: progressService,
    audioService: audioService,
    teacherService: teacherService,
    adminService: adminService,
    parentService: parentService,
    reportService: reportService,
  ));
}

class ManhajiApp extends StatelessWidget {
  final LocalStorageService localStorage;
  final AuthService authService;
  final LessonApiService lessonService;
  final QuizApiService quizService;
  final ProgressApiService progressService;
  final AudioApiService audioService;
  final TeacherService teacherService;
  final AdminService adminService;
  final ParentApiService parentService;
  final ReportService reportService;

  const ManhajiApp({
    super.key,
    required this.localStorage,
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
        ChangeNotifierProvider(
          create: (_) => TeacherProvider(teacherService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(adminService),
        ),
        ChangeNotifierProvider(
          create: (_) => ParentProvider(parentService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(reportService),
        ),
        ChangeNotifierProvider(
          create: (_) => QuestionBankProvider(teacherService, adminService),
        ),
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
