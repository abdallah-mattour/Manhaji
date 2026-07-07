import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/manage_users_screen.dart';
import '../screens/gate/platform_mismatch_screen.dart';
import '../screens/parent/child_progress_screen.dart';
import '../screens/parent/parent_dashboard_screen.dart';
import '../screens/progress/ai_reports_screen.dart';
import '../screens/progress/leaderboard_screen.dart';
import '../screens/rewards/rewards_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/terms_screen.dart';
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
  static const String profile = '/settings/profile';
  static const String changePassword = '/settings/change-password';

  // Legal / about — top-level so the register screen can open the policy
  // pages before the user is authenticated.
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';

  // Teacher
  static const String teacherDashboard = '/teacher';
  static const String classStudents = '/teacher/students';
  static const String teacherStudentDetail = '/teacher/student-detail';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminManageUsers = '/admin/users';

  // Parent
  static const String parentDashboard = '/parent';
  static const String childProgress = '/parent/child-progress';

  // AI Reports
  static const String aiReports = '/ai-reports';

  // Leaderboard
  static const String leaderboard = '/leaderboard';

  // Rewards (Tier 3 gamification)
  static const String rewards = '/rewards';

  // Platform-role gate (student on web, staff on mobile)
  static const String platformMismatch = '/platform-mismatch';

  /// Route a logged-in user to their home, or to the mismatch screen
  /// if they're on the wrong platform. Per proposal:
  ///   - Mobile hosts STUDENT + PARENT only
  ///   - Web   hosts TEACHER + ADMIN only
  static String homeForRole(String? role) {
    final isStaff = role == 'TEACHER' || role == 'ADMIN';
    final isLearner = role == 'STUDENT' || role == 'PARENT';

    if (kIsWeb && isLearner) return platformMismatch;
    if (!kIsWeb && isStaff) return platformMismatch;

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
        profile: (_) => const ProfileScreen(),
        changePassword: (_) => const ChangePasswordScreen(),
        about: (_) => const AboutScreen(),
        privacyPolicy: (_) => const PrivacyPolicyScreen(),
        terms: (_) => const TermsScreen(),
        teacherDashboard: (_) => const TeacherDashboardScreen(),
        classStudents: (_) => const ClassStudentsScreen(),
        teacherStudentDetail: (_) => const StudentDetailScreen(),
        adminDashboard: (_) => const AdminDashboardScreen(),
        adminManageUsers: (_) => const ManageUsersScreen(),
        parentDashboard: (_) => const ParentDashboardScreen(),
        childProgress: (_) => const ChildProgressScreen(),
        aiReports: (_) => const AiReportsScreen(),
        leaderboard: (_) => const LeaderboardScreen(),
        rewards: (_) => const RewardsScreen(),
        platformMismatch: (_) => const PlatformMismatchScreen(),
      };
}
