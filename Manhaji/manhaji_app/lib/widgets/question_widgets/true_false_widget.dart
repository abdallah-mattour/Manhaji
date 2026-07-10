import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../utils/text_direction.dart';

class TrueFalseWidget extends StatelessWidget {
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  /// The question prompt — used to pick the language of the True/False
  /// buttons so an English question shows "True"/"False" and an Arabic
  /// question shows "صح"/"خطأ". Without this the widget hardcoded صح/خطأ,
  /// which made every English TRUE_FALSE question unanswerable (the submitted
  /// "صح" never matched the stored "True", so it always scored wrong and the
  /// picked button always went red).
  final String questionText;

  const TrueFalseWidget({
    super.key,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
    this.questionText = '',
  });

  @override
  Widget build(BuildContext context) {
    // English subject questions use "True"/"False"; Arabic-script subjects
    // (Arabic, Math, Religion) use "صح"/"خطأ". The stored correctAnswer is in
    // the same language as the question, so the button values match it.
    final isEnglish = directionOf(questionText) == TextDirection.ltr;
    final trueValue = isEnglish ? 'True' : 'صح';
    final falseValue = isEnglish ? 'False' : 'خطأ';

    return Row(
      children: [
        Expanded(
          child: _TfButton(
            value: trueValue,
            icon: Icons.check_rounded,
            accentColor: AppTheme.primaryGreen,
            isSelected: selectedAnswer == trueValue,
            isAnswered: isAnswered,
            isCorrect: isCorrect,
            correctAnswer: correctAnswer,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _TfButton(
            value: falseValue,
            icon: Icons.close_rounded,
            accentColor: AppTheme.primaryRed,
            isSelected: selectedAnswer == falseValue,
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
      // On tap (before grading) keep the card WHITE so the label stays fully
      // legible — the thick accent border + accent-tinted icon/text signal the
      // choice. Previously the whole button filled with the accent tint, which
      // read as "the button turned red/green and hid the writing". The light
      // green/red feedback fill only appears AFTER answering (branch above).
      color = AppTheme.cardWhite;
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
