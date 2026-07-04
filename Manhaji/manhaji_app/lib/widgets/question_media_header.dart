import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../config/api_config.dart';
import '../services/audio_focus.dart';
import '../services/local_storage_service.dart';

/// Renders the optional image + audio attached to a question.
///
/// Both fields are optional on [Question]; nothing renders when both are null
/// or empty. The image is shown inline (capped at 180px height to leave room
/// for the prompt + answer area on small phones), and the audio is exposed as
/// a chunky tap-target play button — kids can replay as many times as they
/// like before answering.
///
/// The widget is fail-soft: if the asset 404s (typo in JSON, missing file in
/// the bundle), the user simply sees no image / a no-op button. Never throws.
class QuestionMediaHeader extends StatefulWidget {
  const QuestionMediaHeader({
    super.key,
    required this.imageUrl,
    required this.audioUrl,
    this.english = false,
  });

  final String? imageUrl;
  final String? audioUrl;

  /// Full English experience (2026-07-03): play/stop labels in English.
  final bool english;

  bool get _hasAnything =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (audioUrl != null && audioUrl!.isNotEmpty);

  @override
  State<QuestionMediaHeader> createState() => _QuestionMediaHeaderState();
}

class _QuestionMediaHeaderState extends State<QuestionMediaHeader> {
  AudioPlayer? _player;
  // Audit-3 fix (2026-05-15): the playerStateStream subscription was
  // (a) re-attached on every _toggleAudio play, and (b) never cancelled
  // on dispose. After a child taps "استمع" N times, N listeners accumulate
  // and keep firing setState even after navigation. Track the subscription
  // so we can replace it cleanly and cancel on dispose.
  StreamSubscription<PlayerState>? _stateSub;
  bool _playing = false;

  /// Single-voice coordination (2026-07-03): stable closure handed to
  /// [AudioFocus] so TTS playback stops this player and vice versa.
  late final Future<void> Function() _focusStopper = _stopForFocus;

  Future<void> _stopForFocus() async {
    try {
      await _player?.stop();
    } catch (_) {}
    if (mounted && _playing) setState(() => _playing = false);
  }

  @override
  void dispose() {
    // Audit-3 fix (2026-05-15): cancel the listener and stop playback BEFORE
    // disposing the player. Without the stop(), zombie audio can keep playing
    // for a moment after the widget is gone.
    AudioFocus.release(_focusStopper);
    _stateSub?.cancel();
    _stateSub = null;
    final p = _player;
    _player = null;
    () async {
      try {
        await p?.stop();
      } catch (_) {/* ignore */}
      await p?.dispose();
    }();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.audioUrl;
    if (url == null || url.isEmpty) return;
    final resolved = ApiConfig.resolveMediaUrl(url);
    try {
      _player ??= AudioPlayer();
      if (_playing) {
        await _player!.stop();
        if (mounted) setState(() => _playing = false);
        return;
      }
      // Single-voice rule: silence any TTS (or other clip) before we start.
      await AudioFocus.claim(_focusStopper);
      // Backend cached audio lives under `/uploads/audio/**`, which is
      // gated as `authenticated()` in SecurityConfig (audit fix S4 — voice
      // recordings are PII). Without the bearer header ExoPlayer gets a
      // 401 and reports it as a generic "Source error". Bundled curriculum
      // audio under `/uploads/images/**` and `static/assets/**` is public,
      // so sending the header there is harmless — the server ignores it.
      final headers = await _authHeaders();
      await _player!.setUrl(resolved, headers: headers);
      // Audit-3 fix: cancel any prior listener BEFORE attaching a new one,
      // so repeated taps don't leak listeners.
      await _stateSub?.cancel();
      _stateSub = _player!.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() => _playing = false);
        }
      });
      if (mounted) setState(() => _playing = true);
      await _player!.play();
    } catch (_) {
      // Silent fallback — bad URL or codec; just reset the UI.
      if (mounted) setState(() => _playing = false);
    }
  }

  /// Pulls the JWT from secure storage so we can attach
  /// `Authorization: Bearer <jwt>` to playback requests against
  /// `/uploads/audio/**`. Returns `null` if no token is available, in which
  /// case [_toggleAudio] still tries the request — the server's 401 then
  /// trips the catch block and the UI resets cleanly.
  Future<Map<String, String>?> _authHeaders() async {
    try {
      final storage = context.read<LocalStorageService>();
      final token = await storage.getToken();
      if (token == null || token.isEmpty) return null;
      return {'Authorization': 'Bearer $token'};
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._hasAnything) return const SizedBox.shrink();

    final children = <Widget>[];
    final imageUrl = widget.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Clean-image system (2026-07-03): bundled Flutter assets
      // (assets/openmoji/...) load locally; anything else is a backend URL.
      // Both fail soft (no image, no crash) on a bad path.
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageUrl.startsWith('assets/')
              ? Image.asset(
                  imageUrl,
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                )
              : Image.network(
                  ApiConfig.resolveMediaUrl(imageUrl),
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
        ),
      );
    }

    final audioUrl = widget.audioUrl;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 8));
      children.add(
        Material(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _toggleAudio,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _playing
                        ? (widget.english ? 'Stop' : 'إيقاف')
                        : (widget.english ? 'Listen' : 'استمع'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
