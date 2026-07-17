import 'package:flutter/foundation.dart';

class ApiConfig {
  /// API base can be overridden with:
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8080/api`.
  /// When Flutter web runs on its own dev server, relative `/api` would hit the
  /// Flutter server and return 404, so we point dev web builds at Spring Boot.
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Runtime origin set from the in-app "server address" dialog (persisted in
  /// SharedPreferences, loaded at startup in `main`). A full origin with scheme
  /// and port and NO trailing `/api`, e.g. `http://192.168.1.104:8080`.
  ///
  /// This is the "change the IP without rebuilding" mechanism: when the laptop's
  /// address changes (home / campus / hotspot), set it once on the phone and it
  /// takes precedence over the compiled default below. Null = use the default.
  static String? runtimeOrigin;

  static String get baseUrl {
    final o = runtimeOrigin;
    if (o != null && o.isNotEmpty) return '$o/api';
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (kIsWeb) {
      return _isServedByBackend ? '/api' : 'http://localhost:8080/api';
    }
    return '$_nativeServerUrl/api';
  }

  static String get serverUrl {
    final o = runtimeOrigin;
    if (o != null && o.isNotEmpty) return o;
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl.endsWith('/api')
          ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 4)
          : _apiBaseUrl;
    }
    if (kIsWeb) return _isServedByBackend ? '' : 'http://localhost:8080';
    return _nativeServerUrl;
  }

  /// The origin currently in effect (`scheme://host:port`), for pre-filling the
  /// server-address dialog. Falls back to the native default when nothing is set.
  static String get currentOrigin {
    final s = serverUrl;
    return s.isEmpty ? _nativeServerUrl : s;
  }

  /// Normalize whatever the user types into a clean origin `http://host:port`.
  /// Accepts `192.168.1.104`, `192.168.1.104:8080`, `http://192.168.1.104:8080`,
  /// or a value with a trailing `/` or `/api`. Returns null for blank input
  /// (which clears the override and falls back to the compiled default).
  static String? normalizeOrigin(String input) {
    var s = input.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'/+$'), '');
    if (s.endsWith('/api')) s = s.substring(0, s.length - 4);
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty) return null;
    // Default to port 8080 when the user gave only a host.
    return uri.hasPort ? s : '${uri.scheme}://${uri.host}:8080';
  }

  static bool get _isServedByBackend {
    final uri = Uri.base;
    return uri.host == 'localhost' && uri.hasPort && uri.port == 8080;
  }

  /// Compiled default backend host for on-device (physical phone) testing over
  /// Wi-Fi — the dev PC's LAN IP. This is only the FALLBACK now: prefer setting
  /// the address in-app (gear on the login screen) so you never edit source when
  /// the network changes. For the Android EMULATOR use `http://10.0.2.2:8080`.
  static const String _androidHost = 'http://192.168.1.104:8080';

  static String get _nativeServerUrl {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidHost,
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => 'http://127.0.0.1:8080',
      TargetPlatform.fuchsia => 'http://127.0.0.1:8080',
    };
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
  static const String changePassword = '/auth/change-password';
  static const String updateProfile = '/auth/profile';

  // Lessons
  static const String subjects = '/lessons/subjects';
  static const String lessonsBySubject = '/lessons/subject';
  static const String lessonDetail = '/lessons';

  // Student
  static const String dashboard = '/student/dashboard';
  static const String studentAssignedQuizzes = '/student/assigned-quizzes';
  static String studentAssignedQuiz(int assignmentId) =>
      '$studentAssignedQuizzes/$assignmentId';
  static String startAssignedQuizAttempt(int assignmentId) =>
      '$studentAssignedQuizzes/$assignmentId/attempt/start';

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
  static const String teacherMistakes = '/teacher/analytics/mistakes';
  static const String teacherQuizzes = '/teacher/quizzes';
  static String teacherQuizAssignments(int quizId) =>
      '$teacherQuizzes/$quizId/assignments';
  static String teacherAssignmentResults(int assignmentId) =>
      '/teacher/assignments/$assignmentId/results';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminSubjects = '/admin/subjects';
  static String adminLinkParent(int studentId) =>
      '/admin/students/$studentId/link-parent';
  static String adminTeacherAssignments(int teacherId) =>
      '/admin/teachers/$teacherId/assignments';

  // Parent
  static const String parentDashboard = '/parent/dashboard';
  static const String parentChildren = '/parent/children';

  // AI Reports
  static const String generateReport = '/reports/progress';
  static const String getReports = '/reports/progress';
  static const String performanceStats = '/reports/stats';
  static const String generateLearningPath = '/reports/learning-path';
  static const String getLearningPath = '/reports/learning-path';

  // Audio & AI
  static const String narrateLesson = '/audio/lesson';
  static const String readQuestion = '/audio/question';
  static const String ttsStatus = '/audio/tts/status';
  static const String voiceAnswer = '/quiz/attempt';
  static const String questionHint = '/quiz/question';
}
