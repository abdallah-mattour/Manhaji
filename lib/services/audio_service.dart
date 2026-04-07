import 'package:dio/dio.dart';
import 'api_service.dart';

class AudioApiService {
  final ApiService _api;

  AudioApiService(this._api);

  /// Request TTS narration for a lesson. Returns audio URL or status message.
  Future<Map<String, dynamic>> narrateLesson(int lessonId) async {
    final response = await _api.post('/audio/lesson/$lessonId/narrate');
    return response['data'] ?? {};
  }

  /// Request TTS for a question. Returns audio URL or status message.
  Future<Map<String, dynamic>> readQuestion(int questionId) async {
    final response = await _api.post('/audio/question/$questionId/read');
    return response['data'] ?? {};
  }

  /// Check if TTS is available on the backend.
  Future<bool> isTtsAvailable() async {
    try {
      final response = await _api.get('/audio/tts/status');
      return response['data']?['available'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Submit a voice answer (audio file) for transcription and evaluation.
  Future<Map<String, dynamic>> submitVoiceAnswer({
    required int attemptId,
    required int questionId,
    required String audioFilePath,
    String language = 'ar',
  }) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioFilePath, filename: 'voice.webm'),
      'questionId': questionId,
      'language': language,
    });
    final response = await _api.postMultipart(
      '/quiz/attempt/$attemptId/voice-answer',
      formData: formData,
    );
    return response['data'] ?? {};
  }

  /// Get a hint for a question.
  Future<Map<String, dynamic>> getHint(int questionId, {int level = 1}) async {
    final response = await _api.get(
      '/quiz/question/$questionId/hint',
      queryParams: {'level': level},
    );
    return response['data'] ?? {};
  }
}
