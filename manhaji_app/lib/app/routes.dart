import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/parent/child_progress_screen.dart';
import '../screens/parent/parent_dashboard_screen.dart';
import '../screens/progress/ai_reports_screen.dart';
import '../screens/progress/leaderboard_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/teacher/class_students_screen.dart';
import '../screens/teacher/student_detail_screen.dart';
import '../screens/teacher/teacher_dashboard_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String subjectLessons = '/subject-lessons';
  static const String lesson = '/lesson';
  static const String quiz = '/quiz';
  static const String quizResult = '/quiz-result';
  static const String progress = '/progress';
  static const String settings = '/settings';

  // Teacher
  static const String teacherDashboard = '/teacher';
  static const String classStudents = '/teacher/students';
  static const String teacherStudentDetail = '/teacher/student-detail';

  // Admin
  static const String adminDashboard = '/admin';

  // Parent
  static const String parentDashboard = '/parent';
  static const String childProgress = '/parent/child-progress';

  // AI Reports
  static const String aiReports = '/ai-reports';

  // Leaderboard
  static const String leaderboard = '/leaderboard';

  static String homeForRole(String? role) {
    return switch (role) {
      'TEACHER' => teacherDashboard,
      'ADMIN' => adminDashboard,
      'PARENT' => parentDashboard,
      _ => home,
    };
  }

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        home: (_) => const HomeScreen(),
        progress: (_) => const ProgressScreen(),
        settings: (_) => const SettingsScreen(),
        teacherDashboard: (_) => const TeacherDashboardScreen(),
        classStudents: (_) => const ClassStudentsScreen(),
        teacherStudentDetail: (_) => const StudentDetailScreen(),
        adminDashboard: (_) => const AdminDashboardScreen(),
        parentDashboard: (_) => const ParentDashboardScreen(),
        childProgress: (_) => const ChildProgressScreen(),
        aiReports: (_) => const AiReportsScreen(),
        leaderboard: (_) => const LeaderboardScreen(),
      };
}
