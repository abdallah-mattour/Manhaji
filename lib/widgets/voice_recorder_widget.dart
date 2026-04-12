import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';

/// A child-friendly voice recorder widget with visual feedback.
class VoiceRecorderWidget extends StatefulWidget {
  final Future<void> Function(String audioPath) onRecordingComplete;
  final bool enabled;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.enabled = true,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

enum RecordingState { idle, recording, processing }

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  RecordingState _state = RecordingState.idle;
  int _recordingSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

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

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى السماح بالوصول إلى الميكروفون')),
        );
      }
      return;
    }

    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '',
      );
      setState(() {
        _state = RecordingState.recording;
        _recordingSeconds = 0;
      });
      _pulseController.repeat(reverse: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= maxSeconds) {
          _stopRecording();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();

    final path = await _recorder.stop();
    if (path == null) {
      setState(() => _state = RecordingState.idle);
      return;
    }

    setState(() => _state = RecordingState.processing);
    await widget.onRecordingComplete(path);
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
        const Text(
          'أو تكلّم إجابتك',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _buildRecordButton(),
        if (_state == RecordingState.recording) ...[
          const SizedBox(height: 8),
          Text(
            '$_recordingSeconds / $maxSeconds ثانية',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
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
                valueColor: const AlwaysStoppedAnimation(AppColors.error),
                minHeight: 4,
              ),
            ),
          ),
        ],
        if (_state == RecordingState.processing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'جاري معالجة الصوت...',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
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
                    ? AppColors.error
                    : isProcessing
                    ? Colors.grey
                    : AppColors.accent,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.4),
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
