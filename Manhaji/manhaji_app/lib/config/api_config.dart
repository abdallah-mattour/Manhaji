import 'package:flutter/foundation.dart';

class ApiConfig {
  /// API base can be overridden with:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8080/api`.
  /// When Flutter web runs on its own dev server, relative `/api` would hit the
  /// Flutter server and return 404, so we point dev web builds at Spring Boot.
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (!kIsWeb) return 'http://10.0.2.2:8080/api';

    final uri = Uri.base;
    final servedByBackend =
        uri.host == 'localhost' && (uri.hasPort ? uri.port == 8080 : false);
    return servedByBackend ? '/api' : 'http://localhost:8080/api';
  }

  static String get serverUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl.endsWith('/api')
          ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 4)
          : _apiBaseUrl;
    }
    if (!kIsWeb) return 'http://10.0.2.2:8080';

    final uri = Uri.base;
    final servedByBackend =
        uri.host == 'localhost' && (uri.hasPort ? uri.port == 8080 : false);
    return servedByBackend ? '' : 'http://localhost:8080';
  }

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
  // Personalized "Challenge Me" quiz (Knowledge Tracing). POST {subjectId}
  // generates/refreshes the quiz; GET skills/{subjectId} reads the radar data.
  static const String personalizedQuiz = '/quiz/personalized';
  static const String skillMastery = '/quiz/skills';

  // Teacher
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherStudents = '/teacher/students';
  static const String teacherSubjects = '/teacher/subjects';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminSubjects = '/admin/subjects';
  static String adminLinkParent(int studentId) =>
      '/admin/students/$studentId/link-parent';

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
