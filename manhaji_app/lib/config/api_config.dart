import 'package:flutter/foundation.dart';

class ApiConfig {
  /// On web we assume the Flutter bundle is served from the same origin as the
  /// Spring Boot backend (see Phase E: `static/app/` inside the jar). A relative
  /// `/api` base means no CORS and survives whichever host/port the browser is on.
  /// On mobile we still point at the Android-emulator loopback.
  static String get baseUrl => kIsWeb ? '/api' : 'http://10.0.2.2:8080/api';
  static String get serverUrl => kIsWeb ? '' : 'http://10.0.2.2:8080';

  /// Resolves a backend-relative path like `/uploads/images/...` into a full URL.
  /// Returns the input unchanged if it already starts with `http`.
  static String resolveMediaUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$serverUrl$path';
    return '$serverUrl/$path';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginPhone = '/auth/login/phone';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // Lessons
  static const String subjects = '/lessons/subjects';
  static const String lessonsBySubject = '/lessons/subject';
  static const String lessonDetail = '/lessons';

  // Student
  static const String dashboard = '/student/dashboard';

  // Quiz
  static const String quizByLesson = '/quiz/lesson';
  static const String startAttempt = '/quiz/attempt/start';
  static const String submitAnswer = '/quiz/attempt/answer';
  static const String completeAttempt = '/quiz/attempt/complete';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherStudents = '/teacher/students';
  static const String teacherSubjects = '/teacher/subjects';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminSubjects = '/admin/subjects';

  // Parent
  static const String parentDashboard = '/parent/dashboard';
  static const String parentChildren = '/parent/children';

  // AI Reports
  static const String generateReport = '/reports/progress';
  static const String getReports = '/reports/progress';
  static const String generateLearningPath = '/reports/learning-path';
  static const String getLearningPath = '/reports/learning-path';

  // Audio & AI
  static const String narrateLesson = '/audio/lesson';
  static const String readQuestion = '/audio/question';
  static const String ttsStatus = '/audio/tts/status';
  static const String voiceAnswer = '/quiz/attempt';
  static const String questionHint = '/quiz/question';
}
