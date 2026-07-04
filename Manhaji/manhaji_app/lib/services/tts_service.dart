import 'package:just_audio/just_audio.dart';
import '../config/api_config.dart';
import '../utils/app_log.dart';
import 'audio_focus.dart';
import 'audio_service.dart';
import 'local_storage_service.dart';

/// Speaks text aloud through the backend's neural-TTS pipeline ONLY.
///
/// (2026-07-03) The on-device `flutter_tts` fallback was removed on request:
/// if the backend can't produce audio (no key, offline, synth failure) the
/// speaker stays silent — logged under `[tts]`, never a robotic offline voice.
///
/// ### Single-voice guarantee
///
/// All TTS goes through ONE [AudioPlayer]. Every new utterance:
/// 1. bumps [_playSeq] so any in-flight older request aborts at its next
///    await (two fast taps can't interleave),
/// 2. claims [AudioFocus] so any OTHER audio source in the app (the authored
///    clip player in `QuestionMediaHeader`) is stopped first,
/// 3. stops this player's own previous utterance before fetching the new one.
///
/// ### Audio URL contract
///
/// The backend returns a relative path like `uploads/audio/<name>.mp3`.
/// Playback needs (1) [ApiConfig.resolveMediaUrl] to prefix the server
/// origin, (2) a JWT bearer header because `/uploads/audio/**` is gated as
/// `authenticated()` (audit fix S4), and (3) cleartext permission for the
/// emulator loopback — see `network_security_config.xml`.
///
/// ### Endpoints
///
/// * [speakQuestion] → `POST /audio/question/{id}/read` (cached on the
///   Question row, content-fingerprinted).
/// * [speakText] → `POST /audio/speak` (cached on disk by text fingerprint —
///   any repeated phrase synthesizes once, ever). An in-memory URL cache on
///   top skips the round-trip for phrases repeated within this session
///   ("أحسنت!", teaching cards revisited, etc.).
class TtsService {
  TtsService(this._audioApi, this._storage);

  static final AppLog _log = AppLog.tag('tts');

  final AudioApiService _audioApi;
  final LocalStorageService _storage;
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Stable closure identity for [AudioFocus] claim/release pairing.
  late final Future<void> Function() _focusStopper = _stopPlayback;

  /// Monotonic utterance counter — see class doc.
  int _playSeq = 0;

  /// Session cache: sanitized spoken text → backend audio URL.
  final Map<String, String> _urlCache = {};

  bool _disposed = false;

  /// One-time availability probe. Purely informational since the fallback is
  /// gone — every speak call tries the API regardless, so a backend that was
  /// down at screen-open and recovers later starts speaking again by itself.
  Future<void> init() async {
    try {
      final available = await _audioApi.isTtsAvailable();
      _log.i(available
          ? 'init: backend TTS available'
          : 'init: backend TTS UNAVAILABLE — speakers stay silent until it recovers');
    } catch (e) {
      _log.w('init: availability check failed (speakers silent until the '
          'backend responds) — $e');
    }
  }

  /// Speak a quiz question via the per-question backend cache.
  Future<void> speakQuestion(int questionId, String text) async {
    final seq = ++_playSeq;
    await AudioFocus.claim(_focusStopper);
    try {
      await _audioPlayer.stop();
      final result = await _audioApi.readQuestion(questionId);
      if (seq != _playSeq || _disposed) return;

      final audioUrl = result['audioUrl'] as String?;
      if (audioUrl == null || audioUrl.isEmpty) {
        _log.w('speakQuestion id=$questionId → silent '
            '(no audioUrl, msg=${result['message']})');
        return;
      }
      _log.i('speakQuestion id=$questionId → backend');
      await _playUrl(audioUrl, seq);
    } catch (e) {
      _log.w('speakQuestion id=$questionId → silent (backend failed: $e)');
    }
  }

  /// Speak arbitrary text (teaching cards, feedback phrases, pronunciation /
  /// reading targets) via the generic fingerprint-cached backend endpoint.
  Future<void> speakText(String text) async {
    final cleaned = _sanitizeForSpeech(text);
    if (cleaned.isEmpty) return;

    final seq = ++_playSeq;
    await AudioFocus.claim(_focusStopper);
    try {
      await _audioPlayer.stop();

      String? audioUrl = _urlCache[cleaned];
      if (audioUrl == null) {
        final result = await _audioApi.speakText(cleaned);
        if (seq != _playSeq || _disposed) return;
        audioUrl = result['audioUrl'] as String?;
        if (audioUrl == null || audioUrl.isEmpty) {
          _log.w('speakText → silent (no audioUrl, msg=${result['message']})');
          return;
        }
        _urlCache[cleaned] = audioUrl;
        _log.i('speakText → backend fresh (${cleaned.length} chars)');
      } else {
        _log.i('speakText → backend cached-url (${cleaned.length} chars)');
      }

      if (seq != _playSeq || _disposed) return;
      await _playUrl(audioUrl, seq);
    } catch (e) {
      // Evict on failure — the cached URL may point at a cleaned-up file;
      // the next tap will re-request (and the backend re-synthesizes).
      _urlCache.remove(cleaned);
      _log.w('speakText → silent (backend failed: $e)');
    }
  }

  Future<void> _playUrl(String audioUrl, int seq) async {
    final playableUrl = ApiConfig.resolveMediaUrl(audioUrl);
    final headers = await _authHeaders();
    if (seq != _playSeq || _disposed) return;
    await _audioPlayer.setUrl(playableUrl, headers: headers);
    if (seq != _playSeq || _disposed) return;
    await _audioPlayer.play();
  }

  /// Replace the fill-in-the-blank marker ("___") with a spoken pause (…) and
  /// collapse the resulting double spaces. Mirrors the backend's
  /// sanitizeForSpeech so the fingerprint cache keys stay aligned.
  String _sanitizeForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'_{2,}'), ' … ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  /// Builds the `Authorization: Bearer <jwt>` header needed for
  /// `/uploads/audio/**`. Returns `null` if no token is available — the
  /// caller still attempts the request; the server 401s and the utterance
  /// stays silent (logged).
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

  /// Focus-callback: cancel any in-flight utterance and silence the player.
  Future<void> _stopPlayback() async {
    _playSeq++;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Stop all audio.
  Future<void> stop() async {
    await _stopPlayback();
    AudioFocus.release(_focusStopper);
  }

  /// Dispose resources.
  Future<void> dispose() async {
    _disposed = true;
    _playSeq++;
    AudioFocus.release(_focusStopper);
    try {
      await _audioPlayer.dispose();
    } catch (_) {}
  }
}
