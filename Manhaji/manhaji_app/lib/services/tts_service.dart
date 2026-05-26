import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../config/api_config.dart';
import '../utils/app_log.dart';
import 'audio_service.dart';
import 'local_storage_service.dart';

/// Speaks text aloud, preferring the backend's Edge-TTS pipeline (high-quality
/// neural voices for both Arabic and English, cached to disk after first use)
/// and falling back to on-device `flutter_tts` when the backend is offline
/// or hasn't generated the audio yet.
///
/// ### Audio URL contract
///
/// `AudioApiService.readQuestion` returns a backend-relative path like
/// `uploads/audio/<uuid>_question_<id>.mp3` (see
/// `FileStorageService.saveAudio` on the server). Three things must happen
/// before [just_audio] can play it:
///
/// 1. **Prefix with the server origin.** Schemeless strings are interpreted
///    by ExoPlayer as on-device file paths and produce
///    `FileNotFoundException: ENOENT (No such file or directory)`. We pass
///    the path through [ApiConfig.resolveMediaUrl] to turn it into a real
///    `http://host:port/uploads/...` URL.
/// 2. **Attach the JWT bearer header.** `/uploads/audio/**` is gated as
///    `authenticated()` in `SecurityConfig` (audit fix S4 — student voice
///    recordings are PII). Without the bearer token, the server returns 401
///    and [just_audio] reports it as `Source error`. We read the token from
///    [LocalStorageService] and pass it via `setUrl(..., headers: ...)`.
/// 3. **Be reachable from Android.** Loopback HTTP requires
///    `network_security_config.xml` to allow cleartext for
///    `10.0.2.2` / `127.0.0.1` / `localhost`; without it ExoPlayer throws
///    `CleartextNotPermittedException`. See
///    `android/app/src/main/res/xml/network_security_config.xml`.
///
/// ### Language routing
///
/// Language is detected from the text itself — any Arabic codepoint (U+0600
/// to U+06FF) routes to the Arabic voice; otherwise the English voice is
/// used. Previously the local fallback was hardcoded to Arabic, which meant
/// English questions came out with Arabic phonemes (unintelligible). The
/// fallback now re-applies language per call so a single [FlutterTts]
/// instance can swap between Arabic and English mid-session.
///
/// ### Console logging
///
/// Every decision point emits a line via [AppLog] under the `[tts]` tag —
/// init outcome, which path each request took (backend cached / backend
/// fresh / local fallback), and the underlying error if a request failed.
/// Filter with `flutter run | Select-String "\[tts\]"` to see only TTS
/// activity.
class TtsService {
  TtsService(this._audioApi, this._storage);

  static final AppLog _log = AppLog.tag('tts');

  final AudioApiService _audioApi;
  final LocalStorageService _storage;
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _backendAvailable = false;
  bool _initialized = false;

  bool get isBackendAvailable => _backendAvailable;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Check backend TTS availability once at startup. If the backend says
    // no, every subsequent call goes straight to on-device synthesis — no
    // wasted round-trips.
    try {
      _backendAvailable = await _audioApi.isTtsAvailable();
      _log.i('init: backend=${_backendAvailable ? "available" : "unavailable"}');
    } catch (e) {
      _backendAvailable = false;
      _log.w('init: backend check failed, falling back to local-only — $e');
    }

    // Init local fallback. Don't fix the language here — we re-apply it
    // per call in [_localSpeak] so a single TTS instance can swap between
    // Arabic and English. Rate 0.5 is flutter_tts's natural cadence;
    // pitch 1.0 sounds less cartoonish than the old 1.1 for adult voices.
    try {
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
      _log.i('init: local engine ready');
    } catch (e) {
      _log.e('init: failed to configure local TTS', e);
    }
  }

  /// Heuristic: any character in the Arabic unicode block ⇒ Arabic.
  bool _isArabic(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0x0600 && code <= 0x06FF) return true;
    }
    return false;
  }

  /// Speak a quiz question — backend Edge-TTS if available (best quality),
  /// otherwise on-device `flutter_tts` with the right language picked.
  ///
  /// On backend failure for any reason (network down, 401, ExoPlayer codec
  /// glitch, surrogate-encoding edge case in the sidecar) we silently fall
  /// back to local synthesis. The child never sees a broken speaker button.
  Future<void> speakQuestion(int questionId, String text) async {
    if (!_backendAvailable) {
      _log.i('speakQuestion id=$questionId → local (backend unavailable)');
      await _localSpeak(text);
      return;
    }

    try {
      final result = await _audioApi.readQuestion(questionId);
      final audioUrl = result['audioUrl'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) {
        // Backend responded but produced no URL — usually means the server
        // couldn't synthesize (e.g. Python sidecar exit 4) and returned a
        // message field instead. Falling back to local keeps the UI alive.
        _log.w('speakQuestion id=$questionId → local '
            '(backend returned no audioUrl, msg=${result['message']})');
        await _localSpeak(text);
        return;
      }

      final playableUrl = ApiConfig.resolveMediaUrl(audioUrl);
      final headers = await _authHeaders();
      _log.i('speakQuestion id=$questionId → backend ($playableUrl)');
      await _audioPlayer.setUrl(playableUrl, headers: headers);
      await _audioPlayer.play();
    } catch (e) {
      _log.w('speakQuestion id=$questionId → local (backend failed: $e)');
      await _localSpeak(text);
    }
  }

  /// Speak arbitrary text (teaching cards, hint reveals) — always local,
  /// because the backend caches by questionId and arbitrary strings don't
  /// have a stable cache key.
  Future<void> speakText(String text) async {
    _log.i('speakText → local (${text.length} chars)');
    await _localSpeak(text);
  }

  /// On-device fallback. Re-applies language per call so the same TTS
  /// instance handles both Arabic and English without bleeding phonemes
  /// from one language into the other.
  Future<void> _localSpeak(String text) async {
    if (text.isEmpty) return;
    try {
      final isAr = _isArabic(text);
      await _flutterTts.setLanguage(isAr ? 'ar' : 'en-US');
      // English benefits from a slightly faster cadence than Arabic —
      // English words are shorter, so equal-rate speech feels lethargic.
      await _flutterTts.setSpeechRate(isAr ? 0.5 : 0.55);
      await _flutterTts.speak(text);
    } catch (e) {
      _log.e('local speak failed', e);
    }
  }

  /// Builds the `Authorization: Bearer <jwt>` header needed for
  /// `/uploads/audio/**`. Returns `null` if no token is available — the
  /// caller will still attempt the request, the server will 401, and we'll
  /// fall back to local TTS.
  Future<Map<String, String>?> _authHeaders() async {
    try {
      final token = await _storage.getToken();
      if (token == null || token.isEmpty) {
        _log.w('no JWT in secure storage — playback will likely 401');
        return null;
      }
      return {'Authorization': 'Bearer $token'};
    } catch (e) {
      _log.e('failed to read JWT from secure storage', e);
      return null;
    }
  }

  /// Stop all audio (both backend playback and local engine).
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  /// Dispose resources.
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
