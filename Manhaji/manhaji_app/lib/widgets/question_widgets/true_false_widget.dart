import 'package:flutter/material.dart';
import '../../app/theme.dart';

class TrueFalseWidget extends StatelessWidget {
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const TrueFalseWidget({
    super.key,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TfButton(
            value: 'صح',
            icon: Icons.check_rounded,
            accentColor: AppTheme.primaryGreen,
            isSelected: selectedAnswer == 'صح',
            isAnswered: isAnswered,
            isCorrect: isCorrect,
            correctAnswer: correctAnswer,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _TfButton(
            value: 'خطأ',
            icon: Icons.close_rounded,
            accentColor: AppTheme.primaryRed,
            isSelected: selectedAnswer == 'خطأ',
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

class _TfButton extends StatelessWidget {
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const _TfButton({
    required this.value,
    required this.icon,
    required this.accentColor,
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
    Color contentColor = AppTheme.textDark;

    if (isAnswered) {
      if (value == correctAnswer) {
        color = AppTheme.successContainer;
        borderColor = AppTheme.primaryGreen;
        contentColor = AppTheme.primaryGreenDeep;
      } else if (isSelected && !isCorrect) {
        color = AppTheme.errorContainer;
        borderColor = AppTheme.primaryRed;
        contentColor = AppTheme.primaryRedDeep;
      } else {
        color = AppTheme.surfaceSubtle;
        borderColor = AppTheme.surfaceMuted;
        contentColor = AppTheme.textLight;
      }
    } else if (isSelected) {
      color = accentColor.withValues(alpha: 0.15);
      borderColor = accentColor;
      contentColor = accentColor;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => onSelect(value),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: contentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: contentColor),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
