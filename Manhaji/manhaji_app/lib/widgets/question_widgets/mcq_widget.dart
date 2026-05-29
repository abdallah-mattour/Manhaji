import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';

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
    final options = question.options ?? const <String>[];

    return Column(
      children: [
        for (int i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _McqOption(
              option: options[i],
              isSelected: selectedAnswer == options[i],
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              correctAnswer: correctAnswer,
              onSelect: onSelect,
            ),
          ),
      ],
    );
  }
}

class _McqOption extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const _McqOption({
    required this.option,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.cardWhite;
    Color borderColor = AppTheme.surfaceMuted;
    Color textColor = AppTheme.textDark;

    if (isAnswered) {
      if (option == correctAnswer) {
        color = AppTheme.successContainer;
        borderColor = AppTheme.primaryGreen;
        textColor = AppTheme.primaryGreenDeep;
      } else if (isSelected && !isCorrect) {
        color = AppTheme.errorContainer;
        borderColor = AppTheme.primaryRed;
        textColor = AppTheme.primaryRedDeep;
      } else {
        color = AppTheme.surfaceSubtle;
        borderColor = AppTheme.surfaceMuted;
        textColor = AppTheme.textLight;
      }
    } else if (isSelected) {
      color = AppTheme.infoContainer;
      borderColor = AppTheme.primaryBlue;
      textColor = AppTheme.primaryBlueDeep;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => onSelect(option),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: borderColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                // Per-option direction so English options keep their "?" on
                // the right under the app's ambient RTL; Arabic stays RTL.
                textDirection: directionOf(option),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (isAnswered && (option == correctAnswer || (isSelected && !isCorrect)))
              Icon(
                option == correctAnswer ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: borderColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
