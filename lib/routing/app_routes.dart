class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String authGate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String progress = '/progress';
  static const String leaderboard = '/leaderboard';
  static const String settings = '/settings';

  static const String subjectLessonsPattern = '/subject-lessons/:subjectId';
  static const String lessonPattern = '/lesson/:lessonId';
  static const String lessonCompletePattern = '/lesson-complete/:lessonId';

  static const String subjectIdParam = 'subjectId';
  static const String lessonIdParam = 'lessonId';

  static String subjectLessons(int subjectId) => '/subject-lessons/$subjectId';
  static String lesson(int lessonId) => '/lesson/$lessonId';
  static String lessonComplete(int lessonId) =>
      '/lesson-complete/$lessonId';
}
