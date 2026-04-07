import 'package:flutter/material.dart';
import '../../app/theme.dart';
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
    final options = question.options ?? [];

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
          bgColor = AppTheme.primaryBlue.withValues(alpha: 0.08);
          borderColor = AppTheme.primaryBlue;
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon,
                      color: icon == Icons.check_circle ? Colors.green : Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
