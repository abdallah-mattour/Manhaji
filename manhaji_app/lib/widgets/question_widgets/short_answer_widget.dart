import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../voice_recorder_widget.dart';

class ShortAnswerWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnswered;
  final bool voiceEnabled;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String audioPath)? onVoiceComplete;

  const ShortAnswerWidget({
    super.key,
    required this.controller,
    required this.isAnswered,
    this.voiceEnabled = true,
    required this.onChanged,
    this.onVoiceComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          enabled: !isAnswered,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا...',
            hintStyle: const TextStyle(
                fontFamily: 'Cairo', color: AppTheme.textLight),
            filled: true,
            fillColor: isAnswered
                ? AppTheme.textLight.withValues(alpha: 0.08)
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
        if (voiceEnabled && onVoiceComplete != null)
          VoiceRecorderWidget(
            enabled: !isAnswered,
            onRecordingComplete: onVoiceComplete!,
          ),
      ],
    );
  }
}
