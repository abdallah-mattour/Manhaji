// lib/widgets/question_widgets/short_answer_widget.dart
import 'package:flutter/material.dart';

import '../../core/widgets/app_text_form_field.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
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
        AppTextFormField(
          controller: controller,
          enabled: !isAnswered,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا...',
            filled: true,
            fillColor: isAnswered
                ? const Color(0xFFF1F5F9) // لون رمادي فاتح نظيف
                : AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          onChanged: onChanged,
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
