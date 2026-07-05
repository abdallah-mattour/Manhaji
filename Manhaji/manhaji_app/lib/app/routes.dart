import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_question_bank_questions_screen.dart';
import '../screens/admin/admin_question_bank_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/gate/platform_mismatch_screen.dart';
import '../screens/parent/child_progress_screen.dart';
import '../screens/parent/parent_dashboard_screen.dart';
import '../screens/parent/parent_settings_screen.dart';
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
import '../screens/teacher/teacher_settings_screen.dart';
import '../screens/teacher/teacher_subjects_screen.dart';
import '../utils/role_platform_policy.dart';
import '../widgets/role_guard.dart';
import '../preview/preview_config.dart';
import '../preview/preview_menu_screen.dart';
import '../preview/preview_admin_screen.dart';
import '../preview/preview_teacher_screen.dart';
import '../preview/preview_parent_screen.dart';
import '../preview/preview_student_screen.dart';

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
  static const String teacherSubjects = '/teacher/subjects';
  static const String teacherSettings = '/teacher/settings';
  static const String teacherStudentDetail = '/teacher/student-detail';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminManageUsers = '/admin/users';
  static const String adminSettings = '/admin/settings';
  static const String adminQuestionBank = '/admin/question-bank';
  static const String adminQuestionBankQuestions =
      '/admin/question-bank/questions';

  // Parent
  static const String parentDashboard = '/parent';
  static const String childProgress = '/parent/child-progress';
  static const String parentSettings = '/parent/settings';

  // AI Reports
  static const String aiReports = '/ai-reports';

  // Leaderboard
  static const String leaderboard = '/leaderboard';

  // Platform-role gate (student on web, staff on mobile)
  static const String platformMismatch = '/platform-mismatch';

  // Preview routes — only registered when SCREENSHOT_MODE=true at compile time
  static const String previewMenu = '/preview';
  static const String previewAdmin = '/preview/admin';
  static const String previewTeacher = '/preview/teacher';
  static const String previewParent = '/preview/parent';
  static const String previewStudent = '/preview/student';

  /// Route a logged-in user to their home, or to the mismatch screen
  /// if they're on the wrong platform. Per proposal:
  ///   - Mobile hosts STUDENT + PARENT only
  ///   - Web/desktop hosts TEACHER + ADMIN only
  static String homeForRole(String? role) {
    final normalizedRole = RolePlatformPolicy.normalizeRole(role);

    if (!RolePlatformPolicy.isRoleAllowedOnCurrentPlatform(normalizedRole)) {
      return platformMismatch;
    }

    return switch (normalizedRole) {
      'TEACHER' => teacherDashboard,
      'ADMIN' => adminDashboard,
      'PARENT' => parentDashboard,
      _ => home,
    };
  }

  static Map<String, WidgetBuilder> get routes => {
    // ── Public routes — no guard ──────────────────────────────────────
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    platformMismatch: (_) => const PlatformMismatchScreen(),

    // ── Student routes ────────────────────────────────────────────────
    home: (_) =>
        const RoleGuard(allowedRoles: ['STUDENT'], child: HomeScreen()),
    progress: (_) =>
        const RoleGuard(allowedRoles: ['STUDENT'], child: ProgressScreen()),
    settings: (_) =>
        const RoleGuard(allowedRoles: ['STUDENT'], child: SettingsScreen()),
    aiReports: (_) =>
        const RoleGuard(allowedRoles: ['STUDENT'], child: AiReportsScreen()),
    leaderboard: (_) =>
        const RoleGuard(allowedRoles: ['STUDENT'], child: LeaderboardScreen()),

    // ── Teacher routes ────────────────────────────────────────────────
    teacherDashboard: (_) => const RoleGuard(
      allowedRoles: ['TEACHER'],
      child: TeacherDashboardScreen(),
    ),
    classStudents: (_) => const RoleGuard(
      allowedRoles: ['TEACHER'],
      child: ClassStudentsScreen(),
    ),
    teacherSubjects: (_) => const RoleGuard(
      allowedRoles: ['TEACHER'],
      child: TeacherSubjectsScreen(),
    ),
    teacherSettings: (_) => const RoleGuard(
      allowedRoles: ['TEACHER'],
      child: TeacherSettingsScreen(),
    ),
    teacherStudentDetail: (_) => const RoleGuard(
      allowedRoles: ['TEACHER'],
      child: StudentDetailScreen(),
    ),

    // ── Admin routes ──────────────────────────────────────────────────
    adminDashboard: (_) =>
        const RoleGuard(allowedRoles: ['ADMIN'], child: AdminDashboardScreen()),
    adminManageUsers: (_) =>
        const RoleGuard(allowedRoles: ['ADMIN'], child: ManageUsersScreen()),
    adminSettings: (_) =>
        const RoleGuard(allowedRoles: ['ADMIN'], child: AdminSettingsScreen()),
    adminQuestionBank: (_) => const RoleGuard(
      allowedRoles: ['ADMIN'],
      child: AdminQuestionBankScreen(),
    ),
    adminQuestionBankQuestions: (_) => const RoleGuard(
      allowedRoles: ['ADMIN'],
      child: AdminQuestionBankQuestionsScreen(),
    ),

    // ── Parent routes ─────────────────────────────────────────────────
    parentDashboard: (_) => const RoleGuard(
      allowedRoles: ['PARENT'],
      child: ParentDashboardScreen(),
    ),
    childProgress: (_) =>
        const RoleGuard(allowedRoles: ['PARENT'], child: ChildProgressScreen()),
    parentSettings: (_) => const RoleGuard(
      allowedRoles: ['PARENT'],
      child: ParentSettingsScreen(),
    ),

    // ── Preview routes — excluded from the map when SCREENSHOT_MODE=false ─
    if (kScreenshotMode) ...{
      previewMenu: (_) => const PreviewMenuScreen(),
      previewAdmin: (_) => const PreviewAdminScreen(),
      previewTeacher: (_) => const PreviewTeacherScreen(),
      previewParent: (_) => const PreviewParentScreen(),
      previewStudent: (_) => const PreviewStudentScreen(),
    },
  };
}
