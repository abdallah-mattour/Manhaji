import '../config/api_config.dart';
import '../models/quiz.dart';
import '../models/skill_mastery.dart';
import '../models/student_assigned_quiz.dart';
import 'api_service.dart';

class QuizApiService {
  final ApiService _api;

  QuizApiService(this._api);

  Future<Quiz> getQuizByLesson(int lessonId) async {
    final response = await _api.get('${ApiConfig.quizByLesson}/$lessonId');
    return Quiz.fromJson(response['data'] ?? {});
  }

  /// Knowledge Tracing "Challenge Me": generate/refresh a personalized quiz
  /// for one subject. Questions are picked across the subject's lessons,
  /// weighted toward the student's weakest sub-skills by the backend's BKT
  /// model. Returns the same [Quiz] shape as [getQuizByLesson] so the normal
  /// quiz UI renders it unchanged.
  Future<Quiz> generatePersonalizedQuiz(int subjectId) async {
    final response = await _api.post(
      '${ApiConfig.personalizedQuiz}/$subjectId',
    );
    return Quiz.fromJson(response['data'] ?? {});
  }

  /// Per-subject skill-mastery snapshot for the "My Skills" radar chart.
  Future<SkillMastery> getSkillMastery(int subjectId) async {
    final response = await _api.get('${ApiConfig.skillMastery}/$subjectId');
    return SkillMastery.fromJson(response['data'] ?? {});
  }

  /// Tier A / A1 (2026-05-15) — Practice Mode. Calls the adaptive endpoint
  /// which returns questions reordered by the student's past performance:
  /// weak sub-skills first, then "stretch" difficulty, then novelty.
  /// Falls back server-side to fixed order on first visit.
  Future<Quiz> getAdaptiveQuizByLesson(int lessonId) async {
    final response = await _api.get(
      '${ApiConfig.quizByLesson}/$lessonId/adaptive',
    );
    return Quiz.fromJson(response['data'] ?? {});
  }

  Future<AttemptResult> startAttempt(int quizId) async {
    final response = await _api.post('${ApiConfig.startAttempt}/$quizId');
    return AttemptResult.fromJson(response['data'] ?? {});
  }

  Future<List<StudentAssignedQuizSummary>> getAssignedQuizzes() async {
    final response = await _api.get(ApiConfig.studentAssignedQuizzes);
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .map(
          (quiz) => StudentAssignedQuizSummary.fromJson(
            Map<String, dynamic>.from(quiz as Map),
          ),
        )
        .toList();
  }

  Future<StudentAssignedQuizDetail> getAssignedQuizDetail(
    int assignmentId,
  ) async {
    final response = await _api.get(
      ApiConfig.studentAssignedQuiz(assignmentId),
    );
    return StudentAssignedQuizDetail.fromJson(
      Map<String, dynamic>.from((response['data'] ?? {}) as Map),
    );
  }

  Future<AttemptResult> startAssignedQuizAttempt(int assignmentId) async {
    final response = await _api.post(
      ApiConfig.startAssignedQuizAttempt(assignmentId),
    );
    return AttemptResult.fromJson(response['data'] ?? {});
  }

  Future<SubmitAnswerResult> submitAnswer(
    int attemptId, {
    required int questionId,
    String? answer,
    String? spokenText,
    String? audioRef,
  }) async {
    final data = <String, dynamic>{'questionId': questionId};
    if (answer != null) data['answer'] = answer;
    if (spokenText != null) data['spokenText'] = spokenText;
    if (audioRef != null) data['audioRef'] = audioRef;

    final response = await _api.post(
      '/quiz/attempt/$attemptId/answer',
      data: data,
    );
    return SubmitAnswerResult.fromJson(response['data'] ?? {});
  }

  Future<AttemptResult> completeAttempt(int attemptId) async {
    final response = await _api.post('/quiz/attempt/$attemptId/complete');
    return AttemptResult.fromJson(response['data'] ?? {});
  }

  /// Persist a client-scored tracing attempt so dashboards/reports reflect it.
  /// Scoring stays client-side (pure CustomPainter heuristic); the backend
  /// trusts this payload and stores a StudentResponse row.
  Future<SubmitAnswerResult> submitTracingResult(
    int attemptId, {
    required int questionId,
    required int score,
    required int stars,
    required bool isCorrect,
    String? feedback,
  }) async {
    final data = <String, dynamic>{
      'questionId': questionId,
      'score': score,
      'stars': stars,
      'isCorrect': isCorrect,
    };
    if (feedback != null) data['feedback'] = feedback;

    final response = await _api.post(
      '/quiz/attempt/$attemptId/tracing',
      data: data,
    );
    return SubmitAnswerResult.fromJson(response['data'] ?? {});
  }
}
