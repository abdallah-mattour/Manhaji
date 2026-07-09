import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/pronunciation_score.dart';
import '../utils/app_log.dart';
import 'api_service.dart';

class AudioApiService {
  static final AppLog _log = AppLog.tag('stt');

  final ApiService _api;

  AudioApiService(this._api);

  /// Pulls the filename out of an absolute path so the multipart upload's
  /// `filename` field matches the actual extension Gemini will see in
  /// `Content-Type`. Previously this was hardcoded to `pron.webm` while
  /// the recorder emitted AAC-in-M4A — Gemini's format autodetection still
  /// worked from the bytes, but mismatched filenames make server-side
  /// debugging unnecessarily painful.
  String _basename(String path) {
    final fwd = path.lastIndexOf('/');
    final bwd = path.lastIndexOf('\\');
    final idx = fwd > bwd ? fwd : bwd;
    return idx >= 0 ? path.substring(idx + 1) : path;
  }

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

  /// TTS for arbitrary UI text (teaching cards, feedback phrases, reading
  /// passages). Backend caches by text fingerprint, so a repeated phrase
  /// synthesizes once ever. Returns audio URL or status message.
  Future<Map<String, dynamic>> speakText(String text) async {
    final response = await _api.post('/audio/speak', data: {'text': text});
    return response['data'] ?? {};
  }

  /// Check if TTS is available on the backend.
  Future<bool> isTtsAvailable() async {
    try {
      final response = await _api.get('/audio/tts/status');
      return response['data']?['available'] == true;
    } catch (e) {
      debugPrint('[tts-availability] error: $e');
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
    final filename = _basename(audioFilePath);
    _log.i('voice-answer: upload q=$questionId lang=$language file=$filename');
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioFilePath, filename: filename),
      'questionId': questionId,
      'language': language,
    });
    final response = await _api.postMultipart(
      '/quiz/attempt/$attemptId/voice-answer',
      formData: formData,
    );
    return response['data'] ?? {};
  }

  /// Submit a pronunciation attempt — transcribes + scores phonetic similarity.
  Future<PronunciationScore> submitPronunciation({
    required int attemptId,
    required int questionId,
    required String audioFilePath,
    String language = 'ar',
  }) async {
    final filename = _basename(audioFilePath);
    _log.i('pronunciation: upload q=$questionId lang=$language file=$filename');
    final stopwatch = Stopwatch()..start();
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(audioFilePath, filename: filename),
      'questionId': questionId,
      'language': language,
    });
    try {
      final response = await _api.postMultipart(
        '/quiz/attempt/$attemptId/pronunciation',
        formData: formData,
      );
      final score = PronunciationScore.fromJson(
          (response['data'] as Map).cast<String, dynamic>());
      _log.i('pronunciation: verdict score=${score.score} '
          'correct=${score.isCorrect} heard="${score.transcribedText}" '
          'in ${stopwatch.elapsedMilliseconds}ms');
      return score;
    } catch (e) {
      _log.e('pronunciation: upload/score failed after '
          '${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
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
