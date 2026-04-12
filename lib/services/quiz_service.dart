import '../config/api_config.dart';
import '../models/quiz.dart';
import 'api_service.dart';

class QuizApiService {
  final ApiService _api;

  QuizApiService(this._api);

  Future<Quiz> getQuizByLesson(int lessonId) async {
    final response = await _api.get('${ApiConfig.quizByLesson}/$lessonId');
    return Quiz.fromJson(response['data'] ?? {});
  }

  Future<AttemptResult> startAttempt(int quizId) async {
    final response = await _api.post('${ApiConfig.startAttempt}/$quizId');
    return AttemptResult.fromJson(response['data'] ?? {});
  }

  Future<SubmitAnswerResult> submitAnswer(int attemptId, {
    required int questionId,
    String? answer,
    String? spokenText,
    String? audioRef,
  }) async {
    final response = await _api.post(
      '/quiz/attempt/$attemptId/answer',
      data: {
        'questionId': questionId,
        if (answer != null) 'answer': answer, // ignore: use_null_aware_elements
        if (spokenText != null) 'spokenText': spokenText, // ignore: use_null_aware_elements
        if (audioRef != null) 'audioRef': audioRef, // ignore: use_null_aware_elements
      },
    );
    return SubmitAnswerResult.fromJson(response['data'] ?? {});
  }

  Future<AttemptResult> completeAttempt(int attemptId) async {
    final response = await _api.post('/quiz/attempt/$attemptId/complete');
    return AttemptResult.fromJson(response['data'] ?? {});
  }
}
