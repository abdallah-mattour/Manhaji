import 'package:flutter/material.dart';
import '../../core/widgets/app_text_form_field.dart';
import '../../core/theme/app_colors.dart';

class FillBlankWidget extends StatelessWidget {
  final String questionText;
  final TextEditingController controller;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final ValueChanged<String> onChanged;

  const FillBlankWidget({
    super.key,
    required this.questionText,
    required this.controller,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final parts = questionText.split('___');

    return Column(
      children: [
        if (parts.length > 1)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: parts[0]),
                  WidgetSpan(
                    child: Container(
                      width: 80,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isAnswered
                                ? (isCorrect ? Colors.green : Colors.red)
                                : AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          selectedAnswer ?? '...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isAnswered
                                ? (isCorrect ? Colors.green : Colors.red)
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (parts.length > 1) TextSpan(text: parts[1]),
                ],
              ),
            ),
          ),
        AppTextFormField(
          controller: controller,
          enabled: !isAnswered,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
          decoration: InputDecoration(
            hintText: 'اكتب الكلمة الناقصة...',
            filled: true,
            fillColor: isAnswered ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            prefixIcon: const Icon(Icons.edit_note, color: AppColors.accent),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
