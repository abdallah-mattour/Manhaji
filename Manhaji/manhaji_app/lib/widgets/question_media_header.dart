import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../app/theme.dart';
import '../config/api_config.dart';

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
  });

  final String? imageUrl;
  final String? audioUrl;

  bool get _hasAnything =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (audioUrl != null && audioUrl!.isNotEmpty);

  @override
  State<QuestionMediaHeader> createState() => _QuestionMediaHeaderState();
}

class _QuestionMediaHeaderState extends State<QuestionMediaHeader> {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _player?.dispose();
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
      await _player!.setUrl(resolved);
      // Listen-once for natural completion so the icon flips back.
      _player!.playerStateStream.listen((s) {
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

  @override
  Widget build(BuildContext context) {
    if (!widget._hasAnything) return const SizedBox.shrink();

    final children = <Widget>[];
    final imageUrl = widget.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      children.add(
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
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
                    _playing ? 'إيقاف' : 'استمع',
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
