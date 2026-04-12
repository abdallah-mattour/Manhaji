import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/quiz.dart';

class McqWidget extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const McqWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('MCQ build options: ${question.options}');
    debugPrint('MCQ build options length: ${question.options?.length}');
    final options = question.options ?? [];
    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: const Text(
          'لا توجد خيارات لهذا السؤال',
          style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
        ),
      );
    }

    return Column(
      children: options.map((option) {
        final isSelected = selectedAnswer == option;
        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE0E0E0);
        IconData? icon;

        if (isAnswered) {
          if (option == correctAnswer) {
            bgColor = Colors.green.shade50;
            borderColor = Colors.green;
            icon = Icons.check_circle;
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            icon = Icons.cancel;
          }
        } else if (isSelected) {
          bgColor = AppColors.secondary.withValues(alpha: 0.08);
          borderColor = AppColors.secondary;
        }

        return GestureDetector(
          onTap: isAnswered ? null : () => onSelect(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    color: icon == Icons.check_circle
                        ? Colors.green
                        : Colors.red,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
