import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app/theme.dart';
import '../services/audio_focus.dart';
import '../utils/app_log.dart';

/// A child-friendly voice recorder widget with visual feedback.
///
/// ### Recording pipeline
///
/// 1. User taps the mic button → request `Permission.microphone` if not yet
///    granted (Android shows a system dialog; iOS the equivalent).
/// 2. Allocate a real on-disk path under the OS temp dir
///    (`<tempDir>/manhaji_rec_<ts>.m4a`). Previously this widget passed
///    `path: ''` to `_recorder.start()`, which is undefined behaviour in
///    `record` 5.x — the file landed in an unknown location and the
///    child saw nothing happen.
/// 3. Start the AAC-LC encoder (M4A container) — Gemini's audio
///    transcription accepts M4A natively, no transcode needed server-side.
/// 4. Pulse the button + tick the 15-second countdown. Auto-stop on
///    timeout so a kid leaving the mic on doesn't ship 30 MB of silence
///    to the backend.
/// 5. Stop → handoff `path` to the parent's `onRecordingComplete`
///    callback (which uploads, transcribes, scores).
///
/// ### Logging
///
/// Every transition emits an `[stt]`-tagged line so a tester can follow
/// the flow in the console: tap → permission outcome → start → stop with
/// duration → handoff. If the recorder fails at any step, the error is
/// logged AND surfaced to the user via a SnackBar — no silent failures.
class VoiceRecorderWidget extends StatefulWidget {
  final Future<void> Function(String audioPath) onRecordingComplete;
  final bool enabled;

  /// Full English experience (2026-07-03): English-subject lessons show
  /// prompts, countdown, and error snackbars in English.
  final bool english;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.enabled = true,
    this.english = false,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

enum RecordingState { idle, recording, processing }

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  static final AppLog _log = AppLog.tag('stt');

  final _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  int _recordingSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  String? _currentPath;

  static const int maxSeconds = 15;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  /// Allocate a writable path under the OS temp dir with a unique name.
  /// AAC-LC packaged in an MP4/M4A container — both Android's native
  /// recorder and Gemini's audio transcription understand this directly.
  Future<String> _newTempPath() async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${tempDir.path}${Platform.pathSeparator}manhaji_rec_$ts.m4a';
  }

  Future<void> _showError(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startRecording() async {
    // Single-voice rule (2026-07-03): silence any playing TTS / audio clip
    // before the mic opens, so the app's own voice never bleeds into the
    // child's recording (which would corrupt the transcription).
    await AudioFocus.stopCurrent();

    _log.i('start: requesting microphone permission');
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _log.w('start: microphone permission denied (status=$status)');
      await _showError(widget.english
          ? 'Please allow microphone access'
          : 'يرجى السماح بالوصول إلى الميكروفون');
      return;
    }

    if (!await _recorder.hasPermission()) {
      _log.w('start: recorder reports no permission even though OS granted');
      await _showError(widget.english
          ? 'Could not start the microphone'
          : 'تعذّر تشغيل الميكروفون');
      return;
    }

    try {
      _currentPath = await _newTempPath();
      _log.i('start: writing to $_currentPath');
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _currentPath!,
      );
      if (!mounted) return;
      setState(() {
        _state = RecordingState.recording;
        _recordingSeconds = 0;
      });
      _pulseController.repeat(reverse: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= maxSeconds) {
          _log.i('auto-stop: hit ${maxSeconds}s ceiling');
          _stopRecording();
        }
      });
    } catch (e) {
      _log.e('start: recorder.start() threw', e);
      _currentPath = null;
      if (mounted) setState(() => _state = RecordingState.idle);
      await _showError(widget.english
          ? 'Could not start recording. Try again.'
          : 'تعذّر بدء التسجيل. حاول مرة أخرى.');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    _pulseController.stop();
    final duration = _recordingSeconds;

    String? finalPath;
    try {
      finalPath = await _recorder.stop();
    } catch (e) {
      _log.e('stop: recorder.stop() threw', e);
    }

    // record 5.x returns the path it actually wrote to; this should match
    // what we passed in `_startRecording`, but trust the SDK's value.
    final path = finalPath ?? _currentPath;
    if (path == null || path.isEmpty) {
      _log.w('stop: no output path (recorder.stop returned null)');
      if (mounted) setState(() => _state = RecordingState.idle);
      await _showError(widget.english
          ? 'Could not save the audio. Try again.'
          : 'لم نتمكن من حفظ الصوت. حاول مرة أخرى.');
      return;
    }

    // Sanity check — the recorder occasionally returns a path before the
    // file is flushed to disk on slow devices. We don't want to ship a
    // 0-byte file to Gemini.
    final file = File(path);
    int sizeBytes = 0;
    try {
      sizeBytes = await file.length();
    } catch (_) {/* file doesn't exist */}

    _log.i('stop: ${duration}s recorded, ${sizeBytes}B at $path');

    if (sizeBytes == 0) {
      _log.w('stop: file is empty — refusing to upload');
      if (mounted) setState(() => _state = RecordingState.idle);
      await _showError(widget.english
          ? "We didn't hear anything. Get closer to the microphone and try again."
          : 'لم نسمع صوتاً. اقترب من الميكروفون وحاول مرة أخرى.');
      return;
    }

    if (!mounted) return;
    setState(() => _state = RecordingState.processing);
    try {
      await widget.onRecordingComplete(path);
    } catch (e) {
      _log.e('handoff: parent onRecordingComplete threw', e);
    }
    if (mounted) {
      setState(() => _state = RecordingState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          widget.english ? 'Or speak your answer' : 'أو تكلّم إجابتك',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 8),
        _buildRecordButton(),
        if (_state == RecordingState.recording) ...[
          const SizedBox(height: 8),
          Text(
            widget.english
                ? '$_recordingSeconds / $maxSeconds seconds'
                : '$_recordingSeconds / $maxSeconds ثانية',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _recordingSeconds / maxSeconds,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryRed),
                minHeight: 4,
              ),
            ),
          ),
        ],
        if (_state == RecordingState.processing)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.english
                      ? 'Processing audio...'
                      : 'جاري معالجة الصوت...',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppTheme.textGray),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecordButton() {
    final isRecording = _state == RecordingState.recording;
    final isProcessing = _state == RecordingState.processing;

    return GestureDetector(
      onTap: isProcessing
          ? null
          : isRecording
              ? _stopRecording
              : _startRecording,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isRecording ? 1.0 + _pulseController.value * 0.12 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? AppTheme.primaryRed
                    : isProcessing
                        ? Colors.grey
                        : AppTheme.primaryOrange,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryRed.withValues(alpha: 0.4),
                          blurRadius: 16 + _pulseController.value * 8,
                          spreadRadius: _pulseController.value * 4,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          );
        },
      ),
    );
  }
}
