class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String loginPhone = '/auth/login/phone';
  static const String loginGoogle = '/auth/login/google';
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
}
