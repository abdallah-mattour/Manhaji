import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_service.dart';

class TtsService {
  final AudioApiService _audioApi;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _backendAvailable = false;
  bool _initialized = false;

  TtsService(this._audioApi);

  bool get isBackendAvailable => _backendAvailable;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Check backend TTS
    try {
      _backendAvailable = await _audioApi.isTtsAvailable();
    } catch (_) {
      _backendAvailable = false;
    }

    // Init local TTS
    try {
      await _flutterTts.setLanguage('ar');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setPitch(1.1);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      debugPrint('Failed to initialize local TTS: $e');
    }
  }

  /// Speak a question — try backend TTS first, fallback to local
  Future<void> speakQuestion(int questionId, String text) async {
    if (_backendAvailable) {
      try {
        final result = await _audioApi.readQuestion(questionId);
        final audioUrl = result['audioUrl'] as String?;
        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _audioPlayer.setUrl(audioUrl);
          await _audioPlayer.play();
          return;
        }
      } catch (e) {
        debugPrint('Backend TTS failed for question $questionId: $e');
      }
    }
    // Fallback to local TTS
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Local TTS failed: $e');
    }
  }

  /// Speak arbitrary text (teaching cards) — always local TTS
  Future<void> speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Local TTS speak failed: $e');
    }
  }

  /// Stop all audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
